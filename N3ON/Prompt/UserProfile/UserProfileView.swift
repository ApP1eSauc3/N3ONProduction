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
    @State private var modeSwitchScale: CGFloat = 1.0

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack(alignment: .top) {
                    Color("neonPurpleBackground").ignoresSafeArea()

                    LinearGradient(
                        colors: [Color("neonPurpleBackground").opacity(0.9), Color("dullPurple")],
                        startPoint: .top, endPoint: .bottom
                    )
                    .frame(height: 320)
                    .ignoresSafeArea(edges: .top)
                    .zIndex(0)

                    VStack {
                        Spacer()
                        Color.black
                            .frame(height: geometry.size.height * 0.6)
                            .cornerRadius(20, corners: [.topLeft, .topRight])
                    }
                    .ignoresSafeArea(edges: .bottom)
                    .zIndex(0)

                    ScrollView {
                        VStack(spacing: 0) {
                            header
                                .frame(height: 300)
                                .padding(.bottom, 20)

                            VStack(spacing: 20) {
                                RoleContainer(roles: vm.roles, isDJMode: vm.isDJMode) {
                                    RegularUserSection()
                                } dj: {
                                    DJSection()
                                } venue: {
                                    VenueSection()
                                }

                                activity
                            }
                            .background(Color.black)
                            .cornerRadius(20, corners: [.topLeft, .topRight])
                            .offset(y: -60)
                            .padding(.bottom, 80)
                        }
                    }
                    .zIndex(1)
                }
            }
            .task { await vm.load() }
            .navigationBarHidden(true)
            .photosPicker(
                isPresented: $showImagePicker,
                selection: $pickerItem,
                matching: .images
            )
            .onChangeCompat(of: pickerItem) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await vm.uploadAvatar(image: image)
                    }
                }
            }
            .sheet(isPresented: $showBecomeDJSheet) {
                BecomeDJSheet()
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 14) {
            ZStack(alignment: .bottomTrailing) {
                // Avatar — tap to change photo, long-press to switch role
                PulsingAvatarView(state: vm.avatarState, audioKey: nil, size: 120, fromMemoryCache: true)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: vm.isDJMode
                                        ? [Color("neonPurpleBackground"), .cyan]
                                        : [.white, Color("neonPurpleBackground")],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .padding(2)
                            .shadow(color: Color("neonPurpleBackground"), radius: vm.isDJMode ? 12 : 6)
                    )
                    .scaleEffect(modeSwitchScale)
                    .onTapGesture { showImagePicker.toggle() }
                    .onLongPressGesture(minimumDuration: 0.5) {
                        handleRoleSwitch()
                    }

                // Camera badge (tap)
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
                    .offset(x: -8, y: -8)
                    .allowsHitTesting(false) // tap handled by parent
            }
            .padding(.top, 15)

            Text(vm.username)
                .font(.system(.title2, design: .rounded))
                .fontWeight(.semibold)
                .foregroundStyle(.white)

            // Mode pill — shows current mode, hints at long-press
            modeIndicator

            HStack(spacing: 24) {
                StatItem(value: vm.followers, label: "Followers")
                Divider().frame(height: 40).overlay(Color.white.opacity(0.5))
                StatItem(value: vm.following, label: "Following")
            }
        }
    }

    @ViewBuilder
    private var modeIndicator: some View {
        if vm.isSwitching {
            ProgressView()
                .tint(.white)
                .scaleEffect(0.8)
        } else {
            let isDJ = vm.isDJMode
            HStack(spacing: 6) {
                Image(systemName: isDJ ? "headphones" : "person.fill")
                    .font(.caption2)
                Text(isDJ ? "DJ Mode" : "Fan Mode")
                    .font(.caption.bold())
            }
            .foregroundStyle(isDJ ? Color.cyan : Color.white.opacity(0.7))
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(isDJ
                          ? Color.cyan.opacity(0.15)
                          : Color.white.opacity(0.08))
                    .overlay(Capsule().stroke(
                        isDJ ? Color.cyan.opacity(0.4) : Color.white.opacity(0.15),
                        lineWidth: 1))
            )
            .animation(.easeInOut(duration: 0.25), value: isDJ)
        }
    }

    // MARK: - Activity

    private var activity: some View {
        VStack(spacing: 16) {
            Text("Activity Feed")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            RoundedRectangle(cornerRadius: 12)
                .fill(Color.customDarkGray.opacity(0.9))
                .frame(minHeight: 300)
                .overlay(
                    Text("Content Placeholder").foregroundStyle(.white.opacity(0.5))
                )
                .padding(.horizontal)
        }
        .padding(.bottom, 10)
    }

    // MARK: - Role switch logic

    private func handleRoleSwitch() {
        if vm.roles.contains(.dj) {
            // User has DJ role — toggle mode with haptic
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()

            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                modeSwitchScale = 1.12
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    modeSwitchScale = 1.0
                }
            }
            Task { await vm.toggleDJMode() }
        } else {
            // Not a DJ yet — show upgrade path
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            showBecomeDJSheet = true
        }
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
