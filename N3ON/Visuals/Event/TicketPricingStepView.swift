//
//  TicketPricingStepView.swift
//  N3ON
//
//  Created by liam howe on 12/7/2025.
//

import SwiftUI
import PhotosUI
import Amplify

struct TicketPricingStepView: View {
    @EnvironmentObject var draft: EventDraftViewModel
    @State private var posterItem: PhotosPickerItem? = nil
    @State private var posterImage: Image? = nil
    @State private var showRankAlert: Bool = false
    @State private var showEndorseRequestSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Set Ticket Price").font(.title2.bold())

                Slider(value: $draft.ticketPrice, in: 0...100, step: 1) {
                    Text("Price")
                }
                Text("$\(Int(draft.ticketPrice)) per ticket")
                    .font(.headline)

                Divider()

                Text("Choose your profit share").font(.title2.bold())

                Slider(value: $draft.djSharePercent, in: 10...90, step: 5) {
                    Text("Share")
                }
                Text("DJ Share: \(Int(draft.djSharePercent))%")
                    .font(.headline)

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Estimated Total Revenue: $\(draft.estimatedEarnings.total, specifier: "%.2f")")
                    Text("Your Estimated Earnings: $\(draft.estimatedEarnings.djCut, specifier: "%.2f")")
                        .foregroundColor(.purple)
                }
                .font(.subheadline)

                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Upload Poster")
                        .font(.title2.bold())

                    if let posterImage = posterImage {
                        posterImage
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .cornerRadius(12)
                    } else if let posterKey = draft.posterKey,
                              let url = URL(string: "https://your-cdn-url.com/\(posterKey)") {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image.resizable().scaledToFit().frame(height: 200).cornerRadius(12)
                            case .failure:
                                Image(systemName: "photo.fill").frame(height: 200)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                            .frame(height: 200)
                            .overlay(Text("Tap to upload poster").foregroundColor(.gray))
                    }

                    PhotosPicker(selection: $posterItem, matching: .images, photoLibrary: .shared()) {
                        Text("Choose Poster Image")
                            .padding()
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(8)
                    }
                }

                Button("Submit Event") {
                    Task {
                        let eligible = await draft.verifyEligibility()
                        if eligible {
                            await draft.uploadPosterAndSaveEvent()
                        } else {
                            showRankAlert = true
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 24)
                .alert("Insufficient DJ Rank", isPresented: $showRankAlert) {
                    Button("Request Endorsement") {
                        showEndorseRequestSheet = true
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("You must be a level 5 DJ (5 martini glasses) or meet collaboration requirements to create an event.")
                }
            }
            .padding()
        }
        .onChange(of: posterItem) { newItem in
            guard let item = newItem else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        self.posterImage = Image(uiImage: uiImage)
                        draft.posterData = data
                    }
                }
            }
        }
        .sheet(isPresented: $showEndorseRequestSheet) {
            EndorsementRequestSheet()
        }
    }
}

struct EndorsementRequestSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var message = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Request Endorsement")
                    .font(.title)

                Text("Enter a message to explain why you'd like to be endorsed by a Level 5 DJ.")
                    .font(.subheadline)

                TextEditor(text: $message)
                    .frame(height: 150)
                    .padding()
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.4)))

                Button("Send Request") {
                    // TODO: Save endorsement request to backend
                    print("📨 Sent endorsement request: \(message)")
                    dismiss()
                }
                .buttonStyle(.borderedProminent)

                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
