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

If you add a new app-level model that shares a name with an Amplify model, add it to the `PBXFileSystemSynchronizedBuildFileExceptionSet` for the Data group in `project.pbxproj` (UUID `AA000001000000000000006A`).

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
