//
//  AvatarView.swift
//  N3ON
//
//  Created by liam howe on 16/6/2024.
//
import SwiftUI
import Amplify
import Combine

enum AvatarState: Equatable {
    case remote(avatarKey: String) // Avatar image from remote storage
    case local(image: UIImage) // Avatar image from local storage
}

struct AvatarView: View {
    let state: AvatarState // State of the avatar (remote or local)
    let fromMemoryCache: Bool // Flag for memory cache

    @State private var image: UIImage? = nil // State for the avatar image
    @State private var cancellable: AnyCancellable? = nil // Cancellable for Combine

    init(state: AvatarState, fromMemoryCache: Bool = false) {
        self.state = state
        self.fromMemoryCache = fromMemoryCache
    }

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .clipShape(Circle()) // Display image in a circle
            } else {
                Image(systemName: "person")
                    .resizable()
                    .foregroundColor(.neonPurpleBackground)
                    .padding(8)
                    .background(Color.init(white: 0.9))
                    .clipShape(Circle()) // Display default image in a circle
            }
        }
        .onAppear(perform: loadImage) // Load image when the view appears
    }

    private func loadImage() {
        switch state {
        case .remote(let avatarKey):
            downloadImage(from: avatarKey) // Download image from remote storage
        case .local(let image):
            self.image = image // Use local image
        }
    }

    private func downloadImage(from key: String) {
        cancellable = Amplify.Storage.downloadData(key: key)
            .resultPublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case let .failure(storageError) = completion {
                    print("Failed to download image: \(storageError)")
                }
            }, receiveValue: { data in
                self.image = UIImage(data: data)
            })
    }

}
