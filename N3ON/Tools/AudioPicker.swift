//
//  AudioPicker.swift
//  N3ON
//
//  UIDocumentPickerViewController wrapper for selecting a single audio file.

import SwiftUI
import UniformTypeIdentifiers

struct AudioPicker: UIViewControllerRepresentable {
    @Binding var selectedAudio: URL?

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: [.audio, .mp3, .mpeg4Audio],
            asCopy: true
        )
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: AudioPicker
        init(_ parent: AudioPicker) { self.parent = parent }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.selectedAudio = urls.first
        }
    }
}
