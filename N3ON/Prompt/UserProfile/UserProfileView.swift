// UserProfileView.swift
// N3ON

// MARK: - Design §5.1 — Profile screen zone map (iPhone 14 · 390×844pt · nav bar hidden)
//
//  Zone              Height             SwiftUI expression
//  ─────────────── ──────────────────── ───────────────────────────────────────────
//  Purple hero      ~30% of screen      geo.size.height * 0.30  (dock line position)
//  Radial bloom     35% of screen       .frame(height: geo.size.height * 0.35)
//  Bloom endRadius  87% of width        geo.size.width * 0.87
//  Black anchor     68% of screen       .frame(height: geo.size.height * 0.68)
//  Content card     full screen min     .frame(minHeight: geo.size.height)
//  Header top pad   16pt (fixed)        .padding(.top, 16)
//  Header bot pad   24pt (fixed)        .padding(.bottom, 24)
//
//  All heights are proportional to geo.size — never use fixed pt for container heights.

import SwiftUI
import PhotosUI

struct UserProfileView: View {
    @StateObject private var vm = RoleAwareProfileViewModel()
    @EnvironmentObject private var authVM: AuthViewModel

    @State private var showImagePicker = false
    @State private var pickerItem: PhotosPickerItem?
    @State private var showBecomeDJSheet = false
    @State private var showDJProfilePreview = false
    @State private var showQR = false
    @State private var qrImage: UIImage?
    @State private var showRoleSwitchConfirm = false
    @State private var showDeleteConfirm = false
    /// Measured height of the static header — used as transparent spacer in ScrollView.
    @State private var headerHeight: CGFloat = 280

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
            ZStack(alignment: .top) {

                // ── Background: purple→black gradient stops bleed into tab bar ──
                // dullPurple fills top ~30%, transitions to black by 52%.
                // Any overscroll or tab-bar area shows black, never purple.
                LinearGradient(
                    stops: [
                        .init(color: Color("dullPurple"), location: 0.0),
                        .init(color: Color("dullPurple"), location: 0.30),
                        .init(color: .black,              location: 0.52),
                        .init(color: .black,              location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // Radial neon bloom centred on the avatar zone
                RadialGradient(
                    colors: [Color("neonPurpleBackground").opacity(0.55), .clear], // DESIGN §5.1 bloom opacity
                    center: .init(x: 0.5, y: 0.0),
                    startRadius: 0,
                    endRadius: geo.size.width * 0.87  // DESIGN §5.1 bloom radius — proportional to width
                )
                .frame(height: geo.size.height * 0.35)  // DESIGN §5.1 bloom height — proportional to height
                .ignoresSafeArea(edges: .top)
                .zIndex(0)

                // ── Static header — lives BEHIND the scroll view ───────────────
                // ScrollView (zIndex 1) slides the black content card over this
                // as the user scrolls, hiding the header naturally.
                header
                    .padding(.top, 16)    // DESIGN §5.1 header top padding
                    .padding(.bottom, 32) // DESIGN §5.1 header bottom padding
                    .frame(maxWidth: .infinity)
                    .background(
                        GeometryReader { g in
                            Color.clear.preference(key: HeaderHeightKey.self, value: g.size.height)
                        }
                    )
                    .zIndex(0)

                // ── Scrollable content — covers the header as you scroll ────────
                ScrollView {
                    VStack(spacing: 0) {

                        // Transparent gap reveals the static header beneath.
                        // allowsHitTesting(false) passes taps through to header buttons.
                        // Pull-to-reveal QR tracker lives here.
                        Color.clear
                            .frame(height: headerHeight)
                            .allowsHitTesting(false)
                            .background(
                                GeometryReader { g in
                                    Color.clear.preference(
                                        key: ProfileScrollOffsetKey.self,
                                        value: g.frame(in: .named("profileScroll")).minY
                                    )
                                }
                            )

                        // ── Neon dock line ─────────────────────────────────────
                        neonDockLine

                        // ── Black content card ─────────────────────────────────
                        VStack(spacing: 20) {
                            RoleContainer(role: vm.role) {
                                RegularUserSection()
                            } dj: {
                                DJSection(rank: vm.currentUser?.djRank ?? 0,
                                          userID: vm.currentUser?.id ?? "",
                                          canCreateEvent: vm.canCreateEvent)
                            } venue: {
                                VenueSection()
                            }

                            if vm.isAdmin { adminSection }

                            accountSection
                        }
                        .padding(.top, 28)
                        .padding(.bottom, max(80, geo.safeAreaInsets.bottom + 60))
                        .frame(maxWidth: .infinity, minHeight: geo.size.height * 1.5)
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
                .onPreferenceChange(HeaderHeightKey.self) { h in
                    headerHeight = h
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
                    QRCodeGenerator.make(from: id)
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
            .confirmationDialog("Switch to Fan Mode?", isPresented: $showRoleSwitchConfirm, titleVisibility: .visible) {
                Button("Switch to Fan Mode", role: .destructive) {
                    Task { await vm.switchRole(to: .regular) }
                }
            } message: {
                Text("You'll lose DJ features until you switch back.")
            }
            .alert("Role Switch Failed", isPresented: Binding(
                get: { vm.roleSwitchError != nil },
                set: { if !$0 { vm.roleSwitchError = nil } }
            )) {
                Button("OK") { vm.roleSwitchError = nil }
            } message: {
                Text(vm.roleSwitchError ?? "")
            }
            .confirmationDialog(
                "Delete Account?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete My Account", role: .destructive) {
                    Task { await authVM.deleteAccount() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This is permanent and cannot be undone. Your profile, messages, and all data will be deleted.")
            }
            .alert("Deletion Failed", isPresented: Binding(
                get: { authVM.errorMessage != nil },
                set: { if !$0 { authVM.errorMessage = nil } }
            )) {
                Button("OK") { authVM.errorMessage = nil }
            } message: {
                Text(authVM.errorMessage ?? "")
            }
            .sheet(isPresented: $showBecomeDJSheet) {
                BecomeDJSheet {
                    Task { await vm.switchRole(to: .dj) }
                }
            }
            .sheet(isPresented: $showDJProfilePreview) {
                if let user = vm.currentUser {
                    DJProfilePreviewSheet(djVM: DJViewModel(user: user))
                }
            }
        }
    }

    // MARK: - Account section

    // Admin curation console entry — shown only to admins (orthogonal capability).
    @ViewBuilder private var adminSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Color("neonPurpleBackground"))
                    .frame(width: 3, height: 16)
                Text("Admin")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            NavigationLink {
                AdminCurationView()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                    Text("Curation Console")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.3))
                }
                .font(.subheadline)
                .foregroundStyle(.white)
                .padding(12)                // DESIGN §1.6 row inner padding — 12pt
                .background(Color.customDarkGray)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .frame(minHeight: 44)           // HIG minimum tap target
            .contentShape(Rectangle())
        }
    }

    @ViewBuilder private var accountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header — muted bar distinguishes utility rows from feature zones
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 3, height: 16)
                Text("Account")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            // Sign Out
            Button {
                Task { await authVM.signOut() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.right.square")
                    Text("Sign Out")
                    Spacer()
                }
                .font(.subheadline)
                .foregroundStyle(.white)
                .padding(12)                // DESIGN §1.6 row inner padding — 12pt
                .background(Color.customDarkGray)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))           // DESIGN §1.6 row radius — 10pt
            }
            .frame(minHeight: 44)           // HIG minimum tap target
            .contentShape(Rectangle())

            // Delete Account — visually subdued until confirmed
            Button {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred() // DESIGN §4 destructive haptic
                showDeleteConfirm = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "trash")
                    Text("Delete Account")
                    Spacer()
                }
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
                .padding(12)
                .background(Color.customDarkGray)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
            .disabled(authVM.isLoading)
        }
        .padding(.horizontal, 16) // DESIGN §2.4 — standard 16pt horizontal margin
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
        // DESIGN §5.1 header VStack spacing — 24pt (space6). Change here for tighter/looser header.
        VStack(spacing: 24) {

            // DESIGN §3.4 — BUG: ring applied as .overlay with .padding(2) on the avatar frame.
            // .padding(2) insets the stroke ring INSIDE the 110pt clip boundary.
            // The ring is painting inside the image, not on the container edge.
            // The .shadow is anchored to PulsingAvatarView which has no outer container frame.
            // Fix: remove .overlay/.shadow from here; move ring and glow inside PulsingAvatarView
            // using the container-anchored pattern in §3.4 of Prompt/AGENTS.md.
            ZStack(alignment: .bottomTrailing) {
                // DESIGN §3.4 — ring and glow now live inside PulsingAvatarView; no overlay needed here.
                // Container frame is size+20 = 130pt; PulsingAvatarView manages its own ring at size+4.
                PulsingAvatarView(state: vm.avatarState, audioKey: nil, size: 110, fromMemoryCache: true)
                    // DESIGN §3.4 avatar size — 110pt. Spec is 96pt (24.6% of 390w). Change the `size:` arg above.
                    .onTapGesture {
                        guard vm.role == .dj else { return }
                        showImagePicker.toggle()
                    }

                if vm.role == .dj {
                    Image(systemName: "camera")
                        .symbolVariant(.circle.fill)
                        .font(.system(size: 20, weight: .medium)) // DESIGN §1.7 badge icon size — 20pt
                        .foregroundStyle(.white)
                        .padding(8)  // DESIGN §1.3 badge padding — 8pt (space2). Increase for larger tap target.
                        .background(
                            Circle()
                                .fill(Color("neonPurpleBackground"))
                                .shadow(color: Color("neonPurpleBackground").opacity(0.8), radius: 8) // DESIGN §3.1 badge glow
                        )
                        .offset(x: 4, y: 4)  // DESIGN §5.1 camera badge offset — adjust if avatar size changes
                        .allowsHitTesting(false)
                }
            }

            // DESIGN §1.7 username — .title2 .semibold .rounded. See §1.7 type scale to adjust.
            Text(vm.username)
                .font(.system(.title2, design: .rounded, weight: .semibold))
                .foregroundStyle(.white)

            // Mode pill + role switch hint
            modeIndicator

            // DJ public profile shortcut
            if vm.role == .dj {
                Button {
                    showDJProfilePreview = true
                } label: {
                    Label("Preview public profile", systemImage: "arrow.up.right.square")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.45))
                }
            }

            // Followers/following — DJ only
            if vm.role == .dj {
                // DESIGN §5.1 stats row spacing — 24pt (space6). Change here.
                HStack(spacing: 24) {
                    StatItem(value: vm.followers, label: "Followers")
                    Rectangle()
                        .fill(Color.white.opacity(0.2))  // DESIGN §1.4 separator opacity
                        .frame(width: 1, height: 36)     // DESIGN §5.1 stat separator height — 36pt
                    StatItem(value: vm.following, label: "Following")
                }
                .padding(.top, 4)  // DESIGN §5.1 stats row top padding — 4pt (space1). Off-grid relative to VStack spacing; increase to 8pt for clarity.
            }
        }
        .animation(.easeInOut(duration: 0.25), value: vm.role)
    }

    // MARK: - Role badge

    @ViewBuilder
    private var modeIndicator: some View {
        if vm.isSwitchingRole {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(Color.cyan)
                .frame(height: 28)
        } else if vm.role == .dj {
            // Tappable — opens confirmation to drop back to Fan
            Button {
                showRoleSwitchConfirm = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "headphones")
                        .font(.caption2)
                    Text("DJ")
                        .font(.caption.bold())
                }
                .foregroundStyle(Color.cyan)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(Color.cyan.opacity(0.12))
                        .overlay(Capsule().stroke(Color.cyan.opacity(0.35), lineWidth: 1))
                )
            }
            .accessibilityLabel("DJ mode active — tap to switch to Fan mode")
        } else if vm.role == .regular {
            // Tappable — opens BecomeDJSheet with functional Enable action
            Button {
                showBecomeDJSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "person.fill")
                        .font(.caption2)
                    Text("Fan")
                        .font(.caption.bold())
                }
                .foregroundStyle(.white.opacity(0.45))
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.06))
                        .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
                )
            }
            .accessibilityLabel("Fan mode active — tap to enable DJ mode")
        } else if vm.role == .venue {
            // Static — venue role is admin-assigned via Cognito
            HStack(spacing: 6) {
                Image(systemName: "building.2.fill")
                    .font(.caption2)
                Text("Venue")
                    .font(.caption.bold())
            }
            .foregroundStyle(Color("neonPurpleBackground"))
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(Color("neonPurpleBackground").opacity(0.12))
                    .overlay(Capsule().stroke(Color("neonPurpleBackground").opacity(0.35), lineWidth: 1))
            )
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

/// Measures the rendered height of the static header so the ScrollView
/// transparent spacer stays in sync when role or content changes.
private struct HeaderHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
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
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
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
                                size: 96,
                                fromMemoryCache: true
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

// MARK: - BecomeDJSheet

struct BecomeDJSheet: View {
    var onConfirm: (() -> Void)? = nil
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

                VStack(spacing: 12) {
                    Button("Enable DJ Mode") {
                        onConfirm?()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color("neonPurpleBackground"))
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 32)

                    Button("Not Yet") { dismiss() }
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.45))
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

