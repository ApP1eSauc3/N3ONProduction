# N3ON — Data Layer

This file loads automatically for any file under `N3ON/Data/`. Data contains models, enums, and errors. No async. No SwiftUI. No imports from this project.

> You are defining the vocabulary of the entire codebase. Every other layer speaks in the types you define here. Get these wrong and the compiler errors cascade upward through Task, Workflow, and Prompt. Your job is precision: correct semantics, explicit conformances, no guessing at Amplify field names.
>
> Two sources shape how this layer is written:
> - **swiftbysundell.com — "Basics: Codable"**: Use compiler-synthesised conformance wherever possible. When your Swift naming diverges from the wire format, use `CodingKeys` — don't rename your Swift properties to match JSON. In Swift 6, enums inside `Codable` structs require explicit `enum Foo: String, Codable` — synthesis is not enough.
> - **Apple Swift documentation — "Choosing Between Structures and Classes"**: Default to `struct`. Use `class` only when you need shared mutable identity (reference semantics) or Objective-C interop. Most domain models — events, users, tickets — are value types that benefit from copy semantics and implicit thread safety.

---

## Import rules

```swift
import Foundation   // ✅
import UIKit        // ✅ for UIImage in AvatarState
// ❌ import SwiftUI
// ❌ import Amplify — Data has no knowledge of the persistence layer
// ❌ any import from N3ON project files
```

---

## Struct vs class *(Apple Swift docs)*

- **`struct`** — default choice for models, enums, value containers. Copy semantics mean no shared mutable state, no data races.
- **`class`** — only when identity matters (two variables must refer to the same instance) or Objective-C interop is required.
- **`enum`** — for closed sets of states. Prefer associated values over parallel arrays of optionals.

```swift
// ✅ — value type, Codable, correct conformances
struct UserSummary: Codable, Hashable {
    let id: String
    let username: String
    let isDJ: Bool
    let avatarKey: String?
}

// ❌ — class for a data container adds reference overhead and mutation risk
class UserSummary: Codable { ... }
```

---

## Codable *(swiftbysundell.com)*

```swift
// ✅ — let the compiler synthesise conformance
struct Ticket: Codable { ... }

// ✅ — use CodingKeys when wire format diverges from Swift naming
struct APIResponse: Codable {
    let userID: String
    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
    }
}

// ✅ Swift 6 — enum inside a Codable struct needs explicit conformance
enum TicketType: String, Codable {  // explicit Codable required
    case general, vip, backstage
}

// ❌ Swift 6 — enum Foo: String does not satisfy Codable automatically
enum TicketType: String { ... }  // compile error when used in a Codable struct
```

---

## Every type must be defined here before being referenced elsewhere

If `Task/`, `Workflow/`, or `Prompt/` reference a type that doesn't exist, the build fails with "Cannot find type X in scope". Before writing code that uses a new type, define it here first.

One definition per type — no duplicate `struct`, `enum`, or `class` definitions across files. The build fails with "Invalid redeclaration of X".

---

## Permitted Amplify import exception

`Data/ChatDataModel.swift` is the one file in Data/ that legitimately imports Amplify. It maps `Message → ChatMessage` and must call `.foundationDate` on `Temporal.DateTime`, which is defined in the Amplify framework (not in the generated model files). Do not add `import Amplify` to any other Data file without this same justification.

---

## Known excluded files

`Data/Event.swift` and `Data/EndorsementRequest.swift` are **excluded from the N3ON build target** — they conflict with same-named Amplify-generated models. The Amplify versions in `amplify/generated/models/` are the source of truth for those types.

If you add a new app-level model that shares a name with an Amplify model, add it to the `PBXFileSystemSynchronizedBuildFileExceptionSet` for the Data group in `project.pbxproj` (UUID `AA000001000000000000006A`).

---

## `AvatarState`

Two cases only:

```swift
// ✅
.remote(avatarKey: "some-s3-key")
.local(image: uiImage)
.remote(avatarKey: "default-avatar")  // fallback

// ❌ — does not exist
.placeholder
```

---

## `User.djRank`

`djRank` is `Int?` (nullable). There is no `endorsementLevel` field.

```swift
// ✅
user.djRank ?? 0        // when Int is needed
user.djRank = newValue  // write back

// ❌
user.endorsementLevel   // does not exist
```

---

## Temporal types — `Temporal.DateTime?` is not `Date?`

Amplify uses `Temporal.DateTime` not `Foundation.Date`. They are not interchangeable.

```swift
// ✅
user.createdAt?.foundationDate ?? fallbackDate  // convert to Date
Temporal.DateTime(Date(), timeZone: .current)    // construct (two-parameter form)

// ❌
user.createdAt as? Date     // wrong type
Temporal.DateTime(Date())   // single-parameter form does not compile
```

---

## `EventDJLink` — no `eventID` property

`EventDJLink.event` is a `belongsTo` association (`Event?`). There is no `eventID: String`.

```swift
// ✅
let eventIDs = Set(links.compactMap { $0.event?.id })

// ❌
let eventIDs = Set(links.map { $0.eventID })  // 'EventDJLink' has no member 'eventID'
```

---

## `EndorsementRequest` — `.toUser` / `.fromUser` keys

The Swift predicate keys use the association names, not the underlying DB column names:

```swift
// ✅
EndorsementRequest.keys.toUser
EndorsementRequest.keys.fromUser

// ❌
EndorsementRequest.keys.toUserID
EndorsementRequest.keys.fromUserID
```

---

## `DailyUserCount` — `.venue` key

```swift
// ✅
DailyUserCount.keys.venue == venueID

// ❌
DailyUserCount.keys.venueID
```

---

## Amplify `Model` does not conform to `Identifiable`

Amplify-generated models have `id: String` but do not conform to `Identifiable`. Add a one-line extension in the file that needs it — never in the generated model file:

```swift
// ✅ — at top of the view/service file that uses ForEach or sheet(item:)
extension Post: Identifiable {}

// ❌ — in the generated file (will be overwritten by codegen)
```

---

## `MediaKind.avatar` argument label

```swift
// ✅ — userID with capital I
MediaKind.avatar(userID: id)

// ❌
MediaKind.avatar(userId: id)
```

---

## What to avoid

- `async` functions — Data has no knowledge of persistence or networking
- `import SwiftUI` — Data types must be usable from Task and Workflow which forbid SwiftUI
- Raw hex colours or platform-specific types as model fields
- Mutable `var` on all struct fields — default to `let`, use `var` only where mutation is a requirement
- Defining a type that already exists in `amplify/generated/models/`
