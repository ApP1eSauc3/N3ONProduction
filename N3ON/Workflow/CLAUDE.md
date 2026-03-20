# N3ON — Workflow Layer

This file loads automatically for any file under `N3ON/Workflow/`. Workflow contains `ObservableObject` ViewModels. They orchestrate Task services and publish state to views. They never import SwiftUI.

> You are writing the state machines of this app. A ViewModel is a projection of domain data into displayable state — nothing more. It does not know what a `Text` or `Button` is. It does not make layout decisions. It answers one question: "given what I know about the world, what should the UI show right now?"
>
> Two sources shape how this layer is written:
> - **swiftbysundell.com — "The Lifecycle and Semantics of a SwiftUI View"**: Views are value types — descriptions of UI, not the UI itself. The ViewModel owns domain state; the View owns presentation state. Never blend the two. Side effects (fetching, subscriptions) belong in `.task` and `.onAppear` modifiers, not in `body` computation. A ViewModel that reaches into view layout is a ViewModel that's doing two jobs.
> - **avanderlee.com — "@MainActor usage in Swift"**: Marking an entire `ObservableObject` class `@MainActor` guarantees all `@Published` mutations happen on the main thread without sprinkling `DispatchQueue.main.async` everywhere. Async functions called from background contexts automatically hop to the main actor. This is the correct pattern for iOS 16+ — not a shortcut.

---

## Import rules

```swift
import Foundation
import Amplify      // ✅
import UIKit        // ✅ for UIImage, UIActivityViewController, etc.
import Combine      // ✅ when needed for publishers
// ❌ import SwiftUI — never
```

---

## ViewModel structure — canonical pattern

```swift
// ✅
@MainActor
final class FooViewModel: ObservableObject {
    @Published var items: [Item] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            items = try await SomeService.fetchItems()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

**Rules:**
- Always `@MainActor` on the class declaration — not on individual methods
- Always `final` — ViewModels are not designed for inheritance
- `isLoading = true` + `defer { isLoading = false }` — never leave a loading state stranded
- `@Published` on every property the view observes — nothing else

---

## `@Published` rules *(derived from Swift documentation)*

`@Published` uses `mutating set` — it is **only valid inside `ObservableObject` classes**.

```swift
// ✅ — inside ObservableObject class
@Published var isLoading = false

// ❌ — inside a View struct: "@Published is only available on properties of classes"
@Published var isLoading = false
// Use @State instead
```

---

## `@MainActor` — why the whole class, not individual methods

Marking the class `@MainActor` means:
- All `@Published` mutations are guaranteed on the main thread
- Async functions called from background tasks automatically hop back
- No manual `DispatchQueue.main.async` or `await MainActor.run` needed

```swift
// ✅ — whole class marked
@MainActor
final class EventViewModel: ObservableObject {
    func load() async { /* safe to mutate @Published here */ }
}

// ❌ — individual method marking misses background-initiated mutations
final class EventViewModel: ObservableObject {
    @MainActor func load() async { ... }
    // but what if something else mutates @Published from a Task?
}

// ❌ — DispatchQueue.main belongs to the pre-concurrency era
DispatchQueue.main.async { self.items = result }
```

---

## Never `@Observable` — it is iOS 17+ only

```swift
// ❌ — iOS 17+ only, this app targets iOS 16+
@Observable
final class FooViewModel { ... }

// ✅
@MainActor
final class FooViewModel: ObservableObject { ... }
```

---

## ViewModel vs View responsibility *(swiftbysundell.com)*

| Belongs in ViewModel | Belongs in View |
|---------------------|-----------------|
| Data fetching | Layout and styling |
| Business logic | User interaction handlers |
| Domain state (`items`, `isLoading`) | Presentation state (`showSheet`, `isExpanded`) |
| Error handling | Animation triggers |
| DataStore / Task calls | `.task`, `.onAppear`, `.sheet` modifiers |

The View describes UI given current state. The ViewModel never describes UI. If a ViewModel property is named `buttonColor` or `avatarSize`, it has crossed the boundary.

---

## Async toggle with guard against double-fire

```swift
// ✅ — isSwitching prevents concurrent toggling
@Published var isSwitching = false

func toggle() async {
    guard !isSwitching else { return }
    isSwitching = true
    defer { isSwitching = false }
    // ...
}
```

---

## `EventDraftViewModel` field names

| Wrong | Correct |
|---|---|
| `selectedDate` | `eventDate` |
| `specialRequests` | `specialRequest` |
| `djSharePercent` | `djSharePercentage` |
| `posterData` | `posterImage: UIImage?` |
| `verifyEligibility()` | `meetsRankRequirements()` (sync) |
| `uploadPosterAndSaveEvent()` | `submitEvent()` (async) |
| `estimatedEarnings.total` | `Double(revenueBreakdown.totalCoins)` |
| `estimatedEarnings.djCut` | `Double(revenueBreakdown.hostDJCoins)` |

---

## `DJPayout` is a struct, not a tuple

`EventDraftViewModel.computePayouts(from:)` returns `[DJPayout]` with `.username: String` and `.coins: Int`.

```swift
// ✅
djPayouts.first(where: { $0.username == dj.username })?.coins

// ❌ — DJPayout is not a tuple
djPayouts.first(where: { $0.0 == dj.username })?.1
```

---

## What to avoid

- `import SwiftUI` — if you need a SwiftUI type in a ViewModel, you have a layer violation
- `@Observable` — iOS 17+ only
- `DispatchQueue.main.async` — use `@MainActor`
- Storing signed URLs as `@Published` properties — they expire; store S3 keys
- Making Amplify calls directly — go through `Task/` services
- ViewModel properties named after UI concepts (`buttonTitle`, `cardColor`)
