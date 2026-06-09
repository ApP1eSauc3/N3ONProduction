// RoleSelectionView.swift
// N3ON — Prompt layer
// Shown once after email confirmation. The user picks their role — Regular (fan)
// or DJ. Venue is admin-assigned, not self-selected. The choice is stored via
// AuthViewModel.completeRoleSelection and applied to the User DataStore record on first sign-in.
//
// Design pattern: Dice and RA both use a single-screen role/interest picker immediately
// after account creation, before the user signs in for the first time. Heavy imagery,
// minimal copy, one CTA per option.

import SwiftUI

struct RoleSelectionView: View {
    let username: String
    @EnvironmentObject private var vm: AuthViewModel

    @State private var selected: AppRole? = nil

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                Color.black.ignoresSafeArea()

                // Neon bloom behind the header — same pattern as ConfirmationSignupView
                RadialGradient(
                    colors: [Color("neonPurpleBackground").opacity(0.35), .clear],
                    center: .init(x: 0.5, y: 0.0),
                    startRadius: 0,
                    endRadius: geo.size.width * 0.9
                )
                .frame(height: geo.size.height * 0.40)
                .ignoresSafeArea(edges: .top)

                VStack(spacing: 0) {
                    headerSection
                        .padding(.top, geo.size.height * 0.10)
                        .padding(.bottom, 40)

                    // DESIGN §3.5 neon dock line
                    Rectangle()
                        .fill(LinearGradient(
                            colors: [.clear, Color("neonPurpleBackground"),
                                     Color("neonPurpleBackground"), .clear],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(height: 1.5)
                        .shadow(color: Color("neonPurpleBackground"), radius: 10, y: 4)
                        .shadow(color: Color("neonPurpleBackground").opacity(0.3), radius: 4, y: 2)

                    VStack(spacing: 16) {
                        roleCard(
                            role: .regular,
                            icon: "waveform",
                            title: "I'm here for the music",
                            subtitle: "Discover events, buy tickets, and follow DJs near you."
                        )

                        roleCard(
                            role: .dj,
                            icon: "headphones",
                            title: "I'm a DJ",
                            subtitle: "Build your profile, get endorsed, and host events."
                        )

                        continueButton
                            .padding(.top, 8)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 32)

                    Spacer()
                }
            }
        }
    }

    // MARK: — Header

    private var headerSection: some View {
        VStack(spacing: 10) {
            Text("N3ON")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: Color("neonPurpleBackground").opacity(0.55), radius: 18)
                .shadow(color: Color("neonPurpleBackground").opacity(0.85), radius: 5)

            Text("How do you want to use the app?")
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text("You can always change this later in your profile.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.4))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: — Role card

    private func roleCard(role: AppRole, icon: String, title: String, subtitle: String) -> some View {
        let isSelected = selected == role
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                selected = role
            }
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isSelected
                              ? Color("neonPurpleBackground").opacity(0.2)
                              : Color.white.opacity(0.06))
                        .frame(width: 52, height: 52)
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(isSelected
                                         ? Color("neonPurpleBackground")
                                         : .white.opacity(0.5))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? Color("neonPurpleBackground") : .white.opacity(0.2))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(isSelected ? 0.06 : 0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(
                                isSelected ? Color("neonPurpleBackground").opacity(0.5) : Color.clear,
                                lineWidth: 1
                            )
                    )
            )
            .shadow(
                color: Color("neonPurpleBackground").opacity(isSelected ? 0.25 : 0),
                radius: 12
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

    // MARK: — Continue button

    private var continueButton: some View {
        Button {
            guard let role = selected else { return }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            vm.completeRoleSelection(username: username, isDJ: role == .dj)
        } label: {
            Text("Continue")
                .font(.headline)
                .foregroundStyle(selected != nil ? .white : .white.opacity(0.3))
                .frame(maxWidth: .infinity, minHeight: 50)
        }
        .background(
            selected != nil
                ? AnyShapeStyle(Color("neonPurpleBackground"))
                : AnyShapeStyle(Color.white.opacity(0.08))
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: Color("neonPurpleBackground").opacity(selected != nil ? 0.55 : 0), radius: 18)
        .shadow(color: Color("neonPurpleBackground").opacity(selected != nil ? 0.85 : 0), radius: 5)
        .disabled(selected == nil)
    }
}
