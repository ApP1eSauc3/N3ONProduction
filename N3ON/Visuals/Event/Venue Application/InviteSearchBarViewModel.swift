//
//  InviteSearchBarViewModel.swift
//  N3ON
//
//  Created by liam howe on 12/7/2025.
//

import SwiftUI
import Combine

class InviteSearchBarViewModel: ObservableObject {
    @Published var searchText: String = "" {
        didSet { debounceSearch() }
    }
    @Published var results: [UserSummary] = []

    private var debounceTimer: AnyCancellable?

    private func debounceSearch() {
        debounceTimer?.cancel()
        debounceTimer = Just(searchText)
            .delay(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] term in
                self?.performSearch(term: term)
            }
    }

    func performSearch(term: String) {
        Task {
            do {
                let allUsers = try await Amplify.DataStore.query(User.self)
                let filtered = allUsers.filter {
                    $0.username.lowercased().contains(term.lowercased())
                }
                DispatchQueue.main.async {
                    self.results = filtered.map {
                        UserSummary(id: $0.id, username: $0.username, avatarKey: $0.avatarKey)
                    }
                }
            } catch {
                print("❌ Error fetching users: \(error)")
            }
        }
    }
}
