// VenueApplicationViewModel.swift
// N3ON — Workflow layer
// Drives the 4-step venue application form.
// Orchestrates VenueService — no direct Amplify or CLGeocoder calls.

import Foundation
import UIKit

@MainActor
final class VenueApplicationViewModel: ObservableObject {

    enum Step: Int, CaseIterable {
        case details, location, photos, review

        var title: String {
            switch self {
            case .details:  return "Venue Details"
            case .location: return "Location"
            case .photos:   return "Photos & Amenities"
            case .review:   return "Review & Submit"
            }
        }

        var index: Int { rawValue }
        static var total: Int { allCases.count }
    }

    // MARK: — Step state
    @Published var step: Step = .details

    // MARK: — Step 1: Details
    @Published var name: String = ""
    @Published var venueDescription: String = ""
    @Published var venueType: VenueType = .club
    @Published var maxCapacity: Int = 200

    // MARK: — Step 2: Location
    @Published var address: String = ""
    @Published var latitude: Double? = nil
    @Published var longitude: Double? = nil
    @Published var isGeocoding: Bool = false
    @Published var geocodeError: String? = nil

    // MARK: — Step 3: Photos & Amenities
    @Published var selectedImages: [UIImage] = []
    @Published var amenities: [Amenity] = []

    // MARK: — Submission
    @Published var isSubmitting: Bool = false
    @Published var submissionError: String? = nil
    @Published var didSubmitSuccessfully: Bool = false

    // MARK: — Validation

    var detailsValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && maxCapacity > 0
    }

    var locationValid: Bool {
        !address.trimmingCharacters(in: .whitespaces).isEmpty
            && latitude != nil
            && longitude != nil
    }

    var canAdvance: Bool {
        switch step {
        case .details:  return detailsValid
        case .location: return locationValid
        case .photos:   return true
        case .review:   return false
        }
    }

    // MARK: — Navigation

    func nextStep() {
        guard let next = Step(rawValue: step.rawValue + 1) else { return }
        step = next
    }

    func previousStep() {
        guard let prev = Step(rawValue: step.rawValue - 1) else { return }
        step = prev
    }

    // MARK: — Geocoding

    func geocodeCurrentAddress() async {
        let trimmed = address.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        isGeocoding = true
        geocodeError = nil
        defer { isGeocoding = false }
        do {
            let coord = try await VenueService.geocode(address: trimmed)
            guard !Task.isCancelled else { return }
            latitude = coord.latitude
            longitude = coord.longitude
        } catch {
            geocodeError = "Location not found. Check the address and try again."
            latitude = nil
            longitude = nil
        }
    }

    // MARK: — Submission

    func submitApplication() async {
        guard let lat = latitude, let lng = longitude else {
            submissionError = "Confirm your venue location before submitting."
            return
        }
        isSubmitting = true
        submissionError = nil
        defer { isSubmitting = false }
        do {
            // Generate the venue ID first so image S3 keys are namespaced correctly.
            // VenueService.create accepts an optional id parameter.
            let venueID = UUID().uuidString
            let imageKeys = try await VenueService.uploadImages(selectedImages, venueID: venueID)
            guard !Task.isCancelled else { return }
            _ = try await VenueService.create(
                id: venueID,
                name: name.trimmingCharacters(in: .whitespaces),
                description: venueDescription,
                address: address.trimmingCharacters(in: .whitespaces),
                latitude: lat,
                longitude: lng,
                maxCapacity: maxCapacity,
                imageKeys: imageKeys
            )
            didSubmitSuccessfully = true
        } catch {
            submissionError = error.localizedDescription
        }
    }
}
