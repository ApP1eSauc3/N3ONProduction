// UnreadCounterVM.swift
// N3ON — Workflow layer
// Tracks total unread message count across all the current user's chat rooms.
// Drives the neon badge on the map's chat button.

import Foundation
import Combine
import Dispatch
import Amplify

@MainActor
final class UnreadCounterVM: ObservableObject {
    @Published var count: Int = 0
    private var bag = Set<AnyCancellable>()
    private var me: String?

    func start() async {
        await refresh()
        // Hub is acceptable here — monitoring multiple model types for badge updates,
        // not per-room streaming (see AGENTS.md §Chat architecture).
        // Amplify Hub delivers on a background queue. Hop to main before the sink
        // closure touches @MainActor-isolated state — required under Swift 6
        // strict concurrency, otherwise the access is a data race.
        Amplify.Hub.publisher(for: .dataStore)
            .receive(on: DispatchQueue.main)
            .sink { _ in } receiveValue: { [weak self] payload in
                guard let self else { return }
                if payload.eventName == HubPayload.EventName.DataStore.syncReceived,
                   let ev = payload.data as? MutationEvent,
                   ["Message", "ChatRoom", "UserChatRooms"].contains(ev.modelName) {
                    Task { await self.refresh() }
                }
            }
            .store(in: &bag)
    }

    func reset() { count = 0 }

    private func refresh() async {
        do {
            let userID = try await AuthService.currentUserId()
            me = userID

            let links = try await Amplify.DataStore.query(
                UserChatRooms.self,
                where: UserChatRooms.keys.user == userID
            )
            let roomIDs = Array(Set(links.compactMap { $0.chatRoom.id }))
            guard !roomIDs.isEmpty else { self.count = 0; return }

            // Per-room unread queries are independent — fan them out. N sequential
            // awaits become 1 round-trip in wall-clock terms.
            var total = 0
            try await withThrowingTaskGroup(of: Int.self) { group in
                for rid in roomIDs {
                    group.addTask {
                        let unread = try await Amplify.DataStore.query(
                            Message.self,
                            where: Message.keys.chatRoomID == rid && Message.keys.isRead == false
                        )
                        return unread.reduce(0) { acc, m in
                            (m.sender?.id ?? "") != userID ? acc + 1 : acc
                        }
                    }
                }
                for try await roomCount in group { total += roomCount }
            }
            self.count = total
        } catch {
            self.count = 0
        }
    }
}
