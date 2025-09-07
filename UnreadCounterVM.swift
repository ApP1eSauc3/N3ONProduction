//
//  UnreadCounterVM.swift
//  N3ON
//
//  Created by liam howe on 7/9/2025.
//

import Foundation
import Combine
import Amplify

@MainActor
final class UnreadCounterVM: ObservableObject {
    @Published var count: Int = 0
    private var bag = Set<AnyCancellable>()
    private var me: String?

    func start() async {
        await refresh()
        Amplify.Hub.publisher(for: .dataStore)
            .sink { _ in } receiveValue: { [weak self] payload in
                guard let self else { return }
                if payload.eventName == HubPayload.EventName.DataStore.syncReceived,
                   let ev = payload.data as? MutationEvent,
                   ["Message","ChatRoom","UserChatRooms"].contains(ev.modelName) {
                    Task { await self.refresh() }
                }
            }
            .store(in: &bag)
    }

    func reset() { count = 0 }

    private func refresh() async {
        do {
            let auth = try await Amplify.Auth.getCurrentUser()
            me = auth.userId

            // my rooms via join table
            let links = try await Amplify.DataStore.query(
                UserChatRooms.self,
                where: UserChatRooms.keys.userId == auth.userId
            )
            let roomIDs = Array(Set(links.compactMap { $0.chatRoom.id }))
            guard !roomIDs.isEmpty else { self.count = 0; return }

            var total = 0
            for rid in roomIDs {
                let unreadMsgs = try await Amplify.DataStore.query(
                    Message.self,
                    where: Message.keys.chatRoomID == rid && Message.keys.isRead == false
                )
                total += unreadMsgs.reduce(0) { acc, m in
                    ((m.sender?.id ?? "nil") != auth.userId) ? acc + 1 : acc
                }
            }
            self.count = total
        } catch {
            
            self.count = 0
        }
    }
}
