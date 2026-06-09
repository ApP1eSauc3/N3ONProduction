// VenueProfileView.swift
// N3ON — Prompt layer
// Venue owner's profile: shows their venue, events, gallery, and settings.
// All state owned by VenueProfileViewModel.

import SwiftUI
import PhotosUI

struct VenueProfileView: View {
    @StateObject private var vm = VenueProfileViewModel()
    @State private var selectedTab: VenueTab = .events
    @State private var pickedGalleryItem: PhotosPickerItem? = nil
    @State private var showApplicationForm = false

    enum VenueTab: String, CaseIterable {
        case events = "Events"
        case gallery = "Gallery"
        case settings = "Settings"
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                // DESIGN §5.1 — purple hero zone
                Color("dullPurple").ignoresSafeArea()
                RadialGradient(
                    colors: [Color("neonPurpleBackground").opacity(0.45), .clear],
                    center: .init(x: 0.5, y: 0.0),
                    startRadius: 0,
                    endRadius: geo.size.width * 0.87
                )
                .frame(height: geo.size.height * 0.35)
                .ignoresSafeArea(edges: .top)

                // Black anchor
                VStack {
                    Spacer()
                    Color.black
                        .frame(height: geo.size.height * 0.68)
                        .ignoresSafeArea(edges: .bottom)
                }

                if vm.isLoading {
                    ProgressView().tint(Color("neonPurpleBackground"))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if vm.venue == nil {
                    noVenueView
                } else {
                    mainContent(geo: geo)
                }
            }
        }
        .task { await vm.load() }
        .sheet(isPresented: $showApplicationForm) {
            NavigationStack { VenueApplicationForm() }
        }
        .onChangeCompat(of: pickedGalleryItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await vm.uploadGalleryImage(image)
                }
            }
        }
    }

    // MARK: — No venue yet

    private var noVenueView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "building.2")
                .font(.system(size: 52))
                .foregroundStyle(Color("neonPurpleBackground").opacity(0.6))
            Text("No Venue Yet")
                .font(.system(.title2, design: .rounded, weight: .semibold))
                .foregroundStyle(.white)
            Text("Submit an application to list your venue on N3ON.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Apply for a Venue") {
                showApplicationForm = true
            }
            .buttonStyle(FilledButtonStyle())
            .padding(.horizontal, 32)
            Spacer()
        }
    }

    // MARK: — Main content

    private func mainContent(geo: GeometryProxy) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                heroSection
                    .padding(.top, 16)
                    .padding(.bottom, 24)

                // Neon dock line — DESIGN §3.5
                Rectangle()
                    .fill(LinearGradient(
                        colors: [.clear, Color("neonPurpleBackground"), Color("neonPurpleBackground"), .clear],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .frame(height: 1.5)
                    .shadow(color: Color("neonPurpleBackground"), radius: 10, y: 4)
                    .shadow(color: Color("neonPurpleBackground").opacity(0.3), radius: 4, y: 2)

                // Black content card
                VStack(spacing: 0) {
                    tabBar
                        .padding(.top, 20)
                    tabContent
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .frame(minHeight: geo.size.height * 0.6)
                }
                .background(Color.black)
            }
        }
    }

    // MARK: — Hero

    private var heroSection: some View {
        VStack(spacing: 16) {
            // Venue avatar
            PulsingAvatarView(
                state: vm.avatarState,
                audioKey: nil,
                size: 88,
                fromMemoryCache: false
            )

            // Venue name + status
            VStack(spacing: 6) {
                Text(vm.venue?.name ?? "")
                    .font(.system(.title2, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white)

                HStack(spacing: 6) {
                    Circle()
                        .fill(vm.isApproved ? Color("neonPurpleBackground") : Color.white.opacity(0.3))
                        .frame(width: 6, height: 6)
                    Text(vm.approvalStatus.capitalized)
                        .font(.caption)
                        .foregroundStyle(vm.isApproved ? Color("neonPurpleBackground") : .white.opacity(0.5))
                }
            }

            // Quick stats
            HStack(spacing: 32) {
                statPill(value: "\(vm.eventCount)", label: "Events")
                statPill(value: "\(vm.capacity)", label: "Capacity")
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func statPill(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    // MARK: — Tab bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(VenueTab.allCases, id: \.rawValue) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) { selectedTab = tab }
                } label: {
                    VStack(spacing: 6) {
                        Text(tab.rawValue)
                            .font(.subheadline.weight(selectedTab == tab ? .semibold : .regular))
                            .foregroundStyle(selectedTab == tab ? .white : .white.opacity(0.4))
                        Rectangle()
                            .fill(selectedTab == tab ? Color("neonPurpleBackground") : .clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: — Tab content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .events:   eventsTab
        case .gallery:  galleryTab
        case .settings: settingsTab
        }
    }

    // MARK: — Events tab

    private var eventsTab: some View {
        Group {
            if vm.upcomingEvents.isEmpty {
                emptyTabMessage(
                    icon: "calendar.badge.plus",
                    text: vm.isApproved
                        ? "No upcoming events. DJs can apply to host events at your venue."
                        : "Events are unlocked once your venue is approved."
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(vm.upcomingEvents, id: \.id) { event in
                        venueEventRow(event)
                    }
                }
            }
        }
    }

    private func venueEventRow(_ event: Event) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.eventName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(event.eventDate.foundationDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
            Text("\(event.availableTickets) tickets")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.4))
        }
        .padding(12)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: — Gallery tab

    private var galleryTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            PhotosPicker(selection: $pickedGalleryItem, matching: .images) {
                HStack(spacing: 8) {
                    if vm.isUploadingGallery {
                        ProgressView().tint(.white)
                        Text("Uploading…")
                    } else {
                        Image(systemName: "plus.circle")
                        Text("Add Photo")
                    }
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color("neonPurpleBackground"))
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Color("neonPurpleBackground").opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .disabled(vm.isUploadingGallery)

            if vm.galleryKeys.isEmpty {
                emptyTabMessage(icon: "photo.on.rectangle", text: "No photos yet. Add some to show your venue.")
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
                    ForEach(vm.galleryKeys, id: \.self) { key in
                        AsyncStorageImage(storageKey: key, contentMode: .fill)
                            .frame(height: 110)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                }
            }
        }
    }

    // MARK: — Settings tab

    private var settingsTab: some View {
        VenueSettingsForm(vm: vm)
    }

    // MARK: — Helpers

    private func emptyTabMessage(icon: String, text: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(.white.opacity(0.2))
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.4))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}

