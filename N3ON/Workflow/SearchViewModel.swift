// SearchViewModel.swift
// N3ON — Workflow layer
// Drives SearchView. Debounces the query so DataStore isn't hammered on every
// keystroke. Segmented by category: DJs, Events, Venues.

import Foundation
import Amplify

@MainActor
final class SearchViewModel: ObservableObject {

    enum Category: String, CaseIterable {
        case djs    = "DJs"
        case events = "Events"
        case venues = "Venues"
    }

    @Published var query: String = ""
    @Published var category: Category = .djs
    @Published var results: SearchResults = SearchResults()
    @Published var isSearching: Bool = false
    @Published var recentSearches: [String] = []

    private var debounceTask: Task<Void, Never>?
    private static let maxRecent = 8

    // Called on every query change — debounced 300 ms (RA/Dice pattern)
    func queryChanged(_ new: String) {
        debounceTask?.cancel()
        guard !new.trimmingCharacters(in: .whitespaces).isEmpty else {
            results = SearchResults()
            isSearching = false
            return
        }
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            await performSearch(query: new)
        }
    }

    private func performSearch(query: String) async {
        isSearching = true
        defer { isSearching = false }
        results = await SearchService.search(query: query)
    }

    func commitSearch(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        var updated = recentSearches.filter { $0.lowercased() != trimmed.lowercased() }
        updated.insert(trimmed, at: 0)
        recentSearches = Array(updated.prefix(Self.maxRecent))
    }

    func removeRecent(_ query: String) {
        recentSearches.removeAll { $0 == query }
    }

    func clearRecents() {
        recentSearches.removeAll()
    }

    // Convenience shorthand for the active result set
    var djResults: [User]    { results.djs }
    var eventResults: [Event]  { results.events }
    var venueResults: [Venue]  { results.venues }
}
