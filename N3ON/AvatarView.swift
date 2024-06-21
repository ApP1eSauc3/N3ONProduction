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
    case remote(avatarKey: String)
    case local(image: UIImage)
}

struct AvatarView: View {
    let state: AvatarState
    let fromMemoryCache: Bool
    
    @State private var image: UIImage? = nil
    @State private var cancellable: AnyCancellable? = nil
    
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
                    .clipShape(Circle())
            } else {
                Image(systemName: "person")
                    .resizable()
                    .foregroundColor(.purple)
                    .padding(8)
                    .background(Color.init(white: 0.9))
                    .clipShape(Circle())
            }
        }
        .onAppear(perform: loadImage)
    }
    
    private func loadImage() {
        switch state {
        case .remote(let avatarKey):
            downloadImage(from: avatarKey)
        case .local(let image):
            self.image = image
        }
    }
    
    private func downloadImage(from key: String) {
        cancellable = Amplify.Storage.downloadData(key: key)
            .resultPublisher
            .receive(on: DispatchQueue.main)
            .sink {
                if case let .failure(storageError) = $0 {
                    print("Failed to download image: \(storageError)")
                }
            }
            receiveValue: { data in
                self.image = UIImage(data: data)
            }
    }
}
