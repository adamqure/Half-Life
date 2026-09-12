# Architecture

How Half-Life's features, use cases, repositories, and data fit together.

## Overview

Half-Life combines The Composable Architecture (TCA) with Clean Architecture (constitution Article I). The code is split into three layers, and dependencies always point inward, toward Domain.

| Layer | Contains | May depend on |
|-------|----------|---------------|
| Presentation | TCA features: reducers and views | Domain |
| Domain | Entities, business rules, single-purpose use cases, repository protocols | Nothing |
| Data | Repository implementations and data sources | Domain |

Data flows in one direction:

```
 Command:  View ─▶ Action ─▶ Reducer ─▶ Effect ─▶ UseCase ─▶ Repository ─▶ DataSource
 Update:   Repository ─▶ AsyncStream ─▶ Observe…UseCase ─▶ Action ─▶ Reducer ─▶ State ─▶ View
```

Repositories are the single source of truth. A feature never writes repository-owned data into its `State` directly. It sends a command through a use case, and the new data arrives back through its observation.

A repository can execute a Domain business rule to derive what it publishes from the data it holds. For example, it can turn caffeine intakes into a decay curve before the curve goes out on its `AsyncStream`.

A use case performs one business operation, and that operation can act on more than one repository.

Repositories can share a data source. A data source that stores data signals every repository subscribed to it when that data changes, and each repository re-reads what it needs and publishes it. A write through one repository reaches the others this way, so no use case writes twice just to inform another repository. For example, a drink logged through `DrinkLogRepository` reaches ``CaffeineDecayRepository`` through the drink data source they share (see <doc:DrinkComposer>).

Only UI and presentation run on the main actor. The app target's default actor isolation is `nonisolated` (constitution Article IV.1), because TCA reducers crash under a `MainActor` default, and marking TCA types `nonisolated` under that default leaves compiler warnings. Every UI and presentation type states its isolation explicitly, and SwiftLint enforces it.

- **UI types are `@MainActor`.** Views, the app, and other UI types have `@MainActor` on the line directly above the declaration, even where `View` or `App` would infer it. TCA's `Store` is `@MainActor`.
- **Reducers are `nonisolated`.** Each `@Reducer` type is written `@Reducer nonisolated struct …`, and is never `@MainActor`, because that crashes at runtime. A reducer reduces `Sendable` state, and the store runs it on the main actor.
- **Domain types are immutable `Sendable` values.** Each actor works on its own copy, so there's no shared mutable state to protect. Business rules and use cases hold no state. Domain structs written before the default changed still say `nonisolated`, which is redundant but harmless.
- **Protocols never say `nonisolated`.** In the same module, an actor that conforms to a `nonisolated` protocol inherits `nonisolated`, which an actor can't be, so the module fails to build. The error only appears once the protocol also has a second conformer in the module, such as a test double in a dependency registration. Under the target's default, the keyword adds nothing to a protocol anyway.
- **Repositories are their own actors** (Article I.13). A repository executes business rules on its own actor and hands entities to presentation.

### Lifetimes

| Kind | Lifetime | Holds state? |
|------|----------|--------------|
| Repository | App: created once, outlives every feature | Yes, the source of truth for its data |
| Use case | The owning feature | No, only references to repositories |
| Business rule | The repository that executes it | No, it's a stateless calculation |
| Feature `State` | The feature's presentation | Yes, a reduced projection of repository data plus UI state |
| Observation effect | The feature's view, via `.task { await store.send(.task).finish() }` | No |

## Folder structure

```
Half-Life/
├── App/                     App entry point and root feature
│   └── Dependencies/        DependencyKey registrations: one file per repository, with the use cases built on it
├── Features/<Feature>/      <Feature>Feature.swift (reducer), <Feature>View.swift,
│                            <Feature>ViewAccessibilityID.swift (also in the UI test target)
├── DesignSystem/            Presentation constants: Spacing, CornerRadius, Sizing, Elevation, Typography
├── Logging/                 Logger+HalfLife.swift: Logger(for:), Half-Life's subsystem and categories (see Logging)
├── Assets.xcassets/Colors/  Semantic color sets, one folder per category (see Design System)
├── Domain/
│   ├── Entities/            Plain Sendable, Equatable value types
│   ├── BusinessRules/       Stateless calculations that repositories execute
│   ├── UseCases/            The UseCase protocol, and one file per use case
│   └── Repositories/        Repository protocols
└── Data/
    ├── Repositories/        Live repository implementations (Live<Noun>Repository)
    └── DataSources/         Framework wrappers (<Framework><Noun>DataSource)

Half-LifeUITests/
├── Robots/                  Robot.swift (protocol and screen resolution), <Feature>Robot.swift
└── <Feature>UITests.swift   Scenarios written against robots
```

