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
        try validate(name: name, address: address, latitude: latitude, longitude: longitude, maxCapacity: maxCapacity)
        guard imageKeys.count <= maxImages else { throw VenueServiceError.invalid("Too many photos.") }
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
        try await Backend.dataStore.save(venue)
        return venue
    }

    /// Saves the owner's edits. Approval status and owner always come from
    /// the stored record — never from the edited copy — so a client can't
    /// approve its own venue. (Server-side, Venue @auth still lets the owner
    /// write every field: an approval Lambda is what fully closes it.)
    static func update(_ venue: Venue) async throws -> Venue {
        guard let stored = try await Backend.dataStore.query(Venue.self, byId: venue.id) else {
            throw VenueServiceError.notFound
        }
        try await requireOwner(of: stored)
        try validate(name: venue.name, address: venue.address, latitude: venue.latitude,
                     longitude: venue.longitude, maxCapacity: venue.maxCapacity)
        var safe = venue
        safe.approvalStatus = stored.approvalStatus
        safe.owner = stored.owner
        try await Backend.dataStore.save(safe)
        return safe
    }

    // MARK: - Rules

    static let maxNameLength = 120
    static let maxAddressLength = 300
    static let maxCapacityLimit = 100_000
    static let maxImages = 10
    static let maxComplianceFieldLength = 200

    static func validate(name: String, address: String, latitude: Double, longitude: Double, maxCapacity: Int) throws {
        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let a = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !n.isEmpty, n.count <= maxNameLength else { throw VenueServiceError.invalid("Enter a venue name.") }
        guard !a.isEmpty, a.count <= maxAddressLength else { throw VenueServiceError.invalid("Enter the venue's address.") }
        guard (1...maxCapacityLimit).contains(maxCapacity) else { throw VenueServiceError.invalid("Enter a real capacity.") }
        guard CLLocationCoordinate2DIsValid(CLLocationCoordinate2D(latitude: latitude, longitude: longitude)),
              latitude.isFinite, longitude.isFinite
        else { throw VenueServiceError.invalid("That location isn't valid.") }
    }

    static func requireOwner(of venue: Venue) async throws {
        guard venue.owner?.id == (try await AuthService.currentUserId()) else { throw VenueServiceError.notOwner }
    }

    static func fetch(byId id: String) async throws -> Venue? {
        try await Backend.dataStore.query(Venue.self, byId: id)
    }

    /// Returns all venues whose owner association matches `userID`.
    static func fetchOwned(by userID: String) async throws -> [Venue] {
        try await Backend.dataStore.query(Venue.self, where: Venue.keys.owner == userID)
    }

    /// Returns all venues with APPROVED status — shown to DJs browsing for bookings.
    static func fetchApproved() async throws -> [Venue] {
        try await Backend.dataStore.query(Venue.self, where: Venue.keys.approvalStatus == VenueStatus.approved.rawValue)
    }

    /// Upcoming events at a venue, sorted ascending by date.
    /// DataStore has no date predicate — filter in memory.
    static func fetchUpcomingEvents(venueID: String) async throws -> [Event] {
        let all = try await Backend.dataStore.query(
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
        // Apple's geocoder is rate-limited per app; never spend a request on
        // empty or oversized input.
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= maxAddressLength else {
            throw VenueServiceError.invalid("Enter the venue's address.")
        }
        return try await withCheckedThrowingContinuation { continuation in
            CLGeocoder().geocodeAddressString(trimmed) { placemarks, error in
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
        guard CLLocationCoordinate2DIsValid(location.coordinate) else {
            throw VenueServiceError.invalid("That location isn't valid.")
        }
        return try await withCheckedThrowingContinuation { continuation in
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
    /// Uploads venue photos — downscaled through ImagePipeline (it uploaded
    /// full-resolution photos before) and capped in number. Allowed for a new
    /// venue id (the application uploads before creating the record) or one
    /// you own; never into another owner's venue folder.
    static func uploadImages(_ images: [UIImage], venueID: String) async throws -> [String] {
        guard images.count <= maxImages else { throw VenueServiceError.invalid("Up to \(maxImages) photos.") }
        if let existing = try await Backend.dataStore.query(Venue.self, byId: venueID) {
            try await requireOwner(of: existing)
        }
        var keys: [String] = []
        for image in images {
            guard let jpeg = ImagePipeline.makeJPEGData(from: image, config: .poster) else { continue }
            let key = MediaKind.venueImage(venueID: venueID).makeKey(extension: "jpg")
            let uploaded = try await StorageUploader.uploadJPEG(jpeg, key: key, access: .guest)
            keys.append(uploaded)
        }
        return keys
    }

    // MARK: — Compliance

    /// Saves a VenueComplianceSubmission to DataStore.
    /// Called from VenueProfileViewModel — never from a View directly.
    static func saveCompliance(venueID: String, licenseType: String, contractorName: String) async throws {
        guard let venue = try await Backend.dataStore.query(Venue.self, byId: venueID) else {
            throw VenueServiceError.notFound
        }
        try await requireOwner(of: venue)
        let lic = licenseType.trimmingCharacters(in: .whitespacesAndNewlines)
        let contractor = contractorName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !lic.isEmpty, lic.count <= maxComplianceFieldLength, contractor.count <= maxComplianceFieldLength else {
            throw VenueServiceError.invalid("Check the licence details.")
        }
        let submission = VenueComplianceSubmission(
            id: UUID().uuidString,
            venueID: venueID,
            licenseType: lic,
            contractorName: contractor,
            submittedAt: Temporal.DateTime.now(),
            status: "pending_review"
        )
        try await Backend.dataStore.save(submission)
    }
}

enum VenueServiceError: LocalizedError, Equatable {
    case notFound
    case notOwner
    case invalid(String)
    var errorDescription: String? {
        switch self {
        case .notFound: return "That venue could not be found."
        case .notOwner: return "Only the venue's owner can change it."
        case .invalid(let message): return message
        }
    }
}
