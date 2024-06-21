





import SwiftUI
import Amplify
import PhotosUI

struct UserProfileView: View {
    @State private var avatarState: AvatarState = .remote(avatarKey: "default-avatar-key")
        @State private var showImagePicker: Bool = false
        @State private var image: UIImage? = nil
        @State private var uploadProgress: Double = 0.0
    
    var body: some View {
        VStack {
            AvatarView(state: avatarState, fromMemoryCache: false)
                .frame(width: 100, height: 100)
                .padding()
            
            Button("Change Profile Picture") {
                showImagePicker.toggle()
            }
            .padding()
                       
                       if uploadProgress > 0 && uploadProgress < 1 {
                           ProgressView(value: uploadProgress)
                               .padding()
                       }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $image, onImagePicked: uploadImage)
        }
    }
    
    private func uploadImage() {
        guard let image = image else { return }
        
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            let path = "public/\(UUID().uuidString).jpg"
            
            Task {
                let uploadTask = Amplify.Storage.uploadData(
                    path: .fromString(path),
                    data: imageData
                )
                
                for await progress in await uploadTask.progress {
                    DispatchQueue.main.async {
                                            self.uploadProgress = progress.fractionCompleted
                                        }
                                    }
                do {
                                    let result = try await uploadTask.value
                                    DispatchQueue.main.async {
                                        self.avatarState = .remote(avatarKey: path)
                                        self.uploadProgress = 1.0
                                        print("Upload completed: \(result)")
                                    }
                } catch {
                    print("Failed to upload image: \(error)")
                }
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let onImagePicked: () -> Void
    
    func makeUIViewController(context: Context) -> some UIViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }
            
            provider.loadObject(ofClass: UIImage.self) { image, _ in
                DispatchQueue.main.async {
                    self.parent.image = image as? UIImage
                    self.parent.onImagePicked()
                }
            }
        }
    }
   

}
