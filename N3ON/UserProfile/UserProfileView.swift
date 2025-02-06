





import SwiftUI
import Amplify
import PhotosUI
import MapKit


struct UserProfileView: View {
    @StateObject private var locationManager = LocationManager() // Manages user location
        @State private var avatarState: AvatarState = .remote(avatarKey: "default-avatar-key") // State for the profile image
        @State private var showImagePicker: Bool = false // Controls the image picker visibility
        @State private var image: UIImage? = nil // Holds the selected image
        @State private var uploadProgress: Double = 0.0 // Tracks the image upload progress
        @State private var followers: Int = 0 // Number of followers
        @State private var following: Int = 0 // Number of following

    
    var body: some View {
            VStack(spacing: 0) {
                ZStack {
                    LinearGradient(gradient: Gradient(colors:[.blue, .neonPurpleBackground]), startPoint: .top, endPoint: .bottom)
                        .edgesIgnoringSafeArea(.top)// Purple background for the top section
                    

                    VStack {
                        AvatarView(state: avatarState, fromMemoryCache: false) // Profile image
                            .frame(width: 150, height: 150)
                            .overlay(
                                Button(action: { showImagePicker.toggle()}) { // Button to change profile picture
                                    Image(systemName:"camera")
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(Color.black.opacity(0.3))
                                        .clipShape(Circle())
                                }
                                    .offset(x: 5, y: 5),
                                alignment: .bottomTrailing
                            )
                            .padding(.bottom, 8)
                        
                        Text("Username") // Display username (replace with actual data)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.bottom, 8)
                            .padding(.top, 10)

                        }
                    .padding(.top, 10)
                 }
                .frame(maxWidth: .infinity, maxHeight: 240)
                 
                 VStack {
                     
                     HStack {
                         Spacer()
                         VStack{
                             Text("\(followers)") // Display number of followers
                                 .foregroundColor(.white)
                             
                             Text("Followers") // Display number of followers
                                 .foregroundColor(.white)
                         }
                         Spacer()
                         
                         VStack{
                             Text("\(following)") // Display number of following
                                 .foregroundColor(.white)
                             
                             Text("Following")// Display number of following
                                 .foregroundColor(.white)
                         }
                         Spacer()
                     }
                     .padding()
                     
                     Spacer()
                     
                     Button("Add Friend") { // Button to add a friend
                         // Add friend action
                     }
                .padding()
                .background(Color.neonPurpleBackground.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(50)
                Spacer()
            }
                 .background(Color("customDarkGray")) // Dark grey background for the main section
                             .cornerRadius(10)
                             .padding()
            }
            .background(Color("customDarkGray")) // Dark grey background for the whole view
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $image, onImagePicked: uploadImage)
            }
            }
        
        
    private func uploadImage() {
        guard let image = image else { return }

        if let imageData = image.jpegData(compressionQuality: 0.8) {
            let path = "public/\(UUID().uuidString).jpg"

            Task {
                let uploadTask = Amplify.Storage.uploadData(key: path,
                    data: imageData)

                for await progress in await uploadTask.progress {
                    DispatchQueue.main.async {
                        self.uploadProgress = progress.fractionCompleted
                    }
                }
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


struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        UserProfileView()
    }
}
