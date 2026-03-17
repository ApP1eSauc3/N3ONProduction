# N3ON

iOS 16+ nightlife/events app. AWS Amplify backend (Cognito auth, DataStore/GraphQL, S3 storage).
Read this file before writing any code.

---

## Stack

- **Auth** — `Amplify.Auth` / `AWSCognitoAuthPlugin`. Entry point: `Task/AuthService.swift`.
- **Database** — `Amplify.DataStore` (offline-first GraphQL). Generated models live in `amplify/generated/models/`. Never hand-edit those files.
- **Storage** — `Amplify.Storage` / `AWSS3StoragePlugin`. Entry point: `Task/StorageService.swift`.
- **State** — `ObservableObject` + `@Published`. Never use `@Observable` (iOS 17+ only).
- **Concurrency** — Swift async/await + `@MainActor`. Never use `DispatchQueue.main.async`.

---

## Layer rules

```
Data      →  no imports from this project
Task      →  may import Data. Never imports SwiftUI.
Workflow  →  may import Task, Data. Never imports SwiftUI.
Tools     →  no imports from this project. May import SwiftUI for view modifiers/pickers.
Prompt    →  may import Task, Data, Workflow, Tools. Only layer that imports SwiftUI.
```

File locations:

| Layer    | Path          | Contains                                              |
|----------|---------------|-------------------------------------------------------|
| Data     | `N3ON/Data/`     | Models, enums, errors. No async, no SwiftUI.          |
| Task     | `N3ON/Task/`     | Async services: Amplify calls, upload, location.      |
| Workflow | `N3ON/Workflow/` | `ObservableObject` ViewModels. Orchestrates Task.     |
| Tools    | `N3ON/Tools/`    | Reusable utilities, pickers, view extensions.         |
| Prompt   | `N3ON/Prompt/`   | SwiftUI views. Calls Workflow + Task. Displays state. |

If a change would violate a layer rule, flag it before writing any code.

---

## Non-negotiable rules

### Storage
- **Never store signed URLs.** Store the S3 key string in the database. Generate signed URLs at display time only.
- Use `Task/StorageService.swift` for all uploads. Do not call `Amplify.Storage` directly from views or ViewModels.

### Concurrency
- Every `.task` block that loads remote content must use the storage key string as `id:`, not a closure. Closures are not `Hashable`.
- Check `Task.isCancelled` after every `await` point in loading code.

```swift
// ✅
.task(id: post.imageKey) { await load(post.imageKey) }

// ❌ — task never re-runs when key changes
.task(id: ObjectIdentifier(vm as AnyObject)) { await load() }
```

### onChange
- Never write `.onChange(of:) { newValue in }` — deprecated in iOS 17, unavailable in iOS 16.
- Always use `onChangeCompat` from `Tools/ViewExtensions.swift`.

```swift
// ✅
.onChangeCompat(of: searchText) { _, new in Task { await vm.search(new) } }

// ❌
.onChange(of: searchText) { newText in Task { await vm.search(newText) } }
```

### Amplify DataStore
- Generated model files are in `amplify/generated/models/`. Read them to get field names — do not guess.
- `Data/Event.swift` and `Data/EndorsementRequest.swift` are excluded from the N3ON build target (they conflict with same-named Amplify models). The Amplify versions are the source of truth.
- Query pattern: `try await Amplify.DataStore.query(ModelType.self, where: predicate)`
- `Temporal.DateTime` requires the **two-parameter form** — `Temporal.DateTime(date, timeZone: .current)`. The single-parameter form `Temporal.DateTime(date)` does not compile. Never use `Temporal.DateTime(iso8601String:)` for dates constructed in code.

```swift
// ✅
eventDate: Temporal.DateTime(Date().addingTimeInterval(86400), timeZone: .current)

// ❌ — does not compile
eventDate: Temporal.DateTime(Date().addingTimeInterval(86400))
```

### Auth
- Call `AuthService.currentUserId()` (async throws) to get the current user ID. Never use the synchronous form — the session may not be ready on launch.
- `AuthService.currentUserIdOrNil()` is the safe fallback where absence is valid.

---

## Patterns

### Signed URL at display time
```swift
// Task/StorageService.swift signs on demand — never cache the result
let url = try await Amplify.Storage.getURL(path: StorageService.publishedPath(key))
```

### Upload and save key
```swift
let key = try await StorageService.uploadImage(image, isPublished: true)
// Save `key` to DataStore — never save the URL
```

### ViewModel structure
```swift
@MainActor
final class FooViewModel: ObservableObject {
    @Published var items: [Item] = []
    @Published var isLoading = false

    func load() async {
        isLoading = true
        defer { isLoading = false }
        // ...
    }
}
```

---

## Known conflicts

