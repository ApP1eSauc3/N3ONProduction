// TicketScannerView.swift
// N3ON — Prompt layer
// Doorman-facing QR scanner. The doorman selects which event they're checking in,
// then scans the attendee's QR code (which encodes the attendee's userID).
// AccessControlService checks whether that userID has a valid ticket for the event.
//
// Pattern: Eventbrite's Organizer app and Dice's check-in tool both follow this
// two-step flow — select event → open camera — so doormen never accidentally
// validate tickets for the wrong event.

import SwiftUI
import AVFoundation

struct TicketScannerView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var upcomingEvents: [Event] = []
    @State private var selectedEvent: Event?
    @State private var isLoadingEvents = true
    @State private var scanResult: ScanResult?
    @State private var isScanning = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if isLoadingEvents {
                    ProgressView().tint(Color("neonPurpleBackground"))
                } else if upcomingEvents.isEmpty {
                    emptyState
                } else if selectedEvent == nil {
                    eventPicker
                } else {
                    scannerContent
                }
            }
            .navigationTitle("Scan Tickets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color("neonPurpleBackground"))
                }
                if selectedEvent != nil {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Switch Event") {
                            selectedEvent = nil
                            scanResult = nil
                        }
                        .foregroundStyle(.white.opacity(0.6))
                        .font(.caption)
                    }
                }
            }
            .task { await loadEvents() }
        }
    }

    // MARK: — Empty state

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 44))
                .foregroundStyle(.white.opacity(0.2))
            Text("No upcoming events")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.5))
            Text("Events at your venue appear here once approved.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.3))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    // MARK: — Event picker

    private var eventPicker: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                Text("SELECT EVENT TO CHECK IN")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("neonPurpleBackground"))
                    .tracking(1.5)
                    .padding(.horizontal, 16)

                ForEach(upcomingEvents) { event in
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        selectedEvent = event
                    } label: {
                        HStack(spacing: 14) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(event.eventName)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                Text(event.eventDate.foundationDate.formatted(
                                    date: .abbreviated, time: .shortened
                                ))
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.5))
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.3))
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 16)
        }
    }

    // MARK: — Scanner content

    private var scannerContent: some View {
        VStack(spacing: 0) {
            if let event = selectedEvent {
                // Active event banner
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color("neonPurpleBackground"))
                        .font(.caption)
                    Text("Checking in: \(event.eventName)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.04))
            }

            ZStack {
                // Camera preview
                QRScannerRepresentable(
                    isScanning: $isScanning,
                    onCodeScanned: { code in
                        guard !isScanning else { return }
                        guard let event = selectedEvent else { return }
                        isScanning = true
                        Task { await validate(userID: code, eventID: event.id) }
                    }
                )
                .ignoresSafeArea()

                // Scan frame overlay
                scanFrame
            }
            .frame(maxHeight: .infinity)

            // Result banner
            if let result = scanResult {
                resultBanner(result)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private var scanFrame: some View {
        VStack {
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color("neonPurpleBackground"), lineWidth: 2)
                    .frame(width: 240, height: 240)
                    .shadow(color: Color("neonPurpleBackground").opacity(0.55), radius: 18)
                    .shadow(color: Color("neonPurpleBackground").opacity(0.85), radius: 5)

                Text("Point at attendee's QR code")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .offset(y: 140)
            }
            Spacer()
        }
    }

    private func resultBanner(_ result: ScanResult) -> some View {
        HStack(spacing: 14) {
            Image(systemName: result == .valid ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 28))
                .foregroundStyle(result == .valid ? Color("neonPurpleBackground") : .red)

            VStack(alignment: .leading, spacing: 2) {
                Text(result == .valid ? "Valid Ticket" : "No Valid Ticket")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(result == .valid
                     ? "Admit entry"
                     : "This person does not hold a ticket for this event.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            Button("Scan Next") {
                withAnimation(.easeInOut(duration: 0.25)) {
                    scanResult = nil
                    isScanning = false
                }
            }
            .font(.caption.bold())
            .foregroundStyle(Color("neonPurpleBackground"))
        }
        .padding(16)
        .background(Color.customDarkGray)
        .shadow(color: .black.opacity(0.4), radius: 12, y: -4)
    }

    // MARK: — Validation

    private func validate(userID: String, eventID: String) async {
        let isValid = await AccessControlService.validateTicket(userID: userID, eventID: eventID)
        UIImpactFeedbackGenerator(style: isValid ? .medium : .heavy).impactOccurred()
        withAnimation(.easeInOut(duration: 0.25)) {
            scanResult = isValid ? .valid : .invalid
        }
    }

    // MARK: — Data

    private func loadEvents() async {
        defer { isLoadingEvents = false }
        guard let ownerID = await AuthService.currentUserIdOrNil(),
              let venue = try? await VenueService.fetchOwned(by: ownerID).first
        else { return }
        upcomingEvents = (try? await VenueService.fetchUpcomingEvents(venueID: venue.id)) ?? []
    }

    // MARK: — Types

    private enum ScanResult { case valid, invalid }
}

// MARK: — AVFoundation camera representable

private struct QRScannerRepresentable: UIViewControllerRepresentable {
    @Binding var isScanning: Bool
    var onCodeScanned: (String) -> Void

    func makeUIViewController(context: Context) -> QRScannerViewController {
        let vc = QRScannerViewController()
        vc.onCodeScanned = onCodeScanned
        return vc
    }

    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}
}

private final class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onCodeScanned: ((String) -> Void)?

    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupSession()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { self.session.startRunning() }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if session.isRunning { session.stopRunning() }
    }

    private func setupSession() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return }
        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        view.layer.insertSublayer(layer, at: 0)
        previewLayer = layer
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput objects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let obj = objects.first as? AVMetadataMachineReadableCodeObject,
              let value = obj.stringValue
        else { return }
        onCodeScanned?(value)
    }
}
