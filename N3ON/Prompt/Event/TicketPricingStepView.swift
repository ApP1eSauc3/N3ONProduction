// TicketPricingStepView.swift
// N3ON — Prompt layer
// Stage 3: set ticket price, preview revenue split, upload poster, go live.
// "Go Live" is disabled until a poster is selected. The upload + status
// transition to "live" are both handled in EventDraftViewModel.uploadPosterAndGoLive(_:).

import SwiftUI
import PhotosUI

struct TicketPricingStepView: View {
    @EnvironmentObject var draft: EventDraftViewModel
    @State private var posterItem: PhotosPickerItem?
    @State private var pendingImage: UIImage?
    @State private var showPreview = false

    private var canGoLive: Bool {
        pendingImage != nil && !draft.isUploadingPoster
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                pricingSection
                posterSection
                errorLabel
                previewButton
                goLiveButton
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .sheet(isPresented: $showPreview) {
            EventPopupPreview()
                .environmentObject(draft)
        }
        .onChangeCompat(of: posterItem) { _, newItem in
            Task {
                guard let item = newItem,
                      let data = try? await item.loadTransferable(type: Data.self),
                      let uiImage = UIImage(data: data) else { return }
                pendingImage = uiImage
            }
        }
    }

    // MARK: — Pricing

    private var pricingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionLabel("TICKET PRICE")
            VStack(spacing: 8) {
                HStack {
                    Text("$\(Int(draft.ticketPrice))")
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Text("per ticket")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                }
                Slider(value: $draft.ticketPrice, in: 0...200, step: 5)
                    .tint(Color("neonPurpleBackground"))
            }
            .padding(16)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            if draft.hostDJRank == 5 {
                profitShareSection
            }

            revenueCard
        }
    }

    private var profitShareSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("YOUR PROFIT SHARE")
            HStack {
                Text("\(Int(draft.djSharePercentage))%")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(Color("neonPurpleBackground"))
                Spacer()
                Text("of DJ pool")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
            }
            Slider(value: $draft.djSharePercentage, in: 0...100, step: 5)
                .tint(Color("neonPurpleBackground"))
        }
        .padding(16)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var revenueCard: some View {
        let rb = draft.revenueBreakdown
        return VStack(spacing: 12) {
            revenueRow("Est. total revenue", "$\(Int(rb.totalRevenue))", highlight: false)
            revenueRow("Venue cut (40%)",    "$\(Int(rb.venueRevenue))", highlight: false)
            Divider().background(Color.white.opacity(0.1))
            revenueRow("Your earnings",      "$\(Int(rb.hostDJRevenue))", highlight: true)
        }
        .padding(16)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func revenueRow(_ label: String, _ value: String, highlight: Bool) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(highlight ? .white : .white.opacity(0.5))
            Spacer()
            Text(value)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(highlight ? Color("neonPurpleBackground") : .white.opacity(0.5))
        }
    }

    // MARK: — Poster

    private var posterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                sectionLabel("EVENT POSTER")
                Text("Required before going live")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.3))
            }

            if let image = pendingImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                PhotosPicker(selection: $posterItem, matching: .images) {
                    Text("Change poster")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                }
            } else {
                PhotosPicker(selection: $posterItem, matching: .images) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                        .frame(height: 220)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.system(size: 32))
                                    .foregroundStyle(Color("neonPurpleBackground").opacity(0.6))
                                Text("Tap to choose poster")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.3))
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: — Error

    @ViewBuilder private var errorLabel: some View {
        if let error = draft.posterUploadError {
            Text(error)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    // MARK: — Preview button

    private var previewButton: some View {
        Button {
            showPreview = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "eye")
                Text("Preview as attendee")
                    .font(.subheadline)
            }
            .foregroundStyle(Color("neonPurpleBackground"))
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(Color("neonPurpleBackground").opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    // MARK: — Go Live button

    private var goLiveButton: some View {
        Button {
            guard let image = pendingImage else { return }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            Task { await draft.uploadPosterAndGoLive(image) }
        } label: {
            if draft.isUploadingPoster {
                HStack(spacing: 8) {
                    ProgressView().tint(.white)
                    Text("Going live...")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.7))
                }
            } else {
                Text("Go Live")
                    .font(.headline)
                    .foregroundStyle(canGoLive ? .white : .white.opacity(0.3))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 50)
        .background(
            canGoLive
                ? AnyShapeStyle(Color("neonPurpleBackground"))
                : AnyShapeStyle(Color.white.opacity(0.08))
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: Color("neonPurpleBackground").opacity(canGoLive ? 0.55 : 0), radius: 18)
        .shadow(color: Color("neonPurpleBackground").opacity(canGoLive ? 0.85 : 0), radius: 5)
        .disabled(!canGoLive)
    }

    // MARK: — Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color("neonPurpleBackground"))
            .tracking(1.5)
    }
}
