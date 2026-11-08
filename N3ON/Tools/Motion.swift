//
//  Motion.swift
//  N3ON — Tools layer
//
// The motion system (Prompt/CLAUDE.md §4): every animation curve, duration and
// reusable motion modifier in the app. Views reference these tokens instead of
// writing raw `.spring(...)` / `.easeInOut(...)` values.
//
// Sources: Emil Kowalski, "Agents with taste" (ease-out default, 150–250ms
// dropdowns, exits ~20% faster, press 0.97, popovers from 0.95 at the trigger);
// Apple WWDC23 "Animate with springs" (bounce 0 by default, bounce only at the
// end of a gesture); Rauno Freiberg, "Invisible Details of Interaction Design"
// (gestures track the finger 1:1, motion starts at its trigger); UIScrollView's
// rubber-band curve.
//
// iOS 16 only: no `.snappy` / `.smooth` / `.bouncy` / `.spring(duration:bounce:)`
// / `symbolEffect` / `phaseAnimator` (all iOS 17+). Critically damped springs
// are `.spring(response:dampingFraction: 1.0)`.

import SwiftUI
import UIKit

// MARK: - Tokens

enum Motion {

    // MARK: Durations (seconds)

    /// Micro-interactions: press feedback, small toggles. 100–150ms.
    static let microDuration: Double = 0.15
    /// Dropdowns, popovers, tooltips, inline reveals. 150–250ms.
    static let dropdownDuration: Double = 0.2
    /// Panels, banners, overlays, step changes. 200–300ms.
    static let enterDuration: Double = 0.25
    /// On-screen moves (indicators, progress). Slightly longer — more travel.
    static let moveDuration: Double = 0.3
    /// Exits are 20% shorter than the matching entrance: the user has already
    /// decided, so get out of the way.
    static let exitRatio: Double = 0.8
    static func exitDuration(for enter: Double) -> Double { enter * exitRatio }

    /// Delay between list rows appearing.
    static let staggerStep: Double = 0.03
    /// Rows past this index appear with the last row's delay, so a long list
    /// never makes the user wait (10 rows → 0.3s worst case).
    static let staggerCap = 10
    static func staggerDelay(for index: Int) -> Double {
        Double(min(max(index, 0), staggerCap)) * staggerStep
    }

    // MARK: Scales

    /// Pressed buttons and cards.
    static let pressScale: CGFloat = 0.97
    /// Where popovers, badges and menus start (never from 0).
    static let popoverStartScale: CGFloat = 0.95
    /// Icons cross-fading into each other start/end at this scale.
    static let iconSwapScale: CGFloat = 0.8
    /// Icon cross-fade blur radius (pt). Kept small: under 20px reads as
    /// motion blur, more reads as out-of-focus.
    static let iconSwapBlur: CGFloat = 4
    /// A sliding selection indicator is stretched by this fraction along its
    /// direction of travel at mid-move.
    static let stretchAmount: CGFloat = 0.12
    /// Peak scale of a success pulse.
    static let pulseScale: CGFloat = 1.08

    // MARK: Curves

    /// Strong ease-out (cubic-bezier 0.23, 1, 0.32, 1): fast start, gentle
    /// landing. The default for anything entering or leaving.
    static func enter(_ duration: Double = enterDuration) -> Animation {
        .timingCurve(0.23, 1, 0.32, 1, duration: duration)
    }

    /// Ease-out exit, 20% shorter than the entrance it reverses.
    static func exit(_ enterDuration: Double = enterDuration) -> Animation {
        .timingCurve(0.23, 1, 0.32, 1, duration: exitDuration(for: enterDuration))
    }

    /// Strong ease-in-out (cubic-bezier 0.77, 0, 0.175, 1) for things that
    /// move or morph while staying on screen.
    static func move(_ duration: Double = moveDuration) -> Animation {
        .timingCurve(0.77, 0, 0.175, 1, duration: duration)
    }

    /// Press-down feedback.
    static let press: Animation = .timingCurve(0.23, 1, 0.32, 1, duration: microDuration)

    /// Colour / text / state changes that neither enter nor move.
    static let state: Animation = .easeInOut(duration: enterDuration)

    /// Default interactive spring — critically damped: no overshoot. Everyday
    /// UI does not bounce.
    static let spring: Animation = .spring(response: 0.35, dampingFraction: 1.0)

    /// Release at the end of a drag only. A small bounce (≈10%) reads as the
    /// physical momentum of the throw; Apple keeps bounce for this case.
    static let gestureEnd: Animation = .spring(response: 0.35, dampingFraction: 0.86)