| File | Situation |
|------|-----------|
| `Data/Event.swift` | Excluded from N3ON target — `amplify/generated/models/Event.swift` is used |
| `Data/EndorsementRequest.swift` | Excluded from N3ON target — `amplify/generated/models/EndorsementRequest.swift` is used |
| `API.swift` (root) | Not in the build target — do not add it. It's a 27,000-line auto-generated GraphQL file that defines `struct Venue` and every other model as nested `GraphQLSelectionSet` types. Including it causes "ambiguous type" errors across the entire codebase. |

If you add a new app-level model that shares a name with an Amplify model, add it to the `PBXFileSystemSynchronizedBuildFileExceptionSet` for the Data group in `project.pbxproj` (UUID `AA000001000000000000006A`).

## Schema change workflow

When `schema.graphql` changes, always run both commands before starting a Claude Code session:

```bash
amplify push            # deploys schema to AppSync
amplify codegen models  # regenerates Swift model files
```

Never start a session that references new or changed model types before codegen has run. The Swift files won't exist yet and Claude will hallucinate field names to fill the gap.

---

## Tally system and EventDJLink

The event tally determines whether ticket sales unlock. All logic is server-side — the client is display-only.

- **`EventDJLink` snapshot fields are Lambda-written only.** `rankAtJoining` and `coinContribution` are set via IAM when a DJ joins. Never write them from a View or ViewModel.
- **`djRank` is read-only from the client.** Rank promotion is not yet built. Never write `User.djRank` from app code.
- **`djLinks` not `djUsernames` on Event.** `Event.djUsernames: [String!]!` was removed — DJ roster is via `EventDJLink @hasMany`. Any reference to `djUsernames` is a compile error.
- **Lambda gates ticket sales before stock check.** `purchaseTicket` Lambda calls `calculateTally` first and rejects with `EVENT_NOT_VALID` if tally not met. Never enforce this client-side only.
- **Tally weights and capacity tiers live in DynamoDB config, not in app code.** `RankWeights` and `CapacityTiers` tables are read by Lambda at runtime. Do not hardcode rank weights or tally thresholds anywhere in Swift.

| Rank | Coin weight | Notes |
|------|-------------|-------|
| 1 | 0 | Can join, contributes nothing |
| 2 | 5 | |
| 3 | 7 | |
| 4 | 10 | |
| 5 | 25 | Host rank — only Rank 5 can create events |

---

## Type hygiene

### Define types before referencing them
Every type used in this project must be defined somewhere in `Data/`. If a type like `DJ` or `GroupLocationViewModel` is referenced in `Task/`, `Workflow/`, or `Prompt/` but doesn't exist in `Data/` or `Workflow/`, the build will fail with "Cannot find type X in scope". Check that the type exists before writing code that uses it.

### No duplicate type definitions
A type (`enum`, `struct`, `class`) may only be defined in one file. If a utility type like `QRCodeGenerator` is already defined in `StatItem.swift`, do not redefine it in `Sections.swift` or anywhere else. The build will fail with "Invalid redeclaration of X".

### `AvatarState` cases
`AvatarState` has two cases: `.remote(avatarKey: String)` and `.local(image: UIImage)`. There is no `.placeholder` case. Use `.remote(avatarKey: "default-avatar")` as the fallback.

### Workflow layer must not import SwiftUI
`Workflow/` files use `ObservableObject` + `@Published` from `Combine`, not `SwiftUI`. The correct import is `import Foundation` + `import Amplify` (or `import Combine` if needed). Never `import SwiftUI` in `Workflow/`.

### Amplify model field names — always read the generated file
Amplify-generated models change field names when the schema changes. `Venue` previously had `ownerID: String` — it now has `owner: User?`. Before writing any initializer or query predicate that references an Amplify model, read `amplify/generated/models/<ModelName>.swift` to get the exact field names and types. Do not guess.

### Method overloads must differ in argument labels, not just parameter types
Two methods `func transactions(for userID: String)` and `func transactions(for eventID: String)` are identical signatures to the Swift compiler. Use distinct external labels: `transactions(for userID:)` and `transactions(forEvent eventID:)`.

### Enums used in `Codable` structs require explicit `Codable` conformance in Swift 6
In Swift 6 (Xcode 26+), `enum Foo: String` does not automatically satisfy `Codable` when used inside a `Codable` struct. Always declare `enum Foo: String, Codable` explicitly.

### `ImagePicker` API
`Tools/ImagePicker.swift` binds a **single** image: `ImagePicker(image: $uiImageBinding) { image in ... }`. It does not accept `selectedImages: [UIImage]`. To accumulate multiple images, hold `@State var pickedImage: UIImage?` and append to an array in the `onImagePicked` closure.

---

## Naming rules

