//
//  EventCreationFlow.swift
//  N3ON
//
//  Created by liam howe on 12/7/2025.
//

import SwiftUI
import PhotosUI
import Amplify
import AVFoundation

struct EventCreationFlowView: View {
    @EnvironmentObject var draft: EventDraftViewModel
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var selectedUsername: String? = nil
    @State private var showingPreview = false

    var body: some View {
        VStack(spacing: 20) {
            EventPosterUploadView()
                .environmentObject(draft)

            if let image = draft.posterImage {
                Text("Preview").font(.headline)
                Image(uiImage: image)
                    .resizable().scaledToFit()
                    .frame(height: 200).cornerRadius(10)
            }

            pricingSection

            actionButtons
        }
        .padding()
        .sheet(isPresented: $showingPreview) {
            EventPopupPreview().environmentObject(draft)
        }
    }

    @ViewBuilder private var pricingSection: some View {
        let totalRevenue = draft.ticketPrice * draft.estimatedAttendance
        let venueShare = totalRevenue * 0.4
        let djPool = totalRevenue * 0.6
        let hostDJCut = draft.hostDJRank == 5 ? djPool * (draft.djSharePercentage / 100) : 0
        let djPayouts = draft.computePayouts(from: djPool - hostDJCut)

        VStack(spacing: 12) {
            Text("🎟 Ticket Pricing").font(.headline)
            Slider(value: $draft.ticketPrice, in: 0...100, step: 1)
            Text("\(Int(draft.ticketPrice)) coins")

            if draft.hostDJRank == 5 {
                Text("💰 DJ Profit Share (You control): \(Int(draft.djSharePercentage))%")
                Slider(value: $draft.djSharePercentage, in: 0...100, step: 1)
            }

            DatePicker("Event Time", selection: $draft.eventTime, displayedComponents: [.hourAndMinute])
                .labelsHidden().padding(.top)

            Text("Venue gets: \(Int(venueShare)) coins").foregroundColor(.purple)
            if draft.hostDJRank == 5 {
                Text("You earn: \(Int(hostDJCut)) coins").foregroundColor(.green)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("🎧 Invited DJs").font(.headline)
                ForEach(draft.invitedDJs, id: \.username) { dj in
                    DJPayoutRow(dj: dj, payout: djPayouts.first(where: { $0.username == dj.username }),
                                isSelected: selectedUsername == dj.username)
                        .onTapGesture { selectedUsername = dj.username }
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.1))
        .cornerRadius(12)
    }

    @ViewBuilder private var actionButtons: some View {
        HStack(spacing: 12) {
            Button("Preview Popup") { showingPreview = true }
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(10)

            Button("Submit Event") {
                if draft.posterKey == nil {
                    errorMessage = "Please upload a poster before submitting."
                    showingError = true
                } else if !draft.meetsRankRequirements() {
                    errorMessage = "Event must include at least one rank-5 DJ or three rank-4 DJs."
                    showingError = true
                } else {
                    Task { await draft.submitEvent() }
                }
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .alert("Cannot Submit Event", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
}

private struct DJPayoutRow: View {
    let dj: InvitedDJ
    let payout: DJPayout?
    let isSelected: Bool

    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 44, height: 44)
                    .overlay(Circle().stroke(Color.cyan, lineWidth: 1))
                    .shadow(color: Color.cyan.opacity(0.8), radius: 4)
                Text("\(dj.rank)").foregroundColor(.white).bold()
            }
            VStack(alignment: .leading) {
                Text(dj.username)
                Text("Rank \(dj.rank)").font(.caption).foregroundColor(.gray)
            }
            Spacer()
            if let p = payout {
                Text("\(p.coins) coins").foregroundColor(.green)
            }
        }
        .padding(8)
        .background(isSelected ? Color.cyan.opacity(0.15) : Color.clear)
        .cornerRadius(8)
    }
}//
