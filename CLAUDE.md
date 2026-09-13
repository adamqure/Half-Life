# Half-Life

iOS caffeine-tracking app built with SwiftUI, The Composable Architecture (TCA), and Clean Architecture (Xcode 26, iOS 26.5 deployment target, Swift default actor isolation = `nonisolated`).

Every change to this repository must comply with the three governing documents below. They are not suggestions — a change that violates any of them is not done.

## 1. Constitution — `constitution.md`

@constitution.md

- `constitution.md` defines the foundational principles all code in this repo follows: architecture, dependencies, privacy, accessibility, localization, documentation, code style, and logging. Read it before starting any change.
- It takes precedence over everything else in this file, over existing code patterns, and over convenience. If a request conflicts with it, stop and raise the conflict instead of working around it.
- Where it leaves something undecided, ask rather than choosing.
- Only change `constitution.md` itself when explicitly asked.

### Architecture at a glance (constitution Article I is authoritative)

- **Presentation → Domain ← Data.** Domain imports nothing but Swift and Foundation.
- **Reducers, App Intents, and widgets call use cases**, never repositories or data sources. App Intents and widgets are presentation without a reducer (Article I.18).
- **Use cases** are single-purpose (`<Verb><Noun>UseCase`, conforming to `UseCase` with one `execute(_:)`) and lifetime-scoped to their feature. They hold no state.
- **Repositories** are app-scoped, stateful sources of truth that expose an `AsyncStream` of their data.
- **Features observe** repository data through `Observe…UseCase` in a `.run` effect started from `.task { await store.send(.task).finish() }`, and reduce each emitted value into `State`. Don't write repository-owned data into `State` optimistically.
- **Only data sources** touch HealthKit, SwiftData, or other system frameworks. That includes presenting system UI such as the Mail composer, whose outcome reaches the feature through the repository (Article I.6).
- The DocC catalog's `Architecture` article shows the folder layout and patterns. Keep it current in the same change.

### Actor isolation (settled 2026-09-11, constitution Article IV.1)

The app target has no `SWIFT_DEFAULT_ACTOR_ISOLATION` setting, so its default isolation is `nonisolated`. Don't add the setting back.

Only UI and presentation run on the main actor, and they state their isolation explicitly:

- **Views, the app, and other UI types:** `@MainActor`, on the line directly above the declaration, even where `View` or `App` would infer it.
- **`@Reducer` types:** `nonisolated`, written out (`@Reducer nonisolated struct …`), and never `@MainActor`. A reducer reduces `Sendable` state, and TCA runs it on the `@MainActor` store.
- **App Intents, their entities, the App Shortcuts provider, and `AppEnum`s:** the target's `nonisolated` default, not written out, and never `@MainActor` (Article IV.1.4). Written on a type with `@Parameter` or `@Property` properties, `nonisolated` is a compiler warning.
- **Domain:** `nonisolated`. **Repositories:** their own actors, off the main actor.

SwiftLint enforces the UI, reducer, and App Intent rules. The evidence comes from scratch copies of the project, tested against TCA 1.26.2 on 2026-09-11:

| Target default | Reducer | Result |
|----------------|---------|--------|
| `MainActor` | Unannotated | Reducers crash at runtime with infinite `reduce`/`_reduce` recursion |
| `MainActor` | `nonisolated`, with its `State`/`Action` | TCA's macro-generated conformances produce warnings (Article IX) |
| `nonisolated` | `@MainActor` | The `TestStore` tests crash |
| `nonisolated` | `nonisolated` struct and enum reducers, with a `@MainActor` view | No isolation warnings. Tests pass, including an effect that sends an action back |

## 2. AI interaction log — `ai_log.md`

- `ai_log.md` is the timestamped log of **every** AI interaction on this project. Questions, reviews, debugging, and planning count too, not just changes. Its **Rules** section defines the format; read it before finishing any task.
- Log every task, including ones that change no files. A task is not finished until its entry is appended, and for a change the entry goes in the same commit.
- Take every timestamp from the clock with `date '+%Y-%m-%d %H:%M %z'`. Run it when you receive the prompt that starts a task, at each later prompt or decision, and when the task ends. Never estimate a time afterwards; if one must be reconstructed, mark it `~` and say from what.
- Committed entries are never edited or deleted.
- Full session transcripts live in `ai_transcripts/`, one file per session. Re-run `scripts/export_transcripts.py` before every commit, and link each entry to its session's transcript in the **Transcript** field. The exporter redacts email addresses and the home path, but it can't spot secrets or health data typed into a prompt, so review the transcript diff before committing.

