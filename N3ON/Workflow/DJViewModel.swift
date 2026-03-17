// DJViewModel.swift
// N3ON
//    TODO: Add UserFollows join type to schema for production-safe follow tracking.
//

import Amplify
import Foundation

@MainActor
final class DJViewModel: ObservableObject {
    @Published var user: User
    @Published var upcomingEvents: [Event] = []
    @Published var isLoading = false
    @Published var avatarURL: URL?
    @Published var errorMessage: String?


    init(user: User) {
        self.user = user
        Task {
            await loadUpcomingEvents()
            await loadAvatarURL()
        }
        subscribeToUserUpdates()
    }

    
    // TODO: For scale, add a EventDJLink join table to schema for indexed queries.
    func loadUpcomingEvents() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let allEvents = try await Amplify.DataStore.query(Event.self)
            upcomingEvents = allEvents
                .filter { $0.eventDate.foundationDate > Date() }
                .sorted { $0.eventDate.foundationDate < $1.eventDate.foundationDate }
        } catch {
            errorMessage = "Failed to load events: \(error.localizedDescription)"
        }
    }

    
    func toggleFollow() async {
        // TODO: implement once UserFollows type is added to schema and codegen run
        errorMessage = "Follow feature coming soon."
    }

    func openChatRoomID(with otherUserID: String) -> String {
        let sortedIDs = [user.id, otherUserID].sorted()
        return "dm-\(sortedIDs[0])-\(sortedIDs[1])"
    }

    func loadAvatarURL() async {
        guard let key = user.avatarKey else { return }
        do {
            avatarURL = try await StorageUploader.signedURL(for: key, access: .protected)
        } catch {
            avatarURL = nil
        }
    }

    private func subscribeToUserUpdates() {
        // Amplify v2: DataStore.publisher removed — use observe(_:) async sequence
        Task {
            do {
                for try await change in Amplify.DataStore.observe(User.self) {
                    guard change.mutationType == MutationEvent.MutationType.update.rawValue,
                          let updatedUser = try? change.decodeModel(as: User.self),
                          updatedUser.id == self.user.id else { continue }
                    self.user = updatedUser
                }
            } catch { }
        }
    }
}
