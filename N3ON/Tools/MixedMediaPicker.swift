//
//  MixedMediaPicker.swift
//  N3ON
//
//  Created by liam howe on 12/5/2025.
//

import SwiftUI
import PhotosUI

    

struct MixedMediaPicker: UIViewControllerRepresentable {
    let mediaType: MediaType
    @Binding var selectedImages: [UIImage]
    @Binding var selectedVideos: [URL]

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 5
        switch mediaType {
        case .image: config.filter = .images
        case .video: config.filter = .videos
        case .audio: config.filter = nil
        }
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: MixedMediaPicker
        init(_ parent: MixedMediaPicker) { self.parent = parent }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            for result in results {
                switch parent.mediaType {
                case .image:
                    if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                        result.itemProvider.loadObject(ofClass: UIImage.self) { image, _ in
                            if let ui = image as? UIImage {
                                DispatchQueue.main.async { self.parent.selectedImages.append(ui) }
                            }
                        }
                    }
                case .video:
                    result.itemProvider.loadFileRepresentation(forTypeIdentifier: "public.movie") { url, _ in
                        if let url { DispatchQueue.main.async { self.parent.selectedVideos.append(url) } }
                    }
                case .audio:
                    break
                }
            }
        }
    }
}
