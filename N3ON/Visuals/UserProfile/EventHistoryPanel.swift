//
//  EventHistoryPanel.swift
//  N3ON
//
//  Created by liam howe on 2/7/2025.
//

import SwiftUI

struct EventHistoryPanel: View {
    @Binding var isVisible: Bool
    @ObservedObject var historyVM: EventHistoryViewModel
    @State private var translation: CGSize = .zero
    
    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topTrailing) {
                // Main content area
                VStack(spacing: 0) {
                    // Header with title and close button
                    header
                    
                    // Event history list
                    EventHistoryListView(
                        events: historyVM.events,
                        isLoading: historyVM.isLoading,
                        errorMessage: historyVM.errorMessage
                    )
                }
                .background(Color("darkGray"))
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.2), radius: 20)
                
                // Drag handle indicator at top
                Capsule()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 40, height: 5)
                    .padding(.top, 8)
            }
            .offset(x: max(translation.width, 0))
            .gesture(dragGesture)
        }
        .frame(width: UIScreen.main.bounds.width * 0.85)
    }
    
    private var header: some View {
        HStack {
            Text("Event History")
                .font(.title3.weight(.semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            Button {
                withAnimation {
                    isVisible = false
                }
            } label: {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(Color("darkerGray"))
                            .shadow(radius: 3)
                    )
            }
        }
        .padding()
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                translation = value.translation
            }
            .onEnded { value in
                if value.translation.width > 100 {
                    withAnimation {
                        isVisible = false
                    }
                }
                translation = .zero
            }
    }
}

struct EventHistoryListView: View {
    var events: [EventHistory]
    var isLoading: Bool
    var errorMessage: String?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading Events...")
                    .padding()
                    .frame(maxHeight: .infinity)
            } else if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
                    .frame(maxHeight: .infinity)
            } else if events.isEmpty {
                Text("No past events")
                    .foregroundColor(.white.opacity(0.6))
                    .padding()
                    .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        ForEach(events.sorted(by: { $0.date > $1.date })) { event in
                            EventHistoryCard(event: event)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.top)
                    .padding(.bottom, 20) // Bottom padding for scroll space
                }
            }
        }
    }
}

struct EventHistoryCard: View {
    let event: EventHistory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Event poster
            AsyncImage(url: URL(string: event.posterURL)) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(3/4, contentMode: .fill)
                } else if phase.error != nil {
                    Color.gray.opacity(0.3)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.white)
                        )
                } else {
                    ProgressView()
                }
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            // Event details
            VStack(alignment: .leading, spacing: 8) {
                Text(event.title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .foregroundColor(Color("neonPurpleBackground"))
                    
                    Text(event.date, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text("•")
                        .foregroundColor(.gray)
                    
                    Text(event.date, style: .time)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(Color("neonPurpleBackground"))
                    
                    Text(event.venue)
                        .font(.subheadline)
                        .foregroundColor(Color("neonPurpleBackground"))
                }
            }
            
            // Attending DJs section
            if !event.attendingDJs.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("DJs at this event")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(event.attendingDJs) { dj in
                                VStack(spacing: 4) {
                                    AsyncImage(url: URL(string: dj.avatarURL)) { phase in
                                        if let image = phase.image {
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } else if phase.error != nil {
                                            Circle()
                                                .fill(Color.gray.opacity(0.3))
                                                .overlay(
                                                    Image(systemName: "person.fill")
                                                        .foregroundColor(.white)
                                                )
                                        } else {
                                            ProgressView()
                                        }
                                    }
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color("neonPurpleBackground"), lineWidth: 2)
                                    )
                                    
                                    Text(dj.username)
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                        .frame(width: 70)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(Color("darkerGray"))
        .cornerRadius(12)
    }
}

// MARK: - View Models
class EventHistoryViewModel: ObservableObject {
    @Published var events: [EventHistory] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    func loadAttendanceHistory(for userId: String) {
        isLoading = true
        errorMessage = nil
        
        // In real app, this would be an async network call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.events = [
                EventHistory(
                    id: "1",
                    title: "Neon Nights Festival",
                    venue: "Club Neon",
                    date: Date().addingTimeInterval(-86400 * 7),
                    posterURL: "https://picsum.photos/300/400?event1",
                    attendingDJs: [
                        DJUser(id: "dj1", username: "@luna", avatarURL: "https://picsum.photos/60"),
                        DJUser(id: "dj2", username: "@zara", avatarURL: "https://picsum.photos/61")
                    ]
                ),
                EventHistory(
                    id: "2",
                    title: "Bass Revolution",
                    venue: "The Bass Arena",
                    date: Date().addingTimeInterval(-86400 * 14),
                    posterURL: "https://picsum.photos/300/401?event2",
                    attendingDJs: [
                        DJUser(id: "dj3", username: "@nova", avatarURL: "https://picsum.photos/62")
                    ]
                ),
                EventHistory(
                    id: "3",
                    title: "Synthwave Experience",
                    venue: "Retro Lounge",
                    date: Date().addingTimeInterval(-86400 * 30),
                    posterURL: "https://picsum.photos/300/402?event3",
                    attendingDJs: [
                        DJUser(id: "dj1", username: "@luna", avatarURL: "https://picsum.photos/60"),
                        DJUser(id: "dj4", username: "@ryo", avatarURL: "https://picsum.photos/63")
                    ]
                )
            ]
            self.isLoading = false
        }
    }
}

struct EventHistory: Identifiable {
    let id: String
    let title: String
    let venue: String
    let date: Date
    let posterURL: String
    let attendingDJs: [DJUser]
}

struct DJUser: Identifiable {
    let id: String
    let username: String
    let avatarURL: String
}

// MARK: - Preview
struct EventHistoryPanel_Previews: PreviewProvider {
    static var previews: some View {
        let vm = EventHistoryViewModel()
        vm.events = [
            EventHistory(
                id: "1",
                title: "Neon Nights Festival",
                venue: "Club Neon",
                date: Date(),
                posterURL: "https://picsum.photos/300/400?event1",
                attendingDJs: [
                    DJUser(id: "dj1", username: "@luna", avatarURL: "https://picsum.photos/60"),
                    DJUser(id: "dj2", username: "@zara", avatarURL: "https://picsum.photos/61")
                ]
            )
        ]
        
        return ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            EventHistoryPanel(
                isVisible: .constant(true),
                historyVM: vm
            )
        }
        .preferredColorScheme(.dark)
    }
}
