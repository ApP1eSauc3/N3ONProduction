// MediaPostComposerView.swift
// N3ON — Prompt layer

import SwiftUI
import Amplify
import PhotosUI

struct MediaPostComposerView: View {
    @State private var selectedType: MediaType = .image
    @State private var selectedImages: [UIImage] = []
    @State private var selectedVideos: [URL] = []
    @State private var selectedAudios: [URL] = []
    @State private var caption: String = ""
    @Binding var posts: [Post]

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
                case .audio:         showAudioPicker = true
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

        // Use AuthService — never call Amplify.Auth directly from a view
        guard let userID = await AuthService.currentUserIdOrNil() else { return }

        var keyList: [String] = []
        var typeList: [String] = []

        do {
            if selectedType == .image {
                for img in selectedImages {
                    guard let jpeg = ImagePipeline.makeJPEGData(from: img, config: .feed) else { continue }
                    let key = MediaKind.feedImage(userID: userID).makeKey(extension: "jpg")
                    _ = try await StorageUploader.uploadJPEG(jpeg, key: key, access: .protected)
                    keyList.append(key); typeList.append(MediaType.image.rawValue)
                }
            }
            if selectedType == .video {
                for videoURL in selectedVideos {
                    let key = MediaKind.feedVideo(userID: userID).makeKey(extension: "mov")
                    _ = try await StorageUploader.uploadFile(url: videoURL, key: key, contentType: "video/quicktime", access: .protected)
                    keyList.append(key); typeList.append(MediaType.video.rawValue)
                }
            }
            if selectedType == .audio {
                for audioURL in selectedAudios {
                    let key = MediaKind.feedAudio(userID: userID).makeKey(extension: "m4a")
                    _ = try await StorageUploader.uploadFile(url: audioURL, key: key, contentType: "audio/m4a", access: .protected)
                    keyList.append(key); typeList.append(MediaType.audio.rawValue)
                }
            }

            if !keyList.isEmpty {
                let newPost = Post(
                    id: UUID().uuidString,
                    urls: keyList,
                    types: typeList,
                    timestamp: Temporal.DateTime(Date(), timeZone: .current),
                    caption: caption
                )
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
