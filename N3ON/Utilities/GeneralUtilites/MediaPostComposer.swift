//
//  MediaPostComposer.swift
//  N3ON
//
//  Created by liam howe on 12/5/2025.
//
import SwiftUI
import Amplify
import PhotosUI

struct MediaPostComposer: View {
    @State private var selectedType: MediaType = .image
    @State private var selectedImages: [UIImage] = []
    @State private var selectedVideos: [URL] = []
    @State private var selectedAudios: [URL] = []
    @State private var caption: String = ""
    @Binding var posts: [Post] // your local UI Post model

    @State private var showMediaPicker = false
    @State private var showAudioPicker = false
    @State private var isUploading = false

    var body: some View {
        VStack(spacing: 12) {
            Picker("Type", selection: $selectedType) {
                ForEach([MediaType.image, .video, .audio], id: \.self) { t in
                    Text(t.rawValue.capitalized)
                }
            }
            .pickerStyle(.segmented)

            Button("Select Media") {
                switch selectedType {
                case .image, .video: showMediaPicker = true
                case .audio:        showAudioPicker = true
                }
            }

            TextEditor(text: $caption)
                .frame(height: 100)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)

            Button(isUploading ? "Posting..." : "Post") {
                Task { await post() }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isUploading)
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

    private func post() async {
        isUploading = true
        defer { isUploading = false }

        var urlList: [URL] = []
        var typeList: [MediaType] = []

        do {
            let auth = try await Amplify.Auth.getCurrentUser()
            // images
            if selectedType == .image {
                for img in selectedImages {
                    guard let jpeg = ImagePipeline.makeJPEGData(from: img, config: .feed) else { continue }
                    let key = MediaKind.feedImage(userID: auth.userId).makeKey(extension: "jpg")
                    _ = try await StorageUploader.uploadJPEG(jpeg, key: key, access: .protected)
                    if let url = await StorageUploader.signedURL(for: key, access: .protected) {
                        urlList.append(url); typeList.append(.image)
                    }
                }
            }
            // videos
            if selectedType == .video {
                for videoURL in selectedVideos {
                    let key = MediaKind.feedVideo(userID: auth.userId).makeKey(extension: "mov")
                    _ = try await StorageUploader.uploadFile(url: videoURL, key: key, contentType: "video/quicktime", access: .protected)
                    if let url = await StorageUploader.signedURL(for: key, access: .protected) {
                        urlList.append(url); typeList.append(.video)
                    }
                }
            }
            // audios
            if selectedType == .audio {
                for audioURL in selectedAudios {
                    let key = MediaKind.feedAudio(userID: auth.userId).makeKey(extension: "m4a")
                    _ = try await StorageUploader.uploadFile(url: audioURL, key: key, contentType: "audio/m4a", access: .protected)
                    if let url = await StorageUploader.signedURL(for: key, access: .protected) {
                        urlList.append(url); typeList.append(.audio)
                    }
                }
            }

            if !urlList.isEmpty {
                let newPost = Post(id: UUID(), urls: urlList, types: typeList, timestamp: Date(), caption: caption)
                posts.insert(newPost, at: 0)
            }

            caption = ""
            selectedImages.removeAll()
            selectedVideos.removeAll()
            selectedAudios.removeAll()

        } catch {
            print("Post upload error: \(error)")
        }
    }
}
