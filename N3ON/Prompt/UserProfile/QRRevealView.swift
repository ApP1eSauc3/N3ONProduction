// QRRevealView.swift
// N3ON
//
// Full-screen QR code reveal, pulled up from the profile screen scroll view.

import SwiftUI

struct QRRevealView: View {
    let qrImage: UIImage
    let username: String
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.97).ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button { onDismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white.opacity(0.65))
                    }
                    .padding(.horizontal)
                    .padding(.top, 56)
                }

                Spacer()

                VStack(spacing: 20) {
                    Text(username)
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)

                    Image(uiImage: qrImage)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .padding(24)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .padding(.horizontal, 32)
                        .shadow(color: Color("neonPurpleBackground").opacity(0.5), radius: 20)

                    Text("Swipe up or tap × to close")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.3))
                }

                Spacer()
            }
        }
        .gesture(
            DragGesture().onEnded { v in
                if v.translation.height < -60 { onDismiss() }
            }
        )
    }
}
