// EventDraftViewModel.swift
// N3ON — Workflow layer
//
// Owns draft state for the three-stage event creation flow:
//   Stage 1 — Date picker  → saveEventDraft() saves Event(status:"pending") to DataStore
//   Stage 2 — Limbo        → observeTally() watches EventDJLink records live
//   Stage 3 — Pricing      → uploadPosterAndGoLive() uploads poster, sets status:"live"

import Foundation
import UIKit
import Amplify

// MARK: - Supporting types

struct RevenueBreakdown {
    let totalRevenue: Double
    let venueRevenue: Double
    let hostDJRevenue: Double
    let djPayouts: [DJPayout]   // always empty — per-DJ splits are server-side only
}

struct DJPayout {
    let username: String
    let amount: Double
}

// MARK: - ViewModel

@MainActor
final class EventDraftViewModel: ObservableObject {

    enum Package: String, CaseIterable, Identifiable {
        case basic, medium, extreme
        var id: String { rawValue }
    }

    // MARK: Step coordination
    @Published var currentStep: EventCreationStep = .datePicker

    // MARK: Poster — single canonical field pair
    // EventPosterUploadView previously duplicated these as eventPosterImage/eventPosterKey.
    // Those duplicates are removed. All upload logic is in uploadPosterAndGoLive(_:).
    @Published var posterImage: UIImage?
    @Published var posterKey: String?
    @Published var isUploadingPoster = false
    @Published var posterUploadError: String?

    // MARK: Event identity
    @Published var eventName: String = ""
    @Published var eventDescription: String = ""
    @Published var venue: Venue?
    @Published var package: Package = .basic
    @Published var specialRequest: String = ""
    @Published var vjUsername: String? = nil
    @Published var eventDate: Date = {
        Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    }()
    @Published var eventTime: Date = Date()

    // MARK: Pricing (Stage 3)
    @Published var availableTickets: Int = 100
    @Published var ticketPrice: Double = 0
    @Published var estimatedAttendance: Double = 100
    @Published var djSharePercentage: Double = 50

    /// Loaded from the current user's djRank in load(). Drives the host DJ revenue share.
    @Published var hostDJRank: Int = 0

    // MARK: Tally (live-observed from EventDJLink)
    /// ID of the Event record written to DataStore at the end of Stage 1.
    @Published var createdEventID: String?
    /// Sum of coinContribution across all EventDJLinks for this event.
    @Published var currentTally: Int = 0

    /// Required tally derived from venue capacity tiers and ticket price.
    ///
    /// Capacity tiers mirror Lambda config. The price factor reflects break-even:
    /// at or below the mid-point price the full tier threshold applies; above it
    /// the threshold reduces proportionally (more revenue per head → less DJ draw
    /// required to break even), flooring at 50% of the base tier.
    /// The actual gate is always server-side — this is a client-side estimate only.
    var requiredTally: Int {
        guard let capacity = venue?.maxCapacity else { return 40 }
        let base: Int
        let midpointPrice: Double   // ticket price at which threshold = full tier
        switch capacity {
        case 0...200:   base = 40; midpointPrice = 20
        case 201...500: base = 55; midpointPrice = 30
        default:        base = 80; midpointPrice = 50
        }
        guard ticketPrice > 0 else { return base }
        // factor ∈ [0.5, 1.0]: higher price → smaller factor → lower threshold
        let factor = min(1.0, max(0.5, midpointPrice / ticketPrice))
        return max(10, Int((Double(base) * factor).rounded()))
    }

    /// Estimated break-even at 30% venue fill for the current ticket price.
    /// Returns nil when ticket price or venue is not yet set.
    var breakEvenPreview: (attendees: Int, revenue: Int)? {
        guard ticketPrice > 0, let capacity = venue?.maxCapacity else { return nil }
        let attendees = max(1, Int((Double(capacity) * 0.3).rounded()))
        return (attendees, Int(Double(attendees) * ticketPrice))
    }

    /// Continue button in EventLimboView gates on this.
    var tallyMet: Bool { currentTally >= requiredTally }

    /// Whether the host may leave limbo for pricing/poster. The tally is the real
    /// gate in community mode; during bootstrap (curated mode) it is not enforced,
    /// so hand-curated events can proceed without an accrued lineup. The ranking
    /// system is intact — flipping CurationConfig.platformMode re-enables the gate.
    var canLeaveLimbo: Bool { tallyMet || !CurationService.tallyEnforced }

    // MARK: Submission state
    @Published var submissionError: String?
    @Published var didSubmitSuccessfully = false

    private var tallyObserverTask: Task<Void, Never>?

    // MARK: Constants
    let venueShareRatio: Double = 0.4
    let djPoolRatio: Double = 0.6

    // MARK: - Revenue breakdown

    var revenueBreakdown: RevenueBreakdown {
        let total      = ticketPrice * estimatedAttendance
        let venueShare = total * venueShareRatio
        let djPool     = total * djPoolRatio
        let hostCut    = hostDJRank == 5 ? djPool * (djSharePercentage / 100) : 0
        return RevenueBreakdown(
            totalRevenue:  total,
            venueRevenue:  venueShare,
            hostDJRevenue: hostCut,
            djPayouts:     []
        )
    }

    // MARK: - Load host rank

    /// Called on EventCreationFlowView .task. Sets hostDJRank from the current user's profile.
    func load() async {
        guard let userID = try? await AuthService.currentUserId() else { return }
        guard let user = try? await UserService.fetch(byId: userID) else { return }
        hostDJRank = user.djRank ?? 0
    }

