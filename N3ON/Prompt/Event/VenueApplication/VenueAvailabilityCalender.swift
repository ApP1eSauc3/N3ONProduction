//
//  VenueAvailabilityCalender.swift
//  N3ON
//

import SwiftUI

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
