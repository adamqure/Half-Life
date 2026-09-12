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
│   ├── Dependencies/        DependencyKey registrations: one file per repository, with the use cases built on it
│   └── UITesting/           The UI tests' launch configuration and simulated permissions (see Onboarding)
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
- **Values.** Its preview value is an empty in-memory store. Its live value opens the device's store, and falls back to an in-memory store if that store won't open. When a UI test launches the app, the live value is always an empty in-memory store, so every UI test starts from the same log (LAUNCH-3 in <doc:Onboarding>).

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

A test launches through `launchPastOnboarding()` or `launchAtOnboarding()`, from `Robot.swift`. Each sets a launch environment key that starts the app with a temporary profile and simulated permissions, so a test never meets a system prompt or the simulator's own profile (<doc:Onboarding>). A test resolves which robot is on screen after launch, and again after any command that can change the screen. It names the robots it expects and fails if none of them appears.

```swift
@MainActor
func testLoggingAnEntry() throws {
    let app = XCUIApplication()
    app.launchPastOnboarding()

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
| `DrinkComposerRobot` | ``DrinkComposerView``, the drink composer sheet, with its ``OneTapLogView`` | `DrinkComposerViewAccessibilityID` (`screen`, `drinkTiles` and a tile per drink, the quantity buttons, the "When" choices, `addButton`, `closeButton`), `OneTapLogViewAccessibilityID` (a button per favourite) |
| `TodayRobot` | ``TodayView``, the Today screen, with ``DailyGreetingView``, ``CaffeineDecayView``, ``CaffeineIntakeTodayView``, ``LastCupView``, ``OneTapLogView``, and ``DrinkLogHistoryView`` | `TodayViewAccessibilityID` (`screen`), `DailyGreetingViewAccessibilityID` (`header`), `CaffeineDecayViewAccessibilityID` (`level`, `curve`), `CaffeineIntakeTodayViewAccessibilityID` (`total`), `LastCupViewAccessibilityID` (`tile`), `OneTapLogViewAccessibilityID` (`firstFavourite`, `secondFavourite`, `thirdFavourite`), `DrinkLogHistoryViewAccessibilityID` (`title`, the day buttons, `total`, `drink` on every row, `deleteButton`, `confirmDeleteButton`, `cancelDeleteButton`, `emptyMessage`, `errorMessage`). Its history card commands live in `TodayRobot+History.swift`, an extension that keeps the card's elements private to the robot. |
| `WelcomeRobot` | ``WelcomeView``, onboarding's first screen | `WelcomeViewAccessibilityID` (`screen`, `getStartedButton`) |
| `AboutYouRobot` | ``AboutYouView`` | `AboutYouViewAccessibilityID` (`screen`, `nameField`, `agePicker`, `continueButton`) |
| `HalfLifeFactorsRobot` | ``HalfLifeFactorsView`` | `HalfLifeFactorsViewAccessibilityID` (`screen`, an option for each factor, the three trimesters, `halfLife`, `continueButton`) |
| `BedtimeRobot` | ``BedtimeView`` | `BedtimeViewAccessibilityID` (`screen`, `picker`, `hourPicker`, `minutePicker`, `continueButton`) |
| `PermissionsRobot` | ``PermissionsView`` | `PermissionsViewAccessibilityID` (`screen`, each row's Allow button, status, and Settings button, `continueButton`) |
| `OnboardingSummaryRobot` | ``OnboardingSummaryView`` | `OnboardingSummaryViewAccessibilityID` (`screen`, `title`, `halfLife`, `bedtime`, `recommendedSleep`, `logFirstCupButton`, `takeMeToTodayButton`) |

``OneTapLogView`` appears on two screens, so its identifiers aren't unique across the app. `TodayRobot` and `DrinkComposerRobot` each look for them only inside their own screen's element, and name the favourite with the shared `OneTapFavourite` enum.

Screens in the root tab bar run `auditAccessibilityAboveTheTabBar()` instead of `auditAccessibility()`. The Today screen scrolls under the tab bar, so at launch its lowest cards sit behind the bar, and the audit reads their contrast against the bar. The helper audits twice. At launch, it ignores contrast issues only for elements that reach under the bar or into its fade, 44 pt above the log button, and for issues the audit can't tie to an element, never for the log button itself, and fails on every other issue. Then it swipes up until the screen's first text stops moving, and audits again, ignoring nothing, so every card that was behind the bar is checked in full. Before each audit, it waits for a still screen: it takes screenshots until two in a row are identical, or 20 have been taken. After a launch or a scroll, the bar's glass and the scroll edge effect keep animating after the content stops, and audits taken then failed contrast on text that passes once the screen is still. Waiting for that condition, rather than for a fixed time, keeps to constitution Article II.9. The owner approved the exception and the second audit on 2026-09-12 (<doc:OneTapLog>), and chose the wait the same day, after three audits failed intermittently.

## Features

| Feature | Responsibility | Use cases | Parent |
|---------|----------------|-----------|--------|
| ``TodayFeature`` | The Today screen. It composes one child feature per card (<doc:TodayScreen>). | None of its own | ``AppFeature`` |
| ``DailyGreetingFeature`` | The greeting for the time of day, with the user's name and today's date | ``ObserveUserProfileUseCase``, ``ObserveTimeOfDayUseCase`` | ``TodayFeature`` |
| ``CaffeineDecayFeature`` | The decay card: the caffeine in your system now, the level at bedtime, when the last cup is half gone, and the curve | ``ObserveCaffeineCurveUseCase``, ``ObserveCaffeineStatusUseCase``, ``ObserveTimeOfDayUseCase`` | ``TodayFeature`` |
| ``CaffeineIntakeTodayFeature`` | The "Today" tile: the caffeine logged so far today (<doc:TodayScreen>) | ``ObserveCaffeineIntakeTodayUseCase`` | ``TodayFeature`` |
| ``LastCupFeature`` | The "Last cup" tile: the latest time the usual drink still leaves no more than the sleep threshold at bedtime (<doc:CaffeineCutoff>) | ``ObserveCaffeineCutoffUseCase`` | ``TodayFeature`` |
| ``OneTapLogFeature`` | The one-tap row: the three favourite drinks, each logged as consumed now in one tap, with a 2-second confirmation (<doc:OneTapLog>) | ``ObserveFavouriteDrinksUseCase``, ``LogDrinkUseCase`` | ``TodayFeature`` and ``DrinkComposerFeature`` |
| ``DrinkLogHistoryFeature`` | The history card: one day of the drink log and its total, buttons for the day before and after, and deleting a drink once the user confirms (<doc:TodayScreen>) | ``ObserveDrinkLogDayUseCase``, ``DeleteDrinkUseCase``, ``ObserveTimeOfDayUseCase`` | ``TodayFeature`` |
| ``AppFeature`` | The root: the tab bar with the Today screen, and the log button above the bar that presents the drink composer as a sheet. It presents onboarding full screen until the profile is complete, and completes it when the user leaves the summary (<doc:Onboarding>). | ``ObserveUserProfileUseCase``, ``CompleteOnboardingUseCase`` | None |
| ``DrinkComposerFeature`` | Logs a drink chosen from a sideways row of tiles, with its quantity and when it was consumed. It opens on the last drink logged, and closes when its one-tap row logs a favourite (<doc:DrinkComposer>) | ``LogDrinkUseCase``, ``ObserveLoggedDrinksUseCase`` | ``AppFeature``, as a sheet |
| ``OnboardingFeature`` | The first-run flow: Welcome at the root of a navigation stack, then each step pushed onto its path (<doc:Onboarding>) | None of its own | ``AppFeature``, full screen |
| ``AboutYouFeature`` | Onboarding's name and age | ``ObserveUserProfileUseCase``, ``ObserveTimeOfDayUseCase``, ``SaveAboutYouUseCase`` | ``OnboardingFeature`` |
| ``HalfLifeFactorsFeature`` | What changes how fast the user clears caffeine, and the starting half-life it gives | ``ObserveUserProfileUseCase``, ``SaveHalfLifeFactorsUseCase`` | ``OnboardingFeature`` |
| ``BedtimeFeature`` | The bedtime, on an hour wheel and a minute wheel | ``ObserveUserProfileUseCase``, ``SaveBedtimeUseCase`` | ``OnboardingFeature`` |
| ``PermissionsFeature`` | Apple Health, notifications, and Face ID, each with its status and an action | ``ObservePermissionsUseCase``, ``RequestHealthAccessUseCase``, ``RequestNotificationPermissionUseCase``, ``RequestBiometricPermissionUseCase``, ``RefreshPermissionsUseCase``, ``OpenAppSettingsUseCase`` | ``OnboardingFeature`` |
| ``OnboardingSummaryFeature`` | What onboarding saved, and the two ways out | ``ObserveUserProfileUseCase``, ``ObserveRecommendedSleepUseCase``, ``ObservePermissionsUseCase`` | ``OnboardingFeature`` |

## Use cases

| Use case | Operation | Repositories |
|----------|-----------|--------------|
| ``ObserveCaffeineCurveUseCase`` | Streams the active caffeine curve | ``CaffeineDecayRepository`` |
| ``ObserveCaffeineCutoffUseCase`` | Streams the cutoff: the latest time the user's usual drink can be drunk and leave no more than the sleep threshold at bedtime, in a given calendar (<doc:CaffeineCutoff>) | ``CaffeineDecayRepository`` |
| ``ObserveCaffeineStatusUseCase`` | Streams the caffeine status: the level now and the decay card's two tips, in a given calendar (<doc:TodayScreen>) | ``CaffeineDecayRepository`` |
| _None yet_ | `SendBugReportUseCase` and `ObserveBugReportStatusUseCase` are designed in <doc:Logging> but not yet built. | `BugReportRepository`, plus `CrashReportRepository` for sending |
| ``LogDrinkUseCase`` | Records a drink from the composer, one-tap favourites, or an App Intent, consumed a given number of seconds ago (<doc:DrinkComposer>) | ``CurrentTimeRepository``, ``DrinkLogRepository`` |
| ``ObserveLoggedDrinksUseCase`` | Streams every logged drink, oldest first (<doc:DrinkComposer>) | ``DrinkLogRepository`` |
| ``ObserveFavouriteDrinksUseCase`` | Streams the three one-tap favourites, most logged first (<doc:OneTapLog>) | ``FavouriteDrinksRepository`` |
| ``ObserveCaffeineIntakeTodayUseCase`` | Streams the caffeine logged on the current calendar day, in a given calendar (<doc:TodayScreen>) | ``DrinkLogRepository`` |
| ``ObserveDrinkLogDayUseCase`` | Streams one calendar day of the drink log, its drinks and their caffeine, in a given calendar (<doc:TodayScreen>) | ``DrinkLogRepository`` |
| ``DeleteDrinkUseCase`` | Deletes a drink. The log, the totals, the favourites, and the decay curve follow through the data source the repositories share (<doc:TodayScreen>) | ``DrinkLogRepository`` |
| ``ObserveUserProfileUseCase`` | Streams the user's profile (<doc:TodayScreen>) | ``UserProfileRepository`` |
| ``ObserveTimeOfDayUseCase`` | Streams each minute with the part of the day it falls in, by executing ``DayPeriodRule`` (<doc:TodayScreen>) | ``CurrentTimeRepository`` |
| ``SaveAboutYouUseCase`` | Saves the trimmed name and the birth year the age implies (<doc:Onboarding>) | ``UserProfileRepository``, ``CurrentTimeRepository`` |
| ``SaveHalfLifeFactorsUseCase`` | Saves what changes how fast the user clears caffeine. The repository stores the starting half-life with it. | ``UserProfileRepository`` |
| ``SaveBedtimeUseCase`` | Saves the bedtime | ``UserProfileRepository`` |
| ``CompleteOnboardingUseCase`` | Records that onboarding is complete | ``UserProfileRepository`` |
| ``ObserveRecommendedSleepUseCase`` | Streams the sleep recommended for the user's age, in a given calendar | ``UserProfileRepository`` |
| ``ObservePermissionsUseCase`` | Streams the Health, notification, and Face ID permissions | ``PermissionsRepository`` |
| ``RequestHealthAccessUseCase``, ``RequestNotificationPermissionUseCase``, ``RequestBiometricPermissionUseCase`` | Each asks for its permission | ``PermissionsRepository`` |
| ``RefreshPermissionsUseCase`` | Re-reads the permissions, for example after the Settings app | ``PermissionsRepository`` |
| ``OpenAppSettingsUseCase`` | Opens Half-Life's page in the Settings app | ``PermissionsRepository`` |

## Business rules

| Business rule | Calculates | Executed by |
|---------------|------------|-------------|
| ``CaffeineDecayRule`` | The active caffeine curve under Bateman absorption, which intakes count and which are negligible, and when an intake is half gone (<doc:CaffeineDecayModel>) | ``LiveCaffeineDecayRepository`` |
| ``CaffeineCutoffRule`` | The cutoff: the latest time, rounded down to the half hour, when the user's usual drink, on top of every intake logged, leaves no more than the sleep threshold at the next bedtime. It only considers cups that peak by bedtime, and asks ``CaffeineDecayRule`` for the levels (<doc:CaffeineCutoff>). | ``LiveCaffeineDecayRepository``, which also runs ``FavouriteDrinksRule`` to find the usual drink |
| ``CaffeineStatusRule`` | The caffeine status: the level now, the intakes still counting, when the last one is half gone, and the level at the next bedtime. It asks ``CaffeineDecayRule`` for each of them (<doc:TodayScreen>). | ``LiveCaffeineDecayRepository`` |
| ``DrinkLogRule`` | Whether a drink may be logged: a quantity of at least 1, consumed no later than the current time (<doc:DrinkComposer>) | ``LiveDrinkLogRepository`` |
| ``FavouriteDrinksRule`` | The three one-tap favourites: every drink ever logged, counted by drink and quantity together, most logged first, with starters filling the slots the log can't (<doc:OneTapLog>) | ``LiveFavouriteDrinksRepository``, and ``LiveCaffeineDecayRepository`` to find the cutoff's usual drink |
| ``DailyCaffeineIntakeRule`` | The caffeine in the drinks consumed on one calendar day, from midnight to midnight in a given calendar (<doc:TodayScreen>) | ``LiveDrinkLogRepository`` |
| ``DrinkLogDayRule`` | One calendar day of the drink log: its drinks, and its intake from ``DailyCaffeineIntakeRule`` (<doc:TodayScreen>) | ``LiveDrinkLogRepository`` |
| ``DayPeriodRule`` | The part of the day a moment falls in, for the greeting (<doc:TodayScreen>) | ``ObserveTimeOfDayUseCase``. It's the only use case that executes a business rule; the owner chose this over a second clock repository. |
| ``HalfLifePriorRule`` | The starting half-life, from the factors the user reported (<doc:Onboarding>) | ``LiveUserProfileRepository``, when the factors are saved |
| ``SleepNeedRule`` | The sleep recommended for the user's age (<doc:Onboarding>) | ``LiveUserProfileRepository`` |

## Repositories

| Repository | Owns | Data sources |
|------------|------|--------------|
| ``CaffeineDecayRepository``, implemented by ``LiveCaffeineDecayRepository`` | The caffeine curve (<doc:CaffeineDecayModel>), the cutoff, sent only when it changes (<doc:CaffeineCutoff>), and the caffeine status, recalculated every minute (<doc:TodayScreen>) | ``DrinkLogDataSource``, shared with ``DrinkLogRepository``; ``FileProfileDataSource``, shared with ``UserProfileRepository``, as ``HalfLifeDataSource`` and ``BedtimeDataSource``; ``AbsorptionRateDataSource``; ``ClockDataSource``; ``SleepThresholdDataSource`` |
| _None yet_ | `BugReportRepository` is designed in <doc:Logging> but not yet built. It will own the bug report's status. | `OSLogEntryDataSource`, `MessageUIMailDataSource` (not yet built) |
| _None yet_ | `CrashReportRepository` is designed in <doc:Logging> but not yet built. It will own the unsent crash reports. | `MetricKitCrashReportDataSource`, `FileCrashReportDataSource` (not yet built) |
| ``DrinkLogRepository``, implemented by ``LiveDrinkLogRepository`` | Every logged drink (<doc:DrinkComposer>), the caffeine logged today, recalculated after each change that alters it and at the start of each day, and any one day of the log, for the history card. It also deletes drinks (<doc:TodayScreen>). | ``DrinkLogDataSource``, shared with ``CaffeineDecayRepository``; ``ClockDataSource`` |
| ``FavouriteDrinksRepository``, implemented by ``LiveFavouriteDrinksRepository`` | The three one-tap favourites, recalculated after each change to the drink log (<doc:OneTapLog>) | ``DrinkLogDataSource``, shared with ``DrinkLogRepository`` and ``CaffeineDecayRepository`` |
| ``LiveCurrentTimeRepository`` (``CurrentTimeRepository``) | The current time: `now()`, and a stream that emits at every whole minute (<doc:DrinkComposer>) | ``ClockDataSource`` |
| ``UserProfileRepository``, implemented by ``LiveUserProfileRepository`` | What the user has told the app about themselves: the name, birth year, factors that change the half-life, bedtime, starting half-life, and whether onboarding is complete, plus the sleep recommended for their age (<doc:Onboarding>) | ``FileProfileDataSource``, shared with ``CaffeineDecayRepository``; ``ClockDataSource`` |
| ``PermissionsRepository``, implemented by ``LivePermissionsRepository`` | The statuses of the Health, notification, and Face ID permissions (<doc:Onboarding>) | ``HealthKitAuthorizationDataSource``, ``UserNotificationsAuthorizationDataSource``, ``LocalAuthenticationDataSource``, ``FilePermissionHistoryDataSource``, ``UIKitSystemSettingsDataSource`` |

## Data sources

| Data source | Wraps |
|-------------|-------|
| ``HealthKitRestingHeartRateDataSource``, implementing ``RestingHeartRateDataSource`` | HealthKit's statistics query, for the average of one day's resting heart rate samples (<doc:RestingHeartRate>). It only reads, and no repository reads it yet. Constitution Article V.3.5 allows one HealthKit data source per kind of Health data. |
| ``HealthKitStepCountDataSource``, implementing ``StepCountDataSource`` | HealthKit's statistics query, for the total of one day's step count samples (<doc:StepCount>). It only reads, and no repository reads it yet. |
| ``HealthKitSleepDataSource``, implementing ``SleepDataSource`` | HealthKit's sample query, for the sleep analysis samples that overlap a range, and one observer query per subscriber for changes (<doc:SleepData>). It only reads, on `HKHealthStore.halfLife`, the app's one health store. No repository reads it yet. |
| ``HealthKitAuthorizationDataSource``, implementing ``HealthAuthorizationDataSource`` | HealthKit's authorization request and its request status, on `HKHealthStore.halfLife`. It asks, in one sheet, to read sleep, steps, and resting heart rate, and to write nothing. It's the only data source that requests Health access (constitution Article V.3.1), and it presents Health's sheet itself (Article I.6). |
| ``FileProfileDataSource``, implementing ``UserProfileDataSource``, ``BedtimeDataSource``, and ``HalfLifeDataSource`` | `Profile.json` in Application Support, written atomically with `NSFileProtectionComplete`, on the device only. It stores the profile, with the bedtime and the starting half-life, and signals every subscribed repository after each successful store. One shared instance, from ``ProfileDataSourceKey``, sits behind ``UserProfileRepository`` and ``CaffeineDecayRepository``. Under UI tests and in previews it's a temporary file (<doc:Onboarding>). |
| ``UserNotificationsAuthorizationDataSource``, implementing ``NotificationAuthorizationDataSource`` | `UNUserNotificationCenter`'s authorization status, and its request for alerts and sounds |
| ``LocalAuthenticationDataSource``, implementing ``BiometricAuthenticationDataSource`` | `LAContext`: whether Face ID or Touch ID can be used, and one authentication to ask for it |
| ``FilePermissionHistoryDataSource``, implementing ``PermissionHistoryDataSource`` | `PermissionHistory.json` in Application Support, which remembers that Face ID was asked for, because iOS reports it as available both before and after the user allows it |
| ``UIKitSystemSettingsDataSource``, implementing ``SystemSettingsDataSource`` | Opens Half-Life's page in the Settings app |
| ``SystemClockDataSource`` (``ClockDataSource``) | The system clock, through `Date.now`, and `Task.sleep` for the minute stream. It's the only code that reads the clock. |
| ``SwiftDataDrinkLogDataSource``, implementing ``DrinkLogDataSource`` | SwiftData, in a store that syncs to the user's private CloudKit database (constitution Article V.1). It stores and deletes logged drinks, stores their negligible marks, and signals each store and deletion to the repositories that read it. The sync is configured, and the rest of the CloudKit work is roadmap rank 23. |
| ``StandardAbsorptionRateDataSource``, implementing ``AbsorptionRateDataSource`` | Nothing yet. It returns the standard 13-minute absorption half-life until something can store a tuned rate. |
| ``StandardSleepThresholdDataSource``, implementing ``SleepThresholdDataSource`` | Nothing yet. It returns the standard 40 mg sleep threshold until the personal sensitivity threshold (roadmap rank 22) holds the user's own (<doc:CaffeineCutoff>). |
| _None yet_ | `OSLogEntryDataSource` (wraps `OSLogStore`) and `MessageUIMailDataSource` (wraps MessageUI's Mail composer, which it presents itself, per constitution Article I.6) are designed in <doc:Logging> but not yet built. |
| _None yet_ | `MetricKitCrashReportDataSource` (wraps `MXMetricManager`) and `FileCrashReportDataSource` (stores unsent crash reports) are designed in <doc:Logging> but not yet built. |

## Navigation

``AppView`` is the root: the system tab bar, with the Today screen as its one tab, and the log button as the bar's bottom accessory, just above it. The system tab bar's own buttons carry no accessibility identifiers, so an action tab couldn't be driven by a robot (constitution Article II.6). The owner chose the accessory on 2026-09-12 (<doc:OneTapLog>). Patterns joins the bar as a tab when it's built (roadmap rank 15).

The log button presents ``DrinkComposerView`` as a sheet sized to its content: ``AppFeature`` holds the composer's state in a `@Presents` property, so the sheet is state-driven (constitution Article I.6). The composer closes itself through TCA's `dismiss` dependency, after a drink is logged, when its one-tap row logs a favourite, or when the user taps Close.

Onboarding is presented full screen by ``AppFeature`` while the user's profile says it isn't complete, and dismissed when the profile says it is. Its steps are pushed onto a `StackState` navigation stack. "Log my first cup" opens the drink composer once the full-screen cover has gone (<doc:Onboarding>).

System UI that a framework provides, such as the Mail composer or HealthKit's authorization sheet, is presented by the data source that wraps the framework, not by feature state. The feature learns the outcome through the repository (constitution Article I.6).

## Data and privacy

All user data stays on the device, except the drink log, which syncs to the user's private CloudKit database (constitution Article V.1). List every piece of stored data here.

| Data | Stored in | Protection class | Why it's collected |
|------|-----------|------------------|--------------------|
| Logged drinks: type, quantity, caffeine, time consumed, and the negligible mark | A SwiftData store in the app container, synced to the user's private CloudKit database (``SwiftDataDrinkLogDataSource``) | iOS's default, `NSFileProtectionCompleteUntilFirstUserAuthentication`, chosen by the owner on 2026-09-11 (Article V.4). CloudKit imports and Siri need the store while the device is locked after its first unlock. | The decay curve and the drink log. The user logs each drink. |
| Resting heart rate: one day's average, read from Apple Health (``HealthKitRestingHeartRateDataSource``) | Not stored. It's read from Health when needed and held only in memory, and never synced to iCloud (Article V.3.4). | Not written by the app | To set heart rate against caffeine habits, as the brief asks. No feature reads it yet (<doc:RestingHeartRate>). |
| Sleep: stage intervals read from Apple Health (``HealthKitSleepDataSource``) | Not stored. It's read from Health when needed and held only in memory, and never synced to iCloud (Article V.3.4). | Not written by the app | To set sleep against caffeine timing, as the brief asks. No feature reads it yet (<doc:SleepData>). |
| Step count: one day's total, read from Apple Health (``HealthKitStepCountDataSource``) | Not stored. It's read from Health when needed and held only in memory, and never synced to iCloud (Article V.3.4). | Not written by the app | To set activity against caffeine habits, as the brief asks. No feature reads it yet (<doc:StepCount>). |
| Onboarding's profile: name, birth year, the factors that change the half-life, the starting half-life, the bedtime, and whether onboarding is complete | `Profile.json` in Application Support, on the device only (``FileProfileDataSource``) | `NSFileProtectionComplete` | The greeting, the recommended sleep range, and the personal decay model. The factors can include a pregnancy or liver disease, so they're health data (<doc:Onboarding>). |
| Whether Face ID has been asked for | `PermissionHistory.json` in Application Support (``FilePermissionHistoryDataSource``) | `NSFileProtectionComplete` | The Face ID row's status, because iOS reports Face ID as available both before and after it's allowed |
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
