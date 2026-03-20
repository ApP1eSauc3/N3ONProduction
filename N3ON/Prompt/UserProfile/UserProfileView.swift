// UserProfileView.swift
// N3ON

import SwiftUI
import Amplify
import PhotosUI

struct UserProfileView: View {
    @StateObject private var vm = RoleAwareProfileViewModel()

    @State private var showImagePicker = false
    @State private var pickerItem: PhotosPickerItem?
    @State private var showBecomeDJSheet = false
    @State private var showBecomeFanSheet = false
    @State private var showDJProfilePreview = false
    @State private var modeSwitchScale: CGFloat = 1.0
    @State private var showQR = false
    @State private var qrImage: UIImage?

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
            ZStack(alignment: .top) {

                // ── Background: deep purple field ──────────────────────────────
                Color("dullPurple").ignoresSafeArea()

                // Radial neon bloom centred on the avatar zone
                RadialGradient(
                    colors: [Color("neonPurpleBackground").opacity(0.55), .clear],
                    center: .init(x: 0.5, y: 0.0),
                    startRadius: 0,
                    endRadius: 340
                )
                .frame(height: 420)
                .ignoresSafeArea(edges: .top)
                .zIndex(0)

                // Black anchor — ensures the bottom of the screen is never
                // purple even when content is short or the user overscrolls up.
                VStack {
                    Spacer()
                    Color.black
                        .frame(height: geo.size.height * 0.68)
                        .ignoresSafeArea(edges: .bottom)
                }
                .zIndex(0)

                // ── Scrollable content ─────────────────────────────────────────
                ScrollView {
                    VStack(spacing: 0) {

                        // Pull-to-reveal QR tracker
                        Color.clear
                            .frame(height: 1)
                            .background(
                                GeometryReader { g in
                                    Color.clear.preference(
                                        key: ProfileScrollOffsetKey.self,
                                        value: g.frame(in: .named("profileScroll")).minY
                                    )
                                }
                            )

                        header
                            .padding(.top, 16)
                            .padding(.bottom, 28)

                        // ── Neon dock line ─────────────────────────────────────
                        neonDockLine

                        // ── Black content card ─────────────────────────────────
                        // minHeight = full screen height guarantees the card
                        // always reaches the bottom regardless of content length.
                        VStack(spacing: 20) {
                            RoleContainer(roles: vm.roles, isDJMode: vm.isDJMode) {
                                RegularUserSection()
                            } dj: {
                                DJSection()
                            } venue: {
                                VenueSection()
                            }
                        }
                        .padding(.top, 28)
                        .padding(.bottom, max(80, geo.safeAreaInsets.bottom + 60))
                        .frame(maxWidth: .infinity, minHeight: geo.size.height)
                        .background(Color.black)
                    }
                }
                .coordinateSpace(name: "profileScroll")
                .onPreferenceChange(ProfileScrollOffsetKey.self) { offset in
                    if offset > 90 {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            showQR = true
                        }
                    }
                }
                .zIndex(1)

