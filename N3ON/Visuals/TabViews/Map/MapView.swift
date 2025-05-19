//
//  MapView.swift
//  N3ON
//
//  Created by liam howe on 22/6/2024.
//




import SwiftUI
import MapKit
import CoreLocation

struct MapView: View {
    @EnvironmentObject var viewModel: MapViewModel
    @StateObject var chatVM = ChatViewModel()
    @State private var showChatPanel = false
    @State private var unreadMessages = 0
    @FocusState private var isSearchFieldFocused: Bool
    @State private var isEditing = false

    var body: some View {
        ZStack(alignment: .trailing) {
            ZStack(alignment: .top) {
                CustomMapView(
                    region: $viewModel.mapRegion,
                    isSearchFieldFocused: $isSearchFieldFocused,
                    places: viewModel.mapItems,
                    onDoubleTap: handleDoubleTap,
                )
          //      .edgesIgnoringSafeArea(.all)
           //     .ignoresSafeArea(.container, edges: [.top, .bottom])
                .ignoresSafeArea(.container, edges: [.top])
                
                SearchBar(
                    searchText: $viewModel.searchText,
                    isEditing: $isEditing,
                    isSearchFieldFocused: $isSearchFieldFocused
                )
                .environmentObject(viewModel)
                .padding(.top, 50)
                .padding(.horizontal, 16)
            }

            VStack {
                Button {
                    showChatPanel.toggle()
                    if showChatPanel {
                        chatVM.markMessageAsRead()
                        unreadMessages = 0
                    }
                } label: {
                    Image(systemName: "message.badge.filled.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .padding(12)
                        .background {
                            Circle()
                                .fill(Color("neonPurpleBackground"))
                                .shadow(color: .black.opacity(0.3), radius: 5)
                        }
                        .overlay(alignment: .topTrailing) {
                            if unreadMessages > 0 {
                                Text("\(unreadMessages)")
                                    .font(.caption)
                                    .padding(4)
                                    .background(Color.red)
                                    .clipShape(Circle())
                                    .offset(x: 8, y: -8)
                            }
                        }
                }
                .padding(.top, 60)
                .padding(.trailing, 20)
                
                Spacer()
            }

            ChatPanelView(isVisible: $showChatPanel, chatVM: chatVM)
                .offset(x: showChatPanel ? 0 : UIScreen.main.bounds.width)
                .animation(.spring(), value: showChatPanel)
        }
        .onReceive(chatVM.$messages) { messages in
            updateUnreadCount(messages)
        }
    }

    private func handleDoubleTap(_ coordinate: CLLocationCoordinate2D) {
        let newSpan = MKCoordinateSpan(
            latitudeDelta: viewModel.mapRegion.span.latitudeDelta * 0.5,
            longitudeDelta: viewModel.mapRegion.span.longitudeDelta * 0.5
        )
        
        withAnimation(.easeInOut(duration: 0.3)) {
            viewModel.mapRegion = MKCoordinateRegion(
                center: coordinate,
                span: newSpan
            )
        }
        viewModel.searchText = ""
        isSearchFieldFocused = true
    }

    private func updateUnreadCount(_ messages: [Message]) {
        unreadMessages = messages.filter {
            !$0.isRead && $0.sender?.id != chatVM.currentUserID
        }.count
    }
}
