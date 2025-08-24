//
//  RegularUserSection.swift
//  N3ON
//
//  Created by liam howe on 23/8/2025.
//

import SwiftUI
import Amplify
import CoreImage.CIFilterBuiltins

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
                        .onAppear {
                            let text = AuthService.currentUserId ?? "unknown-user"
                            permanentQR = QRCodeGenerator.generate(from: text)
                        }
                }
                Spacer()
            }
            .padding(.top, 6)
        }
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
        Button { /* navigate */ } label: {
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
        Button { /* navigate */ } label: {
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
