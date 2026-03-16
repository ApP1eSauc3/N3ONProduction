//
//  PulsingAvatarView.swift
//  N3ON
//
//  Created by liam howe on 13/5/2025.
//

import SwiftUI
import Amplify
import AVFoundation
import Combine

struct PulsingAvatarView: View {
    let state: AvatarState //replace with userstate
    let audioKey: String?  // Add audio key reference
    let size: CGFloat
    let fromMemoryCache: Bool
    
    @State private var image: UIImage? = nil
    @State private var cancellable: AnyCancellable? = nil
    @State private var audioCancellable: AnyCancellable? = nil
    @State private var player: AVAudioPlayer? = nil
    @State private var isPulsing = false
    
    init(state: AvatarState, audioKey: String? = nil, size: CGFloat, fromMemoryCache: Bool = false) {
        self.state = state
        self.audioKey = audioKey
        self.size = size
        self.fromMemoryCache = fromMemoryCache
    }
    
    var body: some View {
        ZStack {
            // Pulse effect
            if isPulsing {
                Circle()
                    .stroke(Color.purple, lineWidth: 3)
                    .scaleEffect(isPulsing ? 1.5 : 1)
                    .opacity(isPulsing ? 0 : 1)
                    .animation(.easeOut(duration: 0.8).repeatForever(autoreverses: false), value: isPulsing)
            }
            
            // Existing avatar content
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
                        .background(Color(.systemGray5))
                }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
            .onTapGesture(perform: handleTap)
        }
        .onAppear(perform: loadImage)
        .onDisappear {
            player?.stop()
            cancellable?.cancel()
            audioCancellable?.cancel()
        }
    }
    
    private func loadImage() {
        switch state {
        case .remote(let avatarKey):
            let storagePath = StringStoragePath.fromString(avatarKey)
            cancellable = Amplify.Storage.downloadData(path: storagePath)
                .resultPublisher
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        if case let .failure(error) = completion {
                            print("Image download error: \(error)")
                        }
                    },
                    receiveValue: { data in
                        self.image = UIImage(data: data)
                        loadAudioIfNeeded()
                    }
                )
            
        case .local(let image):
            self.image = image
            loadAudioIfNeeded()
        }
    }
    
    private func loadAudioIfNeeded() {
        guard let audioKey = audioKey else { return }
        
        let audioPath = StringStoragePath.fromString(audioKey)
        audioCancellable = Amplify.Storage.downloadData(path: audioPath)
            .resultPublisher
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        print("Audio download error: \(error)")
                    }
                },
                receiveValue: { data in
                    do {
                        self.player = try AVAudioPlayer(data: data)
                        self.player?.prepareToPlay()
                    } catch {
                        print("Audio initialization failed: \(error)")
                    }
                }
            )
    }
    
    private func handleTap() {
        guard let player = player else { return }
        
        if player.isPlaying {
            player.stop()
            withAnimation { isPulsing = false }
        } else {
            player.play()
            withAnimation { isPulsing = true }
            
            // Stop pulsing when audio finishes
            DispatchQueue.main.asyncAfter(deadline: .now() + player.duration) {
                withAnimation { isPulsing = false }
            }
        }
    }
}
