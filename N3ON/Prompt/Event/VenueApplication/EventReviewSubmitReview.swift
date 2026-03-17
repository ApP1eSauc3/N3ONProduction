//
//  EventReviewSubmitReview.swift
//  N3ON
//
//  Created by liam howe on 12/7/2025.
//

import SwiftUI

struct EventReviewSubmitReview: View {
    @EnvironmentObject var draft: EventDraftViewModel
    
    @State private var showConfirmation = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("review & Submit selection")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            // Group is ambiguous in Swift 6 (inferred as Table row group) — use VStack
            VStack(spacing: 8) {
                HStack {
                    Text("📍 Venue:")
                    Spacer()
                    Text(draft.venue?.name ?? "Not selected")
                }
                HStack {
                    Text("📦 Package:")
                    Spacer()
                    Text(draft.package.rawValue.capitalized)
                }
                HStack {
                    Text("📅 Date:")
                    Spacer()
                    DatePicker("", selection: $draft.eventDate, displayedComponents: .date)
                        .labelsHidden()
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("🎛 DJs:")
                    ForEach(draft.invitedDJUsernames, id: \.self) { dj in
                        Text("- \(dj)")
                    }
                }
                if let vj = draft.vjUsername {
                    HStack {
                        Text("🎥 VJ:")
                        Spacer()
                        Text(vj)
                    }
                }
                if !draft.specialRequest.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("📝 Special Requests:")
                        Text(draft.specialRequest)
                            .italic()
                    }
                }
            }
            .foregroundColor(.white)
            
            Spacer()
            
            Button(action: {
                if draft.isReadyToSubmit() {
                    showConfirmation = true
                }
            }){
                Text("Submit Event")
                    .bold()
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(!draft.isReadyToSubmit())
            .opacity(draft.isReadyToSubmit() ? 1 : 0.5)
            .alert("Event Submitted!", isPresented: $showConfirmation) {
                Button("OK", role: .cancel) { }
            }
        }
        .padding()
        .background(Color("neonPurpleBackground"))
    }
}


#Preview {
    EventReviewSubmitReview()
        .environmentObject(EventDraftViewModel())

}