// MARK: — Settings form (extracted to avoid type-check timeout)

private struct VenueSettingsForm: View {
    @ObservedObject var vm: VenueProfileViewModel
    @State private var editName: String = ""
    @State private var editDescription: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            settingsField(label: "VENUE NAME", binding: $editName)
            settingsField(label: "DESCRIPTION", binding: $editDescription, multiline: true)

            if let error = vm.saveError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }

            Button {
                Task { await vm.saveChanges(name: editName, description: editDescription) }
            } label: {
                if vm.isSaving {
                    ProgressView().tint(.white)
                } else {
                    Text("Save Changes").font(.headline).foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(Color("neonPurpleBackground"))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .disabled(vm.isSaving)

            NavigationLink(destination: VenueComplianceForm(venueID: vm.venue?.id ?? "")) {
                HStack {
                    Image(systemName: "checkmark.shield")
                    Text("Compliance Documents")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .padding(12)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            Spacer()
        }
        .onAppear {
            editName = vm.venue?.name ?? ""
            editDescription = vm.venue?.description ?? ""
        }
    }

    @ViewBuilder
    private func settingsField(label: String, binding: Binding<String>, multiline: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color("neonPurpleBackground"))
                .tracking(1.5)
            if multiline {
                TextEditor(text: binding)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .frame(minHeight: 80)
                    .padding(10)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .scrollContentBackground(.hidden)
            } else {
                TextField("", text: binding, prompt:
                    Text("Enter \(label.lowercased())").foregroundColor(.white.opacity(0.3))
                )
                .font(.subheadline)
                .foregroundStyle(.white)
                .padding(12)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
    }
}
