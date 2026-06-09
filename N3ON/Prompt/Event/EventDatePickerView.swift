// EventDatePickerView.swift
// N3ON — Prompt layer
// Stage 1 of event creation. DJ enters an event name, picks a date (min 3 months
// from today), and sets a start time. Booked dates at this venue trigger a warning.
//
// NOTE: Per-day availability colouring (greying out booked dates) requires
// Airbnb HorizonCalendar (github.com/airbnb/HorizonCalendar). The native
// DatePicker enforces the 3-month minimum via `in: minimumDate...` but cannot
// grey individual dates. Add HorizonCalendar via SPM when per-day state is needed.

import SwiftUI

struct EventDatePickerView: View {
    @EnvironmentObject var draft: EventDraftViewModel

    @State private var bookedDates: Set<Date> = []
    @State private var showDateConflict = false

    private var minimumDate: Date {
        Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    }

    private var canContinue: Bool {
        !draft.eventName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                nameSection
                dateSection

                if showDateConflict { conflictWarning }

                if let error = draft.submissionError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                continueButton
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .task { await loadBookedDates() }
        .onChangeCompat(of: draft.eventDate) { _, newDate in
            checkDateConflict(newDate)
        }
    }

    // MARK: — Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let venue = draft.venue {
                Text(venue.name)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                Text(venue.address)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
    }

    // MARK: — Name + description

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionLabel("EVENT NAME")
            TextField("", text: $draft.eventName, prompt:
                Text("e.g. Neon Nights Vol. 3").foregroundColor(.white.opacity(0.3))
            )
            .font(.subheadline)
            .foregroundStyle(.white)
            .padding(12)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            sectionLabel("DESCRIPTION")
            TextField("", text: $draft.eventDescription, prompt:
                Text("What makes this night special? (optional)").foregroundColor(.white.opacity(0.3))
            )
            .font(.subheadline)
            .foregroundStyle(.white)
            .padding(12)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    // MARK: — Date + time

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                sectionLabel("DATE")
                Text("Minimum 3 months from today")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.3))
            }

            DatePicker(
                "",
                selection: $draft.eventDate,
                in: minimumDate...,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .tint(Color("neonPurpleBackground"))
            .labelsHidden()
            .colorScheme(.dark)

            sectionLabel("START TIME")
            DatePicker(
                "",
                selection: $draft.eventTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .colorScheme(.dark)
            .frame(height: 120)
            .clipped()
        }
    }

    // MARK: — Conflict warning

    private var conflictWarning: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color("neonPurpleBackground"))
            Text("This date is already booked at this venue. You can still continue, but confirm with the venue owner.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(12)
        .background(Color("neonPurpleBackground").opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color("neonPurpleBackground").opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: — Continue button

    private var continueButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            Task { await draft.saveEventDraft() }
        } label: {
            Text("Continue")
                .font(.headline)
                .foregroundStyle(canContinue ? .white : .white.opacity(0.3))
        }
        .frame(maxWidth: .infinity, minHeight: 50)
        .background(
            canContinue
                ? AnyShapeStyle(Color("neonPurpleBackground"))
                : AnyShapeStyle(Color.white.opacity(0.08))
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: Color("neonPurpleBackground").opacity(canContinue ? 0.55 : 0), radius: 18)
        .shadow(color: Color("neonPurpleBackground").opacity(canContinue ? 0.85 : 0), radius: 5)
        .disabled(!canContinue)
    }

    // MARK: — Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color("neonPurpleBackground"))
            .tracking(1.5)
    }

    private func loadBookedDates() async {
        guard let venueID = draft.venue?.id else { return }
        bookedDates = await EventService.bookedDates(forVenueID: venueID)
        checkDateConflict(draft.eventDate)
    }

    private func checkDateConflict(_ date: Date) {
        let cal = Calendar.current
        showDateConflict = bookedDates.contains(cal.startOfDay(for: date))
    }
}
