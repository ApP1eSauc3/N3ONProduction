// ProfileHeaderView.swift
// N3ON
//
// Avatar, username, mode pill, DJ preview shortcut, and follower stats for
// the profile screen header zone. Extracted from UserProfileView so the
// header is its own render-identity rather than a computed property
// re-evaluated as part of the parent body.

import SwiftUI

struct ProfileHeaderView: View {
    @ObservedObject var vm: RoleAwareProfileViewModel
    @Binding var showImagePicker: Bool
    @Binding var showDJProfilePreview: Bool
    @Binding var showRoleSwitchConfirm: Bool
    @Binding var showBecomeDJSheet: Bool

    var body: some View {
        // DESIGN §5.1 header VStack spacing — 24pt (space6). Change here for tighter/looser header.
        VStack(spacing: 24) {

            // DESIGN §3.4 — ring and glow live inside PulsingAvatarView; no overlay needed here.
            // Container frame is size+20 = 130pt; PulsingAvatarView manages its own ring at size+4.
            ZStack(alignment: .bottomTrailing) {
                PulsingAvatarView(state: vm.avatarState, audioKey: nil, size: 110)
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
