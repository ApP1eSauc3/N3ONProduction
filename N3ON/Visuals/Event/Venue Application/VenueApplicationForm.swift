//
//  VenueApplicationForm.swift
//  N3ON
//
//  Created by liam howe on 11/7/2025.
//

import SwiftUI
import MapKit
import PhotosUI

struct VenueApplicationForm: View {
    @StateObject private var locationManager = LocationManager()
    @State private var venueName: String = ""
    @State private var venueDescription: String = ""
    @State private var venueAddress: String = ""
    @State private var venueType: VenueType = .bar
    @State private var selectedImages: [UIImage] = []
    @State private var showImagePicker = false
    @State private var submissionState: SubmissionState = .idle
    @State private var amenities: [Amenity] = []
    
    // Map region
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -27.4698, longitude: 153.0251), // Gold Coast coordinates
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    // Form state
    @State private var showValidationErrors = false
    @State private var formError: String?
    
    var body: some View {
        Form {
            // Section 1: Basic Information
            Section(header: Text("Venue Details").font(.headline)) {
                TextField("Venue Name", text: $venueName)
                    .validation(showValidationErrors && venueName.isEmpty, "Name is required")
                
                TextField("Address", text: $venueAddress)
                    .validation(showValidationErrors && venueAddress.isEmpty, "Address is required")
                
                Picker("Venue Type", selection: $venueType) {
                    ForEach(VenueType.allCases, id: \.self) { type in
                        Text(type.rawValue.capitalized)
                    }
                }
                
                TextEditorWithPlaceholder(text: $venueDescription, placeholder: "Describe your venue...")
                    .frame(minHeight: 100)
            }
            
            // Section 2: Location
            Section(header: Text("Location").font(.headline)) {
                Map(coordinateRegion: $mapRegion, annotationItems: []) { _ in
                    MapMarker(coordinate: mapRegion.center)
                }
                .frame(height: 200)
                .cornerRadius(10)
                .overlay(alignment: .topTrailing) {
                    Button {
                        centerMapOnUserLocation()
                    } label: {
                        Image(systemName: "location.fill")
                            .padding(8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                    .padding(8)
                }
                
                Button("Use Current Location") {
                    if let location = locationManager.userLocation {
                        reverseGeocode(location: location)
                    }
                }
                .disabled(locationManager.userLocation == nil)
            }
            
            // Section 3: Media
            Section(header: Text("Photos").font(.headline)) {
                PhotoSelectionGrid(selectedImages: $selectedImages)
                
                Button("Add Photos") {
                    showImagePicker = true
                }
            }
            
            // Section 4: Amenities
            Section(header: Text("Amenities").font(.headline)) {
                AmenitySelectionView(selectedAmenities: $amenities)
            }
            
            // Submission
            Section {
                Button(action: submitApplication) {
                    HStack {
                        Spacer()
                        Group {
                            switch submissionState {
                            case .idle:
                                Text("Submit Application")
                            case .submitting:
                                ProgressView()
                                    .padding(.trailing, 8)
                                Text("Submitting...")
                            case .success:
                                Image(systemName: "checkmark.circle.fill")
                                Text("Submitted!")
                            }
                        }
                        .font(.headline)
                        Spacer()
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(submissionState == .submitting || submissionState == .success)
                
                if let error = formError {
                    Text(error)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .navigationTitle("Venue Application")
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImages: $selectedImages)
        }
        .onChange(of: venueAddress) { _ in
            geocodeAddress()
        }
    }
    
    // MARK: - Actions
    
    private func centerMapOnUserLocation() {
        guard let location = locationManager.userLocation else { return }
        withAnimation {
            mapRegion.center = location.coordinate
        }
    }
    
    private func reverseGeocode(location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            guard let placemark = placemarks?.first else { return }
            DispatchQueue.main.async {
                venueAddress = [
                    placemark.thoroughfare,
                    placemark.locality,
                    placemark.administrativeArea,
                    placemark.postalCode
                ].compactMap { $0 }.joined(separator: ", ")
            }
        }
    }
    
    private func geocodeAddress() {
        guard !venueAddress.isEmpty else { return }
        
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(venueAddress) { placemarks, error in
            guard let placemark = placemarks?.first,
                  let location = placemark.location else { return }
            
            withAnimation {
                mapRegion.center = location.coordinate
            }
        }
    }
    
    private func submitApplication() {
        showValidationErrors = true
        
        guard validateForm() else { return }
        
        submissionState = .submitting
        formError = nil
        
        Task {
            do {
                // 1. Upload images
                let imageKeys = try await uploadImages()
                
                // 2. Create venue object
                let venue = VenueApplication(
                    name: venueName,
                    description: venueDescription,
                    address: venueAddress,
                    latitude: mapRegion.center.latitude,
                    longitude: mapRegion.center.longitude,
                    type: venueType,
                    amenities: amenities,
                    imageKeys: imageKeys
                )
                
                // 3. Submit to backend (simulated)
                try await submitToBackend(venue: venue)
                
                // 4. Success state
                await MainActor.run {
                    submissionState = .success
                    // Reset form after success
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        resetForm()
                    }
                }
            } catch {
                await MainActor.run {
                    formError = error.localizedDescription
                    submissionState = .idle
                }
            }
        }
    }
    
    private func validateForm() -> Bool {
        if venueName.isEmpty {
            formError = "Venue name is required"
            return false
        }
        
        if venueAddress.isEmpty {
            formError = "Address is required"
            return false
        }
        
        return true
    }
    
    private func uploadImages() async throws -> [String] {
        var keys: [String] = []
        
        for image in selectedImages {
            guard let data = image.jpegData(compressionQuality: 0.8) else { continue }
            let key = "venues/\(UUID().uuidString).jpg"
            let uploadTask = Amplify.Storage.uploadData(key: key, data: data)
            
            for await progress in uploadTask.progress {
                // Handle progress if needed
            }
            
            let result = try await uploadTask.value
            keys.append(result)
        }
        
        return keys
    }
    
    private func submitToBackend(venue: VenueApplication) async throws {
        // Simulate network request
        try await Task.sleep(nanoseconds: 2_000_000_000)
    }
    
    private func resetForm() {
        venueName = ""
        venueDescription = ""
        venueAddress = ""
        venueType = .bar
        selectedImages = []
        amenities = []
        submissionState = .idle
        showValidationErrors = false
    }
}

// MARK: - Supporting Views





 
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(12)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
    }
}





// MARK: - Data Models

enum VenueType: String, CaseIterable {
    case bar, restaurant, club, cafe, hotel, other
}

enum Amenity: String, CaseIterable {
    case wifi, parking, outdoor, liveMusic, danceFloor, pool, smokingArea
    
    var iconName: String {
        switch self {
        case .wifi: return "wifi"
        case .parking: return "parkingsign"
        case .outdoor: return "sun.max"
        case .liveMusic: return "music.mic"
        case .danceFloor: return "figure.dance"
        case .pool: return "water.waves"
        case .smokingArea: return "smoke"
        }
    }
}

struct VenueApplication: Codable {
    let name: String
    let description: String
    let address: String
    let latitude: Double
    let longitude: Double
    let type: VenueType
    let amenities: [Amenity]
    let imageKeys: [String]
}

enum SubmissionState {
    case idle, submitting, success
}

// MARK: - Preview

struct VenueApplicationForm_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            VenueApplicationForm()
        }
    }
}
