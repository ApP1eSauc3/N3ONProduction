//
//  VenueProfileView.swift
//  N3ON
//
//  Created by liam howe on 26/6/2024.
//

import SwiftUI
import PhotosUI
import MapKit
import Amplify

struct VenueProfileView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var venueName: String = ""
    @State private var venueAddress: String = ""
    @State private var locations = [Location]()
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 50, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var avatarState: AvatarState = .remote(avatarKey: "default-venue-avatar")
    @State private var showImagePicker: Bool = false
    @State private var image: UIImage? = nil
    @State private var additionalImages: [UIImage] = [] //stores additional image
    @State private var showAdditionalImagePicker: Bool = false // Controls the sheet for additional images
    @State private var uploadProgress: Double = 0.0
    @State private var selectedTab: Int = 0
    
    var body: some View {
        VStack {
            ZStack {
                Color.neonPurpleBackground
                VStack {
                    VStack {
                        Text(venueName.isEmpty ? "Venue Name" : venueName)
                            .font(.title)
                            .padding(.bottom, 8)
                        
                        AvatarView(state: avatarState, fromMemoryCache: false)
                            .frame(width: 100, height: 100)
                            .padding()
                        
                        Button("Change Profile Picture") {
                            showImagePicker.toggle()
                        }
                        .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: 200)
                    
                    TabView(selection: $selectedTab) {
                        VStack {
                            Button("Upload venue images") {
                                showAdditionalImagePicker = true
                            }
                            .padding()
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            
                            ScrollView {
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                                    ForEach(additionalImages, id: \.self) { image in
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 100, height: 100)
                                            .clipShape(Rectangle())
                                    }
                                }
                                .padding()
                            }
                            
                            TextField("Venue Name", text: $venueName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding()
                            
                            TextField("Venue Address", text: $venueAddress)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding()
                            
                            Button("Add Venue") {
                                Task {
                                    if let coordinate = await geocode(address: venueAddress) {
                                        let newVenue = Location(id: UUID(), name: venueName, description: venueAddress, latitude: coordinate.latitude, longitude: coordinate.longitude)
                                        locations.append(newVenue)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            
                            Map(coordinateRegion: $mapRegion, annotationItems: locations) { location in
                                MapMarker(coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude))
                            }
                            .frame(width: 250, height: 250)
                            .onAppear {
                                if let userLocation = locationManager.userLocation {
                                    setMapRegion(userLocation: userLocation)
                                }
                            }
                        }
                        .tabItem {
                            Text("Add Venue")
                        }
                        .tag(0)
                        
                        VStack {
                            Text("Upload and Display Images")
                                .padding()
                        }
                        .tabItem {
                            Text("Images")
                        }
                        .tag(1)
                    }
                    .frame(maxHeight: .infinity)
                    .background(Color(.darkGray))
                    .cornerRadius(10)
                    .padding()
                }
            }
            
            Text("Address: \(venueAddress)")
                .padding()
        }
        .background(Color(.darkGray))
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $image, onImagePicked: uploadProfileImage) // Profile Image Picker
        }
        .sheet(isPresented: $showAdditionalImagePicker) {
            ImagePicker(image: Binding(get: {
                nil // Binding for individual selection
            }, set: { newImage in
                if let newImage = newImage {
                    additionalImages.append(newImage)
                    uploadAdditionalImages([newImage])
                }
            })) {
                print("Additional image picked")
            }
        }
        
        private func uploadProfileImage() {
            guard let image = image else { return }
            
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                let path = "public/venue-profile/\(UUID().uuidString).jpg"
                
                Task {
                    do {
                        let uploadTask = Amplify.Storage.uploadData(key: path, data: imageData)
                        for await progress in uploadTask.progress {
                            DispatchQueue.main.async {
                                self.uploadProgress = progress.fractionCompleted
                            }
                        }
                        let result = try await uploadTask.value
                        DispatchQueue.main.async {
                            self.avatarState = .remote(avatarKey: path) // Update venue avatar state
                            self.uploadProgress = 1.0
                            print("Profile image upload completed: \(result)")
                        }
                    } catch {
                        print("Failed to upload profile image: \(error)")
                    }
                }
            }
        }
        
        private func uploadAdditionalImages(_ images: [UIImage]) {
            for image in images {
                if let imageData = image.jpegData(compressionQuality: 0.8) {
                    let path = "public/venue-images/\(UUID().uuidString).jpg"
                    
                    Task {
                        do {
                            let uploadTask = Amplify.Storage.uploadData(key: path, data: imageData)
                            _ = try await uploadTask.value
                            print("Additional image uploaded: \(path)")
                        } catch {
                            print("Failed to upload additional image: \(error)")
                        }
                    }
                }
            }
        }
        
        
        private func geocode(address: String) async -> CLLocationCoordinate2D? {
            return await withCheckedContinuation { continuation in
                let geocoder = CLGeocoder()
                geocoder.geocodeAddressString(address) { placemarks, error in
                    if let error = error {
                        print("Failed to geocode address: \(error)")
                        continuation.resume(returning: nil)
                    } else {
                        continuation.resume(returning: placemarks?.first?.location?.coordinate)
                    }
                }
            }
        }
        
        private func setMapRegion(userLocation: CLLocation) {
            mapRegion = MKCoordinateRegion(
                center: userLocation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
    }
}

struct VenueProfileView_Previews: PreviewProvider {
    static var previews: some View {
        VenueProfileView()
    }
}
