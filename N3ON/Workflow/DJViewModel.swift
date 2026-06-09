// DJViewModel.swift
// N3ON

import Amplify
import Foundation

@MainActor
final class DJViewModel: ObservableObject {
    @Published var user: User
    @Published var upcomingEvents: [Event] = []
    @Published var isLoading = false
    @Published var avatarURL: URL?
    @Published var errorMessage: String?
    @Published var isFollowing = false
    @Published var followerCount = 0
    @Published var isTogglingFollow = false

    // Holds the long-running DataStore observation. Cancelled in deinit so
    // this VM can actually be released — an unstored `Task { for try await ... }`
    // captures self strongly forever.
    private var observeTask: Task<Void, Never>?

    init(user: User) {
        self.user = user
        Task {
            await loadUpcomingEvents()
            await loadAvatarURL()
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
            // Push the date filter to DataStore — pulling every Event and filtering
            // in memory scales O(total events), not O(upcoming events).
            upcomingEvents = try await Amplify.DataStore.query(
                Event.self,
                where: Event.keys.eventDate >= Temporal.DateTime.now()
            )
            .sorted { $0.eventDate.foundationDate < $1.eventDate.foundationDate }
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
        defer { isTogglingFollow = false }

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

    private func loadFollowState() async {
        async let following = (try? await FollowService.isFollowing(djID: user.id)) ?? false
        async let count = await FollowService.followerCount(for: user.id)
        (isFollowing, followerCount) = await (following, count)
    }

    // MARK: - Chat

    func openChatRoomID(with otherUserID: String) -> String {
        let sortedIDs = [user.id, otherUserID].sorted()
        return "dm-\(sortedIDs[0])-\(sortedIDs[1])"
    }

    // MARK: - Avatar

    func loadAvatarURL() async {
        guard let key = user.avatarKey else { return }
        do {
            avatarURL = try await StorageUploader.signedURL(for: key, access: .protected)
        } catch {
            avatarURL = nil
        }
    }

    // MARK: - Live updates

    private func subscribeToUserUpdates() {
        observeTask?.cancel()
        observeTask = Task { [weak self] in
            guard let self else { return }
            do {
                for try await change in Amplify.DataStore.observe(User.self) {
                    guard !Task.isCancelled else { return }
                    guard change.mutationType == MutationEvent.MutationType.update.rawValue,
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
