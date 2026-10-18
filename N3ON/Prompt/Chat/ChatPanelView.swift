//
//  ChatPanelView.swift
//  N3ON
//
// The chat inbox that slides over the map. It covers the map's own swipe
// gesture and the chat button, so it must offer its own ways out: a close
// button in the top bar and a swipe right anywhere on the panel.

import SwiftUI

struct ChatPanelView: View {
    var onClose: () -> Void = {}

    var body: some View {
        NavigationStack {
            ChatsInboxView()
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            onClose()
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.headline)
                                .foregroundStyle(Color("neonPurpleBackground"))
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .accessibilityLabel("Close chats")
                    }
                }
        }
        // Swipe right to close. Simultaneous, so lists still scroll vertically
        // and pushed screens keep their own back-swipe.
        .simultaneousGesture(
            DragGesture(minimumDistance: 30, coordinateSpace: .local)
                .onEnded { value in
                    let horizontal = value.translation.width
                    // Swipes from the left edge belong to the navigation
                    // back-gesture (e.g. leaving New Message), not to closing.
                    guard value.startLocation.x > 30,
                          horizontal > 80, abs(value.translation.height) < 60 else { return }
                    onClose()
                }
        )
    }
}