                // ── QR full-screen overlay ─────────────────────────────────────
                if showQR, let qr = qrImage {
                    QRRevealView(qrImage: qr, username: vm.username) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            showQR = false
                        }
                    }
                    .zIndex(2)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal:   .move(edge: .top).combined(with: .opacity)
                    ))
                }
            } // ZStack
            } // GeometryReader
            .task { await vm.load() }
            .task(id: vm.username) {
                guard vm.username != "Username" else { return }
                let id = await AuthService.currentUserIdOrNil() ?? vm.username
                qrImage = await Task.detached(priority: .userInitiated) {
                    QRCodeGenerator.generate(from: id)
                }.value
            }
            .navigationBarHidden(true)
            .photosPicker(isPresented: $showImagePicker, selection: $pickerItem, matching: .images)
            .onChangeCompat(of: pickerItem) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await vm.uploadAvatar(image: image)
                    }
                }
            }
            .sheet(isPresented: $showBecomeDJSheet)  { BecomeDJSheet() }
            .sheet(isPresented: $showBecomeFanSheet)  {
                SwitchToFanSheet {
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(100))
                        await vm.toggleDJMode()
                    }
                }
            }
            .sheet(isPresented: $showDJProfilePreview) {
                if let user = vm.currentUser {
                    DJProfilePreviewSheet(djVM: DJViewModel(user: user))
                }
            }
        }
    }

    // MARK: - Neon dock line

    private var neonDockLine: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        .clear,
                        Color("neonPurpleBackground"),
                        Color("neonPurpleBackground"),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1.5)
            .shadow(color: Color("neonPurpleBackground"), radius: 10, y: 4)
            .shadow(color: Color("neonPurpleBackground").opacity(0.3), radius: 4, y: 2)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 24) {

            // Avatar
            ZStack(alignment: .bottomTrailing) {
                PulsingAvatarView(state: vm.avatarState, audioKey: nil, size: 110, fromMemoryCache: true)
                    .frame(width: 110, height: 110)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: vm.isDJMode
                                        ? [Color("neonPurpleBackground"), .cyan, Color("neonPurpleBackground")]
                                        : [Color.white.opacity(0.4), Color.white.opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .padding(2)
                    )
                    .shadow(
                        color: vm.isDJMode
                            ? Color("neonPurpleBackground").opacity(0.9)
                            : Color.white.opacity(0.15),
                        radius: vm.isDJMode ? 18 : 6
                    )
                    .scaleEffect(modeSwitchScale)
                    .onTapGesture {
                        guard vm.isDJMode else { return }
                        showImagePicker.toggle()
                    }
                    .onLongPressGesture(minimumDuration: 0.5) {
                        handleRoleSwitch()
                    }

                if vm.isDJMode {
                    Image(systemName: "camera")
                        .symbolVariant(.circle.fill)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color("neonPurpleBackground"))
                                .shadow(color: Color("neonPurpleBackground").opacity(0.8), radius: 8)
                        )
                        .offset(x: 4, y: 4)
                        .allowsHitTesting(false)
                }
            }

            // Username
            Text(vm.username)
                .font(.system(.title2, design: .rounded, weight: .semibold))
                .foregroundStyle(.white)

            // Mode pill + role switch hint
            modeIndicator

            // DJ public profile shortcut
            if vm.isDJMode {
                Button {
                    showDJProfilePreview = true
                } label: {
                    Label("Preview public profile", systemImage: "arrow.up.right.square")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.45))
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }

            // Followers/following — only meaningful in DJ mode
            if vm.isDJMode {
                HStack(spacing: 24) {
                    StatItem(value: vm.followers, label: "Followers")
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 1, height: 36)
                    StatItem(value: vm.following, label: "Following")
                }
                .padding(.top, 4)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: vm.isDJMode)
    }

    // MARK: - Mode indicator

    @ViewBuilder
    private var modeIndicator: some View {
        if vm.isSwitching {
            ProgressView().tint(.white).scaleEffect(0.8)
        } else {
            let isDJ = vm.isDJMode
            HStack(spacing: 6) {
                Image(systemName: isDJ ? "headphones" : "person.fill")
                    .font(.caption2)
                Text(isDJ ? "DJ Mode" : "Fan Mode")
                    .font(.caption.bold())
            }
            .foregroundStyle(isDJ ? Color.cyan : Color.white.opacity(0.6))
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(isDJ ? Color.cyan.opacity(0.12) : Color.white.opacity(0.06))
                    .overlay(
                        Capsule().stroke(
                            isDJ ? Color.cyan.opacity(0.35) : Color.white.opacity(0.12),
                            lineWidth: 1
                        )
                    )
            )
            .animation(.easeInOut(duration: 0.25), value: isDJ)
        }
    }

    // MARK: - Role switch logic

    private func handleRoleSwitch() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        if vm.roles.contains(.dj) {
            if vm.isDJMode {
                showBecomeFanSheet = true
            } else {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    modeSwitchScale = 1.12
                }
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(150))
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        modeSwitchScale = 1.0
                    }
                    await vm.toggleDJMode()
                }
            }
        } else {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            showBecomeDJSheet = true
        }
    }
}

