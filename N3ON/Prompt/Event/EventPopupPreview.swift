// EventPopupPreview.swift
// N3ON
//
// TODO: Replace with real event popup preview UI.

import SwiftUI

struct EventPopupPreview: View {
    @EnvironmentObject var draft: EventDraftViewModel

    var body: some View {
        VStack(spacing: 16) {
            Text(draft.eventName.isEmpty ? "Event Preview" : draft.eventName)
                .font(.title2.bold())
                .foregroundStyle(.white)

            if let image = draft.posterImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(12)
                    .padding(.horizontal)
            }

            Text(draft.eventDescription)
                .foregroundStyle(.white.opacity(0.8))
                .padding(.horizontal)

            Spacer()
        }
        .padding(.top, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("neonPurpleBackground").ignoresSafeArea())
    }
}
