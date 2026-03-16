//
//  PostView.swift
//  N3ON
//

import SwiftUI
import AVKit

struct PostView: View {
    let post: Post

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TabView {
                ForEach(Array(zip(post.urls, post.types)), id: \.0) { key, typeRaw in
                    let mediaType = MediaType(rawValue: typeRaw) ?? .image
                    switch mediaType {
                    case .image:
                        AsyncStorageImage(storageKey: key)
                            .scaledToFill()
                            .clipped()
                    case .video:
                        AsyncVideoPlayer(storageKey: key)
                    case .audio:
                        AsyncAudioPlayer(storageKey: key)
                    }
                }
            }
            .frame(height: 250)
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            if let caption = post.caption, !caption.isEmpty {
                Text(caption)
                    .font(.subheadline)
                    .foregroundColor(.white)
            }

            Text(post.timestamp.foundationDate, style: .time)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.bottom)
    }
}

// MARK: - Private subviews

private struct AsyncVideoPlayer: View {
    let storageKey: String
    @State private var player: AVPlayer?

    var body: some View {
        Group {
            if let player {
                VideoPlayer(player: player)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3))
            }
        }
        .task {
            guard player == nil else { return }
            if let url = try? await StorageUploader.signedURL(for: storageKey, access: .guest) {
                player = AVPlayer(url: url)
            }
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }
}

private struct AsyncAudioPlayer: View {
    let storageKey: String
    @State private var resolvedURL: URL?

    var body: some View {
        Group {
            if resolvedURL != nil {
                // TODO: replace with AudioPlayerView(storageKey: storageKey) once rebuilt
                HStack {
                    Image(systemName: "waveform")
                    Text("Audio")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.3))
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            resolvedURL = try? await StorageUploader.signedURL(for: storageKey, access: .guest)
        }
    }
}
