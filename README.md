# iClients

iOS client management app built for a technical test. Stores companies and their multiple addresses locally via Core Data, with full CRUD through a native SwiftUI interface.

## Features

- **Splash screen** with branded icon and timed transition to the main list (skipped automatically under UI tests)
- **Client list** rendered as a responsive grid of uniformly-sized cards (adaptive `LazyVGrid`, 2 columns on iPhone, more on iPad)
- **Create / edit / delete clients** with a long-press context menu on any card and a shared form for add/edit driven by a mode enum
- **Per-client address list** with native swipe actions: leading swipe for **Delete**, trailing swipe for **Edit**
- **Create / edit / delete addresses**, scoped to the selected client, with cascade-delete when a client is removed
- **Live updates** across screens via Core Data's `@FetchRequest` and `@ObservedObject` on managed entities
- **Empty states** with SF Symbols for both clients and addresses
- **Rich input validation** on every form:
  - Min/max character limits per field with live counters (`3/80`, etc.)
  - Hard input cap — fields stop accepting characters at the max, no truncation surprises on save
  - Required-field hints, "at least N characters" hints, and format-error hints in the footer
  - Email format validation via `NSRegularExpression`
  - Phone format validation via `NSDataDetector` (accepts the platform's idea of a phone number, locale-friendly)
  - Save button stays disabled until every field is valid
- **Country text field** for addresses with validation (`2...40` chars) and max-length clamping

## Architecture

**MVVM + Repository pattern**, chosen for testability and clear separation between UI, view state, and persistence.

```
View  ─────▶  ViewModel  ─────▶  Repository (protocol)
 ▲                                        │
 │                                        ▼
 └── @FetchRequest ◀──── NSManagedObjectContext (Core Data)
```

- **View**: SwiftUI, stateless where possible, subscribes to the VM via `@StateObject` and to Core Data entities via `@ObservedObject` / `@FetchRequest`.
- **ViewModel**: `@MainActor` `ObservableObject` holding form state (`formMode` enum for create/edit), validation rules, `didSet` input clamping, and calls into the repository. Never touches `NSManagedObject` attributes directly from the UI.
- **Repository**: Protocol-based abstraction over Core Data CRUD (`ClientRepository`, `AddressRepository`). The `CoreData…Repository` implementations own the context and save policy. ViewModels depend on the protocol, making unit tests trivial.

## Tech stack

- **Swift 5.9+ / SwiftUI** (iOS 17+ — uses `.symbolEffect`, `Form` with `axis: .vertical`, `ContentUnavailableView`)
- **Core Data** with **Codegen: Class Definition** for both `Client` and `Address`
- **XCTest** + **XCUITest** against an in-memory Core Data stack
- **Combine** (`ObservableObject` / `@Published`) for VM ↔ View binding

## Project structure

```
iClients/
├── App/
│   ├── iClientsApp.swift        App entry point; injects managedObjectContext
│   └── RootView.swift           Splash ▸ main list gating (bypassed under -UITesting)
├── Persistence/
│   ├── Persistence.swift        PersistenceController (shared / preview / inMemory)
│   └── iClients.xcdatamodeld    Client and Address entities with relationship
├── Models/
│   ├── Client+Extensions.swift  Factory + computed addressList
│   └── Address+Extensions.swift Factory + formatting helpers
├── Repositories/
│   ├── ClientRepository.swift   Protocol + CoreDataClientRepository
│   └── AddressRepository.swift  Protocol + CoreDataAddressRepository
└── Features/
    ├── Splash/                  SplashView
    ├── Shared/                  EmptyStateView, FieldValidationFooter
    ├── ClientList/              Grid view, card, VM
    ├── ClientForm/              Add/Edit form + validation, VM
    ├── AddressList/             List view, row, VM
    └── AddressForm/             Add/Edit form + country text field validation, VM
```

## Data model

```
Client (1) ────< addresses (Cascade) ────> (*) Address
                                      <──── (1) client (Nullify)
```

- `Client`: `id: UUID`, `companyName: String`, `email: String`, `phone: String`, `createdAt: Date`
- `Address`: `id: UUID`, `street: String`, `city: String`, `country: String`, `postalCode: String`, `createdAt: Date`
- Deleting a client cascade-deletes all of its addresses (enforced by a Core Data delete rule and covered by a unit test).

## Validation rules

| Field          | Min | Max | Format                       |
|----------------|-----|-----|------------------------------|
| Company name   | 2   | 80  | —                            |
| Email          | 5   | 120 | RFC-ish regex                |
| Phone          | 6   | 30  | `NSDataDetector(.phoneNumber)` |
| Street         | 3   | 60  | —                            |
| City           | 2   | 40  | —                            |
| Country        | 2   | 40  | Required text field          |
| Postal code    | 3   | 12  | —                            |

Limits live as `static let` constants on each ViewModel so tests can read the same source of truth the UI uses.

## Running the app

1. Open `iClients.xcodeproj` in Xcode 15 or later.
2. Select the **iClients** scheme and an iOS 17+ simulator.
3. ⌘R to run, or ⌘U to run the full test suite.

## Running the tests

```
Cmd + U
```

Every test — unit and UI — creates a fresh in-memory Core Data stack (`NSInMemoryStoreType`), so runs are isolated and deterministic. UI tests launch the app with a `-UITesting` argument that swaps `PersistenceController.shared` for an in-memory instance and skips the splash screen.

### Unit tests (`iClientsTests`)

**`ClientRepositoryTests`**
- Empty-store `fetchAll` returns `[]`
- `create` persists every field and auto-assigns `id` + `createdAt`
- `fetchAll` returns clients sorted newest-first
- `update` mutates attributes while preserving `id` + `createdAt`
- `delete` removes the client from the store
- `delete` cascades to the client's addresses

**`ClientFormViewModelTests`**
- `init` in `.create` mode yields empty fields and `isValid == false`
- `init` in `.edit` mode pre-populates fields from the managed object
- `isValid` is true only when company name, email, and phone all satisfy length + format
- `isEmailFormatValid` rejects malformed addresses and accepts well-formed ones
- `isPhoneFormatValid` accepts `NSDataDetector`-recognised numbers and rejects plain text
- Max-length `didSet` clamps input on assignment (no over-limit values reach `save()`)
- `save()` trims whitespace and persists through the repository

### UI tests (`iClientsUITests`)

- Empty launch shows the clients empty state (and splash is bypassed)
- Adding a client with valid data makes the card appear in the grid
- The Save button stays disabled while the form is incomplete or has format errors
- Editing a client via the context menu updates the card label live
- Deleting a client via the context menu removes the card
- Adding an address with valid country text shows it in that client's address list
- Address Save/Add button stays disabled for invalid country length and enables for valid `2...40`

Accessibility identifiers are set on every form field and toolbar button to make the UI tests resilient against copy changes.

## Design decisions

- **`@FetchRequest` over manual observation.** Core Data's `@FetchRequest` is SwiftUI-native, auto-updates on context changes, and eliminates a class of "stale list" bugs for one line per list view.
- **Repository protocol, not direct Core Data from the VM.** Makes unit tests cheap (swap in a mock `ClientRepository`) and lets the persistence layer evolve (CloudKit, server sync) without touching UI code.
- **Shared form for create and edit, driven by `ClientFormMode` / `AddressFormMode` enum.** Cuts the form surface area in half and guarantees UX consistency.
- **`@ObservedObject` on `Client` / `Address` in row views.** Managed objects don't automatically trigger SwiftUI re-renders when a single attribute changes; `@ObservedObject` subscribes to `objectWillChange` and fixes this.
- **Validation in the ViewModel.** `isValid`, format-error messages, and `save() throws` live on the VM so the View is "dumb" — binds, shows footers, dismisses. Easy to test and easy to reuse.
- **`didSet` input clamping.** Enforcing max length at the model layer (not just in the view) means pasted text, programmatic edits, and pre-populated edit forms all respect the same ceiling.
- **Reusable `FieldValidationFooter`.** Centralises counter + hint UI so every form field gets consistent feedback for free.
- **Explicit `NSInMemoryStoreType` for tests.** Apple's template trick of pointing a SQLite store at `/dev/null` is flaky on recent iOS; using the real in-memory store type avoids `"A fetch request must have an entity"` crashes and gives tests a clean store every time.
- **`.sheet(item:)` for forms.** Re-creating the form view + VM per presentation gives free state-resetting behavior ("clear the fields" requirement) without manual work.
- **Adaptive grid with fixed card size.** `GridItem(.adaptive(minimum: 165, maximum: 180))` keeps every card the same shape while scaling the column count to the device — no stretched or shrunken cards.


<img width="423" height="936" alt="Screenshot 2026-04-23 at 12 07 33 PM" src="https://github.com/user-attachments/assets/b49552e0-1273-4c09-95d1-6c8b8d0135a2" />
<img width="464" height="954" alt="Screenshot 2026-04-23 at 12 07 41 PM" src="https://github.com/user-attachments/assets/9f7d2a9a-c232-4c16-b815-c4dadc4b76ce" />

https://github.com/user-attachments/assets/1c1ba1ae-e028-43f7-9394-c6e33a1624ee



## Author

Michael Peralta
