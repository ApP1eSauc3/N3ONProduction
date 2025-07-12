//
//  VenueAvailabilityCalender.swift
//  N3ON
//
//  Created by liam howe on 12/7/2025.
//

import SwiftUI
import ElegantCalendar

struct VenueAvailabilityElegantCalendarView: View {
    @Binding var selectedDate: Date
    @EnvironmentObject var draft: EventDraftViewModel
    @EnvironmentObject var viewModel: MapViewModel

    @State private var showingTimePicker = false
    @State private var tempDate: Date = Date()

    private var configuration: CalendarConfiguration {
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .year, value: 1, to: startDate) ?? startDate
        return CalendarConfiguration(startDate: startDate, endDate: endDate)
    }

    private var unavailableDates: Set<Date> {
        guard let venue = draft.venue else { return [] }
        let events = viewModel.events.filter { $0.venueID == venue.id }
        return Set(events.map { Calendar.current.startOfDay(for: $0.eventDate.date) })
    }

    private var isTimeAvailable: Bool {
        guard let venue = draft.venue else { return true }
        let newStart = selectedDate
        let newEnd = newStart.addingTimeInterval(draft.duration)

        let sameVenueEvents = viewModel.events.filter { $0.venueID == venue.id }

        for event in sameVenueEvents {
            let eventStart = event.eventDate.date
            let eventEnd = eventStart.addingTimeInterval(draft.duration) // Assuming 3hr event
            if newStart < eventEnd && eventStart < newEnd {
                return false
            }
        }
        return true
    }

    var body: some View {
        VStack(spacing: 20) {
            ElegantCalendarView(
                calendarManager: .init(
                    configuration: configuration,
                    initialMonth: Date(),
                    dataSource: self
                )
            ) { state in
                withAnimation(.easeInOut) {
                    tempDate = state
                    showingTimePicker = true
                }
            }
            .frame(height: 400)

            if showingTimePicker {
                VStack(spacing: 16) {
                    DatePicker("Event Time", selection: $selectedDate, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .datePickerStyle(.wheel)
                        .onChange(of: selectedDate) { newValue in
                            if isTimeAvailable {
                                draft.selectedDate = newValue
                                showingTimePicker = false
                            }
                        }

                    HStack {
                        Text("Duration: ")
                        Picker("Duration", selection: $draft.duration) {
                            Text("1h").tag(3600.0)
                            Text("2h").tag(7200.0)
                            Text("3h").tag(10800.0)
                            Text("4h").tag(14400.0)
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

extension VenueAvailabilityElegantCalendarView: ElegantCalendarDataSource {
    func calendar(canSelectDate date: Date) -> Bool {
        !unavailableDates.contains(Calendar.current.startOfDay(for: date))
    }

    func calendar(backgroundColorOpacityForDate date: Date) -> Double {
        unavailableDates.contains(Calendar.current.startOfDay(for: date)) ? 0.3 : 1.0
    }
}

#Preview {
    let draft = EventDraftViewModel()
    draft.venue = Venue(id: "v1", name: "Club Lux", description: "EDM heaven", address: "123 Party St", latitude: 37.78, longitude: -122.41, rating: 4.8, imageKey: ["img1"], ownerID: "owner1", maxCapacity: 400, currentUsers: 0, revenue: 0.0, dailyUserCounts: [], reviews: [])
    draft.duration = 10800 // default 3h

    let viewModel = MapViewModel()
    viewModel.events = [
        Event(id: "e1", venueID: "v1", hostDJID: "dj1", djUsernames: ["Nova"], vjUsername: nil, package: "basic", requestNote: nil, eventDate: Temporal.DateTime(Date().addingTimeInterval(86400)))
    ]

    return VenueAvailabilityElegantCalendarView(selectedDate: .constant(Date()))
        .environmentObject(draft)
        .environmentObject(viewModel)
}
