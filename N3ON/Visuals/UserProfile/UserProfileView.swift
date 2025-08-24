


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
        NavigationStack {
            GeometryReader { geometry in
                ZStack(alignment: .top) {
                    Color("neonPurpleBackground").ignoresSafeArea()

                    LinearGradient(
                        colors: [Color("neonPurpleBackground").opacity(0.9), Color("dullPurple")],
                        startPoint: .top, endPoint: .bottom
                    )
                    .frame(height: 320)
                    .ignoresSafeArea(edges: .top)
                    .zIndex(0)

                    VStack {
                        Spacer()
                        Color.black
                            .frame(height: geometry.size.height * 0.6)
                            .cornerRadius(20, corners: [.topLeft, .topRight])
                    }
                    .ignoresSafeArea(edges: .bottom)
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
                                        .foregroundStyle(.white)
                                        .padding(.horizontal)
                                }

                                RoleContainer(roles: vm.roles, isDJMode: vm.isDJMode) {
                                    RegularUserSection()
                                } dj: {
                                    DJSection()
                                } venue: {
                                    VenueSection()
                                }

                                activity
                            }
                            .background(Color.black)
                            .cornerRadius(20, corners: [.topLeft, .topRight])
                            .offset(y: -60)
                            .padding(.bottom, 80)
                        }
                    }
                    .zIndex(1)
                }
            }
            .task { await vm.load() }
            .navigationBarHidden(true)
        }
    }

    private var header: some View {
            VStack(spacing: 18) {
                ZStack(alignment: .bottomTrailing) {
                    // ✅ Use your PulsingAvatarView with AvatarState
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
                            .foregroundStyle(.white)
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
                .foregroundStyle(.white)

            HStack(spacing: 24) {
                StatItem(value: vm.followers, label: "Followers")
                Divider().frame(height: 40).overlay(Color.white.opacity(0.5))
                StatItem(value: vm.following, label: "Following")
            }
        }
    }

    private var activity: some View {
        VStack(spacing: 16) {
            Text("Activity Feed")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            RoundedRectangle(cornerRadius: 12)
                .fill(Color("darkGray").opacity(0.9))
                .frame(minHeight: 300)
                .overlay(
                    Text("Content Placeholder").foregroundStyle(.white.opacity(0.5))
                )
                .padding(.horizontal)
        }
        .padding(.bottom, 10)
    }
}
