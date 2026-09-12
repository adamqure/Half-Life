# Half-Life Constitution

> **Status: DRAFT** — starter version for review. Edit, remove, or add principles, then change the status to **Ratified** with the date.

This document defines the foundational principles every change to Half-Life must follow. It overrides convenience, existing code patterns, and any other project guidance (including `CLAUDE.md`). If a change can't comply with it, the change is wrong, or this document needs a deliberate amendment. It is never quietly worked around.

## Article I: Architecture

The app combines **The Composable Architecture (TCA)** ([pointfreeco/swift-composable-architecture](https://github.com/pointfreeco/swift-composable-architecture)) with **Clean Architecture**. It has three layers.

| Layer | Contains | May depend on |
|-------|----------|---------------|
| **Presentation** | TCA features: reducers and their views | Domain (use cases and entities) |
| **Domain** | Entities, business rules, use cases, and repository protocols | Nothing (Swift and Foundation only) |
| **Data** | Repository implementations and data sources (HealthKit, SwiftData, …) | Domain (to implement its protocols) |

Dependencies point inward, toward Domain. Domain never imports SwiftUI, ComposableArchitecture, HealthKit, or SwiftData. Nothing depends on Presentation.

### Presentation: TCA features

1. **Features are reducers.** Each feature is a `@Reducer` with an `@ObservableState` `State`, an `Action` enum, and a `body`. Presentation logic lives in reducers, never in views.
2. **Views are thin.** A view renders from a `StoreOf<Feature>` and sends actions. It holds no business state of its own (`@State` only for purely visual, ephemeral concerns).
3. **Actions call use cases.** A reducer reaches business logic and data only through use cases, injected with `@Dependency`, and calls them from `Effect`s. It never touches a repository or data source directly.
4. **Repository data is reduced into State.** A feature subscribes to repository data through an `Observe…` use case in a `.run` effect. The feature sends one action per emitted value (e.g. `.entriesUpdated([CaffeineEntry])`), and the reducer reduces that value into `State`. The subscription is tied to the feature's lifetime: the view starts it from `.task { await store.send(.task).finish() }`, or it is cancelled by ID when the feature is dismissed.
5. **One-way data flow.** Commands flow action → use case → repository. Updates flow repository → `Observe…` use case → action → reducer → `State`. A reducer does not optimistically write repository-owned data into `State`; it waits for the repository to emit. Any documented exception must be recorded in the DocC catalog.
6. **Composition and navigation.** Features compose with `Scope`, `.ifLet`, and `.forEach`. Navigation is state-driven using `@Presents` / `PresentationAction` and `StackState` / `StackAction`. These rules govern the app's own screens. System UI that a framework provides, such as MessageUI's Mail composer or HealthKit's authorization sheet, is presented by the data source that wraps the framework (I.14). The feature learns the outcome through the repository, like any other data.

### Domain: use cases, entities, and business rules

7. **Use cases are single-purpose.** Each use case performs exactly one business operation. It conforms to the Domain's `UseCase` protocol and exposes the operation as `execute(_:)`, which takes one `Input` and returns one `Output` (`Void` when there's none). It is named for that operation: `LogCaffeineIntakeUseCase`, `ObserveCaffeineEntriesUseCase`.
8. **Use cases are lifetime-scoped.** A use case lives only as long as the feature that owns it. It holds no state of its own beyond references to the repositories it uses; long-lived state belongs in repositories, and per-screen state belongs in feature `State`. Use cases never cache data between calls.
9. **Use cases depend on repository protocols**, which Domain defines. They never depend on concrete implementations.
10. **Entities and business rules.** Entities are plain `Sendable`, `Equatable` value types with no framework dependencies. Business rules are stateless Domain types that calculate from entities, such as the caffeine decay curve. Repositories execute business rules to derive the data they publish. A business rule holds no state and never touches a repository or data source.

### Data: repositories and data sources

11. **Repositories hold state.** A repository is the single source of truth for its data. It is app-scoped, created once, and outlives every feature. It holds the current data in memory and persists it through data sources.
12. **Repositories publish changes.** Every repository exposes its data as an `AsyncStream` that emits the current value immediately on subscription and then every change.
13. **Repositories are concurrency-safe and stay off the main actor.** Each is its own `actor`, or is isolated to a single global actor other than the main actor (Article IV.1).
14. **Data sources wrap frameworks.** Data sources are the only code that touches HealthKit, SwiftData, the file system, or other system frameworks. Repositories talk to data sources, never to frameworks directly.

### Wiring and testing

15. Use cases and repositories are registered with swift-dependencies (`DependencyKey`) with live, test, and preview values. Repositories are provided as their Domain protocol type.
16. Every layer is tested in isolation. Reducers use an exhaustive `TestStore` with use cases overridden. Use cases are tested against in-memory fake repositories. Repositories are tested against fake data sources.
17. The architecture is documented in the DocC catalog (see Article VIII).

## Article II: Test-first development

1. All production code is written test-first (red → green → refactor).
2. Every bug fix begins with a test that reproduces the bug.
3. The `Half-Life` app target maintains at least **80% line coverage** across the full test suite (unit and UI tests).
4. Tests are never weakened, skipped, or deleted to make a change pass.

### UI tests: the robot pattern

5. **Tests drive the app through robots.** UI tests are XCTest/XCUITest tests in `Half-LifeUITests/`. Each feature's view (a screen) has exactly one robot, `<Feature>Robot`, in `Half-LifeUITests/Robots/`. A test interacts with the app only through robots. It never queries `XCUIApplication` for elements or touches an `XCUIElement` itself.
6. **Elements are found by accessibility identifier.** Every element a robot interacts with or verifies has an accessibility identifier, set in the view's source with `.accessibilityIdentifier(_:)`. Robots never locate elements by label, value, or position.
7. **Identifiers are defined once, per view.** A view's identifiers are `static let` constants on an enum named `<View>AccessibilityID`, in its own file `<View>AccessibilityID.swift` next to the view. That file belongs to both the `Half-Life` and `Half-LifeUITests` targets, so the view and its robot share one definition and a mismatch is a compile error. Neither the view nor the robot writes an identifier as a string literal.
   - Values follow `<view>.<element>` in lower camel case (e.g. `caffeineLogView.addButton`), which keeps them unique across the app.
   - Every view that has a robot defines a `screen` identifier on its root element. The robot uses it to detect its screen.
   - Identifiers aren't user-facing, so they aren't localized (Article VII). They never replace an accessibility label (Article VI.1).
   - The identifiers can't instead be a type nested in the view. The UI test target runs in a separate process and isn't linked against the app, so a reference to any app-target symbol fails to link. This holds for `public` symbols and with `@testable import` (verified 2026-09-11).
8. **Robots own their elements.** A robot has a field for each element it controls, resolved by identifier from its view's `<View>AccessibilityID`. The fields are `private`, so only the robot touches its elements.
9. **Robots speak in semantic commands.** A robot's API expresses the user's intent in the app's domain language (`addEntry(milligrams:)`, not `tapAddButton()`). The robot translates each command into interactions with its elements. It waits for elements to appear rather than sleeping for a fixed time. Commands never return another robot.
10. **Robots verify.** Robots expose semantic verifications (e.g. `verifyEntryCount(_:)`) and an accessibility audit that runs `performAccessibilityAudit()` for their screen (Article VI.4). Verifications report failures at the test's call site. Tests make no assertions about UI elements themselves.
11. **Tests resolve the robot on screen.** After launch, and after every command that can change the screen, a test asks which robot is on screen and names the robots it expects. Resolution waits for one expected robot's `screen` element, then returns that robot. If none appears, the test fails, and the failure names the screen that is showing if a known robot recognizes it. A test branches only among the robots it expected.

## Article III: Simplicity and dependencies

1. Build the simplest thing that satisfies the requirement and its tests. No speculative features or abstractions for hypothetical future needs.
2. Prefer Apple's first-party frameworks over third-party code.
3. No third-party package is added without explicit approval from the project owner. A proposal states the package, version, purpose, and alternatives considered.
4. **Approved dependencies:** `swift-composable-architecture` and its transitive Point-Free dependencies.
5. `Package.resolved` is committed so dependency versions are pinned.

## Article IV: Safety and correctness

1. Concurrency follows Swift's data-race safety model. The app target's default actor isolation is `nonisolated`, because TCA reducers fail under a `MainActor` default. Only the UI and presentation layers run on the main actor, and every UI and presentation type states its isolation explicitly.
   1. **UI types are `@MainActor`.** Views, the app, and other types that conform to a SwiftUI or UIKit UI protocol are marked `@MainActor` explicitly, even where the protocol, such as `View`, would infer it.
   2. **Reducers are `nonisolated`.** A reducer reduces `Sendable` state and actions, and TCA runs it on the store, which is `@MainActor`. So each `@Reducer` type is marked `nonisolated` explicitly, and is never `@MainActor`: a `@MainActor` reducer crashes at runtime (verified 2026-09-11 against TCA 1.26.2).
   3. **Domain and Data stay off the main actor.** Domain types are `nonisolated`: entities are immutable `Sendable` values, and business rules and use cases hold no state. Repositories are their own actors (Article I.13). A data source that presents system UI (Article I.6) runs only that presentation on the main actor, in a method marked `@MainActor`.
   4. **Enforcement.** SwiftLint custom rules in `.swiftlint.yml` reject a UI type without `@MainActor`, a reducer without `nonisolated`, and a `@MainActor` reducer.
2. No force unwraps (`!`) or `try!` in production code unless a comment explains why the operation cannot fail.

## Article V: Privacy and security

Half-Life handles health data: caffeine intake the user records in the app, and caffeine data read from and written to Apple Health (HealthKit).

1. **On device, with private iCloud sync.** User data is stored on the device. The only way it leaves is CloudKit sync of the drink log to the user's own private iCloud database, which the developer can't read. There is no backend and no other sync, and the app makes no other network request that carries user data. Data read from HealthKit is never synced (V.3.4).
2. **Minimum data.** Collect only what a feature needs. The DocC catalog documents what each piece of data is, where it is stored, and why it is collected.
3. **HealthKit.**
   1. Request authorization only for the specific types a feature needs (e.g. `dietaryCaffeine`), at the moment the feature needs them, and never automatically at launch. Onboarding's permissions step may also request the types the app's features read, when the user taps to allow them, after it explains what each is for. A single HealthKit authorization data source requests it, asking in one sheet for all the types the feature needs. The data sources that read or write a type never request authorization themselves.
   2. Health purpose strings (`NSHealthShareUsageDescription`, `NSHealthUpdateUsageDescription`) explain the specific use and are localized.
   3. The app works fully when Health access is denied or unavailable. HealthKit enhances the app but is never required.
   4. HealthKit data is never used for advertising or marketing, never shared with third parties, and never stored in iCloud.
   5. Only data sources access HealthKit (Article I.14), and each is reached only through repositories, so tests and previews never touch real Health data. More than one data source may wrap HealthKit, for example one per kind of Health data.
4. **Storage.** Caffeine records are stored locally and protected with iOS Data Protection at `NSFileProtectionComplete` by default. A weaker class is used only when a feature needs background access, and that choice is documented in the catalog. Any credentials or secrets go in the Keychain.
5. **No health data in logs.** Never log health values. User data interpolated into `Logger` messages uses `privacy: .private`.
6. **Analytics: Apple-only.** Only App Store Connect analytics and MetricKit are allowed. No third-party analytics, crash-reporting, or advertising SDKs, and no tracking.
7. **Privacy manifest.** `PrivacyInfo.xcprivacy` and the App Store privacy label stay accurate. Any change that affects collected data or required-reason APIs updates them in the same change.
8. **Secrets.** API keys, credentials, and other secrets are never committed to the repository.

## Article VI: Accessibility

1. Every interactive element has a meaningful accessibility label, plus a hint or value where it helps. Decorative images are hidden from assistive technologies.
2. Layouts support Dynamic Type up to the largest accessibility sizes without losing essential content.
3. Color is never the only way information is conveyed, and text meets WCAG AA contrast.
4. Every screen is covered by a UI test that runs `performAccessibilityAudit()`.

## Article VII: Localization

1. No hard-coded user-facing strings. All user-facing text lives in a String Catalog. Text in code lives in `Localizable.xcstrings`. Text that iOS reads from the Info.plist, such as purpose strings and the app's name, lives in `InfoPlist.xcstrings`.
   1. The Info.plist declares each key that `InfoPlist.xcstrings` localizes, because App Store validation and the frameworks look for the key there. Its value there is only a placeholder. The text itself is never written into `Info.plist` or the project's build settings.
   2. Every localization the app ships translates every key in `InfoPlist.xcstrings`. A localization without the translation shows the Info.plist's placeholder, not the development language's text.
2. In SwiftUI, use string-literal keys (`Text("…")`) or `LocalizedStringResource`. Outside views, use `String(localized:)`. Never build sentences by concatenation; use interpolation inside a localized string so translators see the whole sentence.
3. Dates, numbers, durations, and measurements are formatted with locale-aware APIs (`.formatted(...)`), never by hand.

## Article VIII: Documentation

1. Every type, property, and function in the `Half-Life` app target that is not `private` or `fileprivate` has a `///` DocC comment.
2. **All architecture is documented in the documentation catalog** (`Half-Life/Documentation.docc/`). This covers features and how they compose, use cases, repositories, data sources, navigation flows, and stored data. Any change that alters the architecture updates the catalog in the same change.
3. The documentation builds (`xcodebuild docbuild`) without warnings.

## Article IX: Code style

1. All Swift code is formatted with **swift-format** (bundled with Xcode) and linted with **SwiftLint**, with zero violations. Configuration files (`.swift-format`, `.swiftlint.yml`) at the repository root are the source of truth.
2. Code compiles without warnings.

## Article X: Transparency of AI assistance

1. Every AI-assisted change is recorded in `ai_log.md` according to its rules.
2. A human is accountable for every change merged into the repository, regardless of who or what wrote it.

## Article XI: Logging

Half-Life logs through Apple's unified logging system, so problems can be diagnosed during development and from bug reports without exposing the user's data. The DocC catalog's Logging article is the reference for these rules and for the log export.

1. **`Logger` only.** The app target logs only through `Logger`, from the `os` framework. It doesn't use `print`, `debugPrint`, `dump`, `NSLog`, or `os_log`, and TCA's `._printChanges()` is never committed.
2. **One subsystem, one category per type.** Every logger uses the app's bundle identifier as its subsystem, and the name of the type that owns it as its category.
3. **Presentation and Data log. Domain doesn't.** Reducers, repositories, and data sources log. Views send actions instead of logging. Domain imports only Swift and Foundation (Article I), and neither provides `Logger`. Domain reports failures by throwing, and the code that catches the error logs it.
4. **Levels.** Each message uses the level that matches its purpose, through the method of that name:
   - `debug`: detail for active development. It isn't stored, so it's never in a log export.
   - `info`: context that's helpful but not essential. It's kept only in memory, so it may be missing from a log export.
   - `notice`: information essential for troubleshooting, such as lifecycle events and state transitions. It's stored.
   - `error`: a failure the app handled, such as a failed save or Health query. It's stored.
   - `fault`: a bug in Half-Life's own code, meaning a state that should be impossible. It's stored. Expected conditions outside the app, such as denied Health access, are never faults.

   Anything a bug report needs is logged at `notice` or above. The aliases `log`, `trace`, `warning`, and `critical` aren't used.
5. **Explicit privacy.** Every interpolated value states its privacy: `.public`, `.private`, or `.private(mask: .hash)`. The defaults aren't relied on, because `Logger` leaves integers, floating-point numbers, and Booleans unredacted by default.
6. **What may be logged.** This extends Article V.5.
   1. Health values are never logged, at any level, not even as `.private`. They include caffeine amounts and intake times, sleep, steps, heart rate, and everything derived from them, such as levels, curves, cutoffs, half-lives, correlations, and counts of records.
   2. Personal data, such as the user's name, bedtime, and goals, is logged only when a diagnosis needs it, and always as `.private` or `.private(mask: .hash)`.
   3. Record identifiers use `.private(mask: .hash)`.
   4. Errors log their domain and code as `.public`, and their description as `.private`, because descriptions can contain user data.
   5. Crash messages, such as those passed to `fatalError` and `precondition`, follow the same rules, because crash reports can include them.
7. **Timing is health data.** Every log entry is timestamped, so a message about a routine health event reveals when it happened, even with no value in it. Successful routine health events, such as a saved intake, are logged at `debug` at most. Failures are still logged at `error`, without values, because bug reports need them.
8. **Logs and crash reports leave the device only in a bug report the user sends.** They leave only in an email draft: the log export in Settings, or the same draft offered on the launch after a crash. The user reviews the draft with its attachments, and Mail sends it only if the user taps Send. Nothing is ever sent automatically. The export contains only Half-Life's subsystem, with private values redacted by the system, plus MetricKit crash reports that haven't been sent yet (Article V.6). Under XI.6–7 it carries no health data, and the app itself makes no network request, so Article V.1 still holds.
9. **Enforcement.** SwiftLint custom rules in `.swiftlint.yml` reject the forbidden logging calls (XI.1), the level aliases (XI.4), and `Logger` interpolations without an explicit `privacy:` (XI.5). No rule can recognize a health value, so code review enforces XI.6–7.

## Amendments

Change this constitution only through a deliberate, dedicated edit, never as a side effect of another change. Record each amendment below.

| Date | Article | Change | Author |
|------|---------|--------|--------|
| 2026-09-11 | — | Initial draft | Adam Ure (AI-assisted) |
| 2026-09-11 | V | Privacy and security rules for on-device caffeine and HealthKit data; Apple-only analytics | Adam Ure (AI-assisted) |
| 2026-09-11 | I | TCA extended with Clean Architecture: single-purpose, lifetime-scoped use cases; stateful app-scoped repositories; features observe repositories through use cases | Adam Ure (AI-assisted) |
| 2026-09-11 | VIII | Doc-comment rule scoped to the app target; catalog scope extended to use cases, repositories, and data sources | Adam Ure (AI-assisted) |
| 2026-09-11 | II | UI tests follow the robot pattern: one robot per screen, per-view accessibility identifiers shared with the UI test target, semantic commands and verifications, tests resolve the robot on screen | Adam Ure (AI-assisted) |
| 2026-09-11 | XI | Logging: `Logger` only, one subsystem with a category per type, a level guide, explicit privacy on every interpolated value, no health values and no timestamps of routine health events in logs, a user-sent email draft as the only way logs and MetricKit crash reports leave the device, and SwiftLint enforcement | Adam Ure (AI-assisted) |
| 2026-09-11 | I | I.6: system UI that a framework provides (the Mail composer, HealthKit's authorization sheet) is presented by its data source, and the feature learns the outcome through the repository | Adam Ure (AI-assisted) |
| 2026-09-11 | I | I.7: use cases conform to a Domain `UseCase` protocol and expose their operation as `execute(_:)` instead of `callAsFunction` | Adam Ure (AI-assisted) |
| 2026-09-11 | I | Business rules join the Domain (the layer table and I.10). I.13: repositories stay off the main actor | Adam Ure (AI-assisted) |
| 2026-09-11 | IV | IV.1: the app target's default actor isolation is `nonisolated` instead of `MainActor`, because TCA reducers crash under a `MainActor` default. Only presentation runs on the main actor, and other main-actor code is marked explicitly | Adam Ure (AI-assisted) |
| 2026-09-11 | IV | IV.1 revised: every UI and presentation type states its isolation explicitly. UI types are `@MainActor` even where `View` would infer it, and reducers are `nonisolated`, never `@MainActor`. Domain and Data stay off the main actor, and SwiftLint enforces the UI and reducer rules | Adam Ure (AI-assisted) |
| 2026-09-11 | V | V.1: the drink log syncs to the user's own private CloudKit database. All other user data stays on the device, and nothing read from HealthKit is synced | Adam Ure (AI-assisted) |
| 2026-09-11 | VII | VII.1: text that iOS reads from the Info.plist, such as purpose strings, lives in `InfoPlist.xcstrings`. The Info.plist declares each key with only a placeholder value, and every shipped localization translates every key | Adam Ure (AI-assisted) |
| 2026-09-11 | V | V.3.5: HealthKit no longer has to go through a single data source. More than one data source may wrap it, each still reached only through repositories, so tests and previews never touch real Health data | Adam Ure (AI-assisted) |
| 2026-09-12 | V | V.3.1: a single HealthKit authorization data source requests access, in one sheet for all the types a feature needs. The data sources that read or write a type never request authorization themselves | Adam Ure (AI-assisted) |
| 2026-09-12 | V | V.3.1: onboarding's permissions step may request Health access for the types the app's features read, when the user taps to allow it, after explaining each type. Access is still never requested automatically at launch | Adam Ure (AI-assisted) |