    // MARK: Rubber band

    /// UIScrollView's rubber-band curve: an offset past a bound is resisted
    /// progressively and can never exceed `dimension`.
    /// `(1 − 1 / (x·c / d + 1)) · d`, c = 0.55.
    static func rubberBand(_ offset: CGFloat, dimension: CGFloat, coefficient: CGFloat = 0.55) -> CGFloat {
        guard dimension > 0, offset != 0 else { return 0 }
        let x = abs(offset)
        let resisted = (1 - 1 / (x * coefficient / dimension + 1)) * dimension
        return offset < 0 ? -resisted : resisted
    }

    /// Clamps `value` to `range`; any overshoot is rubber-banded instead of cut.
    static func rubberBanded(_ value: CGFloat, in range: ClosedRange<CGFloat>, dimension: CGFloat) -> CGFloat {
        if value < range.lowerBound {
            return range.lowerBound + rubberBand(value - range.lowerBound, dimension: dimension)
        }
        if value > range.upperBound {
            return range.upperBound + rubberBand(value - range.upperBound, dimension: dimension)
        }
        return value
    }
}

// MARK: - Press feedback

/// Scales the label to 0.97 while pressed. Replaces `.plain` on custom-drawn
/// buttons so every tappable surface acknowledges the touch.
struct PressableButtonStyle: ButtonStyle {
    var scale: CGFloat = Motion.pressScale

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(Motion.press, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableButtonStyle {
    /// `.buttonStyle(.pressable)` — see `PressableButtonStyle`.
    static var pressable: PressableButtonStyle { PressableButtonStyle() }
}

// MARK: - Transitions

private struct BlurEffectModifier: ViewModifier {
    let radius: CGFloat
    func body(content: Content) -> some View { content.blur(radius: radius) }
}

extension AnyTransition {

    /// Popovers, badges, inline reveals: start at 0.95 + transparent, scaled
    /// toward `anchor` — put the anchor on the side of the trigger, so the
    /// element grows out of it and shrinks back into it. Exit 20% shorter.
    static func popover(anchor: UnitPoint = .center) -> AnyTransition {
        let base = AnyTransition.scale(scale: Motion.popoverStartScale, anchor: anchor).combined(with: .opacity)
        return .asymmetric(
            insertion: base.animation(Motion.enter(Motion.dropdownDuration)),
            removal: base.animation(Motion.exit(Motion.dropdownDuration))
        )
    }

    /// Panels and banners that come in from (and leave toward) an edge.
    /// Always paired with opacity: movement alone reads as clipping.
    static func edgeReveal(_ edge: Edge) -> AnyTransition {
        let base = AnyTransition.move(edge: edge).combined(with: .opacity)
        return .asymmetric(
            insertion: base.animation(Motion.enter()),
            removal: base.animation(Motion.exit())
        )
    }

    /// Icon replacement: the old and new icon overlap, each cross-fading
    /// through a slight blur and scale so the swap reads as one morph rather
    /// than a cut. Give the icon `.id(name)` so SwiftUI sees a replacement.
    static var iconSwap: AnyTransition {
        .opacity
            .combined(with: .scale(scale: Motion.iconSwapScale))
            .combined(with: .modifier(
                active: BlurEffectModifier(radius: Motion.iconSwapBlur),
                identity: BlurEffectModifier(radius: 0)
            ))
    }
}

/// An SF Symbol that cross-fades (with blur) when `systemName` changes.
/// Font and foreground style set outside apply to the image.
struct SwapIcon: View {
    let systemName: String

    init(_ systemName: String) { self.systemName = systemName }

    var body: some View {
        ZStack {
            Image(systemName: systemName)
                .id(systemName)
                .transition(.iconSwap)
        }
        .animation(Motion.state, value: systemName)
    }
}

// MARK: - Sliding selection indicator

/// Scales a view horizontally by up to `amount` at the midpoint of each move,
/// and back to 1 at rest. `progress` counts moves; its fractional part is how
/// far through the current move the animation is.
struct StretchEffect: GeometryEffect {
    var progress: Double
    var amount: CGFloat

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    /// 1 at rest, 1 + amount half-way through a move.
    static func scale(progress: Double, amount: CGFloat) -> CGFloat {
        let phase = progress - progress.rounded(.down)
        return 1 + amount * CGFloat(sin(Double.pi * phase))
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let sx = Self.scale(progress: progress, amount: amount)
        let transform = CGAffineTransform(translationX: size.width / 2, y: 0)
            .scaledBy(x: sx, y: 1)
            .translatedBy(x: -size.width / 2, y: 0)
        return ProjectionTransform(transform)
    }
}

private struct SlidingIndicatorModifier<ID: Hashable, Indicator: View>: ViewModifier {
    let selection: ID
    let namespace: Namespace.ID
    let indicator: Indicator

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var moves: Double = 0

    func body(content: Content) -> some View {
        content
            .background {
                indicator
                    .modifier(StretchEffect(progress: moves, amount: reduceMotion ? 0 : Motion.stretchAmount))
                    .matchedGeometryEffect(id: selection, in: namespace, isSource: false)
                    .animation(Motion.move(), value: selection)
                    .allowsHitTesting(false)
            }
            .onChangeCompat(of: selection) { _, _ in
                withAnimation(Motion.move()) { moves += 1 }
            }
    }
}

extension View {
    /// Marks this view (one per option) as a place the indicator can sit.
    func slidingIndicatorAnchor<ID: Hashable>(_ id: ID, in namespace: Namespace.ID) -> some View {
        matchedGeometryEffect(id: id, in: namespace, isSource: true)
    }

    /// Draws ONE persistent indicator behind the anchors, which slides
    /// (ease-in-out) to the selected anchor and stretches while it travels.
    /// One view reused across states — not one per option fading in and out.
    /// Declare the `@Namespace` in the owning view.
    func slidingIndicator<ID: Hashable, Indicator: View>(
        selection: ID,
        in namespace: Namespace.ID,
        @ViewBuilder indicator: () -> Indicator
    ) -> some View {
        modifier(SlidingIndicatorModifier(selection: selection, namespace: namespace, indicator: indicator()))
    }
}

// MARK: - Stagger

private struct StaggeredAppearModifier: ViewModifier {
    let index: Int
    let isVisible: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible || reduceMotion ? 0 : 8)
            .animation(
                Motion.enter().delay(reduceMotion ? 0 : Motion.staggerDelay(for: index)),
                value: isVisible
            )
    }
}

