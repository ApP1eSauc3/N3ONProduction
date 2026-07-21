// BecomeDJSheet.swift
// N3ON
//
// Onboarding sheet shown when a regular user taps "Fan" mode to learn about
// becoming a DJ. Presented from UserProfileView.

import SwiftUI

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
