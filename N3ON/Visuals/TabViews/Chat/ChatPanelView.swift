//
//  ChatPanelView.swift
//  N3ON
//
//  Created by liam howe on 27/4/2025.
//

// File: ChatPanelView.swift

import SwiftUI

struct ChatPanelView: View {
    @Binding var isVisible: Bool
    @ObservedObject var chatVM: ChatViewModel
    @State private var translation: CGSize = .zero
    @State private var lastMessageID: String?
    
    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topTrailing) {
                // Chat content
                VStack(spacing: 0) {
                    header  // Fixed: lowercase 'h' to match variable name
                    
                    // Chat messages
                    ScrollViewReader { scrollProxy in
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(chatVM.messages.map {
                                    ChatMessage(from: $0, currentUserID: chatVM.currentUserID)
                                }) { message in
                                    MessageRow(message: message)
                                        .padding(.horizontal)
                                        .id(message.id)
                                }
                            }
                        }
                        // Fixed onChange syntax
                        .onChange(of: chatVM.messages) { newMessages in
                            guard let newLast = newMessages.last?.id else { return }
                            if newLast != lastMessageID {
                                lastMessageID = newLast
                                scrollToBottom(proxy: scrollProxy)
                            }
                        }
                    }
                    
                    inputArea
                }
                .background(Color.black)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.2), radius: 20)
                
                // Drag handle
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
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard let lastMessage = chatVM.messages.last else { return }
        withAnimation {
            proxy.scrollTo(lastMessage.id, anchor: .bottom)
        }
    }
    
    private var header: some View {
        HStack {
            Text("Event Chats")
                .font(.title3.weight(.semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            Button {
                isVisible = false
            } label: {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(Color("darkGray"))
                            .shadow(radius: 3)
                    )
            }
        }
        .padding()
    }
    
    private var inputArea: some View {
        HStack {
            TextField("Type a message...", text: $chatVM.messageText)
                .padding(12)
                .background(Color.black.opacity(0.8))
                .cornerRadius(12)
                .foregroundColor(.white)
            
            Button(action: chatVM.sendMessage) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.white)
                    .padding(10)
                    .background(
                        Color("neonPurpleBackground")
                            .cornerRadius(12)
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
                    isVisible = false
                }
                translation = .zero
            }
    }
}
