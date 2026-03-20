# N3ON — Tools Layer

This file loads automatically for any file under `N3ON/Tools/`. Tools contains reusable view modifiers, pickers, extensions, and utilities. No imports from this project. May import SwiftUI.

> You are building the toolkit that every view reaches for. Consistency lives here — one `onChangeCompat`, one colour definition, one picker contract. If a pattern appears in two views, it belongs here. If it appears in one view only, it does not. The test for a Tool is: could any screen in this app use it without knowing where it came from?
>
> Two sources shape how this layer is written:
> - **swiftwithmajid.com — "@ViewBuilder in SwiftUI"**: `@ViewBuilder` enables DSL-like container views with variable content. Use it for components with consistent chrome but flexible interiors — a styled card that accepts any content, a labelled section that accepts any rows. Keep `TupleView` in mind: you get up to 10 direct children before needing a nested container.
> - **swiftbysundell.com — "The Lifecycle and Semantics of a SwiftUI View"**: `UIViewRepresentable` must always implement `updateUIView` — never leave it as a no-op. The system calls it on every state change; an empty implementation means your wrapped UIKit view silently falls out of sync. `makeUIView` creates once; `updateUIView` keeps it correct.

---

## Import rules

```swift
import SwiftUI      // ✅
import UIKit        // ✅ for UIViewControllerRepresentable
import Foundation   // ✅
import MapKit       // ✅ for map utilities
// ❌ any import from N3ON project files
```

---

## `onChangeCompat` — never use `.onChange` directly

`.onChange(of:) { newValue in }` is deprecated in iOS 17 and unavailable correctly in iOS 16.

```swift
// ✅ — always
.onChangeCompat(of: searchText) { _, new in
    Task { await vm.search(new) }
}

// ❌ — deprecated, breaks on iOS 16
.onChange(of: searchText) { newText in ... }
```

---

## Available pickers — check here before creating a new one

| Picker | File | Binds |
|--------|------|-------|
| `ImagePicker` | `Tools/ImagePicker.swift` | Single `UIImage` |
| `MixedMediaPicker` | `Tools/MixedMediaPicker.swift` | Images + video |
| `AudioPicker` | `Tools/AudioPicker.swift` | Audio file URL |

Never reference a picker that isn't in this table. If a new one is needed, create it here as `UIViewControllerRepresentable`.

### `ImagePicker` API — single image only

```swift
// ✅ — one image at a time; accumulate in a closure
@State private var pickedImage: UIImage?
@State private var images: [UIImage] = []

ImagePicker(image: $pickedImage) { image in
    images.append(image)
}

// ❌ — does not accept an array binding
ImagePicker(selectedImages: $images)
```

---

## Colour — always go through `Colour.swift`

`Color.customDarkGray` is defined here. Never use `Color("appDarkGray")` string literals in views.

Never name a color asset the same as a `UIColor` class property (`darkGray`, `lightGray`, `red`, `blue`). It generates a `#warning` in `GeneratedAssetSymbols.swift` on every build.

```swift
// ✅
Color.customDarkGray

// ❌ — string literal bypasses the type-safe extension
Color("appDarkGray")

// ❌ — "appDarkGray" asset named "darkGray" would clash with UIColor.darkGray
```

---

## `ViewModifier` — when to create one *(swiftwithmajid.com)*

Create a `ViewModifier` when:
- The same combination of modifiers (3+) appears on multiple view types
- The styling has a conceptual name ("neon glow", "lifted card", "section header anchor")
- The modifier needs its own `@State` or `@Environment`

Keep it inline when:
- It's a one-off on a single view
- It's fewer than 3 chained modifiers

```swift
// ✅ — named, reusable, semantically clear
struct NeonGlowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: Color("neonPurpleBackground").opacity(0.55), radius: 18)
            .shadow(color: Color("neonPurpleBackground").opacity(0.85), radius: 5)
    }
}

extension View {
    func neonGlow() -> some View { modifier(NeonGlowModifier()) }
}
```

---

## `@ViewBuilder` — container views with flexible content *(swiftwithmajid.com)*

Use `@ViewBuilder` when building a styled container whose content varies at call sites:

```swift
// ✅ — @ViewBuilder parameter for flexible interiors
struct SectionCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline).foregroundStyle(.white)
            content()
        }
        .padding()
        .background(Color.customDarkGray)
        .cornerRadius(12)
    }
}
```

**10-child limit**: `@ViewBuilder`'s `buildBlock` accepts up to 10 direct children. If a caller needs more, wrap in a nested `VStack` or `Group`.

---

## `UIViewRepresentable` — always implement `updateUIView` *(swiftbysundell.com)*

```swift
// ✅
struct MyMapView: UIViewRepresentable {
    var region: MKCoordinateRegion

    func makeUIView(context: Context) -> MKMapView { MKMapView() }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        // Always update — called on every state change
        if uiView.region.center.latitude != region.center.latitude {
            uiView.setRegion(region, animated: true)
        }
    }
}

// ❌ — silent desync: the map never reflects new state
func updateUIView(_ uiView: MKMapView, context: Context) { }
```

---

## Tap target minimum — 44×44 pt

Any interactive control smaller than 44×44 pt needs an explicit hit area:

```swift
// ✅
Image(systemName: "xmark")
    .frame(width: 44, height: 44)
    .contentShape(Rectangle())
    .onTapGesture { ... }
```

---

## `@ViewBuilder` computed properties to prevent type-check timeouts

When Xcode reports "unable to type-check this expression in reasonable time", the `body` is too large. Extract into `@ViewBuilder` computed properties:

```swift
// ✅
var body: some View {
    VStack { headerSection; contentSection; footerSection }
}

@ViewBuilder private var headerSection: some View { ... }
@ViewBuilder private var contentSection: some View { ... }
```

---

## What to avoid

- Importing project files — Tools is infrastructure, it has no knowledge of N3ON's domain
- `import SwiftUI` in files that don't need it (pure `Foundation` utilities)
- Creating a picker wrapper that duplicates one already in this layer
- Using `.onChange` directly — always `onChangeCompat`
- Storing state or making async calls inside a `ViewModifier` without wrapping in `.task`