// MARK: - Scroll offset tracking

private struct ProfileScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - QR full-screen reveal

private struct QRRevealView: View {
    let qrImage: UIImage
    let username: String
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.97).ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button { onDismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white.opacity(0.65))
                    }
                    .padding(.horizontal)
                    .padding(.top, 56)
                }

                Spacer()

                VStack(spacing: 20) {
                    Text(username)
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)

                    Image(uiImage: qrImage)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .padding(24)
                        .background(Color.white)
                        .cornerRadius(20)
                        .padding(.horizontal, 32)
                        .shadow(color: Color("neonPurpleBackground").opacity(0.5), radius: 20)

                    Text("Swipe up or tap × to close")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.3))
                }

                Spacer()
            }
        }
        .gesture(
            DragGesture().onEnded { v in
                if v.translation.height < -60 { onDismiss() }
            }
        )
    }
}

// MARK: - DJ public profile preview sheet

private struct DJProfilePreviewSheet: View {
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
                            PulsingAvatarView(
                                state: .remote(avatarKey: djVM.user.avatarKey ?? "default-avatar"),
                                audioKey: nil,
                                size: 96,
                                fromMemoryCache: true
                            )
                            .overlay(
                                Circle().stroke(
                                    LinearGradient(
                                        colors: [Color("neonPurpleBackground"), .cyan, Color("neonPurpleBackground")],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                ).padding(2)
                            )
                            .shadow(color: Color("neonPurpleBackground").opacity(0.8), radius: 16)

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
        .cornerRadius(10)
    }
}

// MARK: - BecomeDJSheet

struct BecomeDJSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "headphones")
                    .font(.system(size: 56))
                    .foregroundStyle(Color("neonPurpleBackground"))
                    .shadow(color: Color("neonPurpleBackground").opacity(0.9), radius: 20)
                    .shadow(color: Color("neonPurpleBackground").opacity(0.35), radius: 40)
                    .padding(.top, 32)

                Text("Become a DJ")
                    .font(.title.bold())
                    .foregroundStyle(.white)

                Text("To unlock DJ mode, you need to be verified as a DJ. Start at rank 1 — attend events, build your profile, and climb the ranks.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                VStack(spacing: 12) {
                    rankRow(1, "Attend events as a fan")
                    rankRow(2, "6 months active + 26 events")
                    rankRow(3, "12 months + 50 events")
                    rankRow(4, "Headline your first event")
                    rankRow(5, "4 headlined events + endorsements")
                }
                .padding(.horizontal, 24)

                Spacer()

                Button("Got It") { dismiss() }
                    .buttonStyle(.borderedProminent)
                    .tint(Color("neonPurpleBackground"))
                    .padding(.bottom, 32)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color("neonPurpleBackground"))
                }
            }
        }
    }

    private func rankRow(_ rank: Int, _ description: String) -> some View {
        HStack(spacing: 14) {
            Text("\(rank)")
                .font(.headline.bold())
                .foregroundStyle(Color("neonPurpleBackground"))
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color("neonPurpleBackground").opacity(0.15)))
            Text(description)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
            Spacer()
        }
    }
}

// MARK: - SwitchToFanSheet

struct SwitchToFanSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onConfirm: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "person.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.white.opacity(0.55))
                    .padding(.top, 32)

                Text("Switch to Fan Mode")
                    .font(.title.bold())
                    .foregroundStyle(.white)

                Text("Your DJ tools are hidden and you appear as a regular attendee. Your rank and events are preserved — switch back anytime by long-pressing your avatar.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                VStack(spacing: 14) {
                    Button("Switch to Fan Mode") {
                        onConfirm()
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.1))
                    .foregroundStyle(.white)
                    .cornerRadius(14)
                    .padding(.horizontal, 32)

                    Button("Stay as DJ") { dismiss() }
                        .foregroundStyle(Color("neonPurpleBackground"))
                }
                .padding(.bottom, 32)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color("neonPurpleBackground"))
                }
            }
        }
    }
}
