//
//  DJViewModel.swift
//  N3ON
//
//  Created by liam howe on 11/7/2025.
//

import Foundation

class DJViewModel: ObservableObject {
    @Published var dj: DJ
    @Published var upcomingEvents: [Event] = []
    @Published var isLoading = false
    
    init(dj: DJ) {
        self.dj = dj
        loadUpcomingEvents()
        subscribeToUpdates()
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
    
    func toggleFollow() {
        guard let userID = AuthService.currentUserId else { return }
        
        if dj.isFollowedByCurrentUser {
            Amplify.DataStore.query(DJ.self, byId: dj.id) { [weak self] result in
                if case .success(var updatedDJ) = result {
                    updatedDJ?.followers?.removeAll(where: { $0.id == userID })
                    self?.saveDJ(updatedDJ)
                }
            }
        } else {
            Amplify.DataStore.query(User.self, byId: userID) { [weak self] result in
                if case .success(let user) = result,
                   var updatedDJ = self?.dj {
                    updatedDJ.followers?.append(user)
                    self?.saveDJ(updatedDJ)
                }
            }
        }
    }
    
    private func saveDJ(_ dj: DJ?) {
        guard let dj = dj else { return }
        Amplify.DataStore.save(dj) { [weak self] result in
            if case .success = result {
                self?.dj = dj
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
}
