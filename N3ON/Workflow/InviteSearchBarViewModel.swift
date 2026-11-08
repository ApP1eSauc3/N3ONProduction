//
//  InviteSearchBarViewModel.swift
//  N3ON
//
//  Created by liam howe on 12/7/2025.
//

import Foundation
import Amplify
import Combine

@MainActor
final class InviteSearchBarViewModel: ObservableObject {
    @Published var searchText: String = "" {
        didSet { debounceSearch() }
    }
    @Published var results: [UserSummary] = []
    /// DJs the signed-in user follows — drives Follow / Following.
    @Published var followedIDs: Set<String> = []
    /// Set when a DM is ready; the view presents ChatView for it.
    @Published var openChat: ChatViewModel?
    @Published var errorMessage: String?
    @Published var isOpening = false

    private var me: User?
    static let resultLimit = 50
    static let maxTermLength = 50

    private var debounceTimer: AnyCancellable?
    // Holds the current in-flight DataStore query so rapid keystrokes cancel
    // previous searches — otherwise a slower earlier query can overwrite a
    // faster later one and the UI shows stale results.
    private var searchTask: Task<Void, Never>?

    func debounceSearch() {
        debounceTimer?.cancel()
        debounceTimer = Just(searchText)
            .delay(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] term in
                self?.performSearch(term: term)
            }
    }

    func performSearch(term: String) {
        searchTask?.cancel()
        // An empty search returns nobody: `contains("")` matched every account,
        // listing the whole user directory. DJs only (this is the DJ invite
        // search — fans' handles aren't listed), filtered by DataStore, capped.
        let needle = String(term.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().prefix(Self.maxTermLength))
        guard !needle.isEmpty else { results = []; return }
        searchTask = Task {
            do {
                let djs = try await Backend.dataStore.query(User.self, where: User.keys.isDJ == true)
                guard !Task.isCancelled else { return }
                let myID = await AuthService.currentUserIdOrNil()
                let matches = djs.lazy.filter { $0.id != myID && $0.username.lowercased().contains(needle) }.prefix(Self.resultLimit)
                // Already on @MainActor via the class annotation — no hop needed.
                self.results = matches.map {
                    UserSummary(id: $0.id, username: $0.username, avatarKey: $0.avatarKey, isDJ: $0.isDJ)
                }
            } catch {
                AppLog.app.error("Error fetching users: \(error.localizedDescription, privacy: .private)")
            }
        }
    }

    // MARK: - Actions

    func load() async {
        me = try? await AuthService.getCurrentUserModel()
        followedIDs = Set((try? await FollowService.followedDJIDs()) ?? [])
        performSearch(term: searchText)
    }

    func follow(_ user: UserSummary) async {
        do {
            try await FollowService.follow(djID: user.id)
            followedIDs.insert(user.id)
        } catch {
            errorMessage = "Couldn't follow @\(user.username) — try again."
        }
    }

    /// Opens (or creates) the DM room with `user`, after the same eligibility
    /// check every chat entry point uses (Prompt/Chat/CLAUDE.md).
    func message(_ user: UserSummary) async {
        guard !isOpening else { return }
        isOpening = true
        defer { isOpening = false }
        errorMessage = nil
        do {
            if me == nil { me = try await AuthService.getCurrentUserModel() }
            guard let me, let them = try await UserService.fetch(byId: user.id) else {
                errorMessage = "Couldn't open this chat."
                return
            }
            let eligibility = await ChatEligibilityService.check(
                currentUserID: me.id,
                currentRole: await AccessControlService.role(for: me),
                recipientUserID: them.id,
                recipientRole: them.isDJ ? .dj : .regular
            )
            guard case .eligible = eligibility else {
                errorMessage = "Only DJs can message each other directly."
                return
            }
            let room = try await ChatRoomService.openDJDirectRoom(userA: me, userB: them)
            openChat = ChatViewModel(chatRoomID: room.id, currentUserID: me.id)
        } catch {
            errorMessage = "Couldn't open this chat — check your connection."
        }
    }
}
