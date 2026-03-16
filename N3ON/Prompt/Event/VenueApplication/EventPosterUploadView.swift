//
//  EventPosterUploadView.swift
//  N3ON
//

import SwiftUI
import PhotosUI
import Amplify

struct EventPosterUploadView: View {
    @EnvironmentObject var draft: EventDraftViewModel
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var isUploading = false
    @State private var uploadError: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("Upload Event Poster")
                .font(.title2)
                .bold()

            if let image = draft.eventPosterImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 250)
                    .cornerRadius(12)
                    .shadow(radius: 10)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 250)
                    .cornerRadius(12)
                    .overlay(
                        Text("Tap to select image")
                            .foregroundColor(.gray)
                    )
            }

            PhotosPicker("Choose Poster", selection: $selectedItem, matching: .images)
                .buttonStyle(.borderedProminent)

            Button(isUploading ? "Uploading..." : "Upload Poster") {
                Task { await uploadPoster() }
            }
            .disabled(draft.eventPosterImage == nil || isUploading)

            if let uploadError {
                Text(uploadError)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding()
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    draft.eventPosterImage = uiImage
                }
            }
        }
    }

    @MainActor
    private func uploadPoster() async {
        guard let image = draft.eventPosterImage,
              let jpeg = image.jpegData(compressionQuality: 0.8) else { return }

        isUploading = true
        uploadError = nil
        defer { isUploading = false }

        do {
            let auth = try await Amplify.Auth.getCurrentUser()
            // eventPoster takes an eventID — use a user-scoped UUID as placeholder
            // since the event record doesn't exist yet at upload time.
            // This key is stored on draft.eventPosterKey and written to
            // Event.posterKey when submitEvent() is called.
            let placeholderID = auth.userId + "-" + UUID().uuidString
            let key = MediaKind.eventPoster(eventID: placeholderID).makeKey(extension: "jpg")
            _ = try await StorageUploader.uploadJPEG(jpeg, key: key, access: .protected)
            draft.eventPosterKey = key
        } catch {
            uploadError = "Upload failed: \(error.localizedDescription)"
        }
    }
}

#Preview {
    EventPosterUploadView()
        .environmentObject(EventDraftViewModel())
        .preferredColorScheme(.dark)
}