Xcode's `PBXFileSystemSynchronizedRootGroup` compiles all `.swift` files under `Prompt/` into the same target. Two files with the same name anywhere under `Prompt/` — even in different subdirectories — will collide on build output and cause:

```
Multiple commands produce '...SearchView.stringsdata'
duplicate output file on task: SwiftDriver Compilation
```

**Rule: every Swift file in this project must have a unique filename across all layer directories.**

Prefix feature-specific views with their context to avoid clashes:

| Instead of | Use |
|---|---|
| `Prompt/Map/SearchView.swift` | `Prompt/Map/MapSearchView.swift` |
| `Prompt/Event/DetailView.swift` | `Prompt/Event/EventDetailView.swift` |

This applies to all layers, not just `Prompt/`.

---

## Cognito tokens API

`AuthCognitoTokensProvider.getCognitoTokens()` is **synchronous and non-throwing** — it returns `Result<any AuthCognitoTokens, AuthError>`. Never wrap it in `try await`. `AuthCognitoTokens.idToken` is a raw JWT `String`, not a structured object — decode the payload manually via base64 + `JSONSerialization`. The canonical implementation lives in `Data/AppRole.swift` (`decodeJWT(_:)`).

```swift
// ✅
guard case .success(let tokens) = provider.getCognitoTokens(),
      let payload = Self.decodeJWT(tokens.idToken),
      let groups = payload["cognito:groups"] as? [String]
else { return [] }

// ❌ — getCognitoTokens() is not async/throws; tokens.idToken has no .payload property
let tokens = try await provider.getCognitoTokens()
tokens.idToken.payload["cognito:groups"]
```

## Color asset naming

Never name a color asset the same as a `UIColor` class property (`darkGray`, `lightGray`, `red`, `blue`, etc.). Xcode auto-generates `Color` extension symbols from asset names; a clash with `UIColor` produces a `#warning` in `GeneratedAssetSymbols.swift` on every build.

- The app dark-gray asset is named **`appDarkGray`** (not `darkGray`).
- Always reference it via `Color.customDarkGray` (defined in `Tools/Colour.swift`), never via `Color("appDarkGray")` string literals in individual views.

## `MediaKind` argument label

`MediaKind.avatar` takes `userID:` (capital I), matching all other `userID` parameters in the project. Never use `userId:`.

---

## Common async/await mistakes

### `Result.init(catching:)` is synchronous — never pass an async closure to it
`Result { try await someAsyncCall() }` does not compile — `Result.init(catching:)` accepts only a synchronous throwing closure. Use `do/catch` instead:

```swift
// ✅
do {
    let tokens = try await provider.getCognitoTokens()
    // use tokens
} catch { ... }

// ❌ — "Cannot pass function of type '() async throws -> ...' to parameter expecting synchronous function type"
case .success(let x) = await Result { try await provider.getCognitoTokens() }
```

### `StorageUploader.signedURL` returns non-optional `URL` and throws — never use `if let`
`signedURL(for:access:)` returns `URL` (not `URL?`) and is `async throws`. Using `if let url = await StorageUploader.signedURL(...)` produces two errors: "Initializer for conditional binding must have Optional type" and "Call can throw but is not marked with 'try'". Use `try await` directly:

```swift
// ✅
let url = try await StorageUploader.signedURL(for: key, access: .protected)

// ❌
if let url = await StorageUploader.signedURL(for: key, access: .protected) { ... }
```

### `Post.urls` and `Post.types` store S3 keys and raw type strings — not `URL` objects or `MediaType` enums
`Post` (Amplify model) has `urls: [String]` and `types: [String]`. Store the S3 key string and `MediaType.rawValue` respectively. Never store signed `URL` objects — they expire. `Post.id` is `String` and `Post.timestamp` is `Temporal.DateTime`.

```swift
// ✅
Post(id: UUID().uuidString, urls: keyList, types: typeList, timestamp: Temporal.DateTime(Date()), caption: caption)

// ❌
Post(id: UUID(), urls: urlList, types: mediaTypeList, timestamp: Date(), caption: caption)
```

### Missing picker types — check `Tools/` before using any picker
Pickers live in `Tools/`. Available: `ImagePicker`, `MixedMediaPicker`, `AudioPicker`. If a picker is referenced but not present in `Tools/`, create it there as a `UIViewControllerRepresentable`. Never reference a picker that doesn't exist.

---

## What to avoid

- `@Observable` — iOS 17+ only
- `DispatchQueue.main.async` — use `@MainActor`
- `URLSession.shared` for image downloads — no disk cache
- Storing signed URLs in any model or database field
- `.onChange(of:) { newValue in }` — use `onChangeCompat`
- Importing `SwiftUI` in `Task/`, `Workflow/`, or `Data/`
- Calling `Amplify.Storage` directly from a view or ViewModel
- Inventing Amplify field names — read the generated schema file first