## Patterns

### A single-purpose use case

Every use case conforms to ``UseCase`` and exposes its one operation as `execute(_:)` (constitution Article I.7). The operation takes one `Input` and returns one `Output`, and either can be `Void`.

```swift
/// Streams the active caffeine curve, starting with one calculated for the current time.
nonisolated struct ObserveCaffeineCurveUseCase: UseCase {
    let repository: any CaffeineDecayRepository

    func execute(_ input: Void) -> AsyncStream<[CaffeineLevel]> {
        repository.curve()
    }
}
```

The protocol requires `async throws`. A use case that neither suspends nor throws, like this one, can leave both out, and a caller using the concrete type then needs no `try await`. Code that goes through the protocol, such as a generic test helper, still writes `try await`.

### Registering a repository and its use cases

Registrations live in `App/Dependencies/`, one file per repository, with the use cases built on it (constitution Article I.15). Each repository and use case gets a live, a test, and a preview value. A test value reports an issue when a test uses it without overriding it.

A use case's values are built from its repository key's values directly, never through `@Dependency`:

```swift
enum CurrentTimeRepositoryKey: DependencyKey {
    static let liveValue: any CurrentTimeRepository = LiveCurrentTimeRepository(dataSource: SystemClockDataSource())
    static let previewValue: any CurrentTimeRepository = liveValue
    static let testValue: any CurrentTimeRepository = UnimplementedCurrentTimeRepository()
}

private enum ObserveTimeOfDayUseCaseKey: DependencyKey {
    static let liveValue = ObserveTimeOfDayUseCase(currentTime: CurrentTimeRepositoryKey.liveValue)
    static let previewValue = ObserveTimeOfDayUseCase(currentTime: CurrentTimeRepositoryKey.previewValue)
    static let testValue = ObserveTimeOfDayUseCase(currentTime: CurrentTimeRepositoryKey.testValue)
}
```

Dependency values are cached. A use case that looked up its repository through `@Dependency` would capture whichever repository was current the first time it was built, so one test's override would leak into later tests. Building from the key's values keeps each live use case on the one app-scoped repository, which `DependencyRegistrationTests` checks. Reducer tests override the use case itself.

A repository key is internal when use cases in other files are built from it, like `CurrentTimeRepositoryKey`. Otherwise it's private to its file.

A data source that several repositories share gets its own internal key, like ``DrinkLogDataSourceKey``, and each repository key builds from its values. That keeps one instance behind every repository.
- **No property.** It has no `DependencyValues` property, because only repositories use data sources.
- **Values.** Its preview value is an empty in-memory store. Its live value opens the device's store, and falls back to an in-memory store if that store won't open.

Tests never read a live value that opens the device's store. Tests that open a SwiftData store, including anything that reads a preview store, run under the serialized `SwiftDataStoreTests` suite in the test target. A full parallel run once crashed inside Core Data while a store was opening, and the crash couldn't be reproduced on demand.

### A feature that observes a repository and issues commands

```swift
@Reducer
struct CaffeineLogFeature {
    @ObservableState
    struct State: Equatable {
        var entries: [CaffeineEntry] = []
    }

    enum Action {
        case task
        case entriesUpdated([CaffeineEntry])
        case logTapped(milligrams: Double)
        case logFailed
    }

    @Dependency(\.observeCaffeineEntries) var observeCaffeineEntries
    @Dependency(\.logCaffeineIntake) var logCaffeineIntake

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                return .run { send in
                    for await entries in observeCaffeineEntries.execute(()) {
                        await send(.entriesUpdated(entries))
                    }
                }
            case let .entriesUpdated(entries):
                state.entries = entries
                return .none
            case let .logTapped(milligrams):
                return .run { _ in
                    try await logCaffeineIntake.execute(milligrams)
                } catch: { _, send in
                    await send(.logFailed)
                }
            case .logFailed:
                return .none
            }
        }
    }
}
```

The view starts the observation for exactly as long as it's on screen:

