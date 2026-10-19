//
//  UserEventTimelineView.swift
//  N3ON
//
// "My Events" (DJ tools): events you organise or play, split into upcoming
// and past, each opening the event page. Was an Xcode "Hello, World!"
// placeholder until 2026-10.

import SwiftUI

struct UserEventTimelineView: View {
    @State private var events: [Event] = []
    @State private var isLoading = true
    @State private var loadFailed = false
    @State private var selected: Event?

    private var upcoming: [Event] { events.filter { $0.eventDate.foundationDate >= Date() } }
    private var past: [Event] { events.filter { $0.eventDate.foundationDate < Date() }.reversed() }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if isLoading {
                ProgressView().tint(Color("neonPurpleBackground"))
            } else if loadFailed {
                message("Couldn't load your events.", detail: "Check your connection and try again.")
            } else if events.isEmpty {
                message("No events yet", detail: "Events you create or join a lineup for show up here.")
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        if !upcoming.isEmpty { section("UPCOMING", upcoming) }
                        if !past.isEmpty { section("PAST", past) }
                    }
                    .padding(16)
                }
            }
        }
        .navigationTitle("My Events")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await load() }
        .refreshable { await load() }
        .sheet(item: $selected) { event in
            EventDetailView(vm: EventViewModel(event: event))
        }
    }

    private func load() async {
        defer { isLoading = false }
        do {
            events = try await EventService.myEvents()
            loadFailed = false
        } catch {
            loadFailed = true
        }
    }

    private func section(_ title: String, _ items: [Event]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color("neonPurpleBackground"))
                .tracking(1.5)
            ForEach(items, id: \.id) { event in
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    selected = event
                } label: {
                    row(event)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func row(_ event: Event) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.eventName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(event.eventDate.foundationDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
            Text(event.status.capitalized)
                .font(.caption.weight(.semibold))
                .foregroundStyle(event.status == EventStatus.live.rawValue ? Color("neonPurpleBackground") : .white.opacity(0.5))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.white.opacity(0.06)))
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding(12)
        .frame(minHeight: 44)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func message(_ title: String, detail: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar")
                .font(.system(size: 40))
                .foregroundStyle(.white.opacity(0.3))
            Text(title)
                .font(.headline)
                .foregroundStyle(.white.opacity(0.7))
            Text(detail)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
}

#Preview {
    NavigationStack { UserEventTimelineView() }
}
