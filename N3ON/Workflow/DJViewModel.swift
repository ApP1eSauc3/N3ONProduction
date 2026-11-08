// DJViewModel.swift
// N3ON

import Amplify
import Foundation

@MainActor
final class DJViewModel: ObservableObject {
    @Published var user: User
    @Published var upcomingEvents: [Event] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isFollowing = false
    @Published var followerCount = 0
    @Published var isTogglingFollow = false

    // Holds the long-running DataStore observation. Cancelled in deinit so
    // this VM can actually be released — an unstored `Task { for try await ... }`
    // captures self strongly forever.
    private var observeTask: Task<Void, Never>?
    /// The load started by init; kept so callers (and tests) can await it.
    private(set) var initialLoad: Task<Void, Never>?
    /// Bumped on every follow toggle, so a slower load can't overwrite it.
    private var followGeneration = 0

    init(user: User) {
        self.user = user
        initialLoad = Task {
            await loadUpcomingEvents()
            await loadFollowState()
        }
        subscribeToUserUpdates()
    }

    deinit {
        observeTask?.cancel()
    }

    // MARK: - Events

    func loadUpcomingEvents() async {
        isLoading = true
        defer { isLoading = false }
        do {
            upcomingEvents = try await EventService.upcomingEvents(forDJ: user.id)
        } catch {
            errorMessage = "Failed to load events: \(error.localizedDescription)"
        }
    }

    // MARK: - Follow

    /// Toggles follow state. Only valid when user.isDJ is true — regular users
    /// and venues cannot be followed.
    func toggleFollow() async {
        guard user.isDJ else { return }
        guard !isTogglingFollow else { return }
        isTogglingFollow = true
        // Bumped at start AND end: a load that overlaps any part of a toggle
        // read the store before the toggle's write landed, so it is discarded.
        followGeneration += 1
        defer { isTogglingFollow = false; followGeneration += 1 }

        let wasFollowing = isFollowing
        // Optimistic update
        isFollowing = !wasFollowing
        followerCount += wasFollowing ? -1 : 1

        do {
            if wasFollowing {
                try await FollowService.unfollow(djID: user.id)
            } else {
                try await FollowService.follow(djID: user.id)
            }
        } catch {
            // Revert on failure
            isFollowing = wasFollowing
            followerCount += wasFollowing ? 1 : -1
            errorMessage = error.localizedDescription
        }
    }

    func loadFollowState() async {
        let generation = followGeneration
        async let following = (try? await FollowService.isFollowing(djID: user.id)) ?? false
        async let count = await FollowService.followerCount(for: user.id)
        let (f, c) = await (following, count)
        // A tap landed while this was loading: its optimistic state wins.
        // Rejects every overlap with a toggle: started before it (generation
        // moved), ended during it (still toggling), or started during it and
        // ended after (the end-of-toggle bump moved the generation).
        guard generation == followGeneration, !isTogglingFollow else { return }
        (isFollowing, followerCount) = (f, c)
    }

    // MARK: - Chat

    func openChatRoomID(with otherUserID: String) -> String {
        ChatRoomService.dmRoomName(user.id, otherUserID)
    }

    // MARK: - Live updates

    func subscribeToUserUpdates() {
        observeTask?.cancel()
        observeTask = Task { [weak self] in
            guard let self else { return }
            do {
                for try await change in Backend.dataStore.observe(User.self) {
                    guard !Task.isCancelled else { return }
                    // Cheap id check first: this stream carries every User update.
                    guard change.mutationType == MutationEvent.MutationType.update.rawValue,
                          change.modelId == self.user.id,
                          let updatedUser = try? change.decodeModel(as: User.self),
                          updatedUser.id == self.user.id else { continue }
                    // The enclosing Task has no guaranteed actor — hop to MainActor
                    // before mutating the @Published property on @MainActor self.
                    await MainActor.run { self.user = updatedUser }
                }
            } catch { }
        }
    }
}
