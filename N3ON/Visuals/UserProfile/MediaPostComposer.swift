//
//  MediaPostComposer.swift
//  N3ON
//
//  Created by liam howe on 12/5/2025.
//
import SwiftUI
import Amplify
import PhotosUI
import MapKit
import AVKit

struct MediaPostComposer: View {
    @State private var selectedType: MediaType = .image
    @State private var selectedImages: [UIImage] = []
    @State private var selectedVideos: [URL] = []
    @State private var selectedAudios: [URL] = []
    @State private var caption: String = ""
    @Binding var posts: [Post]
    
    @State private var showMediaPicker = false
    @State private var showAudioPicker = false
    
    var body: some View {
        VStack(spacing: 12) {
            Picker("Type", selection: $selectedType) {
                ForEach([MediaType.image, .video, .audio], id: \.self) { type in
                    Text(type.rawValue.capitalized)
                }
            }
            .pickerStyle(SegmentedPickerStyle())

            Button("Select Media") {
                switch selectedType {
                case .image, .video:
                    showMediaPicker = true
                case .audio:
                    showAudioPicker = true
                }
            }

            TextEditor(text: $caption)
                .frame(height: 100)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)

            Button("Post") {
                Task {
                    var mediaURLs: [URL] = []
                    var mediaTypes: [MediaType] = []

                    if selectedType == .image {
                        for img in selectedImages {
                            if let key = try? await StorageService.uploadImage(img, isPublished: true),
                               let url = URL(string: "https://YOUR_BUCKET_NAME.s3.amazonaws.com/\(key)") {
                                mediaURLs.append(url)
                                mediaTypes.append(.image)
                            }
                        }
                    }

                    if selectedType == .video {
                        for videoURL in selectedVideos {
                            if let videoData = try? Data(contentsOf: videoURL) {
                                let fileName = UUID().uuidString + ".mov"
                                let path = "public/\(fileName)"
                                _ = try? await Amplify.Storage.uploadData(key: path, data: videoData)
                                if let url = URL(string: "https://YOUR_BUCKET_NAME.s3.amazonaws.com/\(path)") {
                                    mediaURLs.append(url)
                                    mediaTypes.append(.video)
                                }
                            }
                        }
                    }

                    if selectedType == .audio {
                        for audioURL in selectedAudios {
                            if let audioData = try? Data(contentsOf: audioURL) {
                                let fileName = UUID().uuidString + ".m4a"
                                let path = "public/\(fileName)"
                                _ = try? await Amplify.Storage.uploadData(key: path, data: audioData)
                                if let url = URL(string: "https://YOUR_BUCKET_NAME.s3.amazonaws.com/\(path)") {
                                    mediaURLs.append(url)
                                    mediaTypes.append(.audio)
                                }
                            }
                        }
                    }

                    if !mediaURLs.isEmpty {
                        let newPost = Post(id: UUID(), urls: mediaURLs, types: mediaTypes, timestamp: Date(), caption: caption)
                        posts.insert(newPost, at: 0)
                    }

                    caption = ""
                    selectedImages = []
                    selectedVideos = []
                    selectedAudios = []
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .sheet(isPresented: $showMediaPicker) {
            MixedMediaPicker(
                mediaType: selectedType,
                selectedImages: $selectedImages,
                selectedVideos: $selectedVideos
            )
        }
        .sheet(isPresented: $showAudioPicker) {
            AudioPicker(selectedAudio: Binding(
                get: { selectedAudios.first },
                set: { if let url = $0 { selectedAudios = [url] } }
            ))
        }
    }
}
