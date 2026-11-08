//
//  ChatPanelView.swift
//  N3ON
//
// The chat inbox that slides over the map. It covers the map's own swipe
// gesture and the chat button, so it must offer its own ways out: a close
// button in the top bar and a swipe right anywhere on the panel.

import SwiftUI

struct ChatPanelView: View {
    /// How far the panel travels between open and closed.
    let panelWidth: CGFloat
    /// True while the panel is open or being dragged open. The inbox uses it to
    /// cascade its rows in when the panel arrives (the panel is always rendered,
    /// so "on appear" would fire at app launch, off screen).
    var isActive: Bool = true
    /// Closes the panel. The caller wraps it in the animation it wants.
    var onClose: () -> Void = {}

    /// One close-drag: its direction, decided once at the start so a vertical
    /// scroll of the inbox never moves the panel sideways, and its live offset.
    struct CloseDrag {
        var axis: Axis?
        var offset: CGFloat = 0
    }

    /// @GestureState: resets itself — springing the panel back — when the drag
    /// ends OR is cancelled, so a lost touch can't leave it part-way closed.
    @GestureState(resetTransaction: SwiftUI.Transaction(animation: Motion.gestureEnd))
    private var closeDrag = CloseDrag()

    var body: some View {
        NavigationStack {
            ChatsInboxView(isActive: isActive)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(Motion.exit()) { onClose() }   // DESIGN §4 exit, 20% shorter
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
        // Follows the finger 1:1 while held (no animation — DESIGN §4: don't
        // tween while held); dragging left past fully open rubber-bands.
        .offset(x: closeDrag.offset)
        // Swipe right to close. Simultaneous, so lists still scroll vertically
        // and pushed screens keep their own back-swipe.
        .simultaneousGesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .local)
                .updating($closeDrag) { value, drag, _ in
                    drag = Self.track(drag, start: value.startLocation,
                                      translation: value.translation, panelWidth: panelWidth)
                }
                .onEnded { value in
                    // closeDrag has already reset (and is springing back); decide
                    // from the whole drag. Closing animates the resting position
                    // on the same spring, so the panel continues from the finger.
                    guard Self.closes(start: value.startLocation, translation: value.translation,
                                      predicted: value.predictedEndTranslation,
                                      panelWidth: panelWidth) else { return }
                    withAnimation(Motion.gestureEnd) { onClose() }   // DESIGN §4 gesture-end spring
                }
        )
    }

    // MARK: - Gesture rules (pure, unit-tested)

    /// Swipes from the left edge (first 30pt) belong to the navigation
    /// back-gesture (e.g. leaving New Message), not to closing the panel.
    static func axis(start: CGPoint, translation: CGSize) -> Axis {
        let horizontal = abs(translation.width) > abs(translation.height)
        return (start.x > 30 && horizontal) ? .horizontal : .vertical
    }

    /// Next drag state: the axis locks on the first update; only a horizontal
    /// drag moves the panel, rubber-banded past fully open (offset < 0).
    static func track(_ drag: CloseDrag, start: CGPoint, translation: CGSize, panelWidth: CGFloat) -> CloseDrag {
        var next = drag
        if next.axis == nil { next.axis = axis(start: start, translation: translation) }
        guard next.axis == .horizontal else { return next }
        next.offset = Motion.rubberBanded(translation.width, in: 0...panelWidth, dimension: panelWidth)
        return next
    }

    /// A deliberate rightward swipe: horizontal overall, and either far enough
    /// (80pt) or flicked hard enough to land past 40% of the panel.
    static func closes(start: CGPoint, translation: CGSize, predicted: CGSize, panelWidth: CGFloat) -> Bool {
        guard axis(start: start, translation: translation) == .horizontal else { return false }
        return translation.width > 80 || predicted.width > panelWidth * 0.4
    }
}