```swift
CaffeineLogView(store: store)
    .task { await store.send(.task).finish() }
```

### Logging

Reducers, repositories, and data sources log through `Logger(for:)`. Views and Domain don't log, and Domain can't, because `Logger` isn't available through Foundation. A reducer logs a use case's failure in its effect's `catch:`. Levels, redaction, and the log export are covered in <doc:Logging> (constitution Article XI).

## UI tests

UI tests follow the robot pattern (constitution Article II.5–11). A test describes a scenario in the app's domain language. Each screen's robot translates that language into interactions with the screen's elements, which it finds by accessibility identifier.

```
 Test ─▶ resolve robot on screen ─▶ Robot command / verification ─▶ XCUIElement (by identifier)
```

### Identifiers shared between a view and its robot

Each view keeps its identifiers in its own `<View>AccessibilityID.swift` file. In the File inspector, that file's **Target Membership** includes both `Half-Life` and `Half-LifeUITests`, and it's the only app file in the UI test target. The robot can't reference a type nested in the view, or use `@testable import Half_Life`. The UI test bundle runs in Xcode's test runner, not in the app, and isn't linked against it, so any reference to an app symbol fails to link.

```swift
/// Accessibility identifiers for the caffeine log screen, shared with the UI test target.
enum CaffeineLogViewAccessibilityID {
    /// The screen's root element, which robots use to detect the screen.
    static let screen = "caffeineLogView.screen"
    /// The button that logs a new caffeine entry.
    static let addButton = "caffeineLogView.addButton"
}
```

The view applies them. Its root becomes an accessibility container that carries the `screen` identifier, so the identifier marks the container itself rather than its children:

```swift
VStack {
    Button("Add") { store.send(.addTapped) }
        .accessibilityIdentifier(CaffeineLogViewAccessibilityID.addButton)
}
.accessibilityElement(children: .contain)
.accessibilityIdentifier(CaffeineLogViewAccessibilityID.screen)
```

A new identifier file joins the UI test target through a membership exception on the synchronized `Half-Life` folder, which Xcode writes when you tick the target in the File inspector.

### A robot

A robot conforms to `Robot` (`Half-LifeUITests/Robots/Robot.swift`) and names its screen's identifier. It owns a private field for each element it controls. Its API is made of semantic commands and verifications, and commands never return another robot. Every robot gets `auditAccessibility()` and `screenshot()` from the protocol, and is listed in `Robots.all` so resolution failures can name the screen that's showing.

```swift
struct CaffeineLogRobot: Robot {
    static let screenIdentifier = CaffeineLogViewAccessibilityID.screen

    let app: XCUIApplication

    private var addButton: XCUIElement { app.buttons[CaffeineLogViewAccessibilityID.addButton] }

    func addEntry(milligrams: Int) {
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()
        // …
    }

    func verifyEntryCount(_ count: Int, file: StaticString = #filePath, line: UInt = #line) {
        // Assert against the robot's own elements; report at the test's call site.
    }
}
```

### A test

A test resolves which robot is on screen after launch, and again after any command that can change the screen. It names the robots it expects and fails if none of them appears.

```swift
@MainActor
func testLoggingAnEntry() throws {
    let app = XCUIApplication()
    app.launch()

    let log = try app.resolve(CaffeineLogRobot.self)
    log.addEntry(milligrams: 95)
    log.verifyEntryCount(1)
    try log.auditAccessibility()
}
```

Where more than one screen can appear, the test resolves among several robots and branches only on those:

```swift
switch try app.resolve(expecting: [CaffeineLogRobot.self, OnboardingRobot.self]) {
case let log as CaffeineLogRobot: …
case let onboarding as OnboardingRobot: …
default: XCTFail("Resolved a robot that wasn't expected")
}
```

If none of the expected screens appears within the timeout, resolution throws `UnexpectedScreenError`, which fails the test with a message such as "Expected AbsentRobot, but AppRobot is showing." If more than one expected screen is showing, the first robot listed wins. `RobotResolutionUITests` covers both behaviors.

### Robots

