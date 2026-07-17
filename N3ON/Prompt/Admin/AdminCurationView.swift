// AdminCurationView.swift
// N3ON — Prompt layer (Admin)
//
// Bootstrap curation console. Only reachable when AccessControlService.isAdmin().
// Lets the admin team supersede ranking rules during the cold-start phase: seed
// DJ ranks, mark DJs curated (allowed to host), feature events, force-publish past
// the tally, and hand-build event lineups. The ranking system itself is unchanged —
// see Data/CurationConfig.swift. Follows Prompt/AGENTS.md (black base, single neon
// accent, 8pt grid, haptics on actions).

import SwiftUI

struct AdminCurationView: View {
    @StateObject private var vm = AdminCurationViewModel()
    @State private var tab: Tab = .djs
    @State private var lineupEvent: Event?

    private enum Tab { case djs, events }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 16) {
                tabSwitcher

                if let err = vm.errorMessage {
                    Text(err)
                        .font(.caption)
                        .foregroundStyle(.red.opacity(0.8))
                        .padding(.horizontal, 16)
                }

                if vm.isLoading {
                    Spacer()
                    ProgressView().tint(Color("neonPurpleBackground"))
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            switch tab {
                            case .djs:    ForEach(vm.djs, id: \.id) { djRow($0) }
                            case .events: ForEach(vm.events, id: \.id) { eventRow($0) }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 32)
                    }
                }
            }
            .padding(.top, 12)
        }
        .navigationTitle("Curation Console")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await vm.load() }
        .sheet(item: $lineupEvent) { event in
            LineupSheet(vm: vm, event: event)
        }
    }

    // MARK: — Tab switcher

    private var tabSwitcher: some View {
        HStack(spacing: 0) {
            tabButton("DJs", .djs)
            tabButton("Events", .events)
        }
        .padding(4)
        .background(Color.white.opacity(0.06))
        .clipShape(Capsule())
        .padding(.horizontal, 16)
    }

    private func tabButton(_ title: String, _ value: Tab) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            tab = value
        } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tab == value ? .white : .white.opacity(0.5))
                .frame(maxWidth: .infinity, minHeight: 44)   // HIG min tap target
                .background(tab == value ? Color("neonPurpleBackground") : Color.clear)
                .clipShape(Capsule())
        }
    }

    // MARK: — DJ row

    private func djRow(_ dj: User) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                PulsingAvatarView(
                    state: .remote(avatarKey: dj.avatarKey ?? "default-avatar"),
                    audioKey: nil, size: 40
                )
                VStack(alignment: .leading, spacing: 2) {
                    Text("@\(dj.username)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(dj.isCurated ? "Curated" : "Rank \(dj.djRank ?? 0)")
                        .font(.caption)
                        .foregroundStyle(dj.isCurated ? Color("neonPurpleBackground") : .white.opacity(0.5))
                }
                Spacer()
            }
            HStack(spacing: 10) {
                rankMenu(dj)
                curatedButton(dj)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func rankMenu(_ dj: User) -> some View {
        Menu {
            Button("No rank") { Task { await vm.seedRank(nil, for: dj) } }
            ForEach(1...5, id: \.self) { r in
                Button("Rank \(r)") { Task { await vm.seedRank(r, for: dj) } }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "arrow.up.circle")
                Text("Rank \(dj.djRank ?? 0)")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .frame(minHeight: 44)
            .background(Color.white.opacity(0.06))
            .clipShape(Capsule())
        }
    }

    private func curatedButton(_ dj: User) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            Task { await vm.toggleCurated(dj) }
        } label: {
            Text(dj.isCurated ? "Curated ✓" : "Mark curated")
                .font(.caption.weight(.semibold))
                .foregroundStyle(dj.isCurated ? .white : Color("neonPurpleBackground"))
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .background(dj.isCurated
                            ? Color("neonPurpleBackground")
                            : Color("neonPurpleBackground").opacity(0.12))
                .clipShape(Capsule())
        }
    }

    // MARK: — Event row

    private func eventRow(_ event: Event) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(event.eventName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(event.status.capitalized + (event.isFeatured ? " · Featured" : ""))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
            HStack(spacing: 10) {
                featureButton(event)
                if event.status != EventStatus.live.rawValue {
                    publishButton(event)
                }
                lineupButton(event)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func featureButton(_ event: Event) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            Task { await vm.toggleFeatured(event) }
        } label: {
            Label(event.isFeatured ? "Featured" : "Feature", systemImage: "star.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(event.isFeatured ? .white : Color("neonPurpleBackground"))
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .background(event.isFeatured
                            ? Color("neonPurpleBackground")
                            : Color("neonPurpleBackground").opacity(0.12))
                .clipShape(Capsule())
        }
    }

    private func publishButton(_ event: Event) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            Task { await vm.forcePublish(event) }
        } label: {
            Text("Publish")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .background(Color("neonPurpleBackground"))
                .clipShape(Capsule())
                // DESIGN §3.1 — no glow: this is a per-row list action, not a singular
                // primary CTA; glowing every row would blow the 2–3-per-screen budget.
        }
    }

    private func lineupButton(_ event: Event) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            lineupEvent = event
        } label: {
            Label("Lineup", systemImage: "person.2.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .background(Color.white.opacity(0.06))
                .clipShape(Capsule())
        }
    }
}

// MARK: — Lineup sheet

private struct LineupSheet: View {
    @ObservedObject var vm: AdminCurationViewModel
    let event: Event
    @Environment(\.dismiss) private var dismiss
    @State private var added: Set<String> = []

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    LazyVStack(spacing: 8) {
                        Text("Attach DJs to “\(event.eventName)”")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.4))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)

                        ForEach(vm.djs, id: \.id) { dj in
                            HStack(spacing: 12) {
                                PulsingAvatarView(
                                    state: .remote(avatarKey: dj.avatarKey ?? "default-avatar"),
                                    audioKey: nil, size: 36
                                )
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("@\(dj.username)")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.white)
                                    Text("Rank \(dj.djRank ?? 0)")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.4))
                                }
                                Spacer()
                                Button {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    added.insert(dj.id)
                                    Task { await vm.attachDJ(dj, to: event) }
                                } label: {
                                    Text(added.contains(dj.id) ? "Added" : "Add")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(added.contains(dj.id) ? .white.opacity(0.35) : Color("neonPurpleBackground"))
                                        .padding(.horizontal, 12)
                                        .frame(minHeight: 44)
                                        .background(added.contains(dj.id)
                                                    ? Color.white.opacity(0.06)
                                                    : Color("neonPurpleBackground").opacity(0.12))
                                        .clipShape(Capsule())
                                }
                                .disabled(added.contains(dj.id))
                            }
                            .padding(12)
                            .background(Color.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Manage Lineup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color("neonPurpleBackground"))
                }
            }
        }
    }
}
