// QRRevealView.swift
// N3ON
//
// Full-screen QR code reveal, pulled up from the profile screen scroll view.

import SwiftUI

struct QRRevealView: View {
    let qrImage: UIImage
    let username: String
    let onDismiss: () -> Void

    /// Live vertical drag of the card (0 at rest). @GestureState: springs back
    /// by itself when the drag ends or is cancelled.
    @GestureState(resetTransaction: SwiftUI.Transaction(animation: Motion.gestureEnd))
    private var dragY: CGFloat = 0
    /// Flips on appear so the details settle in order after the overlay lands.
    @State private var settled = false

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
                        .staggeredAppear(index: 0, isVisible: settled)   // DESIGN §4 details settle in order

                    Image(uiImage: qrImage)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .padding(24)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .padding(.horizontal, 32)
                        .shadow(color: Color("neonPurpleBackground").opacity(0.5), radius: 20)
                        .staggeredAppear(index: 1, isVisible: settled)

                    Text("Swipe up or tap × to close")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.3))
                        .staggeredAppear(index: 2, isVisible: settled)
                }
                // Follows the finger 1:1 while held (no tween); pulling down,
                // the wrong way, is resisted by a rubber band.
                .offset(y: dragY)

                Spacer()
            }
        }
        .onAppear { settled = true }
        .gesture(
            DragGesture()
                .updating($dragY) { v, offset, _ in
                    offset = Motion.rubberBanded(v.translation.height, in: -.infinity...0, dimension: 120)
                }
                .onEnded { v in
                    // Not dismissed: dragY's reset springs the card back (DESIGN §4 gesture-end).
                    if v.translation.height < -60 || v.predictedEndTranslation.height < -200 {
                        onDismiss()
                    }
                }
        )
    }
}
