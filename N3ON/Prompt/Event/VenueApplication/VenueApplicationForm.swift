// VenueApplicationForm.swift
// N3ON — Prompt layer
// 4-step venue application: Details → Location → Photos → Review.
// All state and logic owned by VenueApplicationViewModel.

import SwiftUI
import MapKit

struct VenueApplicationForm: View {
    @StateObject private var vm = VenueApplicationViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                stepProgressBar
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 24)

                ScrollView {
                    VStack(spacing: 0) {
                        stepContent
                            .padding(.horizontal, 16)
                    }
                }

                navigationButtons
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
            }
        }
        .navigationTitle(vm.step.title)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Application Submitted", isPresented: $vm.didSubmitSuccessfully) {
            Button("Done") { dismiss() }
        } message: {
            Text("Your venue is under review. We'll notify you once it's approved.")
        }
    }

    // MARK: — Progress bar

    private var stepProgressBar: some View {
        HStack(spacing: 4) {
            ForEach(VenueApplicationViewModel.Step.allCases, id: \.rawValue) { s in
                Capsule()
                    .fill(s.rawValue <= vm.step.rawValue
                          ? Color("neonPurpleBackground")
                          : Color.white.opacity(0.15))
                    .frame(height: 3)
                    .animation(.easeInOut(duration: 0.25), value: vm.step)
            }
        }
    }

    // MARK: — Step routing

    @ViewBuilder
    private var stepContent: some View {
        switch vm.step {
        case .details:  detailsStep
        case .location: locationStep
        case .photos:   photosStep
        case .review:   reviewStep
        }
    }

    // MARK: — Navigation buttons

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            if vm.step != .details {
                Button("Back") { vm.previousStep() }
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            if vm.step == .review {
                Button {
                    Task { await vm.submitApplication() }
                } label: {
                    if vm.isSubmitting {
                        ProgressView().tint(.white)
                    } else {
                        Text("Submit Application").font(.headline).foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(Color("neonPurpleBackground").opacity(vm.isSubmitting ? 0.5 : 1))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: Color("neonPurpleBackground").opacity(0.55), radius: 18)
                .shadow(color: Color("neonPurpleBackground").opacity(0.85), radius: 5)
                .disabled(vm.isSubmitting)
            } else {
                Button("Next") { vm.nextStep() }
                    .font(.headline)
                    .foregroundStyle(vm.canAdvance ? .white : .white.opacity(0.3))
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(vm.canAdvance
                                ? Color("neonPurpleBackground")
                                : Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .disabled(!vm.canAdvance)
            }
        }
    }

    // MARK: — Step 1: Details

    @ViewBuilder
    private var detailsStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            formSectionHeader("VENUE NAME")
            formField($vm.name, placeholder: "e.g. Club Noir")

            formSectionHeader("DESCRIPTION")
            TextEditor(text: $vm.venueDescription)
                .font(.subheadline)
                .foregroundStyle(.white)
                .frame(minHeight: 100)
                .padding(12)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .scrollContentBackground(.hidden)

            formSectionHeader("VENUE TYPE")
            venueTypePicker

            formSectionHeader("MAX CAPACITY")
            capacityStepper

            Spacer(minLength: 24)
        }
    }

    private var venueTypePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(VenueType.allCases, id: \.rawValue) { type in
                    let selected = vm.venueType == type
                    Button {
                        vm.venueType = type
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: type.iconName)
                            Text(type.displayName).font(.caption.weight(.medium))
                        }
                        .foregroundStyle(selected ? .white : .white.opacity(0.5))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selected
                                    ? Color("neonPurpleBackground").opacity(0.3)
                                    : Color.white.opacity(0.06))
                        .clipShape(Capsule())
                        .overlay(Capsule()
                            .stroke(selected ? Color("neonPurpleBackground") : .clear, lineWidth: 1))
                    }
                }
            }
        }
    }

    private var capacityStepper: some View {
        HStack {
            Text("\(vm.maxCapacity) guests")
                .font(.subheadline)
                .foregroundStyle(.white)
            Spacer()
            Stepper("", value: $vm.maxCapacity, in: 50...5000, step: 50)
                .labelsHidden()
                .tint(Color("neonPurpleBackground"))
        }
        .padding(12)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: — Step 2: Location

    @ViewBuilder
    private var locationStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            formSectionHeader("VENUE ADDRESS")

            HStack(spacing: 8) {
                formField($vm.address, placeholder: "123 Main St, Gold Coast")
                confirmLocationButton
            }

            if let error = vm.geocodeError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }

            locationMapArea

            Spacer(minLength: 24)
        }
    }

    private var confirmLocationButton: some View {
        Button {
            Task { await vm.geocodeCurrentAddress() }
        } label: {
            if vm.isGeocoding {
                ProgressView().tint(.white)
            } else {
                Image(systemName: "location.magnifyingglass")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color("neonPurpleBackground"))
            }
        }
        .frame(width: 44, height: 44)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .disabled(vm.isGeocoding)
    }

    @ViewBuilder
    private var locationMapArea: some View {
        if let lat = vm.latitude, let lng = vm.longitude {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color("neonPurpleBackground"))
                    Text("Location confirmed")
                        .font(.caption)
                        .foregroundStyle(Color("neonPurpleBackground"))
                }
                LocationMapView(latitude: lat, longitude: lng)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        } else {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .frame(height: 200)
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "map")
                            .font(.system(size: 28))
                            .foregroundStyle(.white.opacity(0.2))
                        Text("Enter address and tap the search icon")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.3))
                    }
                )
        }
    }

    // MARK: — Step 3: Photos & Amenities

    @ViewBuilder
    private var photosStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            formSectionHeader("VENUE PHOTOS")
            Text("Add photos that show your venue's atmosphere (optional)")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))

            PhotoSelectionGrid(selectedImages: $vm.selectedImages)

            // Tap the grid's add button — reuse ImagePicker via closure accumulation
            ImagePicker(image: .constant(nil)) { image in
                vm.selectedImages.append(image)
            }
            .buttonStyle(FilledButtonStyle())

            formSectionHeader("AMENITIES")
            amenityGrid

            Spacer(minLength: 24)
        }
    }

    private var amenityGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            ForEach(Amenity.allCases, id: \.rawValue) { amenity in
                let selected = vm.amenities.contains(amenity)
                Button {
                    if selected {
                        vm.amenities.removeAll { $0 == amenity }
                    } else {
                        vm.amenities.append(amenity)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: amenity.iconName).font(.system(size: 14))
                        Text(amenity.displayName).font(.caption.weight(.medium))
                        Spacer()
                        if selected {
                            Image(systemName: "checkmark").font(.system(size: 11, weight: .bold))
                        }
                    }
                    .foregroundStyle(selected ? .white : .white.opacity(0.5))
                    .padding(10)
                    .background(selected
                                ? Color("neonPurpleBackground").opacity(0.2)
                                : Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(selected ? Color("neonPurpleBackground").opacity(0.5) : .clear, lineWidth: 1))
                }
            }
        }
    }

    // MARK: — Step 4: Review

    @ViewBuilder
    private var reviewStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Review your application before submitting.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))

            reviewCard {
                reviewRow(label: "Name", value: vm.name)
                reviewRow(label: "Type", value: vm.venueType.displayName)
                reviewRow(label: "Capacity", value: "\(vm.maxCapacity) guests")
                reviewRow(label: "Address", value: vm.address)
            }

            reviewCard {
                reviewRow(label: "Photos", value: "\(vm.selectedImages.count) selected")
                reviewRow(label: "Amenities",
                          value: vm.amenities.isEmpty
                              ? "None"
                              : vm.amenities.map(\.displayName).joined(separator: ", "))
            }

            if let error = vm.submissionError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            Text("Approved venues appear on the N3ON map and can host events.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.3))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)

            Spacer(minLength: 24)
        }
    }

    // MARK: — Shared helpers

    private func formSectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color("neonPurpleBackground"))
            .tracking(1.5)
    }

    private func formField(_ binding: Binding<String>, placeholder: String) -> some View {
        TextField("", text: binding, prompt:
            Text(placeholder).foregroundColor(.white.opacity(0.3))
        )
        .font(.subheadline)
        .foregroundStyle(.white)
        .padding(12)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func reviewCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) { content() }
            .padding(16)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func reviewRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
                .frame(width: 80, alignment: .leading)
            Text(value.isEmpty ? "—" : value)
                .font(.subheadline)
                .foregroundStyle(.white)
            Spacer()
        }
    }
}

// MARK: — Non-interactive location pin map

private struct LocationMapView: UIViewRepresentable {
    let latitude: Double
    let longitude: Double

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.isScrollEnabled = false
        map.isZoomEnabled = false
        map.isUserInteractionEnabled = false
        return map
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        let coord = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region = MKCoordinateRegion(
            center: coord,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        mapView.setRegion(region, animated: false)
        mapView.removeAnnotations(mapView.annotations)
        let pin = MKPointAnnotation()
        pin.coordinate = coord
        mapView.addAnnotation(pin)
    }
}
