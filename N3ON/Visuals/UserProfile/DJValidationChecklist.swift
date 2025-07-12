//
//  DJValidationChecklist.swift
//  N3ON
//
//  Created by liam howe on 12/7/2025.
//

import SwiftUI

struct DJValidationChecklist: View {
    @EnvironmentObject var draft: EventDraftViewModel

    @State private var glowPulse = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            checklistRow(text: "1 Level 5 or 3 Level 4 DJs", satisfied: satisfiesCore)
            checklistRow(text: "At least 1 Level 3 DJ", satisfied: has1Level3)
        }
        .padding()
        .background(Color.black.opacity(0.7))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(satisfiesAll ? Color.neonGreen : Color.purple.opacity(0.6), lineWidth: 2)
                .shadow(color: satisfiesAll ? Color.neonGreen : Color.purple.opacity(0.5),
                        radius: glowPulse && satisfiesAll ? 10 : 5)
                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: glowPulse)
        )
        .onAppear {
            glowPulse = satisfiesAll
        }
        .onChange(of: satisfiesAll) { isValid in
            glowPulse = isValid
        }
    }

    func checklistRow(text: String, satisfied: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: satisfied ? "checkmark.circle.fill" : "xmark.octagon.fill")
                .foregroundColor(satisfied ? .neonGreen : .neonRed)
                .shadow(color: satisfied ? .neonGreen : .neonRed, radius: 5)
            Text(text)
                .foregroundColor(.white)
                .font(.subheadline.bold())
        }
    }

    var rankCounts: [Int: Int] {
        Dictionary(grouping: draft.invitedDJs, by: \.rank).mapValues(\.count)
    }

    var satisfiesCore: Bool {
        (rankCounts[5] ?? 0) >= 1 || (rankCounts[4] ?? 0) >= 3
    }

    var has1Level3: Bool {
        (rankCounts[3] ?? 0) >= 1
    }

    var satisfiesAll: Bool {
        satisfiesCore && has1Level3
    }
}

extension Color {
    static let neonGreen = Color(red: 0.0, green: 1.0, blue: 0.5)
    static let neonRed = Color(red: 1.0, green: 0.2, blue: 0.3)
}
