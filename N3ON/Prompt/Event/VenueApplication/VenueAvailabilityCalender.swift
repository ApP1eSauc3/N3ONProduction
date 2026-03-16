//
//  VenueAvailabilityCalender.swift
//  N3ON
//

import SwiftUI
import Amplify

struct VenueAvailabilityElegantCalendarView: View {
    @EnvironmentObject var draft: EventDraftViewModel

    // Events for the selected venue passed in by the parent.
    // MapViewModel has no events property — caller filters by venue.id.
    let venueEvents: [Event]

    private var conflictingDates: Set<Date> {
        Set(venueEvents.map {
            Calendar.current.startOfDay(for: $0.eventDate.foundationDate)
        })
    }

    private var selectedDayHasConflict: Bool {
        conflictingDates.contains(Calendar.current.startOfDay(for: draft.eventDate))
    }

    var body: some View {
        VStack(spacing: 20) {
            DatePicker(
                "Event Date & Time",
                selection: $draft.eventDate,
                in: Date()...,
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.graphical)

            if selectedDayHasConflict {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("This venue already has an event on the selected date.")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
}

#Preview {
    let draft = EventDraftViewModel()
    draft.venue = Venue(
        id: "v1",
        name: "Club Lux",
        description: "EDM heaven",
        address: "123 Party St",
        latitude: 37.78,
        longitude: -122.41,
        rating: 4.8,
        imageKey: ["img1"],
        ownerID: "owner1",
        maxCapacity: 400,
        currentUsers: 0,
        revenue: 0.0
    )

    let sampleEvents: [Event] = [
        Event(
            id: "e1",
            venueID: "v1",
            hostDJID: "dj1",
            vjUsername: nil,
            package: "basic",
            requestNote: nil,
            eventDate: Temporal.DateTime(Date().addingTimeInterval(86400), timeZone: .current),
            eventName: "Test Event",
            description: "Preview event",
            ticketPrice: 20.0,
            availableTickets: 100
        )
    ]

    VenueAvailabilityElegantCalendarView(venueEvents: sampleEvents)
        .environmentObject(draft)
}
