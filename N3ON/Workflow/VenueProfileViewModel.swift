// VenueProfileViewModel.swift
// N3ON — Workflow layer
// Manages the venue owner's profile: loads their venue, handles edits and uploads.
// All Amplify/Storage calls delegated to VenueService.

import Foundation
import UIKit
import Amplify

@MainActor
final class VenueProfileViewModel: ObservableObject {

    @Published var venue: Venue? = nil
    @Published var upcomingEvents: [Event] = []
    @Published var avatarState: AvatarState = .remote(avatarKey: "default-venue-avatar")
    @Published var galleryKeys: [String] = []
    @Published var isLoading: Bool = false
    @Published var isSaving: Bool = false
    @Published var saveError: String? = nil
    @Published var isUploadingGallery: Bool = false

    var approvalStatus: String { venue?.approvalStatus ?? VenueStatus.pending.rawValue }
    var isApproved: Bool { venue?.approvalStatus == VenueStatus.approved.rawValue }
    var eventCount: Int { upcomingEvents.count }
    var capacity: Int { venue?.maxCapacity ?? 0 }

    // MARK: — Load

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let userID = try await AuthService.currentUserId()
            guard !Task.isCancelled else { return }
            let venues = try await VenueService.fetchOwned(by: userID)
            guard !Task.isCancelled else { return }
            guard let v = venues.first else { return }
            apply(venue: v)
            upcomingEvents = try await VenueService.fetchUpcomingEvents(venueID: v.id)
        } catch {
            // No venue yet — user needs to submit application
        }
    }

    private func apply(venue v: Venue) {
        venue = v
        galleryKeys = v.imageKey ?? []
        if let firstKey = v.imageKey?.first {
            avatarState = .remote(avatarKey: firstKey)
        }
    }

    // MARK: — Edit

    func saveChanges(name: String, description: String) async {
        guard var updated = venue else { return }
        isSaving = true
        saveError = nil
        defer { isSaving = false }
        do {
            updated.name = name
            updated.description = description
            let saved = try await VenueService.update(updated)
            venue = saved
        } catch {
            saveError = error.localizedDescription
        }
    }

    // MARK: — Gallery upload

    func uploadGalleryImage(_ image: UIImage) async {
        guard let venueID = venue?.id else { return }
        isUploadingGallery = true
        defer { isUploadingGallery = false }
        do {
            let keys = try await VenueService.uploadImages([image], venueID: venueID)
            guard let key = keys.first else { return }
            galleryKeys.append(key)
            var updated = venue!
            updated.imageKey = galleryKeys
            venue = try await VenueService.update(updated)
            // Update avatar to the first image if it was the default
            if galleryKeys.count == 1 {
                avatarState = .remote(avatarKey: key)
            }
        } catch {
            // silently fail — image stays in local state only
        }
    }

    // MARK: — Compliance

    func submitCompliance(licenseType: String, contractorName: String) async throws {
        guard let venueID = venue?.id else { return }
        try await VenueService.saveCompliance(
            venueID: venueID,
            licenseType: licenseType,
            contractorName: contractorName
        )
    }
}