| Robot | Screen | Identifiers |
|-------|--------|-------------|
| `AppRobot` | ``AppView``, the root screen | `AppViewAccessibilityID` (`screen`, `logButton`) |
| `DrinkComposerRobot` | ``DrinkComposerView``, the drink composer sheet | `DrinkComposerViewAccessibilityID` (`screen`, `drinkTiles` and a tile per drink, the quantity buttons, the "When" choices, `addButton`, `closeButton`) |
| `TodayRobot` | ``TodayView``, the Today screen, with ``DailyGreetingView`` and ``CaffeineDecayView`` | `TodayViewAccessibilityID` (`screen`), `DailyGreetingViewAccessibilityID` (`header`), `CaffeineDecayViewAccessibilityID` (`level`, `curve`) |

## Features

| Feature | Responsibility | Use cases | Parent |
|---------|----------------|-----------|--------|
| ``TodayFeature`` | The Today screen. It composes one child feature per card (<doc:TodayScreen>). | None of its own | ``AppFeature`` |
| ``DailyGreetingFeature`` | The greeting for the time of day, with the user's name and today's date | ``ObserveUserProfileUseCase``, ``ObserveTimeOfDayUseCase`` | ``TodayFeature`` |
| ``CaffeineDecayFeature`` | The decay card: the caffeine in your system now, the level at bedtime, when the last cup is half gone, and the curve | ``ObserveCaffeineCurveUseCase``, ``ObserveCaffeineStatusUseCase``, ``ObserveTimeOfDayUseCase`` | ``TodayFeature`` |
| ``AppFeature`` | The root: the Today screen, and the log button that presents the drink composer as a sheet | None of its own | None |
| ``DrinkComposerFeature`` | Logs a drink chosen from a sideways row of tiles, with its quantity and when it was consumed. It opens on the last drink logged (<doc:DrinkComposer>) | ``LogDrinkUseCase``, ``ObserveLoggedDrinksUseCase`` | ``AppFeature``, as a sheet |

## Use cases

| Use case | Operation | Repositories |
|----------|-----------|--------------|
| ``ObserveCaffeineCurveUseCase`` | Streams the active caffeine curve | ``CaffeineDecayRepository`` |
| ``ObserveCaffeineStatusUseCase`` | Streams the caffeine status: the level now and the decay card's two tips, in a given calendar (<doc:TodayScreen>) | ``CaffeineDecayRepository`` |
| _None yet_ | `SendBugReportUseCase` and `ObserveBugReportStatusUseCase` are designed in <doc:Logging> but not yet built. | `BugReportRepository`, plus `CrashReportRepository` for sending |
| ``LogDrinkUseCase`` | Records a drink from the composer, one-tap favourites, or an App Intent, consumed a given number of seconds ago (<doc:DrinkComposer>) | ``CurrentTimeRepository``, ``DrinkLogRepository`` |
| ``ObserveLoggedDrinksUseCase`` | Streams every logged drink, oldest first (<doc:DrinkComposer>) | ``DrinkLogRepository`` |
| ``ObserveUserProfileUseCase`` | Streams the user's profile (<doc:TodayScreen>) | ``UserProfileRepository`` |
| ``ObserveTimeOfDayUseCase`` | Streams each minute with the part of the day it falls in, by executing ``DayPeriodRule`` (<doc:TodayScreen>) | ``CurrentTimeRepository`` |

## Business rules

| Business rule | Calculates | Executed by |
|---------------|------------|-------------|
| ``CaffeineDecayRule`` | The active caffeine curve under Bateman absorption, which intakes count and which are negligible, and when an intake is half gone (<doc:CaffeineDecayModel>) | ``LiveCaffeineDecayRepository`` |
| ``CaffeineStatusRule`` | The caffeine status: the level now, the intakes still counting, when the last one is half gone, and the level at the next bedtime. It asks ``CaffeineDecayRule`` for each of them (<doc:TodayScreen>). | ``LiveCaffeineDecayRepository`` |
| ``DrinkLogRule`` | Whether a drink may be logged: a quantity of at least 1, consumed no later than the current time (<doc:DrinkComposer>) | ``LiveDrinkLogRepository`` |
| ``DayPeriodRule`` | The part of the day a moment falls in, for the greeting (<doc:TodayScreen>) | ``ObserveTimeOfDayUseCase``. It's the only use case that executes a business rule; the owner chose this over a second clock repository. |

## Repositories

