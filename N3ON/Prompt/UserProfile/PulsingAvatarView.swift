//
//  PulsingAvatarView.swift
//  N3ON
//

// MARK: - Design §3.4 — Avatar + glow ring spec
//
// Dimensions (all relative to `size` parameter):
//   Image clip:        size × size   (Circle clipShape)
//   Ring frame:        size + 4pt    (2pt gap outside clip — DO NOT add .overlay ring outside this view)
//   Ring lineWidth:    2pt           (all states)
//   Outer container:  size + 20pt   (anchors all glow shadows)
//   Bloom blur:        radius 12
//
// Size scale:
//   Own profile header   96pt    DJ card / map sheet  52pt
//   Chat thread header   40pt    Message bubble       36pt
//   Minimum              28pt
//
// Glow layers (applied to outer container as .shadow):
//   Outer bloom:  neonPurpleBackground opacity 0.20  radius 20
//   Inner core:   neonPurpleBackground opacity 0.55  radius 18
//
// Pulse animation (ring at size+4, expands outward):
//   Peak scale 1.35 · opacity 0.0 at peak · .easeOut(duration: 1.0).repeatForever(autoreverses: false)
//
// ❌ WRONG: .overlay(Circle().stroke(...).padding(n)) outside this view
//    .padding(n) insets the ring inside the clip boundary — ring follows image, not container.

import SwiftUI
import AVFoundation

struct PulsingAvatarView: View {
    let state: AvatarState          // DESIGN §3.4 — avatar image source (remote key or local UIImage)
    let audioKey: String?           // optional S3 key for profile audio clip
    let size: CGFloat               // DESIGN §3.4 — image diameter; ring = size+4; container = size+20
    let fromMemoryCache: Bool

    @State private var image: UIImage?
    @State private var player: AVAudioPlayer?
    @State private var isPulsing = false

    init(state: AvatarState, audioKey: String? = nil, size: CGFloat, fromMemoryCache: Bool = false) {
        self.state = state
        self.audioKey = audioKey
        self.size = size
        self.fromMemoryCache = fromMemoryCache
    }

    var body: some View {
        ZStack {
            // DESIGN §3.4 — bloom layer behind everything, never clipped
            Circle()
                .fill(Color("neonPurpleBackground").opacity(0.15))
                .frame(width: size + 20, height: size + 20)
                .blur(radius: 12)

            // DESIGN §3.4 — pulse ring anchored to container edge (size + 4), not image
            if isPulsing {
                Circle()
                    .stroke(Color("neonPurpleBackground").opacity(0.7), lineWidth: 2)
                    .frame(width: size + 4, height: size + 4)
                    .scaleEffect(isPulsing ? 1.35 : 1.0)    // DESIGN §3.4 pulse peak scale
                    .opacity(isPulsing ? 0.0 : 0.7)
                    .animation(
                        .easeOut(duration: 1.0).repeatForever(autoreverses: false), // DESIGN §3.4 1.0s
                        value: isPulsing
                    )
            }

            // DESIGN §3.4 — avatar image clipped to circle; ring sits OUTSIDE this clipShape
            Group {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "person")
                        .resizable()
                        .scaledToFit()
                        .padding(8)
                        .foregroundStyle(Color.white.opacity(0.5))
                        .background(Color.white.opacity(0.06))  // DESIGN §3.4 placeholder fill
                }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
            .onTapGesture(perform: handleTap)

            // DESIGN §3.4 — static ring stroke on container boundary (size + 4), outside clip
            Circle()
                .stroke(Color("neonPurpleBackground").opacity(0.55), lineWidth: 2)
                .frame(width: size + 4, height: size + 4)
        }
        .frame(width: size + 20, height: size + 20)                              // DESIGN §3.4 container anchors glow
        .shadow(color: Color("neonPurpleBackground").opacity(0.55), radius: 18)  // DESIGN §3.4 inner shadow
        .shadow(color: Color("neonPurpleBackground").opacity(0.20), radius: 20)  // DESIGN §3.4 outer bloom
        .task(id: taskID) {
            await loadContent()
        }
        .onDisappear {
            player?.stop()
            withAnimation { isPulsing = false }
        }
    }

    private var taskID: String {
        switch state {
        case .remote(let key): return key
        case .local: return "local"
        }
    }

    private func loadContent() async {
        await loadImage()
        guard !Task.isCancelled else { return }
        await loadAudioIfNeeded()
    }

    private func loadImage() async {
        switch state {
        case .remote(let avatarKey):
            guard let url = try? await StorageUploader.signedURL(for: avatarKey, access: .protected) else { return }
            guard !Task.isCancelled else { return }
            guard let (data, _) = try? await URLSession.shared.data(from: url) else { return }
            guard !Task.isCancelled else { return }
            image = UIImage(data: data)

        case .local(let uiImage):
            image = uiImage
        }
    }

    private func loadAudioIfNeeded() async {
        guard let audioKey = audioKey else { return }
        guard let url = try? await StorageUploader.signedURL(for: audioKey, access: .protected) else { return }
        guard !Task.isCancelled else { return }
        // Data(contentsOf:) is synchronous — it blocks a cooperative thread for
        // the full download. Use the async overload so the task yields.
        guard let (data, _) = try? await URLSession.shared.data(from: url) else { return }
        guard !Task.isCancelled else { return }
        do {
            let audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer.prepareToPlay()
            player = audioPlayer
        } catch {
            print("Audio init error: \(error)")
        }
    }

    private func handleTap() {
        guard let player = player else { return }
        if player.isPlaying {
            player.stop()
            withAnimation { isPulsing = false }
        } else {
            player.play()
            withAnimation { isPulsing = true }
            let duration = player.duration
            Task {
                try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                guard !Task.isCancelled else { return }
                withAnimation { isPulsing = false }
            }
        }
    }
}
