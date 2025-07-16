


// UserProfileView.swift

import SwiftUI
import Amplify
import PhotosUI
import MapKit

struct UserProfileView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var avatarState: AvatarState = .remote(avatarKey: "default-avatar-key")
    @State private var showImagePicker: Bool = false
    @State private var image: UIImage? = nil
    @State private var uploadProgress: Double = 0.0
    @State private var followers: Int = 0
    @State private var following: Int = 0
    @State private var isFollowed = false

    private let storageService = StorageService.shared
    @ObservedObject var djViewModel: DJViewModel

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {

                Color("neonPurpleBackground")
                    .edgesIgnoringSafeArea(.all)
                LinearGradient(
                    colors: [
                        Color("neonPurpleBackground").opacity(0.9),
                        Color("dullPurple")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 320)
                .edgesIgnoringSafeArea(.top)
                .zIndex(0)

                VStack {
                    Spacer()
                    Color.black
                        .frame(height: geometry.size.height * 0.6)
                        .cornerRadius(20, corners: [.topLeft, .topRight])
                }
                .edgesIgnoringSafeArea(.bottom)
                .zIndex(0)

                ScrollView {
                    VStack(spacing: 0) {
                        VStack(spacing: 24) {
                            ZStack(alignment: .bottomTrailing) {
                                PulsingAvatarView(state: avatarState, fromMemoryCache: true)
                                    .frame(width: 120, height: 120)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                LinearGradient(
                                                    colors: [.white, Color("neonPurpleBackground")],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1.5
                                            )
                                            .padding(2)
                                            .shadow(color: Color("neonPurpleBackground"), radius: 8)
                                    )

                                Button {
                                    showImagePicker.toggle()
                                } label: {
                                    Image(systemName: "camera")
                                        .symbolVariant(.circle.fill)
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background {
                                            Circle()
                                                .fill(Color("neonPurpleBackground"))
                                                .shadow(color: Color("neonPurpleBackground").opacity(0.8), radius: 8)
                                        }
                                }
                                .offset(x: -8, y: -8)
                            }
                            .padding(.top, 15)

                            Text(djViewModel.dj.username)
                                .font(.system(.title2, design: .rounded))
                                .fontWeight(.semibold)
                                .foregroundColor(.white)

                            Button(action: {
                                djViewModel.toggleFollow { success in
                                    isFollowed.toggle()
                                }
                            }) {
                                Text(isFollowed ? "Unfollow" : "Follow")
                                    .font(.subheadline)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.white.opacity(0.15))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                        .frame(height: 320)
                        .padding(.bottom, 20)

                        VStack(spacing: 24) {
                            HStack(spacing: 24) {
                                StatItem(value: followers, label: "Followers")
                                Divider()
                                    .frame(height: 40)
                                    .overlay(Color.white.opacity(0.5))
                                StatItem(value: following, label: "Following")
                            }
                            .padding(.vertical, 16)

                            VStack(spacing: 16) {
                                Text("Activity Feed")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color("darkGray").opacity(0.9))
                                    .frame(minHeight: 300)
                                    .overlay(
                                        Text("Content Placeholder")
                                            .foregroundColor(.white.opacity(0.5))
                                    )
                            }
                            .padding(.horizontal)
                        }
                        .background(Color.black)
                        .cornerRadius(20, corners: [.topLeft, .topRight])
                        .offset(y: -60)
                        .padding(.bottom, 80)
                    }
                }
                .zIndex(1)
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $image) { pickedImage in
                    // Handle image upload
                }
            }
        }
    }
}

extension View {
    func safeArea() -> UIEdgeInsets {
        guard let window = UIApplication.shared.windows.first else {
            return .zero
        }
        return window.safeAreaInsets
    }
}

struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        let dummyDJ = DJ(id: "1", username: "DJ Test", followers: [], isFollowedByCurrentUser: false)
        UserProfileView(djViewModel: DJViewModel(dj: dummyDJ))
    }
}
