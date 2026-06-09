// EventDetailView.swift
// N3ON
//
// Presented as a sheet when a user taps an event annotation on the map.
// Three zones: full-bleed poster → DJ lineup → pinned ticket CTA.

import SwiftUI

struct EventDetailView: View {
    @ObservedObject var vm: EventViewModel
    @State private var showError = false
    @State private var selectedDJ: User?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    posterSection
                    contentSection
                }
            }
            .scrollIndicators(.hidden)
            .safeAreaInset(edge: .bottom) {
                ticketFooter
            }
        }
        .task {
            await vm.loadDJProfiles()
        }
        .onChangeCompat(of: vm.errorMessage) { _, message in
            showError = message != nil
        }
        .alert("Purchase Failed", isPresented: $showError) {
            Button("OK") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
        .sheet(item: $selectedDJ) { user in
            DJProfilePreviewSheet(djVM: DJViewModel(user: user))
        }
    }

    // MARK: — Poster

    @ViewBuilder
    private var posterSection: some View {
        ZStack(alignment: .bottomLeading) {
            // Image or placeholder
            Group {
                if let key = vm.event.posterKey {
                    AsyncStorageImage(storageKey: key, contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(Color("dullPurple"))
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 52))
                                .foregroundStyle(Color("neonPurpleBackground").opacity(0.35))
                        )
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 300)
            .clipped()

            // Gradient scrim — event name always readable
            LinearGradient(
                colors: [.clear, .black.opacity(0.9)],
                startPoint: UnitPoint(x: 0.5, y: 0.3),
                endPoint: .bottom
            )
            .frame(height: 300)

            // Event name + date over gradient
            VStack(alignment: .leading, spacing: 4) {
                Text(vm.event.eventName)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                Text(vm.formattedDate)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    // MARK: — Content

    @ViewBuilder
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            djLineupSection
            descriptionSection
        }
        .padding(.top, 20)
    }

    // MARK: — DJ Lineup

    @ViewBuilder
    private var djLineupSection: some View {
        if vm.isLoadingDJs {
            HStack(spacing: 16) {
                ForEach(0..<3, id: \.self) { _ in
                    djAvatarSkeleton
                }
            }
            .padding(.horizontal, 16)
        } else if !vm.djProfiles.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("LINEUP")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("neonPurpleBackground"))
                    .tracking(1.5)
                    .padding(.horizontal, 16)

                ScrollView(.horizontal) {
                    HStack(spacing: 16) {
                        ForEach(vm.djProfiles, id: \.id) { dj in
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                selectedDJ = dj
                            } label: {
                                DJAvatarCell(user: dj)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    private var djAvatarSkeleton: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 52, height: 52)
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .frame(width: 48, height: 10)
        }
    }

    // MARK: — Description

    @ViewBuilder
    private var descriptionSection: some View {
        if !vm.event.description.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("ABOUT")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("neonPurpleBackground"))
                    .tracking(1.5)

                Text(vm.event.description)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: — Ticket Footer

    private var ticketFooter: some View {
        VStack(spacing: 0) {
            // Fade edge blends scroll content into the footer
            LinearGradient(
                colors: [.clear, .black],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 32)
            .allowsHitTesting(false)

            HStack(alignment: .center, spacing: 12) {
                // Price column
                VStack(alignment: .leading, spacing: 2) {
                    if vm.isSoldOut {
                        Text("Sold Out")
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .foregroundStyle(.white.opacity(0.35))
                    } else if vm.event.ticketPrice > 0 {
                        Text("$\(Int(vm.event.ticketPrice * Double(vm.ticketQuantity)))")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                        Text(vm.ticketQuantity > 1 ? "\(vm.ticketQuantity) tickets" : "per ticket")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    } else {
                        Text("Free")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundStyle(Color("neonPurpleBackground"))
                    }
                }

                Spacer()

                // Quantity stepper (hidden when sold out or free)
                if !vm.isSoldOut && vm.event.ticketPrice > 0 {
                    HStack(spacing: 0) {
                        Button {
                            if vm.ticketQuantity > 1 { vm.ticketQuantity -= 1 }
                        } label: {
                            Image(systemName: "minus")
                                .font(.caption.bold())
                                .foregroundStyle(.white.opacity(vm.ticketQuantity > 1 ? 0.8 : 0.25))
                                .frame(width: 32, height: 32)
                        }
                        .disabled(vm.ticketQuantity <= 1)

                        Text("\(vm.ticketQuantity)")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 28)

                        Button {
                            if vm.ticketQuantity < 10 { vm.ticketQuantity += 1 }
                        } label: {
                            Image(systemName: "plus")
                                .font(.caption.bold())
                                .foregroundStyle(.white.opacity(vm.ticketQuantity < 10 ? 0.8 : 0.25))
                                .frame(width: 32, height: 32)
                        }
                        .disabled(vm.ticketQuantity >= 10)
                    }
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                } else if !vm.isSoldOut && vm.event.availableTickets > 0 {
                    Text("\(vm.event.availableTickets) left")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                }

                // CTA
                Button {
                    Task { await vm.handlePurchase() }
                } label: {
                    Group {
                        if vm.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text(vm.isSoldOut ? "Sold Out" : "Buy Tickets")
                                .font(.headline)
                                .foregroundStyle(vm.isSoldOut ? .white.opacity(0.3) : .white)
                        }
                    }
                    .frame(width: 136, height: 50)
                }
                .background(
                    vm.isSoldOut
                        ? AnyShapeStyle(Color.white.opacity(0.08))
                        : AnyShapeStyle(Color("neonPurpleBackground"))
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: Color("neonPurpleBackground").opacity(vm.isSoldOut ? 0 : 0.55), radius: 18)
                .shadow(color: Color("neonPurpleBackground").opacity(vm.isSoldOut ? 0 : 0.85), radius: 5)
                .disabled(vm.isLoading || vm.isSoldOut)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color.black.ignoresSafeArea(.all, edges: .bottom))
        }
    }
}

// MARK: — DJ Avatar Cell

private struct DJAvatarCell: View {
    let user: User

    var body: some View {
        VStack(spacing: 8) {
            PulsingAvatarView(
                state: AvatarState.fromUser(user),
                audioKey: user.profileAudioKey,
                size: 52,
                fromMemoryCache: false
            )
            Text("@\(user.username)")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.7))
                .lineLimit(1)
                .frame(width: 72)
        }
    }
}