## 3. Testing principles

### Test-driven development (required)

Work in red → green → refactor cycles:

1. **Red** — write a failing test that describes the behavior you're about to add or the bug you're about to fix. Run it and confirm it fails for the expected reason.
2. **Green** — write the minimum production code needed to make it pass.
3. **Refactor** — clean up with the tests green.

- No production code without a failing test first. Bug fixes start with a test that reproduces the bug.
- Don't weaken, skip, or delete an existing test to make a change pass. If a test is wrong, say so and explain why before changing it.
- Report test results honestly — if anything fails, show the output.

### Code coverage (minimum 80%)

- The `Half-Life` app target must stay at **≥ 80% line coverage**, measured from a full test run (unit tests and UI tests both count). The shared scheme limits coverage to the app target, so package code doesn't count.
- New or changed code should be covered by the tests written in the TDD cycle; a change must not drop overall coverage below 80%.
- Check coverage before calling a change done, and state the resulting number.

### What to test, per layer

- Unit tests use **Swift Testing** (`import Testing`, `@Test`, `#expect`, `#require`) in `Half-LifeTests/`. Don't add new XCTest unit tests.
- **Reducers:** exhaustive `TestStore`, with use cases overridden. Never use live dependencies in tests.
- **Use cases:** against in-memory fake repositories.
- **Repositories:** against fake data sources, including that the `AsyncStream` emits the current value first and then each change.
- **UI:** XCTest/XCUITest in `Half-LifeUITests/`, following the robot pattern (constitution Article II.5–11):
  - One `<Feature>Robot` per screen in `Half-LifeUITests/Robots/`, conforming to `Robot` and listed in `Robots.all`. Tests never query `XCUIElement`s. They call a robot's semantic commands and verifications.
  - Accessibility identifiers live in `<View>AccessibilityID.swift` next to the view. Its target membership includes **both** `Half-Life` and `Half-LifeUITests`. Don't write identifiers as string literals. Don't try `@testable import Half_Life` from the UI tests: it compiles but fails to link.
  - After launch and after any navigation, the test resolves which expected robot is on screen, or fails.
  - Every robot exposes an accessibility audit (`performAccessibilityAudit()`), and every screen's tests run it.
  - Widgets, Siri snippets, and App Intents' dialogs have no robot. They're covered by unit tests, previews, and an Accessibility Inspector check (Article I.20).
- **Tooling:** scripts in `scripts/` are written test-first too, with Python `unittest` tests in `scripts/tests/`. They use only the standard library of the Python 3.9 bundled with Xcode (`/usr/bin/python3`).

## Product spec

@spec.md

- `spec.md` is femmli's case-study brief. It defines what the app must do, what's out of scope, what gets submitted, and how the work is judged. It's a verbatim transcription of `spec/brief.pdf`, which stays authoritative. `spec/prototype/` holds screenshots of the prototype that the brief calls "a working directional reference, not a spec."
- `roadmap.md` sets the order of the work. The brief defines what the work must satisfy. Where the brief conflicts with `constitution.md`, the constitution wins. Raise the conflict with the user; don't quietly build to either one.
- Edit `spec.md` or anything in `spec/` only to correct a transcription error.

## Feature order

`roadmap.md` holds the owner's feature implementation order, ranked by value ÷ effort with dependencies overriding. Build features in that order unless the user says otherwise. Re-rank or re-score items only when the user asks.

## Commands

TCA and its dependencies use Swift macros, so command-line builds pass `-skipMacroValidation`. This is acceptable only because those packages are approved dependencies (constitution Article III).

