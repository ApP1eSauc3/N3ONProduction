// TicketDetailView.swift
// N3ON — Prompt layer
// Full-screen ticket view shown when a user taps a ticket in their wallet.
// The QR code is permanently tied to the user's account ID — same code for every event.
// The doorman scans this QR with their phone and their app checks whether the scanned
// userID holds a valid ticket for the event being checked in.

import SwiftUI

struct TicketDetailView: View {
    let ticket: Ticket
    let eventName: String
    let userID: String

    @Environment(\.dismiss) private var dismiss
    @State private var qrImage: UIImage? = nil
    @State private var showFullScreenQR = false

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE d MMM yyyy"
        return f
    }()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        eventHeader
                        qrSection
                        ticketMeta
                        instructions
                        Spacer(minLength: 32)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                }
            }
            .navigationTitle("Your Ticket")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color("neonPurpleBackground"))
                }
            }
            .task {
                qrImage = QRCodeGenerator.make(from: userID, size: 280)
            }
            .sheet(isPresented: $showFullScreenQR) {
                FullScreenQRView(qrImage: qrImage, userID: userID)
            }
        }
    }

    // MARK: — Event header

    private var eventHeader: some View {
        VStack(spacing: 8) {
            Text(eventName)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            HStack(spacing: 8) {
                Image(systemName: "ticket.fill")
                    .foregroundStyle(Color("neonPurpleBackground"))
                    .font(.caption)
                Text("× \(ticket.quantity)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: — QR section

    private var qrSection: some View {
        VStack(spacing: 16) {
            Text("SCAN AT DOOR")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color("neonPurpleBackground"))
                .tracking(1.5)

            if let qr = qrImage {
                Button {
                    showFullScreenQR = true
                } label: {
                    VStack(spacing: 12) {
                        Image(uiImage: qr)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.caption2)
                            Text("Tap to expand")
                                .font(.caption2)
                        }
                        .foregroundStyle(.white.opacity(0.35))
                    }
                }
                .buttonStyle(.plain)
            } else {
                ProgressView().tint(Color("neonPurpleBackground"))
                    .frame(width: 200, height: 200)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        // Neon glow on QR card — signals this is the admission credential
        .shadow(color: Color("neonPurpleBackground").opacity(0.2), radius: 20)
    }

    // MARK: — Ticket meta

    private var ticketMeta: some View {
        VStack(spacing: 0) {
            metaRow(
                label: "Purchased",
                value: Self.dateFormatter.string(from: ticket.purchaseTime.foundationDate)
            )
            Divider().background(Color.white.opacity(0.06))
            metaRow(label: "Ticket ID", value: String(ticket.id.prefix(8)).uppercased())
            Divider().background(Color.white.opacity(0.06))
            metaRow(label: "Quantity", value: "\(ticket.quantity)")
        }
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func metaRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: — Instructions

    private var instructions: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle")
                .foregroundStyle(Color("neonPurpleBackground"))
                .font(.subheadline)
            Text("Show this QR code to the doorman at the event entrance. Your code is linked to your N3ON account — do not share it.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.4))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: — Full-screen QR (max brightness for scanning in dark venues)

private struct FullScreenQRView: View {
    let qrImage: UIImage?
    let userID: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                if let qr = qrImage {
                    Image(uiImage: qr)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .padding(32)
                } else {
                    ProgressView().tint(.white)
                }

                Text("Show this to the doorman")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .onAppear {
            UIScreen.main.brightness = 1.0
        }
        .onDisappear {
            UIScreen.main.brightness = UIScreen.main.brightness
        }
        .onTapGesture { dismiss() }
    }
}
