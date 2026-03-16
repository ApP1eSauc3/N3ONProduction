// RegularUserSection.swift
// N3ON
//

import SwiftUI
import Amplify
import CoreImage.CIFilterBuiltins

enum QRCodeGenerator {
    static func generate(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        guard let data = string.data(using: .utf8) else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        guard
            let outputImage = filter.outputImage,
            let cgImage = context.createCGImage(
                outputImage,
                from: outputImage.extent
            )
        else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

struct RegularUserSection: View {
    @State private var permanentQR: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("My Tickets").font(.headline).foregroundColor(.white)

            RoundedRectangle(cornerRadius: 12)
                .fill(Color("darkGray"))
                .frame(height: 120)
                .overlay(
                    Text("Purchased tickets & QR codes")
                        .foregroundColor(.white.opacity(0.6))
                )

            Text("My Profile QR")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))

            HStack(spacing: 16) {
                if let qr = permanentQR {
                    Image(uiImage: qr)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .background(Color.white)
                        .cornerRadius(10)
                } else {
                    Text("Generating...")
                        .foregroundColor(.white.opacity(0.5))
                }
                Spacer()
            }
            .padding(.top, 6)
        }
        .task {
            await loadQRCode()
        }
    }

    private func loadQRCode() async {
        let userID = await AuthService.currentUserIdOrNil() ?? "unknown-user"
        let qr = await Task.detached(priority: .userInitiated) {
            QRCodeGenerator.generate(from: userID)
        }.value
        await MainActor.run { permanentQR = qr }
    }
}

struct DJSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DJ Tools").font(.headline).foregroundColor(.white)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                tool("Find Venues", "map")
                tool("Manage Events", "calendar")
                tool("Find DJs", "magnifyingglass")
                tool("Post Media", "square.and.arrow.up")
            }
        }
    }

    private func tool(_ title: String, _ system: String) -> some View {
        Button { /* TODO: wire to NavigationPath */ } label: {
            HStack {
                Image(systemName: system)
                Text(title)
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(Color("darkGray"))
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
}

struct VenueSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Venue Tools").font(.headline).foregroundColor(.white)

            VStack(spacing: 12) {
                row("My Venue Profile", "building.2")
                row("Compliance", "doc.text.magnifyingglass")
                row("Event Requests", "tray.full")
            }
        }
    }

    private func row(_ title: String, _ system: String) -> some View {
        Button { /* TODO: wire to NavigationPath */ } label: {
            HStack {
                Image(systemName: system)
                Text(title)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(12)
            .background(Color("darkGray"))
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
}
