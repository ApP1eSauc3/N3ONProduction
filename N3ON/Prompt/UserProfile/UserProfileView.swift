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
                ProfileHeaderView(
                    vm: vm,
                    showImagePicker: $showImagePicker,
                    showDJProfilePreview: $showDJProfilePreview,
                    showRoleSwitchConfirm: $showRoleSwitchConfirm,
                    showBecomeDJSheet: $showBecomeDJSheet
                )
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

                            if vm.isAdmin { ProfileAdminSection() }

                            ProfileAccountSection(showDeleteConfirm: $showDeleteConfirm)
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

