//
//  DJValidationChecklist.swift
//  N3ON
//
// Shows lineup tally status for the host DJ during event creation.
// Driven by EventDraftViewModel.currentTally / requiredTally — both are
// updated in real-time by the AsyncSequence observer in EventDraftViewModel.

import SwiftUI

struct DJValidationChecklist: View {
    @EnvironmentObject var draft: EventDraftViewModel

    @State private var glowPulse = false

    private var tallyMet: Bool { draft.tallyMet }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            checklistRow(
                text: "Tally reached (\(draft.currentTally) / \(draft.requiredTally) coins)",
                satisfied: tallyMet
            )
            checklistRow(
                text: "Invite DJs via the Limbo stage",
                satisfied: draft.currentTally > 0
            )
        }
        .padding()
        .background(Color.black.opacity(0.7))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                // DESIGN §3.2 — single neon accent; neonPurpleBackground when valid, dim white when not
                .stroke(
                    tallyMet ? Color("neonPurpleBackground") : Color.white.opacity(0.2),
                    lineWidth: 2
                )
                .shadow(
                    color: tallyMet ? Color("neonPurpleBackground") : .clear,
                    radius: glowPulse && tallyMet ? 10 : 5
                )
                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: glowPulse)
        )
        .onAppear { glowPulse = tallyMet }
        .onChangeCompat(of: tallyMet) { _, isValid in glowPulse = isValid }
    }

    private func checklistRow(text: String, satisfied: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: satisfied ? "checkmark.circle.fill" : "xmark.octagon.fill")
                // DESIGN §3.2 — neon accent for satisfied; disabled opacity for not satisfied
                .foregroundStyle(satisfied ? Color("neonPurpleBackground") : Color.white.opacity(0.3))
                .shadow(color: satisfied ? Color("neonPurpleBackground") : .clear, radius: 5)
            Text(text)
                .foregroundStyle(.white)
                .font(.subheadline.bold())
        }
    }
}