```sh
# Build
xcodebuild build -project Half-Life.xcodeproj -scheme Half-Life -skipMacroValidation \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5'

# Full test run with coverage (unit + UI). The result bundle must not already exist.
rm -rf build/TestResults.xcresult
xcodebuild test -project Half-Life.xcodeproj -scheme Half-Life -skipMacroValidation \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -resultBundlePath build/TestResults.xcresult

# Coverage report
xcrun xccov view --report --only-targets build/TestResults.xcresult

# Faster iteration during a TDD cycle: unit tests only (not valid for the coverage check)
xcodebuild test ... -only-testing:Half-LifeTests

# Format (swift-format ships with Xcode), then lint — both must be clean
xcrun swift-format format --in-place --recursive Half-Life Half-LifeTests Half-LifeUITests Half-LifeWidgets
xcrun swift-format lint --strict --recursive Half-Life Half-LifeTests Half-LifeUITests Half-LifeWidgets
swiftlint lint --strict

# Export AI session transcripts to ai_transcripts/ (before every commit), and test the exporter
/usr/bin/python3 scripts/export_transcripts.py
/usr/bin/python3 -m unittest discover -s scripts/tests

# Build DocC documentation (must produce no warnings)
xcodebuild docbuild -project Half-Life.xcodeproj -scheme Half-Life -skipMacroValidation \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath build/DocBuild
```

## Git workflow

- Work directly on `main`; no feature branches or PRs.
- Commit only when asked. Each commit contains the change, its tests, its documentation, and its `ai_log.md` entry together.
- Commit messages follow **Conventional Commits**: `<type>(<optional scope>): <imperative summary>`, e.g. `feat(log): add caffeine intake entry`. Types: `feat`, `fix`, `test`, `refactor`, `docs`, `style`, `build`, `ci`, `chore`. Breaking changes use `!` after the type.
- `build/` and `xcuserdata/` are git-ignored. `Package.resolved` and the shared scheme are committed.

## Dependencies

- Never add a Swift package (or any third-party code) without explicit approval. Propose it first: package, version, purpose, and alternatives considered.
- Approved and added: `swift-composable-architecture` (pinned from 1.26.2, up to the next major version) and its transitive Point-Free dependencies.

## Every change must also

- **Protect privacy** — on device, except the drink log's sync to the user's private CloudKit database; nothing read from HealthKit is synced. HealthKit only through data sources, each reached through a repository, with authorization requested only by the HealthKit authorization data source (V.3.1), no health data in logs, Apple-only analytics (Article V).
- **Be accessible** — VoiceOver labels on interactive elements, decorative images hidden, Dynamic Type support, no color-only signals (Article VI).
- **Be localization-ready** — no hard-coded user-facing strings; everything goes through `Half-Life/Localizable.xcstrings`, or through `Half-Life/InfoPlist.xcstrings` for Info.plist text such as purpose strings, or through `Half-Life/AppShortcuts.xcstrings` for App Shortcut phrases. `Info.plist` holds only a placeholder for each of those keys, and every shipped language translates them all (Article VII).
- **Be documented** — `///` DocC comments on every non-`private`/`fileprivate` declaration in the app target, and architecture changes reflected in `Half-Life/Documentation.docc/` in the same change (Article VIII).
- **Be formatted and lint-clean** — swift-format and SwiftLint with zero violations, no compiler warnings (Article IX).
- **State isolation explicitly** — `@MainActor` directly above every UI type, `@Reducer nonisolated` on every reducer and never `@MainActor`, never `@MainActor` on an App Intent, its entities, the App Shortcuts provider, or an `AppEnum`, and no main-actor code in Domain or Data (Article IV.1).
- **Log safely** — only through `Logger(for:)`, never `print`. Use the level that fits (anything a bug report needs goes at `notice` or above), and give every interpolated value an explicit `privacy:`. Never log health values, and log routine health events at `debug` at most, because timestamps reveal when they happened (Article XI, DocC `Logging` article).

## Code conventions

- Every Swift file starts with the project's ASCII-art banner header followed by `// <Target> <FileName>` (copy it from an existing file).

## Definition of done

Before reporting any change as complete, confirm all of these:

- [ ] Complies with `constitution.md`, including the layer rules
- [ ] Written test-first; all unit and UI tests pass
- [ ] `Half-Life` target coverage ≥ 80% (state the number)
- [ ] Private (including logs, Article XI), accessible, and localization-ready
- [ ] DocC comments added; `Architecture` article updated if architecture changed; `docbuild` clean
- [ ] swift-format and SwiftLint clean; no compiler warnings
- [ ] No unapproved dependencies added
- [ ] `ai_log.md` entry appended per its Rules