| Repository | Owns | Data sources |
|------------|------|--------------|
| ``CaffeineDecayRepository``, implemented by ``LiveCaffeineDecayRepository`` | The caffeine curve (<doc:CaffeineDecayModel>), and the caffeine status, recalculated every minute (<doc:TodayScreen>) | ``DrinkLogDataSource``, shared with ``DrinkLogRepository``; ``HalfLifeDataSource``; ``AbsorptionRateDataSource``; ``BedtimeDataSource``; ``ClockDataSource`` |
| _None yet_ | `BugReportRepository` is designed in <doc:Logging> but not yet built. It will own the bug report's status. | `OSLogEntryDataSource`, `MessageUIMailDataSource` (not yet built) |
| _None yet_ | `CrashReportRepository` is designed in <doc:Logging> but not yet built. It will own the unsent crash reports. | `MetricKitCrashReportDataSource`, `FileCrashReportDataSource` (not yet built) |
| ``DrinkLogRepository``, implemented by ``LiveDrinkLogRepository`` | Every logged drink (<doc:DrinkComposer>) | ``DrinkLogDataSource``, shared with ``CaffeineDecayRepository``; ``ClockDataSource`` |
| ``LiveCurrentTimeRepository`` (``CurrentTimeRepository``) | The current time: `now()`, and a stream that emits at every whole minute (<doc:DrinkComposer>) | ``ClockDataSource`` |
| ``UserProfileRepository``, implemented by ``LiveUserProfileRepository`` | What the user has told the app about themselves: for now, only their name (<doc:TodayScreen>) | ``UserProfileDataSource`` |

## Data sources

