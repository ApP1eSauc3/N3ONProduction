//
//  ChatsInboxView.swift
//  N3ON
//
//  Created by liam howe on 28/8/2025.
//

import SwiftUI
import Combine
import Amplify

struct ChatSummary: Identifiable, Equatable {
    let id: String
    let title: String
    let last: String?
    let lastAt: Date?
    let unread: Int
    let isEvent: Bool
    let eventDate: Date?
    let pinned: Bool
}

@MainActor
final class ChatsInboxVM: ObservableObject {
    @Published var pinned: [ChatSummary] = []
    @Published var others: [ChatSummary] = []
    @Published var loading = false

    private var bag = Set<AnyCancellable>()
    private(set) var me: String?

    func start() {
        Task { await refresh() }
        observe()
    }

    func refresh() async {
        loading = true
        defer { loading = false }
        do {
            let auth = try await Amplify.Auth.getCurrentUser()
            me = auth.userId

            let links = try await Amplify.DataStore.query(
                UserChatRooms.self,
                where: UserChatRooms.keys.userId == auth.userId
            )
            let roomIds = Array(Set(links.compactMap { $0.chatRoom.id }))
            guard !roomIds.isEmpty else { pinned = []; others = []; return }

            let rooms = try await Amplify.DataStore.query(ChatRoom.self, where: ChatRoom.keys.id.in(roomIds))

            var summaries: [ChatSummary] = []
            for room in rooms {
                if let s = try await summarize(room: room, me: auth.userId) { summaries.append(s) }
            }

            let pinnedItems = summaries.filter { $0.pinned }
                .sorted {
                    if let l = $0.eventDate, let r = $1.eventDate, l != r { return l < r }
                    return ($0.lastAt ?? .distantPast) > ($1.lastAt ?? .distantPast)
                }
            let otherItems = summaries.filter { !$0.pinned }
                .sorted { ($0.lastAt ?? .distantPast) > ($1.lastAt ?? .distantPast) }

            self.pinned = pinnedItems
            self.others = otherItems
        } catch {
            print("Inbox refresh error:", error.localizedDescription)
        }
    }

    private func unreadCount(for roomID: String, me: String) async throws -> Int {
        let unreadMsgs = try await Amplify.DataStore.query(
            Message.self,
            where: Message.keys.chatRoomID == roomID && Message.keys.isRead == false
        )
        return unreadMsgs.reduce(0) { acc, m in
            ((m.sender?.id ?? "nil") != me) ? acc + 1 : acc
        }
    }

    fileprivate func summarize(room: ChatRoom, me: String) async throws -> ChatSummary? {
        let last = room.lastMessage
        let lastAt = room.lastMessageTimestamp?.foundationDate

        let links = try await Amplify.DataStore.query(
            UserChatRooms.self,
            where: UserChatRooms.keys.chatRoomId == room.id
        )
        let users = links.compactMap { $0.user }
        let otherNames = users.filter { $0.id != me }.map { $0.username }

        let title: String = {
            if room.associatedEvent != nil { return "Event Chat" }
            if otherNames.count == 1 { return otherNames[0] }
            if otherNames.count > 1 { return otherNames.joined(separator: ", ") }
            return room.name
        }()

        let unread = try await unreadCount(for: room.id, me: me)

        var pinned = false
        var eventDate: Date? = nil
        if let eid = room.associatedEvent,
           let event = try await Amplify.DataStore.query(Event.self, byId: eid) {
            eventDate = event.eventDate.foundationDate
            let today = Calendar.current.startOfDay(for: Date())
            let active = (eventDate ?? today) >= today
            if active {
                if event.hostDJID == me {
                    pinned = true
                } else if let venue = try await Amplify.DataStore.query(Venue.self, byId: event.venueID),
                          venue.ownerID == me {
                    pinned = true
                }
            }
        }

        return ChatSummary(
            id: room.id,
            title: title,
            last: last,
            lastAt: lastAt,
            unread: unread,
            isEvent: room.associatedEvent != nil,
            eventDate: eventDate,
            pinned: pinned
        )
    }

    private func observe() {
        Amplify.Hub.publisher(for: .dataStore)
            .sink { _ in } receiveValue: { [weak self] payload in
                guard let self else { return }
                if payload.eventName == HubPayload.EventName.DataStore.syncReceived,
                   let ev = payload.data as? MutationEvent,
                   ["Message","ChatRoom","Event","UserChatRooms"].contains(ev.modelName) {
                    Task { await self.refresh() }
                }
            }
            .store(in: &bag)
    }
}

struct ChatsInboxView: View {
    @StateObject private var vm = ChatsInboxVM()
    @State private var openVM: ChatViewModel?
    @State private var showChat = false

    var body: some View {
        Group {
            if vm.loading {
                ProgressView("Loading…")
            } else if vm.pinned.isEmpty && vm.others.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("No conversations yet").foregroundStyle(.secondary)
                }
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        if !vm.pinned.isEmpty {
                            SectionHeader("Active Events")
                            ForEach(vm.pinned) { r in ChatRow(r) { open(r) } }
                        }
                        if !vm.others.isEmpty {
                            SectionHeader("Messages")
                            ForEach(vm.others) { r in ChatRow(r) { open(r) } }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
        }
        .task { vm.start() }
        .sheet(isPresented: $showChat) { if let openVM { ChatView(viewModel: openVM) } }
        .navigationTitle("Chats")
        .toolbar {
            NavigationLink(destination: InviteDJView()) { Image(systemName: "square.and.pencil") }
        }
    }

    private func open(_ s: ChatSummary) {
        guard let me = vm.me else { return }
        openVM = ChatViewModel(chatRoomID: s.id, currentUserID: me)
        showChat = true
    }
}

private struct SectionHeader: View {
    let title: String
    init(_ t: String) { title = t }
    var body: some View { HStack { Text(title).font(.headline); Spacer() } }
}

private struct ChatRow: View {
    let row: ChatSummary
    let tap: () -> Void
    init(_ row: ChatSummary, _ tap: @escaping () -> Void) { self.row = row; self.tap = tap }

    var body: some View {
        Button(action: tap) {
            HStack(spacing: 12) {
                Circle()
                    .fill(row.isEvent ? Color.orange.opacity(0.2) : Color.blue.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .overlay(Image(systemName: row.isEvent ? "calendar" : "person.2"))
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(row.title).font(.subheadline).bold().lineLimit(1)
                        Spacer()
                        if let ts = row.lastAt { Text(short(ts)).font(.caption2).foregroundStyle(.secondary) }
                    }
                    if let last = row.last, !last.isEmpty {
                        Text(last).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
                if row.unread > 0 {
                    Text("\(row.unread)")
                        .font(.caption2).bold()
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Capsule().fill(Color.accentColor.opacity(0.2)))
                }
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground)))
        }
        .buttonStyle(.plain)
    }

    private func short(_ d: Date) -> String {
        let f = DateFormatter()
        f.doesRelativeDateFormatting = true
        f.dateStyle = .short; f.timeStyle = .short
        return f.string(from: d)
    }
}
