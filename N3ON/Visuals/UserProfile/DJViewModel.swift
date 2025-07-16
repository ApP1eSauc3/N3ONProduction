//
//  DJViewModel.swift
//  N3ON
//
//  Created by liam howe on 11/7/2025.
//
// DJViewModel.swift

// DJViewModel.swift

import Amplify
import Foundation
import Combine

class DJViewModel: ObservableObject {
    @Published var dj: DJ
    @Published var upcomingEvents: [Event] = []
    @Published var isLoading = false
    @Published var avatarURL: URL?

    private var cancellables = Set<AnyCancellable>()

    init(dj: DJ) {
        self.dj = dj
        loadUpcomingEvents()
        subscribeToUpdates()
        
        if let key = dj.avatarKey {
            loadAvatarURL(for: key)
        }
    }

    private func loadUpcomingEvents() {
        isLoading = true
        Amplify.DataStore.query(
            Event.self,
            where: Event.keys.djs.contains(dj.id)
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                if case .success(let events) = result {
                    self?.upcomingEvents = events
                        .filter { $0.eventDate.foundationDate > Date() }
                        .sorted { $0.eventDate < $1.eventDate }
                }
            }
        }
    }

    func toggleFollow(completion: @escaping (Bool) -> Void = { _ in }) {
        guard let userID = AuthService.currentUserId else { return }

        if dj.isFollowedByCurrentUser {
            Amplify.DataStore.query(DJ.self, byId: dj.id) { [weak self] result in
                if case .success(var updatedDJ) = result {
                    updatedDJ?.followers?.removeAll(where: { $0.id == userID })
                    self?.saveDJ(updatedDJ, completion: completion)
                }
            }
        } else {
            Amplify.DataStore.query(User.self, byId: userID) { [weak self] result in
                if case .success(let user) = result,
                   var updatedDJ = self?.dj {
                    updatedDJ.followers?.append(user)
                    self?.saveDJ(updatedDJ, completion: completion)
                }
            }
        }
    }

    func openChat(with otherDJ: DJ, completion: @escaping (String) -> Void) {
        let sortedIDs = [dj.id, otherDJ.id].sorted()
        let chatRoomID = "dm-\(sortedIDs[0])-\(sortedIDs[1])"
        completion(chatRoomID)
    }

    private func saveDJ(_ dj: DJ?, completion: @escaping (Bool) -> Void = { _ in }) {
        guard let dj = dj else { return }
        Amplify.DataStore.save(dj) { [weak self] result in
            if case .success = result {
                DispatchQueue.main.async {
                    self?.dj = dj
                    completion(true)
                }
            } else {
                completion(false)
            }
        }
    }

    private func subscribeToUpdates() {
        Amplify.DataStore.publisher(for: DJ.self)
            .sink { _ in } receiveValue: { [weak self] change in
                if case .update(let updatedDJ) = change,
                   updatedDJ.id == self?.dj.id {
                    self?.dj = updatedDJ
                }
            }
            .store(in: &cancellables)
    }

    // ✅ New function to load the protected avatar image URL
    func loadAvatarURL(for key: String) {
        Amplify.Storage.getURL(key: key, options: .init(accessLevel: .protected)) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let url):
                    self?.avatarURL = url
                case .failure(let error):
                    print("❌ Failed to get avatar URL: \(error)")
                    self?.avatarURL = nil
                }
            }
        }
    }
}
