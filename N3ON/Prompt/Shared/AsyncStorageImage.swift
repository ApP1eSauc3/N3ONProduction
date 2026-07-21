//
//  AsyncStorageImage.swift
//  N3ON
//

import SwiftUI

/// Loads an image from S3 by signing the storage key at display time.
/// Never store signed URLs — always pass the raw S3 key.
struct AsyncStorageImage: View {
    let storageKey: String
    var contentMode: ContentMode = .fill

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        ProgressView()
                    )
            }
        }
        .task(id: storageKey) {
            if let cached = ImageCache.shared.image(forKey: storageKey) {
                image = cached
                return
            }
            image = nil
            guard let loaded = try? await ImageCache.loadImage(forKey: storageKey, access: .guest) else { return }
            guard !Task.isCancelled else { return }
            image = loaded
        }
    }
}
