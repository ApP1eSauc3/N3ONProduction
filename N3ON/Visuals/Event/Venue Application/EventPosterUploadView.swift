//
//  EventPosterUploadView.swift
//  N3ON
//
//  Created by liam howe on 12/7/2025.
//

struct EventPosterUploadView: View {
    @EnvironmentObject var draft: EventDraftViewModel
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var isUploading = false

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

            Button("Upload Poster") {
                uploadPoster()
            }
            .disabled(draft.eventPosterImage == nil || isUploading)
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

    func uploadPoster() {
        guard let imageData = draft.eventPosterImage?.jpegData(compressionQuality: 0.8) else { return }
        let key = "event-posters/\(UUID().uuidString).jpg"

        isUploading = true
        Task {
            do {
                try await Amplify.Storage.uploadData(key: key, data: imageData)
                draft.eventPosterKey = key
                print("✅ Poster uploaded: \(key)")
            } catch {
                print("❌ Upload failed: \(error)")
            }
            isUploading = false
        }
    }
}
