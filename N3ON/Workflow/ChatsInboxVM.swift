// ChatsInboxVM.swift
// N3ON — Workflow layer
// Drives ChatsInboxView. Builds ChatSummary objects from ChatRoom records,
// resolves participant names, tracks unread counts, and observes Message
// mutations for real-time inbox refresh.

import Foundation
import Amplify

// MARK: - ChatSummary DTO

struct ChatSummary: Identifiable, Equatable {
    let id: String          // chatRoomID
    let title: String
    let last: String?
    let lastAt: Date?
    let unread: Int
    let isEvent: Bool
    let eventDate: Date?
    let expiresAt: Date?    // non-nil for event rooms — 48 hrs after eventDate
    let pinned: Bool

    var isExpired: Bool {
        guard let exp = expiresAt else { return false }
        return Date() > exp
    }
}

// MARK: - ViewModel

@MainActor
final class ChatsInboxVM: ObservableObject {
    @Published var pinned: [ChatSummary] = []
    @Published var others: [ChatSummary] = []
    @Published var loading = false

    private(set) var me: String?
    private var observationTask: Task<Void, Never>?
    // Coalesces bursts of DataStore mutations into a single refresh. Each new
    // event cancels the pending refresh and schedules a fresh one 400ms later,
    // so a single refresh fires after the burst settles instead of N of them.
    private var refreshTask: Task<Void, Never>?

    func start() {
        Task { await refresh() }
        startObserving()
    }

    func refresh() async {
        loading = true
        defer { loading = false }
        do {
            let userID = try await AuthService.currentUserId()
            me = userID

            let roomIDs = try await ChatRoomService.roomIDs(for: userID)
            guard !roomIDs.isEmpty else { pinned = []; others = []; return }

            // Amplify DataStore has no .in() predicate — query all and filter in memory
            let allRooms = try await ChatRoomService.allRooms()
            let rooms = allRooms.filter { roomIDs.contains($0.id) }

            // Each room's summary fires 2–4 independent DataStore queries.
            // Running them concurrently turns N serial round-trips into roughly 1×.
            var summaries: [ChatSummary] = []
            try await withThrowingTaskGroup(of: ChatSummary?.self) { group in
                for room in rooms {
                    group.addTask { [weak self] in
                        try await self?.summarize(room: room, me: userID)
                    }
                }
                for try await result in group {
                    if let s = result { summaries.append(s) }
                }
            }

            // Active event rooms float to top, sorted by event date ascending.
            // Expired event rooms and DM rooms sort by most recent message.
            let pinnedItems = summaries
                .filter { $0.pinned }
                .sorted {
                    if let l = $0.eventDate, let r = $1.eventDate, l != r { return l < r }
                    return ($0.lastAt ?? .distantPast) > ($1.lastAt ?? .distantPast)
                }
            let otherItems = summaries
                .filter { !$0.pinned }
                .sorted { ($0.lastAt ?? .distantPast) > ($1.lastAt ?? .distantPast) }

            self.pinned = pinnedItems
            self.others = otherItems
        } catch {
            // Auth failure or DataStore offline — silently degrade to empty state
        }
    }

    deinit {
        observationTask?.cancel()
        refreshTask?.cancel()
    }

    // MARK: - Private

    private func summarize(room: ChatRoom, me: String) async throws -> ChatSummary? {
        // Participants and unread count are independent queries — overlap them.
        async let othersFetch = ChatRoomService.participants(for: room.id, excludingID: me)
        async let unreadFetch = ChatRoomService.unreadCount(in: room.id, excludingSenderID: me)
        let others = try await othersFetch
        let otherNames = others.map { $0.username }

        let title: String = {
            if room.associatedEvent != nil { return "Event Chat" }
            if otherNames.count == 1       { return otherNames[0] }
            if otherNames.count > 1        { return otherNames.joined(separator: ", ") }
            return room.name
        }()

        let unread = try await unreadFetch

        var pinned    = false
        var eventDate: Date? = nil
        var expiresAt: Date? = nil

        if let eid = room.associatedEvent,
           let event = try await EventService.fetchEvent(byId: eid) {
            eventDate = event.eventDate.foundationDate
            expiresAt = eventDate.map { $0.addingTimeInterval(chatEventExpiryInterval) }
            let expired = expiresAt.map { Date() > $0 } ?? false
            if !expired {
                if event.hostDJID == me {
                    pinned = true
                } else if let venue = try await VenueService.fetch(byId: event.venueID),
                          venue.owner?.id == me {
                    pinned = true
                }
            }
        }

        return ChatSummary(
            id: room.id,
            title: title,
            last: room.lastMessage,
            lastAt: room.lastMessageTimestamp?.foundationDate,
            unread: unread,
            isEvent: room.associatedEvent != nil,
            eventDate: eventDate,
            expiresAt: expiresAt,
            pinned: pinned
        )
    }

    /// Observe Message mutations and refresh.
    /// Refreshes are debounced: N rapid mutations → 1 refresh, 400ms after the burst ends.
    private func startObserving() {
        observationTask?.cancel()
        observationTask = Task { [weak self] in
            guard let self else { return }
            do {
                for try await change in Amplify.DataStore.observe(Message.self) {
                    guard !Task.isCancelled else { return }
                    guard ["create", "update"].contains(change.mutationType) else { continue }
                    self.scheduleDebouncedRefresh()
                }
            } catch { }
        }
    }

    private func scheduleDebouncedRefresh() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            await self?.refresh()
        }
    }
}
