// UnreadCounterVM.swift
// N3ON — Workflow layer
// Tracks total unread message count across all the current user's chat rooms.
// Drives the neon badge on the map's chat button.

import Foundation
import Amplify

@MainActor
final class UnreadCounterVM: ObservableObject {
    @Published var count: Int = 0
    private var hubTask: Task<Void, Never>?

    func start() async {
        await refresh()
        // Hub is acceptable here — monitoring multiple model types for badge updates,
        // not per-room streaming (see CLAUDE.md §Chat architecture).
        // AsyncPublisher (.values) instead of a Combine sink: each iteration
        // resumes on this @MainActor class, so no manual main-queue hop.
        hubTask?.cancel()
        hubTask = Task { [weak self] in
            for await payload in Amplify.Hub.publisher(for: .dataStore).values {
                guard !Task.isCancelled else { return }
                guard let self else { return }
                if payload.eventName == HubPayload.EventName.DataStore.syncReceived,
                   let ev = payload.data as? MutationEvent,
                   ["Message", "ChatRoom", "UserChatRooms"].contains(ev.modelName) {
                    await self.refresh()
                }
            }
        }
    }

    deinit { hubTask?.cancel() }

    func reset() { count = 0 }

    private func refresh() async {
        do {
            let userID = try await AuthService.currentUserId()

            let roomIDs = try await ChatRoomService.roomIDs(for: userID)
            guard !roomIDs.isEmpty else { self.count = 0; return }

            // Per-room unread queries are independent — fan them out. N sequential
            // awaits become 1 round-trip in wall-clock terms.
            var total = 0
            try await withThrowingTaskGroup(of: Int.self) { group in
                for rid in roomIDs {
                    group.addTask {
                        try await ChatRoomService.unreadCount(in: rid, excludingSenderID: userID)
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
