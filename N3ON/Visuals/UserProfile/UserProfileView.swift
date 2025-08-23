


// UserProfileView.swift

import SwiftUI
import Amplify
import PhotosUI
import CoreImage.CIFilterBuiltins

struct UserProfileView: View {
    @StateObject private var vm = RoleAwareProfileViewModel()
    @State private var showImagePicker = false
    @State private var pickedImage: UIImage?

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                Color("neonPurpleBackground").edgesIgnoringSafeArea(.all)

                LinearGradient(
                    colors: [Color("neonPurpleBackground").opacity(0.9), Color("dullPurple")],
                    startPoint: .top, endPoint: .bottom
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
                        header
                            .frame(height: 280)
                            .padding(.bottom, 20)

                        VStack(spacing: 20) {
                            if vm.roles.contains(.dj) {
                                Toggle("DJ Mode", isOn: $vm.isDJMode)
                                    .toggleStyle(SwitchToggleStyle(tint: Color("neonPurpleBackground")))
                                    .foregroundColor(.white)
                                    .padding(.horizontal)
                            }

                            RoleContainer(roles: vm.roles, isDJMode: vm.isDJMode) {
                                RegularUserSection()
                            } dj: {
                                DJSection()
                            } venue: {
                                VenueSection()
                            }

                            activityBlock
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
                ImagePicker(image: $pickedImage) { img in
                    // hook your StorageService upload here if desired
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 18) {
            ZStack(alignment: .bottomTrailing) {
                PulsingAvatarView(state: vm.avatarState, fromMemoryCache: true)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.white, Color("neonPurpleBackground")],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                            .padding(2)
                            .shadow(color: Color("neonPurpleBackground"), radius: 8)
                    )

                Button { showImagePicker.toggle() } label: {
                    Image(systemName: "camera")
                        .symbolVariant(.circle.fill)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color("neonPurpleBackground"))
                                .shadow(color: Color("neonPurpleBackground").opacity(0.8), radius: 8)
                        )
                }
                .offset(x: -8, y: -8)
            }
            .padding(.top, 15)

            Text(vm.username)
                .font(.system(.title2, design: .rounded))
                .fontWeight(.semibold)
                .foregroundColor(.white)

            HStack(spacing: 24) {
                StatItem(value: vm.followers, label: "Followers")
                Divider().frame(height: 40).overlay(Color.white.opacity(0.5))
                StatItem(value: vm.following, label: "Following")
            }
        }
    }

    private var activityBlock: some View {
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
                .padding(.horizontal)
        }
        .padding(.bottom, 10)
    }
}
