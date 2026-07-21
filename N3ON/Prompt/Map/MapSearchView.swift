// MapSearchView.swift
// N3ON — Prompt layer
// (Named per root CLAUDE.md filename-uniqueness rule — never plain SearchView.swift.)
// Global search: DJs, Events, Venues. Presented as a full-screen sheet from MapView.
//
// Design reference:
// — Resident Advisor: category tabs pinned below search bar, live results,
//   DJ results show avatar + rank badge, event rows show poster thumbnail + headliner.
// — Dice: segmented categories with counts in badges, empty state shows "trending" block.
// — Bandsintown: recent searches shown before typing, artist results first.
//
// N3ON follows the RA structure: pinned tab bar, live debounced results per category,
// recent searches shown on empty query. DJs are default category (app is DJ-centric).

import SwiftUI

struct MapSearchView: View {
    @StateObject private var vm = SearchViewModel()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isSearchFocused: Bool

    @State private var selectedEvent: Event?
    @State private var selectedDJ: User?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    searchBar
                    categoryTabs
                    resultsList
                }
            }
            .ignoresSafeArea(.keyboard)
            .navigationBarHidden(true)
            // Event detail sheet
            .sheet(item: $selectedEvent) { event in
                EventDetailView(vm: EventViewModel(event: event))
            }
            // DJ profile sheet
            .sheet(item: $selectedDJ) { user in
                DJProfilePreviewSheet(djVM: DJViewModel(user: user))
            }
        }
        .onAppear { isSearchFocused = true }
        .onChangeCompat(of: vm.query) { _, new in
            vm.queryChanged(new)
        }
    }

    // MARK: — Search bar

    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.white.opacity(0.4))

                TextField("", text: $vm.query, prompt:
                    Text("DJs, events, venues…").foregroundColor(.white.opacity(0.3))
                )
                .foregroundStyle(.white)
                .focused($isSearchFocused)
                .submitLabel(.search)
                .onSubmit { vm.commitSearch(vm.query) }
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

                if !vm.query.isEmpty {
                    Button {
                        vm.query = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
            }
            .padding(10)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            Button("Cancel") {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                dismiss()
            }
            .font(.subheadline)
            .foregroundStyle(Color("neonPurpleBackground"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black)
    }

    // MARK: — Category tabs (RA pattern: pinned below search, counts as badges)

    private var categoryTabs: some View {
        VStack(spacing: 0) {
        HStack(spacing: 0) {
            ForEach(SearchViewModel.Category.allCases, id: \.self) { cat in
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.easeInOut(duration: 0.2)) { vm.category = cat }
                } label: {
                    VStack(spacing: 6) {
                        HStack(spacing: 4) {
                            Text(cat.rawValue)
                                .font(.subheadline.weight(vm.category == cat ? .semibold : .regular))
                                .foregroundStyle(vm.category == cat ? .white : .white.opacity(0.4))

                            // Result count badge
                            if !vm.query.isEmpty {
                                let count = resultCount(for: cat)
                                if count > 0 {
                                    Text("\(count)")
                                        .font(.caption2.bold())
                                        .foregroundStyle(
                                            vm.category == cat
                                                ? Color("neonPurpleBackground")
                                                : .white.opacity(0.3)
                                        )
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(
                                            (vm.category == cat
                                             ? Color("neonPurpleBackground")
                                             : Color.white).opacity(0.1)
                                        )
                                        .clipShape(Capsule())
                                }
                            }
                        }

                        // Active indicator
                        Rectangle()
                            .fill(vm.category == cat
                                  ? Color("neonPurpleBackground")
                                  : Color.clear)
                            .frame(height: 2)
                            .shadow(
                                color: Color("neonPurpleBackground").opacity(
                                    vm.category == cat ? 0.6 : 0
                                ),
                                radius: 6
                            )
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
        .background(Color.black)

        // Bottom separator
        Rectangle()
            .fill(Color.white.opacity(0.06))
            .frame(height: 1)
        }
    }

    // MARK: — Results

    @ViewBuilder
    private var resultsList: some View {
        if vm.isSearching {
            Spacer()
            ProgressView().tint(Color("neonPurpleBackground"))
            Spacer()
        } else if vm.query.isEmpty {
            recentSearchesView
        } else {
            switch vm.category {
            case .djs:    djResultsView
            case .events: eventResultsView
            case .venues: venueResultsView
            }
        }
    }

    // MARK: — Recent searches (Bandsintown / RA pattern)

    private var recentSearchesView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if vm.recentSearches.isEmpty {
                    emptyHint
                } else {
                    HStack {
                        Text("RECENT")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color("neonPurpleBackground"))
                            .tracking(1.5)
                        Spacer()
                        Button("Clear") { vm.clearRecents() }
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    ForEach(vm.recentSearches, id: \.self) { recent in
                        recentRow(recent)
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private var emptyHint: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36))
                .foregroundStyle(.white.opacity(0.1))
                .padding(.top, 60)
            Text("Search for DJs, events, or venues")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.3))
        }
        .frame(maxWidth: .infinity)
    }

    private func recentRow(_ query: String) -> some View {
        Button {
            vm.query = query
            vm.queryChanged(query)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(.white.opacity(0.3))
                    .frame(width: 20)
                Text(query)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                Button {
                    vm.removeRecent(query)
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.3))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    // MARK: — DJ results (RA-style: avatar + username + rank badge)

    private var djResultsView: some View {
        Group {
            if vm.djResults.isEmpty {
                noResultsView(for: "DJs")
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(vm.djResults, id: \.id) { user in
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                selectedDJ = user
                            } label: {
                                DJSearchRow(user: user)
                            }
                            .buttonStyle(.plain)
                            Divider().background(Color.white.opacity(0.05))
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    // MARK: — Event results (Dice-style: poster thumbnail + name + date + price)

    private var eventResultsView: some View {
        Group {
            if vm.eventResults.isEmpty {
                noResultsView(for: "events")
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(vm.eventResults, id: \.id) { event in
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                selectedEvent = event
                            } label: {
                                EventSearchRow(event: event)
                            }
                            .buttonStyle(.plain)
                            Divider().background(Color.white.opacity(0.05))
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    // MARK: — Venue results

    private var venueResultsView: some View {
        Group {
            if vm.venueResults.isEmpty {
                noResultsView(for: "venues")
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(vm.venueResults, id: \.id) { venue in
                            VenueSearchRow(venue: venue)
                            Divider().background(Color.white.opacity(0.05))
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    // MARK: — Helpers

    private func resultCount(for category: SearchViewModel.Category) -> Int {
        switch category {
        case .djs:    return vm.djResults.count
        case .events: return vm.eventResults.count
        case .venues: return vm.venueResults.count
        }
    }

    private func noResultsView(for label: String) -> some View {
        VStack(spacing: 8) {
            Text("No \(label) found for \"\(vm.query)\"")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.4))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.top, 48)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: — Row cells

private struct DJSearchRow: View {
    let user: User

    var body: some View {
        HStack(spacing: 14) {
            PulsingAvatarView(
                state: AvatarState.fromUser(user),
                audioKey: user.profileAudioKey,
                size: 44
            )

            VStack(alignment: .leading, spacing: 2) {
                Text("@\(user.username)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                if let rank = user.djRank, rank > 0 {
                    Text("Rank \(rank) DJ")
                        .font(.caption)
                        .foregroundStyle(Color("neonPurpleBackground"))
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.25))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

private struct EventSearchRow: View {
    let event: Event

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMM · HH:mm"
        return f
    }()

    var body: some View {
        HStack(spacing: 14) {
            // Poster thumbnail or placeholder
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color("neonPurpleBackground").opacity(0.25))
                .frame(width: 52, height: 52)
                .overlay(
                    Group {
                        if let key = event.posterKey {
                            AsyncStorageImage(storageKey: key, contentMode: .fill)
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        } else {
                            Image(systemName: "music.note")
                                .foregroundStyle(Color("neonPurpleBackground").opacity(0.6))
                        }
                    }
                )
                .clipped()

            VStack(alignment: .leading, spacing: 3) {
                Text(event.eventName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(Self.dateFormatter.string(from: event.eventDate.foundationDate))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                if event.ticketPrice > 0 {
                    Text("From $\(Int(event.ticketPrice))")
                        .font(.caption2)
                        .foregroundStyle(Color("neonPurpleBackground"))
                } else {
                    Text("Free")
                        .font(.caption2)
                        .foregroundStyle(Color("neonPurpleBackground"))
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.25))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

private struct VenueSearchRow: View {
    let venue: Venue

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color("dullPurple"))
                .frame(width: 52, height: 52)
                .overlay(
                    Image(systemName: "building.2")
                        .foregroundStyle(Color("neonPurpleBackground").opacity(0.6))
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(venue.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(venue.address)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(1)
                Text("Cap. \(venue.maxCapacity)")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.35))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.25))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// Note: Venue: Identifiable is declared in MapView.swift
// Note: Event: Identifiable is declared in VenueEventSheet.swift
// User: Identifiable is needed for ForEach in DJ results
extension User: Identifiable {}
