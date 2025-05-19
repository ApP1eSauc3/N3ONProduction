//
//  MixedMediaPicker.swift
//  N3ON
//
//  Created by liam howe on 12/5/2025.
//

import Foundation
import Amplify
import MapKit
import AVKit

struct MixedMediaPicker: UIViewControllerRepresentable {
    let mediaType: MediaType
    @Binding var selectedImages: [UIImage]
    @Binding var selectedVideos: [URL]

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 5
        config.filter = mediaType == .image ? .images : .videos

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: MixedMediaPicker

        init(_ parent: MixedMediaPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            for result in results {
                if parent.mediaType == .image {
                    if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                        result.itemProvider.loadObject(ofClass: UIImage.self) { image, _ in
                            if let uiImage = image as? UIImage {
                                DispatchQueue.main.async {
                                    parent.selectedImages.append(uiImage)
                                }
                            }
                        }
                    }
                } else if parent.mediaType == .video {
                    result.itemProvider.loadFileRepresentation(forTypeIdentifier: "public.movie") { url, _ in
                        if let url = url {
                            DispatchQueue.main.async {
                                parent.selectedVideos.append(url)
                            }
                        }
                    }
                }
            }
        }
    }
}
