# N3ON — Task Layer

This file loads automatically for any file under `N3ON/Task/`. Task is the **only** layer that calls Amplify directly. It never imports SwiftUI.

> You are writing the service boundary of a production iOS app. Every function here is `async throws`. The caller trusts that you handle Amplify's quirks, Cognito's token API, and S3's key-vs-URL distinction. Your job is to be a clean, predictable interface — not to bleed Amplify types into the rest of the codebase.
>
> Two sources shape how this layer is written:
> - **avanderlee.com — "Async Await in Swift"**: Async/await replaces callback chains. Execution is linear and readable. Wrap legacy callback APIs with `withCheckedThrowingContinuation` rather than mixing paradigms. Never pass async closures to `Result.init(catching:)` — it is synchronous only.
> - **hackingwithswift.com — "How to Cancel a Task"**: Cancellation is cooperative — tasks must actively check. Call `Task.checkCancellation()` or test `Task.isCancelled` after every significant `await` point. Foundation APIs check automatically, but your own loops do not.

---

## Import rules

```swift
import Foundation
import Amplify      // ✅
import UIKit        // ✅ when needed for image types
// ❌ import SwiftUI — never
```

---

## The three entry points — always go through these

| Concern | Entry point | Never call directly from |
|---------|-------------|--------------------------|
| Auth | `AuthService.swift` | Views, ViewModels |
| Storage (upload/sign) | `StorageService.swift` + `StorageUploader.swift` | Views, ViewModels |
| DataStore (read/write) | Task service files | Views (`Amplify.DataStore` calls belong here) |

---

## Auth

- `AuthService.currentUserId()` — `async throws`. Use when absence is an error.
- `AuthService.currentUserIdOrNil()` — `async`, never throws. Use when guest state is valid.
- Never call the synchronous Amplify auth form — the session may not be ready on launch.

### Cognito tokens

`getCognitoTokens()` is **synchronous and non-throwing** — `Result<any AuthCognitoTokens, AuthError>`. Never wrap in `try await`.

```swift
// ✅ — standalone guard, then switch
guard let provider = session as? AuthCognitoTokensProvider else { return [] }
let idToken: String
switch provider.getCognitoTokens() {
case .success(let tokens): idToken = tokens.idToken
case .failure: return []
}

// ❌ — multi-condition guard loses the associated value type
guard let provider = ..., case .success(let tokens) = provider.getCognitoTokens() else { return [] }

// ❌ — getCognitoTokens() is not async/throws
let tokens = try await provider.getCognitoTokens()
```

`idToken` is a raw JWT `String`. Decode via base64 + `JSONSerialization`. Canonical implementation: `Data/AppRole.swift → decodeJWT(_:)`.

---

## Storage

**Key rule: never store a signed URL. Store the S3 key string. Sign at display time.**

```swift
// ✅ upload — save the key, not the URL
let key = try await StorageService.uploadImage(image, isPublished: true)
// store key in DataStore

// ✅ sign at display time only
let url = try await StorageUploader.signedURL(for: key, access: .protected)

// ❌ Amplify v1 callback API — removed in v2
Amplify.Storage.getURL(key: key, options: .init(accessLevel: .protected)) { result in ... }
```

`StorageUploader.signedURL(for:access:)` returns `URL` (non-optional) and is `async throws`. Never use `if let`:

```swift
// ✅
let url = try await StorageUploader.signedURL(for: key, access: .protected)

// ❌ — "Initializer for conditional binding must have Optional type"
if let url = await StorageUploader.signedURL(for: key, access: .protected) { ... }
```

---

## Amplify DataStore

Always read `amplify/generated/models/<ModelName>.swift` before writing a query predicate. Never guess field names.

```swift
// ✅
try await Amplify.DataStore.query(ModelType.self, where: predicate)

// ❌ — no .in() predicate exists on ModelKey
Amplify.DataStore.query(ChatRoom.self, where: ChatRoom.keys.id.in(roomIds))

// ✅ — filter in memory instead
let all = try await Amplify.DataStore.query(ChatRoom.self)
let rooms = all.filter { roomIds.contains($0.id) }
```

**`belongsTo` association keys use the association name, not the underlying DB column:**

```swift
// ✅
Amplify.DataStore.query(Venue.self, where: Venue.keys.owner == userID)
Amplify.DataStore.query(UserChatRooms.self, where: UserChatRooms.keys.chatRoom == roomID)
Amplify.DataStore.query(EndorsementRequest.self, where: EndorsementRequest.keys.toUser == userID)

// ❌
Venue.keys.ownerID        // 'Venue.CodingKeys' has no member 'ownerID'
UserChatRooms.keys.chatRoomId
EndorsementRequest.keys.toUserID
```

**`Temporal.DateTime` — always the two-parameter form:**

```swift
// ✅
Temporal.DateTime(Date(), timeZone: .current)

// ❌ — does not compile
Temporal.DateTime(Date())
Temporal.DateTime(iso8601String: "...")  // for constructed dates
```

**`DataStore.observe()` not `publisher(for:)` (removed in Amplify v2):**

```swift
// ✅
for try await change in Amplify.DataStore.observe(User.self) {
    guard let updated = try? change.decodeModel(as: User.self) else { continue }
}

// ❌ — removed
Amplify.DataStore.publisher(for: User.self).sink { ... }
```

---

## Amplify model field types

| Model | Field | Type | Note |
|-------|-------|------|------|
| `Message` | `sender` | `User?` | Not `senderID: String` |
| `Venue` | `owner` | `User?` | Predicate key is `.owner` |
| `EventDJLink` | `event` | `Event?` | Access ID via `.event?.id` |
| `Post` | `urls` | `[String]` | S3 keys — never signed URLs |
| `Post` | `types` | `[String]` | `MediaType.rawValue` strings |
| `Post` | `timestamp` | `Temporal.DateTime` | Not `Date` |

---

## Task cancellation *(hackingwithswift.com)*

> "Tasks won't stop immediately — they must actively check for cancellation."

- Check `Task.isCancelled` after every `await` point in loops or multi-step operations
- Use `Task.checkCancellation()` (throws `CancellationError`) at natural checkpoints
- Foundation and Amplify APIs check automatically before proceeding
- SwiftUI's `.task()` modifier cancels automatically when the view disappears

```swift
// ✅
let items = try await Amplify.DataStore.query(Event.self)
guard !Task.isCancelled else { return }
for item in items {
    try Task.checkCancellation()
    // process item
}
```

---

## Async/await patterns *(avanderlee.com)*

```swift
// ✅ — linear, readable
let images = try await fetchImages()
let resized = try await resizeImages(images)

// ✅ — bridge legacy callback to async
func fetchData() async throws -> Data {
    try await withCheckedThrowingContinuation { continuation in
        legacyService.fetch { result in
            continuation.resume(with: result)
        }
    }
}

// ❌ — Result.init(catching:) is synchronous only
let result = await Result { try await someAsyncCall() }  // compile error

// ❌ — DispatchQueue belongs to the pre-concurrency era
DispatchQueue.main.async { ... }
```

---

## Method signature hygiene

Two `func foo(for id: String)` overloads with different parameter types are **identical signatures** to the compiler. Use distinct external labels:

```swift
// ✅
func transactions(for userID: String)
func transactions(forEvent eventID: String)

// ❌ — "invalid redeclaration"
func transactions(for userID: String)
func transactions(for eventID: String)
```

---

## URLSession

`URLSession.shared` is acceptable for third-party REST API calls. It is **banned for image downloads** — no disk cache, creates memory pressure. All image loading goes through `StorageUploader` / `PulsingAvatarView`.