private struct StaggerTriggerModifier: ViewModifier {
    let hasContent: Bool
    @Binding var isVisible: Bool

    func body(content: Content) -> some View {
        content
            .onAppear { if hasContent { isVisible = true } }
            .onChangeCompat(of: hasContent) { _, has in if has { isVisible = true } }
    }
}

extension View {
    /// A list row that fades and rises in, 30ms after the row above it.
    /// `isVisible` comes from the parent (see `staggerTrigger`), so rows that a
    /// lazy list re-creates while scrolling do not animate again.
    func staggeredAppear(index: Int, isVisible: Bool) -> some View {
        modifier(StaggeredAppearModifier(index: index, isVisible: isVisible))
    }

    /// Flips `isVisible` to true the first time the list has rows — on appear,
    /// or when its data arrives. Never flips it back.
    func staggerTrigger(hasContent: Bool, isVisible: Binding<Bool>) -> some View {
        modifier(StaggerTriggerModifier(hasContent: hasContent, isVisible: isVisible))
    }
}

// MARK: - Success pulse

private struct SuccessPulseModifier<Trigger: Equatable>: ViewModifier {
    let trigger: Trigger
    let haptic: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var scale: CGFloat = 1
    /// Bumped per pulse; `.task(id:)` runs the up-then-settle sequence and
    /// cancels it if the view goes away or another pulse starts.
    @State private var pulses = 0

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onChangeCompat(of: trigger) { _, _ in
                if haptic { UINotificationFeedbackGenerator().notificationOccurred(.success) }
                pulses += 1
            }
            .task(id: pulses) {
                guard pulses > 0, !reduceMotion else { return }
                withAnimation(Motion.enter(Motion.microDuration)) { scale = Motion.pulseScale }
                try? await Task.sleep(nanoseconds: UInt64(Motion.microDuration * 1_000_000_000))
                withAnimation(Motion.move(Motion.dropdownDuration)) { scale = 1 }
            }
    }
}

extension View {
    /// A brief scale pulse (1 → 1.08 → 1) plus a success haptic each time
    /// `trigger` changes — the confirmation that an action worked. In a loud
    /// venue the haptic is the part that gets noticed.
    func successPulse<Trigger: Equatable>(trigger: Trigger, haptic: Bool = true) -> some View {
        modifier(SuccessPulseModifier(trigger: trigger, haptic: haptic))
    }
}