| Data source | Wraps |
|-------------|-------|
| ``HealthKitRestingHeartRateDataSource``, implementing ``RestingHeartRateDataSource`` | HealthKit's statistics query, for the average of one day's resting heart rate samples (<doc:RestingHeartRate>). It only reads, and no repository reads it yet. Constitution Article V.3.5 allows one HealthKit data source per kind of Health data. |
| ``HealthKitStepCountDataSource``, implementing ``StepCountDataSource`` | HealthKit's statistics query, for the total of one day's step count samples (<doc:StepCount>). It only reads, and no repository reads it yet. |
| ``HealthKitSleepDataSource``, implementing ``SleepDataSource`` | HealthKit's sample query, for the sleep analysis samples that overlap a range, and one observer query per subscriber for changes (<doc:SleepData>). It only reads, on `HKHealthStore.halfLife`, the app's one health store. No repository reads it yet. |
| _None yet_ | A HealthKit authorization data source, built with onboarding (roadmap rank 6). It will ask in one sheet for every Health type a feature needs, and it's the only data source that requests Health access (constitution Article V.3.1). |
| ``SystemClockDataSource`` (``ClockDataSource``) | The system clock, through `Date.now`, and `Task.sleep` for the minute stream. It's the only code that reads the clock. |
| ``SwiftDataDrinkLogDataSource``, implementing ``DrinkLogDataSource`` | SwiftData, in a store that syncs to the user's private CloudKit database (constitution Article V.1). It stores logged drinks and their negligible marks, and signals changes to the repositories that read it. The sync is configured, and the rest of the CloudKit work is roadmap rank 23. |
| ``StandardHalfLifeDataSource``, implementing ``HalfLifeDataSource`` | Nothing yet. It returns the standard half-life until the tuning features store a user's own. |
| ``StandardAbsorptionRateDataSource``, implementing ``AbsorptionRateDataSource`` | Nothing yet. It returns the standard 13-minute absorption half-life until something can store a tuned rate. |
| ``StandardBedtimeDataSource``, implementing ``BedtimeDataSource`` | Nothing yet. It returns the standard 10:30pm bedtime until the onboarding survey or Settings (roadmap ranks 6 and 21) stores a user's own. |
| ``EmptyUserProfileDataSource``, implementing ``UserProfileDataSource`` | Nothing yet. It has no stored profile until the onboarding survey (roadmap rank 6) stores one. |
| _None yet_ | `OSLogEntryDataSource` (wraps `OSLogStore`) and `MessageUIMailDataSource` (wraps MessageUI's Mail composer, which it presents itself, per constitution Article I.6) are designed in <doc:Logging> but not yet built. |
| _None yet_ | `MetricKitCrashReportDataSource` (wraps `MXMetricManager`) and `FileCrashReportDataSource` (stores unsent crash reports) are designed in <doc:Logging> but not yet built. |

## Navigation

``AppView`` is the root. It shows the Today screen, with the log button pinned below it. The log button presents ``DrinkComposerView`` as a sheet sized to its content: ``AppFeature`` holds the composer's state in a `@Presents` property, so the sheet is state-driven (constitution Article I.6). The composer closes itself through TCA's `dismiss` dependency, after a drink is logged or when the user taps Close.

System UI that a framework provides, such as the Mail composer or HealthKit's authorization sheet, is presented by the data source that wraps the framework, not by feature state. The feature learns the outcome through the repository (constitution Article I.6).

## Data and privacy

All user data stays on the device, except the drink log, which syncs to the user's private CloudKit database (constitution Article V.1). List every piece of stored data here.

| Data | Stored in | Protection class | Why it's collected |
|------|-----------|------------------|--------------------|
| Logged drinks: type, quantity, caffeine, time consumed, and the negligible mark | A SwiftData store in the app container, synced to the user's private CloudKit database (``SwiftDataDrinkLogDataSource``) | iOS's default, `NSFileProtectionCompleteUntilFirstUserAuthentication`, chosen by the owner on 2026-09-11 (Article V.4). CloudKit imports and Siri need the store while the device is locked after its first unlock. | The decay curve and the drink log. The user logs each drink. |
| Resting heart rate: one day's average, read from Apple Health (``HealthKitRestingHeartRateDataSource``) | Not stored. It's read from Health when needed and held only in memory, and never synced to iCloud (Article V.3.4). | Not written by the app | To set heart rate against caffeine habits, as the brief asks. No feature reads it yet (<doc:RestingHeartRate>). |
| Sleep: stage intervals read from Apple Health (``HealthKitSleepDataSource``) | Not stored. It's read from Health when needed and held only in memory, and never synced to iCloud (Article V.3.4). | Not written by the app | To set sleep against caffeine timing, as the brief asks. No feature reads it yet (<doc:SleepData>). |
| Step count: one day's total, read from Apple Health (``HealthKitStepCountDataSource``) | Not stored. It's read from Health when needed and held only in memory, and never synced to iCloud (Article V.3.4). | Not written by the app | To set activity against caffeine habits, as the brief asks. No feature reads it yet (<doc:StepCount>). |
| Bug report log attachment (designed in <doc:Logging>, not yet built) | Memory only, handed to the Mail composer as data. Mail keeps its own copy once the draft is sent or saved. | Not written by the app | Attached to a bug report that the user chooses to send. It holds no health values (Article XI). |
| Unsent crash reports (designed in <doc:Logging>, not yet built) | Application Support, until a draft carrying them is sent | `NSFileProtectionComplete` | Attached to the next bug report the user sends. MetricKit's crash diagnostic: call stacks, exception codes, and device and OS metadata. No health values (Article XI.6.5). |

### Purpose strings

A purpose string is the text iOS shows when Half-Life asks for access to a protected resource. The app declares five.

| Key | Shown when Half-Life asks to |
|-----|------------------------------|
| `NSHealthShareUsageDescription` | Read Health data |
| `NSHealthUpdateUsageDescription` | Save caffeine to Health |
| `NSHealthClinicalHealthRecordsShareUsageDescription` | Read clinical health records. Reading them also needs the HealthKit capability's Clinical Health Records option, which the app doesn't have yet. |
| `NSSiriUsageDescription` | Use Siri |
| `NSFaceIDUsageDescription` | Use Face ID |

The text lives in `InfoPlist.xcstrings`, the String Catalog for the Info.plist, so it's localized like every other user-facing string (constitution Articles V.3.2 and VII.1).

- **`Info.plist` still declares each key**, with the value `Localized in InfoPlist.xcstrings`. App Store validation and the frameworks look for the key in the Info.plist itself, and a key that exists only in the catalog doesn't appear there. Don't enter purpose strings in the target's build settings or in Xcode's capability editor, which writes them into `project.pbxproj` as `INFOPLIST_KEY_…` settings.
- **The catalog's text replaces the placeholder** in every localization that translates the key. A localization that doesn't translate it shows the Info.plist's placeholder, not the English text. So every localization translates every purpose string before it ships.
- **The entries are manual.** Xcode's localization sync leaves manual entries alone. It adds `CFBundleName` to the catalog by itself, and that entry is kept so the sync doesn't change the file.

`PurposeStringTests` checks this:

- **PURPOSE-1:** `Info.plist` declares every key.
- **PURPOSE-2:** every localization the app ships translates every key.
- **PURPOSE-3:** the lookup the system uses returns the catalog's text, not the placeholder.
