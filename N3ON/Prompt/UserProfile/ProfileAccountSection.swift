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
}
