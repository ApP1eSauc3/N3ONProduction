// VenueService.swift
// N3ON — Task layer
// All Venue DataStore operations, geocoding, and image uploads.
// Views and ViewModels never call Amplify or CLGeocoder directly.

import Foundation
import UIKit
import CoreLocation
import Amplify

enum VenueService {

    // MARK: — DataStore

    /// Creates a new Venue with PENDING approval status.
    /// Fetches the current user model to set the owner association.
    static func create(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        address: String,
        latitude: Double,
        longitude: Double,
        maxCapacity: Int,
        imageKeys: [String]
    ) async throws -> Venue {
        let owner = try await AuthService.getCurrentUserModel()
        let venue = Venue(
            id: id,
            name: name,
            description: description,
            address: address,
            latitude: latitude,
            longitude: longitude,
            imageKey: imageKeys.isEmpty ? nil : imageKeys,
            owner: owner,
            maxCapacity: maxCapacity,
            approvalStatus: VenueStatus.pending.rawValue
        )
        try await Amplify.DataStore.save(venue)
        return venue
    }

    static func update(_ venue: Venue) async throws -> Venue {
        try await Amplify.DataStore.save(venue)
        return venue
    }

    static func fetch(byId id: String) async throws -> Venue? {
        try await Amplify.DataStore.query(Venue.self, byId: id)
    }

    /// Returns all venues whose owner association matches `userID`.
    static func fetchOwned(by userID: String) async throws -> [Venue] {
        try await Amplify.DataStore.query(Venue.self, where: Venue.keys.owner == userID)
    }

    /// Returns all venues with APPROVED status — shown to DJs browsing for bookings.
    static func fetchApproved() async throws -> [Venue] {
        try await Amplify.DataStore.query(Venue.self, where: Venue.keys.approvalStatus == VenueStatus.approved.rawValue)
    }

    /// Upcoming events at a venue, sorted ascending by date.
    /// DataStore has no date predicate — filter in memory.
    static func fetchUpcomingEvents(venueID: String) async throws -> [Event] {
        let all = try await Amplify.DataStore.query(
            Event.self,
            where: Event.keys.venueID == venueID
        )
        return all
            .filter { $0.eventDate.foundationDate > Date() }
            .sorted { $0.eventDate.foundationDate < $1.eventDate.foundationDate }
    }

    // MARK: — Geocoding

    /// Converts a human-readable address string into geographic coordinates.
    /// Throws if the address cannot be resolved.
    static func geocode(address: String) async throws -> CLLocationCoordinate2D {
        try await withCheckedThrowingContinuation { continuation in
            CLGeocoder().geocodeAddressString(address) { placemarks, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let coordinate = placemarks?.first?.location?.coordinate {
                    continuation.resume(returning: coordinate)
                } else {
                    continuation.resume(throwing: NSError(
                        domain: "VenueService",
                        code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "No location found for that address."]
                    ))
                }
            }
        }
    }

    /// Converts a CLLocation to a formatted address string.
    static func reverseGeocode(_ location: CLLocation) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let p = placemarks?.first {
                    let parts = [p.thoroughfare, p.locality, p.administrativeArea, p.postalCode]
                    let address = parts.compactMap { $0 }.joined(separator: ", ")
                    continuation.resume(returning: address)
                } else {
                    continuation.resume(returning: "")
                }
            }
        }
    }

    // MARK: — Storage

    /// Uploads venue images to S3 and returns their storage keys.
    /// Uses `MediaKind.venueImage` for consistent key structure.
    static func uploadImages(_ images: [UIImage], venueID: String) async throws -> [String] {
        var keys: [String] = []
        for image in images {
            guard let jpeg = image.jpegData(compressionQuality: 0.8) else { continue }
            let key = MediaKind.venueImage(venueID: venueID).makeKey(extension: "jpg")
            let uploaded = try await StorageUploader.uploadJPEG(jpeg, key: key, access: .protected)
            keys.append(uploaded)
        }
        return keys
    }

    // MARK: — Compliance

    /// Saves a VenueComplianceSubmission to DataStore.
    /// Called from VenueProfileViewModel — never from a View directly.
    static func saveCompliance(venueID: String, licenseType: String, contractorName: String) async throws {
        let submission = VenueComplianceSubmission(
            id: UUID().uuidString,
            venueID: venueID,
            licenseType: licenseType,
            contractorName: contractorName,
            submittedAt: Temporal.DateTime.now(),
            status: "pending_review"
        )
        try await Amplify.DataStore.save(submission)
    }
}
