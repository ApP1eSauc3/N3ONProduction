//
//  InviteSearchBarViewModel.swift
//  N3ON
//
//  Created by liam howe on 12/7/2025.
//

import Foundation
import Combine

@MainActor
final class InviteSearchBarViewModel: ObservableObject {
    @Published var searchText: String = "" {
        didSet { debounceSearch() }
    }
    @Published var results: [UserSummary] = []

    private var debounceTimer: AnyCancellable?
    // Holds the current in-flight DataStore query so rapid keystrokes cancel
    // previous searches — otherwise a slower earlier query can overwrite a
    // faster later one and the UI shows stale results.
    private var searchTask: Task<Void, Never>?

    private func debounceSearch() {
        debounceTimer?.cancel()
        debounceTimer = Just(searchText)
            .delay(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] term in
                self?.performSearch(term: term)
            }
    }

    func performSearch(term: String) {
        searchTask?.cancel()
        searchTask = Task {
            do {
                let allUsers = try await UserService.fetchAll()
                guard !Task.isCancelled else { return }
                let filtered = allUsers.filter {
                    $0.username.lowercased().contains(term.lowercased())
                }
                // Already on @MainActor via the class annotation — no hop needed.
                self.results = filtered.map {
                    UserSummary(id: $0.id, username: $0.username, avatarKey: $0.avatarKey, isDJ: $0.isDJ)
                }
            } catch {
                print("❌ Error fetching users: \(error)")
            }
        }
    }
}