    // MARK: - Stage 1 — save pending event

    /// Validates fields, saves Event with status "pending", starts tally observation,
    /// then advances currentStep to .limbo.
    func saveEventDraft() async {
        guard let venue = venue else {
            submissionError = "No venue selected."
            return
        }
        guard !eventName.trimmingCharacters(in: .whitespaces).isEmpty else {
            submissionError = "Event name is required."
            return
        }
        submissionError = nil

        do {
            let userID  = try await AuthService.currentUserId()
            let combined = combinedEventDateTime()
            let event = Event(
                venueID:          venue.id,
                hostDJID:         userID,
                package:          package.rawValue,
                requestNote:      specialRequest.isEmpty ? nil : specialRequest,
                eventDate:        Temporal.DateTime(combined, timeZone: .current),
                eventName:        eventName,
                description:      eventDescription,
                ticketPrice:      0,               // set in Stage 3
                availableTickets: availableTickets,
                status:           EventStatus.pending.rawValue,
                isFeatured:       false
            )
            try await EventService.save(event)
            createdEventID = event.id
            startTallyObserver()
            currentStep = .limbo
        } catch {
            submissionError = "Could not save event: \(error.localizedDescription)"
        }
    }

    // MARK: - Tally observation

    private func startTallyObserver() {
        tallyObserverTask?.cancel()
        tallyObserverTask = Task { [weak self] in
            guard let self else { return }
            await self.refreshTally()
            do {
                // observe() takes no predicate in Amplify v2 — filter in-stream.
                // Only re-query when the mutated link belongs to THIS event;
                // otherwise every EventDJLink write anywhere re-reads the table.
                for try await change in Amplify.DataStore.observe(EventDJLink.self) {
                    guard !Task.isCancelled else { return }
                    // Skip only when the link provably belongs to another event.
                    // If the association didn't decode, refresh — never miss a tally.
                    if let link = try? change.decodeModel(as: EventDJLink.self),
                       let linkEventID = link.event?.id,
                       linkEventID != self.createdEventID {
                        continue
                    }
                    await self.refreshTally()
                }
            } catch { }
        }
    }

    private func refreshTally() async {
        guard let eventID = createdEventID else { return }
        let links = (try? await EventService.djLinks(forEventID: eventID)) ?? []
        currentTally = links.reduce(0) { $0 + $1.coinContribution }
    }

    // MARK: - Stage 3 — upload poster + go live

    /// Uploads the poster image, then updates the Event record with the poster key,
    /// ticket price, and status:"live". Creates the event chat room on success.
    func uploadPosterAndGoLive(_ image: UIImage) async {
        guard let jpeg = image.jpegData(compressionQuality: 0.8) else { return }
        isUploadingPoster = true
        posterUploadError = nil
        defer { isUploadingPoster = false }

        do {
            let userID  = try await AuthService.currentUserId()
            let keyBase = userID + "-" + (createdEventID ?? UUID().uuidString)
            let key     = MediaKind.eventPoster(eventID: keyBase).makeKey(extension: "jpg")

            _ = try await StorageUploader.uploadJPEG(jpeg, key: key, access: .guest)
            posterImage = image
            posterKey   = key

            guard let eventID = createdEventID,
                  var event = try? await EventService.fetchEvent(byId: eventID) else {
                posterUploadError = "Could not locate event record."
                return
            }
            event.posterKey        = key
            event.ticketPrice      = ticketPrice
            event.availableTickets = availableTickets
            event.status           = EventStatus.live.rawValue
            try await EventService.save(event)

            // Create the event chat room — non-fatal on failure
            try? await ChatRoomService.createEventChatRoom(eventID: eventID)

            didSubmitSuccessfully = true
        } catch {
            posterUploadError = "Upload failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Glow utility (used by MapViewModel)

    func glowStrength(for venue: Venue, allEvents: [Event]) -> Double {
        let calendar = Calendar.current
        let today    = Date()
        var glow: Double = 0.0
        for event in allEvents where event.venueID == venue.id {
            let days = calendar.dateComponents(
                [.day], from: today, to: event.eventDate.foundationDate
            ).day ?? 30
            switch days {
            case 0..<7:    glow += 1.0
            case 7..<15:   glow += 0.6
            case 15..<30:  glow += 0.3
            default:       glow += 0.1
            }
        }
        return min(glow, 1.0)
    }

    // MARK: - Reset

    func reset() {
        tallyObserverTask?.cancel()
        tallyObserverTask  = nil
        currentStep        = .datePicker
        posterImage        = nil
        posterKey          = nil
        isUploadingPoster  = false
        posterUploadError  = nil
        venue              = nil
        package            = .basic
        specialRequest     = ""
        vjUsername         = nil
        eventDate          = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
        eventTime          = Date()
        eventName          = ""
        eventDescription   = ""
        availableTickets   = 100
        ticketPrice        = 0
        djSharePercentage  = 50
        currentTally       = 0
        createdEventID     = nil
        submissionError    = nil
        didSubmitSuccessfully = false
    }

    // MARK: - Private helpers

    private func combinedEventDateTime() -> Date {
        let cal   = Calendar.current
        let dateC = cal.dateComponents([.year, .month, .day], from: eventDate)
        let timeC = cal.dateComponents([.hour, .minute], from: eventTime)
        var combined      = DateComponents()
        combined.year     = dateC.year
        combined.month    = dateC.month
        combined.day      = dateC.day
        combined.hour     = timeC.hour
        combined.minute   = timeC.minute
        return cal.date(from: combined) ?? eventDate
    }
}
