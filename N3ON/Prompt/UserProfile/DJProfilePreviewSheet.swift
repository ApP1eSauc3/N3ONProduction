// DJProfilePreviewSheet.swift
// N3ON
//
// Read-only preview of how a DJ's public profile appears to other users.
// Presented from UserProfileView (self-preview), MapSearchView, and
// EventDetailView (viewing another DJ).

import SwiftUI

struct DJProfilePreviewSheet: View {
    @StateObject var djVM: DJViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color("dullPurple").ignoresSafeArea()

                RadialGradient(
                    colors: [Color("neonPurpleBackground").opacity(0.45), .clear],
                    center: .init(x: 0.5, y: 0.0),
                    startRadius: 0,
                    endRadius: 280
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        // Avatar + rank
                        VStack(spacing: 12) {
                            // DESIGN §3.4 — ring and glow are inside PulsingAvatarView; no overlay needed
                            PulsingAvatarView(
                                state: .remote(avatarKey: djVM.user.avatarKey ?? "default-avatar"),
                                audioKey: djVM.user.profileAudioKey,
                                size: 96
                            )

                            Text(djVM.user.username)
                                .font(.system(.title2, design: .rounded, weight: .semibold))
                                .foregroundStyle(.white)

                            if let rank = djVM.user.djRank, rank > 0 {
                                rankBadge(rank)
                            }
                        }
                        .padding(.top, 24)

                        // Upcoming events
                        if !djVM.upcomingEvents.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Upcoming Events")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                ForEach(djVM.upcomingEvents.prefix(4)) { event in
                                    eventRow(event)
                                }
                            }
                            .padding(.horizontal)
                        } else if djVM.isLoading {
                            ProgressView().tint(.white).padding()
                        } else {
                            Text("No upcoming events")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.5))
                                .padding()
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Public Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color("neonPurpleBackground"))
                }
            }
        }
    }

    private func rankBadge(_ rank: Int) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "headphones")
                .font(.caption2)
            Text("Rank \(rank)")
                .font(.caption.bold())
        }
        .foregroundStyle(Color("neonPurpleBackground"))
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(Color("neonPurpleBackground").opacity(0.12))
                .overlay(Capsule().stroke(Color("neonPurpleBackground").opacity(0.3), lineWidth: 1))
        )
    }

    private func eventRow(_ event: Event) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color("neonPurpleBackground").opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "music.note")
                        .foregroundStyle(Color("neonPurpleBackground"))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(event.eventName)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                Text(event.eventDate.foundationDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
        }
        .padding(10)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
