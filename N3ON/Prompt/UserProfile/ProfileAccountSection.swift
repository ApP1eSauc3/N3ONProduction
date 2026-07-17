// ProfileAccountSection.swift
// N3ON
//
// Sign Out / Delete Account rows shown at the bottom of the profile screen.
// Extracted from UserProfileView so it's its own render-identity rather than
// a computed property re-evaluated as part of the parent body.

import SwiftUI

struct ProfileAccountSection: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @Binding var showDeleteConfirm: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Muted bar distinguishes utility rows from feature zones
            ProfileSectionHeader(title: "Account", barColor: .white.opacity(0.3))

            // Sign Out
            Button {
                Task { await authVM.signOut() }
            } label: {
                ProfileRowLabel(icon: "arrow.right.square", title: "Sign Out")
            }
            .frame(minHeight: 44)           // HIG minimum tap target
            .contentShape(Rectangle())

            // Delete Account — visually subdued until confirmed
            Button {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred() // DESIGN §4 destructive haptic
                showDeleteConfirm = true
            } label: {
                ProfileRowLabel(icon: "trash", title: "Delete Account", textOpacity: 0.5)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
            .disabled(authVM.isLoading)
        }
        .padding(.horizontal, 16) // DESIGN §2.4 — standard 16pt horizontal margin
    }
}
