# Architecture

How Half-Life's features, use cases, repositories, and data fit together.

## Overview

Half-Life combines The Composable Architecture (TCA) with Clean Architecture (constitution Article I). The code is split into three layers, and dependencies always point inward, toward Domain.

| Layer | Contains | May depend on |
|-------|----------|---------------|
| Presentation | TCA features (reducers and views), App Intents, and widgets. App Intents and widgets are presentation without a reducer (constitution Article I.18, <doc:AppIntents>, <doc:Widgets>). | Domain |
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
│   └── UITesting/           The UI tests' launch configuration, simulated permissions (see Onboarding), the
│                            simulated app lock (see App Lock), and simulated Health data (see Apple Health Card)
├── Features/<Feature>/      <Feature>Feature.swift (reducer), <Feature>View.swift,
│                            <Feature>ViewAccessibilityID.swift (also in the UI test target)
├── AppIntents/              App Intents, the values they return, the App Shortcuts provider, and the sleep-time
│                            snippet (see App Intents)
├── DesignSystem/            Presentation constants: Spacing, CornerRadius, Sizing, Elevation, Typography
├── Logging/                 Logger+HalfLife.swift: Logger(for:), Half-Life's subsystem and categories (see Logging)
├── Assets.xcassets/Colors/  Semantic color sets, one folder per category (see Design System)
├── Assets.xcassets/Images/  The brand mark, which the launch screen and the splash screen draw (see Splash Screen)
├── Domain/
│   ├── Entities/            Plain Sendable, Equatable value types
│   ├── BusinessRules/       Stateless calculations that repositories execute
│   ├── UseCases/            The UseCase protocol, and one file per use case
│   └── Repositories/        Repository protocols
└── Data/
    ├── Repositories/        Live repository implementations (Live<Noun>Repository)
    └── DataSources/         Framework wrappers (<Framework><Noun>DataSource)
        └── FoundationModels/ The language model data source, its instructions, and its tools (see Language Model)

Half-LifeUITests/
├── Robots/                  Robot.swift (protocol and screen resolution), <Feature>Robot.swift
└── <Feature>UITests.swift   Scenarios written against robots

Half-LifeWidgets/            The widget extension: its bundle, the One tap and In your system widgets and their
                             views, the timeline provider, and its composition root. It compiles a few Domain and
                             Data files from Half-Life/ as well (see Widgets).
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

A repository key is internal when use cases or data sources in other files are built from it, like `CurrentTimeRepositoryKey`. Otherwise it's private to its file.

A data source that several repositories share gets its own internal key, like ``DrinkLogDataSourceKey``, and each repository key builds from its values. That keeps one instance behind every repository.
- **No property.** It has no `DependencyValues` property, because only repositories use data sources.
- **Values.** Its preview value is an empty in-memory store. Its live value opens the device's store, and falls back to an in-memory store if that store won't open. When a UI test launches the app, the live value is always an empty in-memory store, so every UI test starts from the same log (LAUNCH-3 in <doc:Onboarding>).

Tests never read a live value that opens the device's store. Tests that open a SwiftData store, including anything that reads a preview store, run under the serialized `SwiftDataStoreTests` suite in the test target. A full parallel run once crashed inside Core Data while a store was opening, and the crash couldn't be reproduced on demand.

### A data source whose tools read repositories

``FoundationModelLanguageModelDataSource`` is the one data source that reads repositories. Its tools conform to the Foundation Models framework's `Tool` protocol, so they belong to the data source that imports the framework (constitution Article I.14). They read the Domain repository protocols, never another data source, so the model's numbers are the ones the screens show, and HealthKit stays behind its repositories (Article V.3.5). Its registration builds it from the internal keys of the repositories the tools read: `CaffeineDecayRepositoryKey`, `DrinkLogRepositoryKey`, and `CurrentTimeRepositoryKey`. Each instruction builds its own tools, so the ``LogDrinkUseCase`` that `logDrink` holds lives for one instruction (Article I.8, <doc:LanguageModel>).

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
| `AppRobot` | ``AppView``, the root screen | `AppViewAccessibilityID` (`screen`, `logButton`). The tab bar's Today, Insights, and Settings buttons are found by their titles, from `AppTab`'s String Catalog keys, the one exception constitution Article II.6 allows (see "Navigation"). |
| `AppLockRobot` | ``AppLockView``, the lock screen (<doc:AppLock>) | `AppLockViewAccessibilityID` (`screen`, `unlockButton`) |
| `SplashRobot` | ``SplashView``, the screen shown while the app launches (<doc:SplashScreen>). Its tests hold the launch with `launchHoldingTheSplash()`. | `SplashViewAccessibilityID` (`screen`, `wordmark`, `progress`) |
| `DrinkComposerRobot` | ``DrinkComposerView``, the drink composer sheet, with its ``OneTapLogView`` | `DrinkComposerViewAccessibilityID` (`screen`, `drinkTiles` and a tile per drink, the quantity buttons, the "When" choices, `addButton`, `closeButton`), `OneTapLogViewAccessibilityID` (a button per favourite) |
| `TodayRobot` | ``TodayView``, the Today screen, with ``DailyGreetingView``, ``CaffeineDecayView``, ``CaffeineIntakeTodayView``, ``LastCupView``, ``OneTapLogView``, and ``DrinkLogHistoryView`` | `TodayViewAccessibilityID` (`screen`), `DailyGreetingViewAccessibilityID` (`header`), `CaffeineDecayViewAccessibilityID` (`level`, `curve`), `CaffeineIntakeTodayViewAccessibilityID` (`total`), `LastCupViewAccessibilityID` (`tile`), `OneTapLogViewAccessibilityID` (`firstFavourite`, `secondFavourite`, `thirdFavourite`), `DrinkLogHistoryViewAccessibilityID` (`title`, the day buttons, `total`, `drink` on every row, `deleteButton`, `confirmDeleteButton`, `cancelDeleteButton`, `emptyMessage`, `errorMessage`), `HealthSummaryViewAccessibilityID` (`title`, `card`, `lastNight`, `inBed`, `steps`, `restingHeartRate`). Its history card commands live in `TodayRobot+History.swift`, and its Apple Health card commands in `TodayRobot+Health.swift`, extensions that keep each card's elements private to the robot. |
| `WelcomeRobot` | ``WelcomeView``, onboarding's first screen | `WelcomeViewAccessibilityID` (`screen`, `getStartedButton`) |
| `AboutYouRobot` | ``AboutYouView`` | `AboutYouViewAccessibilityID` (`screen`, `nameField`, `agePicker`, `continueButton`) |
| `HalfLifeFactorsRobot` | ``HalfLifeFactorsView`` | `HalfLifeFactorsViewAccessibilityID` (`screen`, an option for each factor, the three trimesters, `continueButton`) |
| `BedtimeRobot` | ``BedtimeView`` | `BedtimeViewAccessibilityID` (`screen`, `content`, `picker`, `continueButton`) |
| `PermissionsRobot` | ``PermissionsView`` | `PermissionsViewAccessibilityID` (`screen`, each row's Allow button, status, and Settings button, `continueButton`) |
| `SiriShortcutsRobot` | ``SiriShortcutsView``, onboarding's "Use Siri and Shortcuts" step | `SiriShortcutsViewAccessibilityID` (`screen`, `content`, `logPhrase`, `levelPhrase`, `sleepPhrase`, `askPhrase`, `shortcutsLink`, `continueButton`). Its audit, `auditAccessibilityExcusingTheShortcutsButton()`, excuses only clipped text inside Apple's `ShortcutsLink`, an exception the owner approved on 2026-09-13 (<doc:Onboarding>). |
| `OnboardingSummaryRobot` | ``OnboardingSummaryView`` | `OnboardingSummaryViewAccessibilityID` (`screen`, `title`, `bedtime`, `recommendedSleep`, `logFirstCupButton`, `takeMeToTodayButton`) |
| `InsightsRobot` | ``InsightsView``, the Insights tab, with ``SleepWindowView`` and ``LastSevenDaysView`` | `InsightsViewAccessibilityID` (`screen`, `content`, `sleepWindowCard`, `sleepWindowTimes`, `sleepWindowSummary`, `sleepWindowChart`, `weekCard`, `weekColumns`, `weekDetailTitle`, `weekDetailCaffeine`, `weekDetailLastCup`, `healthDataCard`, and a button per kind). Its Health data commands are in `InsightsRobot+HealthData.swift`. |
| `SleepDetailRobot` | ``SleepDetailView``, the Sleep screen the sleep button pushes on the Insights tab | `SleepDetailViewAccessibilityID` (`screen`, `title`, `analysisCard`, `finding`, `timeAsleepCard`, `timeAsleepChart`, `timeAsleepComparison`, `fallingAsleepCard`, `fallingAsleepNote`, `fallingAsleepChart`, `fallingAsleepComparison`, `source`) |
| `HeartRateDetailRobot` | ``HeartRateDetailView``, the screen the resting heart rate button pushes on the Insights tab | `HeartRateDetailViewAccessibilityID` (`screen`, `title`, `headline`, `headlineDetail`, `afterCaffeine`, `otherDays`, `chart`, `footnote`, `source`) |
| `StepsDetailRobot` | ``StepsDetailView``, the screen the steps button pushes on the Insights tab | `StepsDetailViewAccessibilityID` (`screen`, `title`, `verdict`, `afterCaffeine`, `otherDays`, `definition`, `chart`, `source`) |
| `SettingsRobot` | ``SettingsView``, the Settings tab's root list | `SettingsViewAccessibilityID` (`screen`, on the scroll view, which the robot swipes, a row per screen, and `appVersion`). Its commands open each row's screen, and it checks the app's version line. |
| `AboutYouSettingsRobot` | ``AboutYouSettingsView`` | `AboutYouSettingsViewAccessibilityID` (`screen`, `nameField`, `agePicker`) |
| `FactorsSettingsRobot` | ``FactorsSettingsView`` | `FactorsSettingsViewAccessibilityID` (`screen`, an option per factor, the three trimesters) |
| `BedtimeSettingsRobot` | ``BedtimeSettingsView`` | `BedtimeSettingsViewAccessibilityID` (`screen`, `picker`) |
| `PermissionSettingsRobot` | ``PermissionSettingsView`` | `PermissionSettingsViewAccessibilityID` (`screen`, each permission's Allow button, status, and Settings button) |
| `AppLockSettingsRobot` | ``AppLockSettingsView``, around ``AppLockSettingsSection`` | `AppLockSettingsViewAccessibilityID` (`screen`, `appLockOption`, `appLockError`) |
| `DemoHistorySettingsRobot` | ``DemoHistorySettingsView`` | `DemoHistorySettingsViewAccessibilityID` (`screen`, `addDemoButton`, `removeDemoButton`, `demoError`, `demoHealthDataOption`, `demoHealthDataError`) |

``OneTapLogView`` appears on two screens, so its identifiers aren't unique across the app. `TodayRobot` and `DrinkComposerRobot` each look for them only inside their own screen's element, and name the favourite with the shared `OneTapFavourite` enum.

Screens in the root tab bar run `auditAccessibilityAboveTheTabBar()` instead of `auditAccessibility()`. The Today screen scrolls under the tab bar, so at launch its lowest cards sit behind the bar, and the audit reads their contrast against the bar. The helper audits twice. At launch, it ignores contrast issues only for elements that reach under the bar or into its fade, 44 pt above the log button, and for issues the audit can't tie to an element, never for the log button itself, and fails on every other issue. Then it swipes up until the screen's first text stops moving, and audits again, so every card that was behind the bar is checked in full. At the end of a screen a little taller than the phone, the top of the content, such as a pushed Settings screen's title, sits under the navigation bar and in its fade. So the second audit ignores a contrast issue only for an element that reaches above where the content started at rest, and only if the first audit checked that element in full, because at rest it sat wholly above the bottom fade. Before each audit, it waits for a still screen: it takes screenshots until three in a row are identical, or 30 have been taken. After a launch or a scroll, the bar's glass and the scroll edge effect keep animating after the content stops, and audits taken then failed contrast on text that passes once the screen is still. Waiting for that condition, rather than for a fixed time, keeps to constitution Article II.9. The owner approved the exception and the second audit on 2026-09-12 (<doc:OneTapLog>), and chose the wait the same day, after three audits failed intermittently. On 2026-09-13, the wait grew from two identical screenshots of 20 to three of 30, after a long Today screen's second audit failed while it still moved, and the owner approved the top of the second audit (<doc:Settings>).

## Features

| Feature | Responsibility | Use cases | Parent |
|---------|----------------|-----------|--------|
| ``TodayFeature`` | The Today screen. It composes one child feature per card (<doc:TodayScreen>). | None of its own | ``AppFeature`` |
| ``DailyGreetingFeature`` | The greeting for the time of day, with the user's name and today's date | ``ObserveUserProfileUseCase``, ``ObserveTimeOfDayUseCase`` | ``TodayFeature`` |
| ``CaffeineDecayFeature`` | The decay card: the caffeine in your system now, the level at bedtime, when the last cup is half gone, and the curve. It refreshes the personal half-life estimate when it appears (<doc:HalfLifeEstimator>). | ``ObserveCaffeineCurveUseCase``, ``ObserveCaffeineStatusUseCase``, ``ObserveTimeOfDayUseCase``, ``RefreshHalfLifeEstimateUseCase`` | ``TodayFeature`` |
| ``CaffeineIntakeTodayFeature`` | The "Today" tile: the caffeine logged so far today (<doc:TodayScreen>) | ``ObserveCaffeineIntakeTodayUseCase`` | ``TodayFeature`` |
| ``LastCupFeature`` | The "Last cup" tile: the latest time the usual drink still leaves no more than the sleep threshold at bedtime (<doc:CaffeineCutoff>) | ``ObserveCaffeineCutoffUseCase`` | ``TodayFeature`` |
| ``CutoffReminderFeature`` | No screen. It schedules a local notification at each of the next seven nights' cutoffs, and schedules them again when the cutoffs or the notification permission change (<doc:CutoffReminder>) | ``ObserveUpcomingCutoffsUseCase``, ``ObservePermissionsUseCase``, ``ScheduleCutoffRemindersUseCase`` | ``AppFeature``, started by ``AppView`` |
| ``OneTapLogFeature`` | The one-tap row: the three favourite drinks, each logged as consumed now in one tap, with a 2-second confirmation (<doc:OneTapLog>) | ``ObserveFavouriteDrinksUseCase``, ``LogDrinkUseCase`` | ``TodayFeature`` and ``DrinkComposerFeature`` |
| ``DrinkLogHistoryFeature`` | The history card: one day of the drink log and its total, buttons for the day before and after, and deleting a drink once the user confirms (<doc:TodayScreen>) | ``ObserveDrinkLogDayUseCase``, ``DeleteDrinkUseCase``, ``ObserveTimeOfDayUseCase`` | ``TodayFeature`` |
| ``HealthSummaryFeature`` | The Apple Health card: last night's sleep, or time in bed, today's steps, and today's resting heart rate, each only when Health has it, and hidden when none does. ``TodayView`` starts its observation, because a hidden card never runs `.task` (<doc:AppleHealthCard>). | ``ObserveHealthSummaryUseCase`` | ``TodayFeature`` |
| ``AppFeature`` | The root: the tab bar with the Today, Insights, and Settings tabs, and the log button above the bar that presents the drink composer as a sheet. Until the first profile and the app lock have arrived, ``AppView`` shows ``SplashView``, which has no store, in their place (<doc:SplashScreen>). It presents onboarding full screen until the profile is complete, and completes it when the user leaves the summary (<doc:Onboarding>). It runs ``CutoffReminderFeature`` (<doc:CutoffReminder>). It shows the lock screen in the tab bar's place while the app lock has locked the app, and locks the app when it goes to the background (<doc:AppLock>). From launch, it keeps the Home Screen widgets' snapshot current (<doc:Widgets>), and the caffeine tolerance, which the cutoff reads as the sleep threshold (<doc:Insights>). | ``ObserveUserProfileUseCase``, ``CompleteOnboardingUseCase``, ``ObserveAppLockUseCase``, ``LockAppUseCase``, ``KeepWidgetsCurrentUseCase``, ``KeepSleepToleranceCurrentUseCase`` | None |
| ``AppLockFeature`` | The lock screen: asks to unlock by itself once per return from the background, and from its Unlock button (<doc:AppLock>) | ``UnlockAppUseCase`` | ``AppFeature`` |
| ``AppLockSettingsFeature`` | Settings' App lock section: the switch that turns the lock on or off (<doc:AppLock>) | ``ObserveAppLockUseCase``, ``ObservePermissionsUseCase``, ``TurnOnAppLockUseCase``, ``TurnOffAppLockUseCase`` | ``SettingsFeature`` |
| ``InsightsFeature`` | The Insights tab. It composes one child feature per card: "What we noticed", tonight's sleep window, the last 7 days, and the Health data buttons. It pushes each kind's screen onto its `StackState` path (<doc:Insights>). | None of its own | ``AppFeature`` |
| ``WhatWeNoticedFeature`` | The "What we noticed" card: one finding about the user's nights, in the on-device model's words, with "Feel right?". It writes the insight once for each request, and records each answer (<doc:Insights>). | ``ObserveInsightCardUseCase``, ``WriteInsightUseCase``, ``RecordInsightFeedbackUseCase`` | ``InsightsFeature`` |
| ``SleepWindowFeature`` | The "Best time to sleep tonight" card: when the caffeine already logged falls to the sleep threshold, and the 90 minutes to fall asleep in (<doc:Insights>) | ``ObserveSleepWindowUseCase`` | ``InsightsFeature`` |
| ``LastSevenDaysFeature`` | The "last 7 days" card: each day's caffeine and the sleep that followed it, and the chosen day's details (<doc:Insights>) | ``ObserveDrinkLogWeekUseCase``, ``ObserveSleepWeekUseCase`` | ``InsightsFeature`` |
| ``HealthDataListFeature`` | The "Against your caffeine" card: a button for each kind of Health data with any data, which opens its screen (<doc:Insights>) | ``ObserveAvailableHealthDataUseCase`` | ``InsightsFeature`` |
| ``SleepDetailFeature`` | The Sleep screen: each night's time asleep and time to fall asleep in the last 30 days against the caffeine at sleep onset, and the caffeine tolerance they show, which the cutoff uses as the sleep threshold (<doc:Insights>) | ``ObserveSleepCaffeineAnalysisUseCase`` | ``InsightsFeature``, through its `Path` |
| ``HeartRateDetailFeature`` | The resting heart rate screen: the resting heart rate on the days after a caffeine night against the other days, over the last 30 days (<doc:Insights>) | ``ObserveRestingHeartRateComparisonUseCase`` | ``InsightsFeature``, through its `Path` |
| ``StepsDetailFeature`` | The steps screen: the steps on the days after a caffeine night against the other days, over the last 30 days (<doc:Insights>) | ``ObserveStepsComparisonUseCase`` | ``InsightsFeature``, through its `Path` |
| ``ObserveSleepCaffeineAnalysisUseCase`` | Streams the analysis of the nights in the last 30 days against the caffeine at sleep onset: the nights, the caffeine tolerance, and time asleep and the time to fall asleep either side of the threshold in use (<doc:Insights>) | ``SleepToleranceRepository`` |
| ``ObserveCaffeineNightsUseCase`` | Streams the caffeine in the user when each of the last 31 nights began, judged against the threshold in use, in a given calendar (<doc:Insights>) | ``SleepToleranceRepository`` |
| ``KeepSleepToleranceCurrentUseCase`` | Keeps the caffeine tolerance, and so the sleep threshold, current for as long as it runs. ``AppFeature`` runs it from launch (<doc:Insights>). | ``SleepToleranceRepository`` |
| ``SettingsFeature`` | The Settings tab: a root list of rows, each pushing its own screen onto a `StackState` path, and the root's own profile, app lock, and demo sections for the rows' values. Its last line is the app's version and build (<doc:Settings>). | ``ObserveAppVersionUseCase`` | ``AppFeature`` |
| ``ProfileSettingsFeature`` | Each of Settings' About you, Caffeine and your body, and Bedtime screens, and the root's summary of them: the onboarding answers, changed after onboarding | ``ObserveUserProfileUseCase``, ``ObserveTimeOfDayUseCase``, ``SaveAboutYouUseCase``, ``SaveHalfLifeFactorsUseCase``, ``SaveBedtimeUseCase`` | ``SettingsFeature``, on its root and on each pushed profile screen |
| ``DemoHistoryFeature`` | The demo drinks, on Settings' Demo data screen, and the root's summary of them: adds 30 days of demo drinks, or removes them | ``ObserveDemoHistoryUseCase``, ``AddDemoHistoryUseCase``, ``RemoveDemoHistoryUseCase`` | ``SettingsFeature`` on its root, and ``DemoDataFeature`` on the pushed Demo data screen |
| ``DemoDataFeature`` | Settings' Demo data screen: the demo drinks and the demo Health data switch, side by side (<doc:Settings>, <doc:AppleHealthCard>) | None of its own | ``SettingsFeature``, pushed onto its path |
| ``DemoHealthDataFeature`` | The demo Health data switch: shows made-up Health data on the Apple Health card in place of Apple Health's (<doc:AppleHealthCard>) | ``ObserveDemoHealthDataUseCase``, ``SetDemoHealthDataUseCase`` | ``DemoDataFeature`` |
| ``DrinkComposerFeature`` | Logs a drink chosen from a sideways row of tiles, with its quantity and when it was consumed. It opens on the last drink logged, and closes when its one-tap row logs a favourite. It warns when the chosen drink is past its cutoff, without stopping it (<doc:DrinkComposer>) | ``LogDrinkUseCase``, ``ObserveLoggedDrinksUseCase``, ``ObserveCutoffWarningUseCase`` | ``AppFeature``, as a sheet |
| ``OnboardingFeature`` | The first-run flow: Welcome at the root of a navigation stack, then each step pushed onto its path (<doc:Onboarding>) | None of its own | ``AppFeature``, full screen |
| ``AboutYouFeature`` | Onboarding's name and age | ``ObserveUserProfileUseCase``, ``ObserveTimeOfDayUseCase``, ``SaveAboutYouUseCase`` | ``OnboardingFeature`` |
| ``HalfLifeFactorsFeature`` | What changes how fast the user clears caffeine. It never shows the half-life the answers give (<doc:Onboarding>). | ``ObserveUserProfileUseCase``, ``SaveHalfLifeFactorsUseCase`` | ``OnboardingFeature`` |
| ``BedtimeFeature`` | The bedtime, on the system's time picker | ``ObserveUserProfileUseCase``, ``SaveBedtimeUseCase`` | ``OnboardingFeature`` |
| ``PermissionsFeature`` | Apple Health, notifications, and Face ID, each with its status and an action. In onboarding, allowing Face ID also turns the app lock on, through ``TurnOnAppLockUseCase`` (<doc:AppLock>). | ``ObservePermissionsUseCase``, ``RequestHealthAccessUseCase``, ``RequestNotificationPermissionUseCase``, ``RequestBiometricPermissionUseCase``, ``RefreshPermissionsUseCase``, ``OpenAppSettingsUseCase`` | ``OnboardingFeature``, and ``SettingsFeature`` for its pushed Permissions screen |
| ``SiriShortcutsFeature`` | Onboarding's "Use Siri and Shortcuts" step: four phrases to try, and the button to Half-Life's shortcuts in the Shortcuts app. It asks for nothing, because App Shortcuts need no permission (<doc:Onboarding>, <doc:AppIntents>). | None | ``OnboardingFeature`` |
| ``OnboardingSummaryFeature`` | What onboarding saved, and the two ways out | ``ObserveUserProfileUseCase``, ``ObserveRecommendedSleepUseCase``, ``ObservePermissionsUseCase`` | ``OnboardingFeature`` |

## App Intents

App Intents are presentation without a reducer (constitution Article I.18). Each one calls its use cases directly, from the same `DependencyKey`s as the reducers, reads a question's answer from the first value an `Observe…` use case sends, and runs in the app's process. They take the target's `nonisolated` default and are never `@MainActor` (Article IV.1.4). ``HalfLifeShortcuts`` gives each an App Shortcut, with its phrases in `AppShortcuts.xcstrings` (<doc:AppIntents>).

| Intent | Does or answers | Use cases |
|--------|-----------------|-----------|
| ``LogDrinkIntent`` | Logs a drink, consumed now, from Siri, Shortcuts, the Action Button, or the one-tap widget. It's a `LiveActivityIntent`, so a widget's button runs it in the app. | ``LogDrinkUseCase`` |
| ``GetCaffeineStatusIntent`` | The caffeine in the body now, and at bedtime | ``ObserveCaffeineStatusUseCase`` |
| ``GetLastCupIntent`` | The latest time for the usual drink | ``ObserveCaffeineCutoffUseCase`` |
| ``GetCaffeineIntakeIntent`` | A day's drinks and total, today unless another day is named | ``ObserveTimeOfDayUseCase``, ``ObserveDrinkLogDayUseCase`` |
| ``GetSleepTimeIntent`` | Tonight's window to fall asleep in, with the Insights card's chart, ``SleepWindowChart``, in a snippet | ``ObserveSleepWindowUseCase`` |
| ``AskHalfLifeIntent`` | Any other question, answered by the on-device model, or an offer to open the app when Apple Intelligence is unavailable | ``RespondToInstructionUseCase`` |

## Widgets

Widgets are presentation without a reducer, in the `Half-LifeWidgets` extension (constitution Articles I.18–20). Each widget's timeline provider takes the first timeline ``ObserveWidgetTimelineUseCase`` publishes, and One tap's buttons perform ``LogDrinkIntent``, which runs in the app's process. The extension only reads the snapshot the app stores in the App Group container, so the app stays the only process that writes user data (<doc:Widgets>).

| Widget | Shows | A tap |
|--------|-------|-------|
| One tap | The top favourite, or all three on the medium widget, and when the latest drink was consumed | Logs the favourite, consumed now, through ``LogDrinkIntent`` |
| In your system | The caffeine now and its curve, and on the medium widget the level at bedtime | Opens the app |

## Use cases

| Use case | Operation | Repositories |
|----------|-----------|--------------|
| ``ObserveCaffeineCurveUseCase`` | Streams the active caffeine curve | ``CaffeineDecayRepository`` |
| ``ObserveCaffeineCutoffUseCase`` | Streams the cutoff: the latest time the user's usual drink can be drunk and leave no more than the sleep threshold at bedtime, in a given calendar (<doc:CaffeineCutoff>) | ``CaffeineDecayRepository`` |
| ``ObserveUpcomingCutoffsUseCase`` | Streams the cutoffs for the next several nights, tonight's first, in a given calendar (<doc:CutoffReminder>) | ``CaffeineDecayRepository`` |
| ``ObserveSleepWindowUseCase`` | Streams tonight's sleep window, in a given calendar (<doc:Insights>) | ``CaffeineDecayRepository`` |
| ``ObserveDrinkLogWeekUseCase`` | Streams the 7 days before today in the drink log, yesterday last, in a given calendar. Today is left out, because its night hasn't happened (<doc:Insights>). | ``DrinkLogRepository`` |
| ``ObserveSleepWeekUseCase`` | Streams the sleep that followed each of the 7 days before today, yesterday's last, in a given calendar (<doc:Insights>) | ``HealthDataRepository`` |
| ``ObserveAvailableHealthDataUseCase`` | Streams the kinds of Health data with any data in the last 30 days, in a given calendar (<doc:Insights>) | ``HealthDataRepository`` |
| ``ObserveRestingHeartRateComparisonUseCase`` | Streams the resting heart rate on the days after a caffeine night against the other days, over the last 30 days, in a given calendar. It combines the latest caffeine nights and resting heart rates, and executes ``RestingHeartRateComparisonRule`` (<doc:Insights>). | ``SleepToleranceRepository``, ``HealthDataRepository`` |
| ``ObserveStepsComparisonUseCase`` | Streams the steps on the days after a caffeine night against the other days, over the last 30 days, in a given calendar. It combines the latest caffeine nights and step history, and executes ``StepsComparisonRule`` (<doc:Insights>). | ``SleepToleranceRepository``, ``HealthDataRepository`` |
| ``ObserveInsightFeedbackUseCase`` | Streams the "Feel right?" answers on the Insights tab's first card (<doc:Insights>) | ``InsightFeedbackRepository`` |
| ``RecordInsightFeedbackUseCase`` | Stores a "Feel right?" answer, with the finding it answered, at the current time (<doc:Insights>) | ``CurrentTimeRepository``, ``InsightFeedbackRepository`` |
| ``ObserveInsightCardUseCase`` | Streams what the Insights tab's first card shows, or nothing while it's hidden: the finding, whether it asks "Feel right?", and the last disagreement. It combines three streams and executes ``SleepPatternRule`` and ``InsightFeedbackRule``, an exception the owner approved on 2026-09-13 (<doc:Insights>). | ``SleepToleranceRepository``, ``InsightFeedbackRepository``, ``LanguageModelRepository`` |
| ``ScheduleCutoffRemindersUseCase`` | Replaces the scheduled cutoff reminders with new ones (<doc:CutoffReminder>) | ``CutoffReminderRepository`` |
| ``ObserveCutoffWarningUseCase`` | Streams the drink composer's warning for a drink, consumed a given number of seconds ago, or `nil` when it fits (<doc:CaffeineCutoff>) | ``CaffeineDecayRepository`` |
| ``ObserveCaffeineStatusUseCase`` | Streams the caffeine status: the level now and the decay card's two tips, in a given calendar (<doc:TodayScreen>) | ``CaffeineDecayRepository`` |
| ``ObserveHalfLifeEstimateUseCase`` | Streams the personal half-life estimate. No feature shows it yet (<doc:HalfLifeEstimator>). | ``HalfLifeEstimateRepository`` |
| ``RefreshHalfLifeEstimateUseCase`` | Recalculates the personal half-life estimate if it's due: when none is stored, when it's a week old, or when the survey's starting half-life has changed (<doc:HalfLifeEstimator>) | ``HalfLifeEstimateRepository`` |
| _None yet_ | `SendBugReportUseCase` and `ObserveBugReportStatusUseCase` are designed in <doc:Logging> but not yet built. | `BugReportRepository`, plus `CrashReportRepository` for sending |
| ``LogDrinkUseCase`` | Records a drink from the composer, one-tap favourites, or an App Intent, consumed a given number of seconds ago (<doc:DrinkComposer>) | ``CurrentTimeRepository``, ``DrinkLogRepository`` |
| ``ObserveLoggedDrinksUseCase`` | Streams every logged drink, oldest first (<doc:DrinkComposer>) | ``DrinkLogRepository`` |
| ``ObserveFavouriteDrinksUseCase`` | Streams the three one-tap favourites, most logged first (<doc:OneTapLog>) | ``FavouriteDrinksRepository`` |
| ``ObserveCaffeineIntakeTodayUseCase`` | Streams the caffeine logged on the current calendar day, in a given calendar (<doc:TodayScreen>) | ``DrinkLogRepository`` |
| ``ObserveDrinkLogDayUseCase`` | Streams one calendar day of the drink log, its drinks and their caffeine, in a given calendar (<doc:TodayScreen>) | ``DrinkLogRepository`` |
| ``DeleteDrinkUseCase`` | Deletes a drink. The log, the totals, the favourites, and the decay curve follow through the data source the repositories share (<doc:TodayScreen>) | ``DrinkLogRepository`` |
| ``AddDemoHistoryUseCase`` | Adds 30 days of demo drinks, ending now, in place of any already there (<doc:Settings>) | ``DrinkLogRepository`` |
| ``RemoveDemoHistoryUseCase`` | Removes every demo drink, and keeps the user's own (<doc:Settings>) | ``DrinkLogRepository`` |
| ``ObserveDemoHistoryUseCase`` | Streams whether the drink log holds demo drinks (<doc:Settings>) | ``DrinkLogRepository`` |
| ``ObserveHealthSummaryUseCase`` | Streams today's Apple Health summary: last night, today's steps, and today's resting heart rate, in a given calendar (<doc:AppleHealthCard>) | ``HealthDataRepository`` |
| ``ObserveDemoHealthDataUseCase`` | Streams whether the demo Health data switch is on (<doc:AppleHealthCard>) | ``HealthDataRepository`` |
| ``SetDemoHealthDataUseCase`` | Turns the demo Health data switch on or off (<doc:AppleHealthCard>) | ``HealthDataRepository`` |
| ``ObserveUserProfileUseCase`` | Streams the user's profile (<doc:TodayScreen>) | ``UserProfileRepository`` |
| ``ObserveTimeOfDayUseCase`` | Streams each minute with the part of the day it falls in, by executing ``DayPeriodRule`` (<doc:TodayScreen>) | ``CurrentTimeRepository`` |
| ``SaveAboutYouUseCase`` | Saves the trimmed name and the birth year the age implies, from onboarding and Settings (<doc:Onboarding>, <doc:Settings>) | ``UserProfileRepository``, ``CurrentTimeRepository`` |
| ``SaveHalfLifeFactorsUseCase`` | Saves what changes how fast the user clears caffeine, from onboarding and Settings. The repository stores the starting half-life with it. | ``UserProfileRepository`` |
| ``SaveBedtimeUseCase`` | Saves the bedtime, from onboarding and Settings | ``UserProfileRepository`` |
| ``CompleteOnboardingUseCase`` | Records that onboarding is complete | ``UserProfileRepository`` |
| ``ObserveRecommendedSleepUseCase`` | Streams the sleep recommended for the user's age, in a given calendar | ``UserProfileRepository`` |
| ``ObservePermissionsUseCase`` | Streams the Health, notification, and Face ID permissions | ``PermissionsRepository`` |
| ``RequestHealthAccessUseCase``, ``RequestNotificationPermissionUseCase``, ``RequestBiometricPermissionUseCase`` | Each asks for its permission | ``PermissionsRepository`` |
| ``RefreshPermissionsUseCase`` | Re-reads the permissions, for example after the Settings app | ``PermissionsRepository`` |
| ``OpenAppSettingsUseCase`` | Opens Half-Life's page in the Settings app | ``PermissionsRepository`` |
| ``ObserveAppVersionUseCase`` | Streams the app's version and build, for the last line of Settings' root (<doc:Settings>) | ``AppVersionRepository`` |
| ``ObserveAppLockUseCase`` | Streams the app lock: whether it's on, and whether the app is locked (<doc:AppLock>) | ``AppLockRepository`` |
| ``TurnOnAppLockUseCase`` | Asks for Face ID if it hasn't been asked for, then turns the app lock on if it's allowed | ``PermissionsRepository``, ``AppLockRepository`` |
| ``TurnOffAppLockUseCase``, ``LockAppUseCase``, ``UnlockAppUseCase`` | Turn the app lock off, lock the app if the lock is on, and ask the user to unlock it | ``AppLockRepository`` |
| ``ObserveLanguageModelAvailabilityUseCase`` | Streams whether the on-device language model can be used, so features that use it hide while it can't (<doc:LanguageModel>) | ``LanguageModelRepository`` |
| ``RespondToInstructionUseCase`` | Answers one instruction with the on-device language model, in a session of its own. Only an App Intent's instruction can log a drink (<doc:LanguageModel>). | ``LanguageModelRepository`` |
| ``WriteInsightUseCase`` | Puts the Insights tab's first finding into words with the on-device language model, from the finding the card holds and the one the user last disagreed with (<doc:Insights>) | ``LanguageModelRepository`` |
| ``KeepWidgetsCurrentUseCase`` | Keeps the widget snapshot current for as long as it runs, from launch (<doc:Widgets>) | ``WidgetSnapshotRepository`` |
| ``ObserveWidgetTimelineUseCase`` | Streams the widgets' timeline, in a given calendar, for the widget extension (<doc:Widgets>) | ``WidgetTimelineRepository`` |

## Business rules

| Business rule | Calculates | Executed by |
|---------------|------------|-------------|
| ``CaffeineDecayRule`` | The active caffeine curve under Bateman absorption, which intakes count and which are negligible, and when an intake is half gone (<doc:CaffeineDecayModel>) | ``LiveCaffeineDecayRepository`` |
| ``CaffeineCutoffRule`` | The cutoff: the latest time, rounded down to the half hour, when the user's usual drink, on top of every intake logged, leaves no more than the sleep threshold at the next bedtime. It only considers cups that peak by bedtime, and asks ``CaffeineDecayRule`` for the levels (<doc:CaffeineCutoff>). It also gives the cutoffs for several nights, each calculated from the bedtime before it (<doc:CutoffReminder>), and the drink composer's warning for a drink past its cutoff (<doc:CaffeineCutoff>). | ``LiveCaffeineDecayRepository``, which also runs ``FavouriteDrinksRule`` to find the usual drink |
| ``SleepWindowRule`` | Tonight's sleep window: the first whole minute after which the caffeine logged stays at or below the sleep threshold until noon, and the 90 minutes from the later of that and the bedtime. It asks ``CaffeineDecayRule`` for the level at every minute from 6pm (<doc:Insights>). | ``LiveCaffeineDecayRepository`` |
| ``SleepHistoryRule`` | The night that followed each of the last several days: ``LastNightSleepRule``'s night ending from noon that day to noon the next, with today's always empty, and the one range to read sleep for (<doc:Insights>) | ``LiveHealthDataRepository`` |
| ``HealthDataAvailabilityRule`` | Which kinds of Health data have any data: sleep when any sleep was recorded, and steps and resting heart rate when any day has a value (<doc:Insights>) | ``LiveHealthDataRepository`` |
| ``CaffeineNightRule`` | Each past night's caffeine, for every comparison on the Insights tab: at the sleep onset Health recorded, the first from noon that day to noon the next, or else at the bedtime, and whether it's over the sleep threshold (<doc:Insights>) | ``SleepToleranceRepository``, for `caffeineNights(days:in:)` |
| ``SleepToleranceRule`` | The Sleep screen's analysis: the nights of the last 30 days, each with its time asleep, its time to fall asleep, and the caffeine at its onset from ``CaffeineDecayRule``; the caffeine tolerance, where a hockey-stick fit finds time asleep starts to drop, from 20 to 80 mg; and the averages either side of the threshold in use. It also gives every recognised night's onset, for ``CaffeineNightRule`` (<doc:Insights>). | ``LiveSleepToleranceRepository`` |
| ``RestingHeartRateComparisonRule`` | The resting heart rate on the days after a caffeine night against the other days: each group's average and day count, and whether the difference is a pattern, no clear difference, or not enough days yet (<doc:Insights>) | ``ObserveRestingHeartRateComparisonUseCase``. It's one of three use cases that execute a business rule, which the owner approved on 2026-09-13 over giving one repository the other's data (see ``DayPeriodRule``). |
| ``StepsComparisonRule`` | The steps on the days after a caffeine night against the other days: each side's average and day count, and whether the difference is beyond twice its standard error, within it, or has too few days yet (<doc:Insights>) | ``ObserveStepsComparisonUseCase``. It's one of three use cases that execute a business rule, which the owner approved on 2026-09-13 over giving one repository the other's data (see ``DayPeriodRule``). |
| ``SleepPatternRule`` | The finding on the Insights tab's first card, from the Sleep screen's ``SleepCaffeineAnalysis``: the direction its comparison of time asleep shows over the threshold in use, and the confidence its smaller group allows (<doc:Insights>) | ``ObserveInsightCardUseCase``. It's another use case that executes a business rule, which the owner chose on 2026-09-13 over giving the Sleep screen's repository card 1's rule. |
| ``InsightNumberRule`` | Whether every number in the model's finding is one the facts gave it (<doc:Insights>) | ``LiveLanguageModelRepository``, on each insight the model writes |
| ``InsightFeedbackRule`` | What the "Feel right?" answers do to the first card: dismissed after "Not really", no question after an answer, both until the confidence changes, and the latest "Not really" for the next prompt (<doc:Insights>) | ``ObserveInsightCardUseCase``, with ``SleepPatternRule`` |
| ``CaffeineStatusRule`` | The caffeine status: the level now, the intakes still counting, when the last one is half gone, and the level at the next bedtime. It asks ``CaffeineDecayRule`` for each of them (<doc:TodayScreen>). | ``LiveCaffeineDecayRepository`` |
| ``DrinkLogRule`` | Whether a drink may be logged: a quantity of at least 1, consumed no later than the current time (<doc:DrinkComposer>) | ``LiveDrinkLogRepository`` |
| ``FavouriteDrinksRule`` | The three one-tap favourites: every drink ever logged, counted by drink and quantity together, most logged first, with starters filling the slots the log can't (<doc:OneTapLog>) | ``LiveFavouriteDrinksRepository``, and ``LiveCaffeineDecayRepository`` to find the cutoff's usual drink |
| ``DailyCaffeineIntakeRule`` | The caffeine in the drinks consumed on one calendar day, from midnight to midnight in a given calendar (<doc:TodayScreen>) | ``LiveDrinkLogRepository`` |
| ``DrinkLogDayRule`` | One calendar day of the drink log: its drinks, and its intake from ``DailyCaffeineIntakeRule`` (<doc:TodayScreen>). It also gives the last several days, oldest first (<doc:Insights>). | ``LiveDrinkLogRepository`` |
| ``DemoHistoryRule`` | The demo history: a fixed script of drinks for the 30 days before today, and today's up to now, each marked demo (<doc:Settings>) | ``LiveDrinkLogRepository`` |
| ``DayPeriodRule`` | The part of the day a moment falls in, for the greeting (<doc:TodayScreen>) | ``ObserveTimeOfDayUseCase``. Use cases that execute a business rule are exceptions the owner approved: this one on 2026-09-11, over a second clock repository, then ``ObserveRestingHeartRateComparisonUseCase`` and ``ObserveStepsComparisonUseCase`` on 2026-09-13, each over giving one repository the other's data. |
| ``HalfLifePriorRule`` | The starting half-life, from the factors the user reported (<doc:Onboarding>) | ``LiveUserProfileRepository``, when the factors are saved |
| ``SleepNightRule`` | The nights in Health's sleep intervals: sessions of sleep, held together by recorded time awake, each with at least 3 hours of sleep and some stages, with its onset, wake, deep sleep, and time awake (<doc:HalfLifeEstimator>). ``LastNightSleepRule`` shares its sessions and its union. | ``LiveHalfLifeEstimateRepository`` |
| ``LastNightSleepRule`` | Last night for the Apple Health card: the latest session, grouped as ``SleepNightRule`` groups them, that ends between noon yesterday and noon today with at least 3 hours of sleep, staged or not, and its time asleep. With no such session, the time in bed ending in that window (<doc:AppleHealthCard>). | ``LiveHealthDataRepository`` |
| ``HalfLifeEstimationRule`` | The personal half-life estimate: a Bayesian update of the survey's starting half-life with the user's nights, with an 80% range. It asks ``CaffeineDecayRule`` for the caffeine at each night's sleep onset (<doc:HalfLifeEstimator>). | ``LiveHalfLifeEstimateRepository`` |
| The caffeine tolerance: the most caffeine at sleep onset before the user's time asleep starts to drop, or that there's none, with the number of nights on each side of it (<doc:Insights>) | `SleepTolerance.json` in Application Support, on the device only, and left out of iCloud backups (``FileSleepToleranceDataSource``) | `NSFileProtectionComplete` | The sleep threshold, which sets the cutoff, the composer's warning, the reminders, and the sleep window. It's derived from Health's sleep, so it's never synced to or backed up in iCloud, and never logged (Articles V.3.4 and XI.6). The sleep it's calculated from isn't stored. |
| ``SleepNeedRule`` | The sleep recommended for the user's age (<doc:Onboarding>) | ``LiveUserProfileRepository`` |
| ``WidgetSnapshotRule`` | The widget snapshot: the level every 5 minutes until the caffeine is gone, from ``CaffeineDecayRule``, the favourites from ``FavouriteDrinksRule``, the bedtime, when the latest drink was consumed, and whether onboarding is complete (<doc:Widgets>) | ``LiveWidgetSnapshotRepository`` |
| ``WidgetTimelineRule`` | The widgets' timeline: an entry every 5 minutes for 12 hours, each reading the snapshot's forecast by date (<doc:Widgets>) | ``LiveWidgetTimelineRepository``, in the widget extension |

## Repositories

| Repository | Owns | Data sources |
|------------|------|--------------|
| ``CaffeineDecayRepository``, implemented by ``LiveCaffeineDecayRepository`` | The caffeine curve (<doc:CaffeineDecayModel>), the cutoff, the cutoffs for the next several nights, the drink composer's cutoff warning, and tonight's sleep window, each sent only when it changes (<doc:CaffeineCutoff>, <doc:CutoffReminder>, <doc:Insights>), and the caffeine status, recalculated every minute (<doc:TodayScreen>) | ``DrinkLogDataSource``, shared with ``DrinkLogRepository``; ``FileProfileDataSource``, shared with ``UserProfileRepository``, as ``BedtimeDataSource``; ``EstimatedHalfLifeDataSource`` as ``HalfLifeDataSource``, which reads ``FileHalfLifeEstimateDataSource``, shared with ``HalfLifeEstimateRepository``, and the profile; ``AbsorptionRateDataSource``; ``ClockDataSource``; ``PersonalSleepThresholdDataSource`` as ``SleepThresholdDataSource``, which reads ``FileSleepToleranceDataSource``, shared with ``SleepToleranceRepository`` |
| _None yet_ | `BugReportRepository` is designed in <doc:Logging> but not yet built. It will own the bug report's status. | `OSLogEntryDataSource`, `MessageUIMailDataSource` (not yet built) |
| _None yet_ | `CrashReportRepository` is designed in <doc:Logging> but not yet built. It will own the unsent crash reports. | `MetricKitCrashReportDataSource`, `FileCrashReportDataSource` (not yet built) |
| ``DrinkLogRepository``, implemented by ``LiveDrinkLogRepository`` | Every logged drink (<doc:DrinkComposer>), the caffeine logged today, recalculated after each change that alters it and at the start of each day, and any one day of the log, for the history card. It also deletes drinks (<doc:TodayScreen>). It adds and removes the demo history, and publishes whether the log holds any (<doc:Settings>). It also streams the last several days, moving on at midnight (<doc:Insights>). | ``DrinkLogDataSource``, shared with ``CaffeineDecayRepository``; ``ClockDataSource`` |
| ``FavouriteDrinksRepository``, implemented by ``LiveFavouriteDrinksRepository`` | The three one-tap favourites, recalculated after each change to the drink log (<doc:OneTapLog>) | ``DrinkLogDataSource``, shared with ``DrinkLogRepository`` and ``CaffeineDecayRepository`` |
| ``LiveCurrentTimeRepository`` (``CurrentTimeRepository``) | The current time: `now()`, and a stream that emits at every whole minute (<doc:DrinkComposer>) | ``ClockDataSource`` |
| ``AppVersionRepository``, implemented by ``LiveAppVersionRepository`` | The app's version and build, read once when it's created. Its stream sends them once, then finishes, because they never change while the app runs (<doc:Settings>). | ``BundleAppVersionDataSource`` |
| ``UserProfileRepository``, implemented by ``LiveUserProfileRepository`` | What the user has told the app about themselves: the name, birth year, factors that change the half-life, bedtime, starting half-life, and whether onboarding is complete, plus the sleep recommended for their age (<doc:Onboarding>) | ``FileProfileDataSource``, shared with ``CaffeineDecayRepository`` and ``HalfLifeEstimateRepository``; ``ClockDataSource`` |
| ``HalfLifeEstimateRepository``, implemented by ``LiveHalfLifeEstimateRepository`` | The personal half-life estimate, recalculated when it's a week old or when the survey's starting half-life changes, and stored where the decay model reads it (<doc:HalfLifeEstimator>) | ``DrinkLogDataSource``, shared with ``DrinkLogRepository``; ``SleepDataSource``, ``StepCountDataSource``, and ``RestingHeartRateDataSource``, from HealthKit, or ``UnavailableHealthDataSource`` in previews and UI tests; ``FileProfileDataSource``, shared with ``UserProfileRepository``, as ``HalfLifeDataSource``; ``FileHalfLifeEstimateDataSource``, shared with ``CaffeineDecayRepository``; ``AbsorptionRateDataSource``; ``ClockDataSource`` |
| ``HealthDataRepository``, implemented by ``LiveHealthDataRepository`` | Today's Apple Health summary, re-read when its data sources signal a change, at the start of each day, when Health access is first requested, and when the demo switch turns, and sent only when it changes. It also owns the demo Health data switch, and reads the demo data sources while it's on (<doc:AppleHealthCard>). It also streams the sleep that followed each of the last several days, on the same events (<doc:Insights>). It also streams the kinds of Health data with any data, for the Insights tab's buttons, and each day's resting heart rate, for the resting heart rate screen, and each whole day's steps before today, for the steps screen (<doc:Insights>). | ``SleepDataSource``, ``StepCountDataSource``, and ``RestingHeartRateDataSource``, from HealthKit, or ``SimulatedHealthDataSource`` under UI tests and ``UnavailableHealthDataSource`` in previews; the demo's ``DemoSleepDataSource``, ``DemoStepCountDataSource``, and ``DemoRestingHeartRateDataSource``; ``HealthKitAuthorizationDataSource``, shared in kind with ``PermissionsRepository``; ``FileDemoHealthDataFlagDataSource``, shared with ``SleepToleranceRepository``; ``ClockDataSource`` |
| ``SleepToleranceRepository``, implemented by ``LiveSleepToleranceRepository`` | The analysis of the nights in the last 30 days against the caffeine at sleep onset, and the caffeine tolerance it stores for the decay model, recalculated after a change to the drinks, the half-life, the bedtime, the demo switch, or the chosen sleep, at the start of each day, and when Health access is first requested, and sent only when it changes. From the same read, it streams each night's caffeine, the one stream every Insights comparison reads (<doc:Insights>). | ``SleepDataSource``, from HealthKit, or ``SimulatedHealthDataSource`` under UI tests and ``UnavailableHealthDataSource`` in previews, and the demo's ``DemoSleepDataSource``; ``HealthKitAuthorizationDataSource``, shared in kind with ``PermissionsRepository``; ``FileDemoHealthDataFlagDataSource``, shared with ``HealthDataRepository``; ``DrinkLogDataSource``, shared with ``DrinkLogRepository``; ``EstimatedHalfLifeDataSource`` as ``HalfLifeDataSource``, as the curve reads it; ``FileProfileDataSource`` as ``BedtimeDataSource``; ``AbsorptionRateDataSource``; ``FileSleepToleranceDataSource``, shared with ``CaffeineDecayRepository``; ``ClockDataSource`` |
| ``LanguageModelRepository``, implemented by ``LiveLanguageModelRepository`` | Whether the on-device language model can be used, re-read at each minute and sent only when it changes. It passes each instruction to the model, and keeps nothing from it. It also writes the Insights tab's first finding, and keeps it only when ``InsightNumberRule`` finds every number in the tool's facts (<doc:LanguageModel>). | ``FoundationModelLanguageModelDataSource``, as ``LanguageModelDataSource``, or ``SimulatedLanguageModelDataSource`` under UI tests; ``ClockDataSource`` |
| ``InsightFeedbackRepository``, implemented by ``LiveInsightFeedbackRepository`` | The "Feel right?" answers, read for each new subscriber and sent to every subscriber after each answer it records (<doc:Insights>) | ``FileInsightFeedbackDataSource`` |
| ``AppLockRepository``, implemented by ``LiveAppLockRepository`` | Whether the app lock is on, stored, and whether the app is locked, in memory. It starts the app locked when the lock is on (<doc:AppLock>). | ``FileAppLockSettingDataSource``, ``LocalAuthenticationDeviceOwnerDataSource`` |
| ``PermissionsRepository``, implemented by ``LivePermissionsRepository`` | The statuses of the Health, notification, and Face ID permissions (<doc:Onboarding>) | ``HealthKitAuthorizationDataSource``, ``UserNotificationsAuthorizationDataSource``, ``LocalAuthenticationDataSource``, ``FilePermissionHistoryDataSource``, ``UIKitSystemSettingsDataSource`` |
| ``CutoffReminderRepository``, implemented by ``LiveCutoffReminderRepository`` | The reminders scheduled at the next seven nights' cutoffs: scheduled only while notifications are allowed, and only those still to come (<doc:CutoffReminder>) | ``UserNotificationsReminderDataSource``, or ``SimulatedCutoffReminderDataSource`` in previews and UI tests; ``UserNotificationsAuthorizationDataSource``, shared in kind with ``PermissionsRepository``; ``ClockDataSource`` |
| ``WidgetSnapshotRepository``, implemented by ``LiveWidgetSnapshotRepository`` | The widget snapshot, recalculated after each change to the drink log, the profile, or the half-life, stored for the widget extension, and followed by a reload of the widgets (<doc:Widgets>) | ``DrinkLogDataSource``, ``FileProfileDataSource`` as ``UserProfileDataSource``, and ``EstimatedHalfLifeDataSource`` as ``HalfLifeDataSource``, each shared in kind with the repositories that read them; ``AbsorptionRateDataSource``; ``ClockDataSource``; ``FileWidgetSnapshotDataSource``; ``WidgetKitReloadDataSource`` |
| ``WidgetTimelineRepository``, implemented by ``LiveWidgetTimelineRepository`` | In the widget extension, one timeline read from the stored snapshot. It lives for one timeline (constitution Article I.19, <doc:Widgets>). | ``FileWidgetSnapshotDataSource``, read only; ``ClockDataSource`` |

## Data sources

| Data source | Wraps |
|-------------|-------|
| ``HealthKitRestingHeartRateDataSource``, implementing ``RestingHeartRateDataSource`` | HealthKit's statistics query, for the average of one day's resting heart rate samples, and one observer query per subscriber for changes (<doc:RestingHeartRate>). It only reads. ``HalfLifeEstimateRepository`` reads it, for the day before each night (<doc:HalfLifeEstimator>), and ``HealthDataRepository`` reads today's (<doc:AppleHealthCard>). Constitution Article V.3.5 allows one HealthKit data source per kind of Health data. |
| ``HealthKitStepCountDataSource``, implementing ``StepCountDataSource`` | HealthKit's statistics query, for the total of one day's step count samples, and one observer query per subscriber for changes (<doc:StepCount>). It only reads. ``HalfLifeEstimateRepository`` reads it, for the day before each night (<doc:HalfLifeEstimator>), and ``HealthDataRepository`` reads today's (<doc:AppleHealthCard>). |
| ``HealthKitSleepDataSource``, implementing ``SleepDataSource`` | HealthKit's sample query, for the sleep analysis samples that overlap a range, and one observer query per subscriber for changes (<doc:SleepData>). It only reads, on `HKHealthStore.halfLife`, the app's one health store. ``HalfLifeEstimateRepository`` reads the last 90 days of it (<doc:HalfLifeEstimator>), and ``HealthDataRepository`` reads last night's (<doc:AppleHealthCard>). ``SleepToleranceRepository`` reads the last 30 days of it (<doc:Insights>). |
| ``DemoSleepDataSource``, ``DemoStepCountDataSource``, and ``DemoRestingHeartRateDataSource`` | Nothing. They answer from ``DemoHealthScript``'s 30 days of made-up sleep, steps, and resting heart rate, in step with the demo drinks, while the demo Health data switch is on. They never touch HealthKit (constitution Article V.3.5, <doc:AppleHealthCard>). |
| ``FileDemoHealthDataFlagDataSource``, implementing ``DemoHealthDataFlagDataSource`` | `DemoHealthData.json` in Application Support, written atomically: whether the demo Health data switch is on. One shared instance, from ``DemoHealthDataFlagDataSourceKey``, sits behind ``HealthDataRepository`` and ``SleepToleranceRepository``. Under UI tests and in previews it's a temporary file (<doc:AppleHealthCard>). |
| ``SimulatedHealthDataSource``, implementing ``SleepDataSource``, ``StepCountDataSource``, and ``RestingHeartRateDataSource`` | Nothing. It stands in for HealthKit under UI tests, holding the fixed Health data the launch environment chose, with ``RequestedHealthAccessDataSource`` for Health access (<doc:AppleHealthCard>). |
| ``SimulatedLanguageModelDataSource``, implementing ``LanguageModelDataSource`` | Nothing. It stands in for the on-device model under UI tests. It's unavailable unless the launch environment asks for it, and then it writes each insight from the facts an insight's prompt gives (<doc:LanguageModel>). |
| ``HealthKitAuthorizationDataSource``, implementing ``HealthAuthorizationDataSource`` | HealthKit's authorization request and its request status, on `HKHealthStore.halfLife`. It asks, in one sheet, to read sleep, steps, and resting heart rate, and to write nothing. It's the only data source that requests Health access (constitution Article V.3.1), and it presents Health's sheet itself (Article I.6). |
| ``FileProfileDataSource``, implementing ``UserProfileDataSource``, ``BedtimeDataSource``, and ``HalfLifeDataSource`` | `Profile.json` in Application Support, written atomically with `NSFileProtectionComplete`, on the device only. It stores the profile, with the bedtime and the starting half-life, and signals every subscribed repository after each successful store. One shared instance, from ``ProfileDataSourceKey``, sits behind ``UserProfileRepository``, ``CaffeineDecayRepository``, and ``HalfLifeEstimateRepository``. The decay repository reads its half-life through ``EstimatedHalfLifeDataSource``. Under UI tests and in previews it's a temporary file (<doc:Onboarding>). |
| ``FileHalfLifeEstimateDataSource``, implementing ``HalfLifeEstimateDataSource`` | `HalfLifeEstimate.json` in Application Support, written atomically with `NSFileProtectionComplete`, left out of iCloud backups, on the device only. It stores the personal half-life estimate, and signals every subscriber after each successful store. One shared instance, from ``HalfLifeEstimateDataSourceKey``, sits behind ``HalfLifeEstimateRepository``, and behind ``CaffeineDecayRepository`` through ``EstimatedHalfLifeDataSource``. Under UI tests and in previews it's a temporary file (<doc:HalfLifeEstimator>). |
| ``EstimatedHalfLifeDataSource``, implementing ``HalfLifeDataSource`` | Nothing of its own. It gives the decay model the stored estimate's half-life when the estimate started from the survey's current half-life, and the profile's otherwise, and signals when either changes (<doc:HalfLifeEstimator>). |
| ``UnavailableHealthDataSource``, implementing ``SleepDataSource``, ``StepCountDataSource``, and ``RestingHeartRateDataSource`` | Nothing. It stands in for HealthKit in previews and UI tests, with no data, so neither reads real Health data (constitution Article V.3.5, <doc:HalfLifeEstimator>). |
| ``UserNotificationsAuthorizationDataSource``, implementing ``NotificationAuthorizationDataSource`` | `UNUserNotificationCenter`'s authorization status, and its request for alerts and sounds |
| ``UserNotificationsReminderDataSource``, implementing ``CutoffReminderDataSource`` | `UNUserNotificationCenter`'s pending requests. It replaces the cutoff reminders, each a request delivered once at its date, and reads back the ones still pending. It leaves every other request alone (<doc:CutoffReminder>). |
| ``LocalAuthenticationDataSource``, implementing ``BiometricAuthenticationDataSource`` | `LAContext`: whether Face ID or Touch ID can be used, and one authentication to ask for it |
| ``FilePermissionHistoryDataSource``, implementing ``PermissionHistoryDataSource`` | `PermissionHistory.json` in Application Support, which remembers that Face ID was asked for, because iOS reports it as available both before and after the user allows it |
| ``FileInsightFeedbackDataSource``, implementing ``InsightFeedbackDataSource`` | `InsightFeedback.json` in Application Support: every "Feel right?" answer, in order, with the finding it answered (<doc:Insights>) |
| ``FileAppLockSettingDataSource``, implementing ``AppLockSettingDataSource`` | `AppLock.json` in Application Support, written atomically with `NSFileProtectionComplete`: whether the app lock is on (<doc:AppLock>) |
| ``LocalAuthenticationDeviceOwnerDataSource``, implementing ``DeviceOwnerAuthenticationDataSource`` | `LAContext`'s device owner policy, to unlock the app: Face ID or Touch ID, then the passcode. The system presents the prompt (constitution Article I.6). |
| ``UIKitSystemSettingsDataSource``, implementing ``SystemSettingsDataSource`` | Opens Half-Life's page in the Settings app |
| ``BundleAppVersionDataSource``, implementing ``AppVersionDataSource`` | The app bundle's Info.plist: `CFBundleShortVersionString` and `CFBundleVersion`. It's the only code that reads them (<doc:Settings>). |
| ``FoundationModelLanguageModelDataSource``, implementing ``LanguageModelDataSource`` | Apple's on-device language model, through the Foundation Models framework. It reads the model's availability, and answers each instruction in a new `LanguageModelSession` with new tools, which read ``CaffeineDecayRepository``, ``DrinkLogRepository``, and ``CurrentTimeRepository``. Only an App Intent's instruction gets `logDrink`, which logs through ``LogDrinkUseCase``. An insight gets a session of its own, with no tools, a prompt that gives the facts of the finding that came with the request, and guided generation into `GeneratedInsight`, capped at 150 tokens (<doc:LanguageModel>). |
| ``SystemClockDataSource`` (``ClockDataSource``) | The system clock, through `Date.now`, and `Task.sleep` for the minute stream. It's the only code that reads the clock. |
| ``SwiftDataDrinkLogDataSource``, implementing ``DrinkLogDataSource`` | SwiftData, in a store on the device only, with CloudKit off (<doc:DrinkComposer>). It stores and deletes logged drinks, stores their negligible and demo marks, replaces the demo drinks in one save, and signals each store, deletion, and replacement to the repositories that read it. CloudKit sync, which constitution Article V.1 allows, is deferred to roadmap rank 23. |
| ``StandardAbsorptionRateDataSource``, implementing ``AbsorptionRateDataSource`` | Nothing yet. It returns the standard 13-minute absorption half-life until something can store a tuned rate. |
| ``StandardSleepThresholdDataSource``, implementing ``SleepThresholdDataSource`` | Nothing. It returns the standard 40 mg sleep threshold, and never changes. It stands in where a repository is built without a threshold, as in tests (<doc:CaffeineCutoff>). |
| ``PersonalSleepThresholdDataSource``, implementing ``SleepThresholdDataSource`` | Nothing of its own. It gives the decay model the stored caffeine tolerance as the sleep threshold, or the standard 40 mg without one, and signals when a tolerance is stored (<doc:Insights>). |
| ``FileSleepToleranceDataSource``, implementing ``SleepToleranceDataSource`` | `SleepTolerance.json` in Application Support, written atomically with `NSFileProtectionComplete`, left out of iCloud backups, on the device only. It stores the caffeine tolerance, or that there's none, and signals every subscriber after each successful store. One shared instance, from ``SleepToleranceDataSourceKey``, sits behind ``SleepToleranceRepository``, and behind ``CaffeineDecayRepository`` through ``PersonalSleepThresholdDataSource``. Under UI tests and in previews it's a temporary file (<doc:Insights>). |
| ``FileWidgetSnapshotDataSource``, implementing ``WidgetSnapshotDataSource`` | `WidgetSnapshot.json` in the App Group container `group.com.quillanq.Half-Life`, written atomically with `NSFileProtectionCompleteUntilFirstUserAuthentication` and left out of iCloud backups. The app writes it and the widget extension reads it. Under UI tests and in previews it's a temporary file (<doc:Widgets>). |
| ``WidgetKitReloadDataSource``, implementing ``WidgetReloadDataSource`` | WidgetKit's `WidgetCenter`, which it asks to reload the widgets after each new snapshot. It's the app's only WidgetKit code (<doc:Widgets>). |
| _None yet_ | `OSLogEntryDataSource` (wraps `OSLogStore`) and `MessageUIMailDataSource` (wraps MessageUI's Mail composer, which it presents itself, per constitution Article I.6) are designed in <doc:Logging> but not yet built. |
| _None yet_ | `MetricKitCrashReportDataSource` (wraps `MXMetricManager`) and `FileCrashReportDataSource` (stores unsent crash reports) are designed in <doc:Logging> but not yet built. |

## Navigation

``AppView`` is the root: the system tab bar, with the Today, Insights, and Settings tabs, and the log button as the bar's bottom accessory, just above it. The system tab bar's own buttons carry no accessibility identifiers, so an action tab couldn't be driven by a robot (constitution Article II.6). The owner chose the accessory on 2026-09-12 (<doc:OneTapLog>). The Insights tab pushes each Health data kind's screen onto its own navigation stack (<doc:Insights>).

For Settings, the owner amended Article II.6 on 2026-09-12: `AppRobot` finds each tab's button by its label, the tab's title in the development language, and no other robot or element is found that way (<doc:Settings>). Each tab is a case of `AppTab`, in `AppViewAccessibilityID.swift`, whose raw value is its title's String Catalog key. The view and the robot both look the key up, the robot in the UI test bundle's copy of the catalog in English, so neither hard-codes the title. The tabs switch through the system tab bar's own selection, so no feature state holds which one is showing.

Settings has a navigation stack of its own: its root is a list of rows, and ``SettingsFeature`` pushes each row's screen onto a `StackState` path, as onboarding pushes its steps (<doc:Settings>).

The log button presents ``DrinkComposerView`` as a sheet sized to its content: ``AppFeature`` holds the composer's state in a `@Presents` property, so the sheet is state-driven (constitution Article I.6). The composer closes itself through TCA's `dismiss` dependency, after a drink is logged, when its one-tap row logs a favourite, or when the user taps Close.

Onboarding is presented full screen by ``AppFeature`` while the user's profile says it isn't complete, and dismissed when the profile says it is. Its steps are pushed onto a `StackState` navigation stack. "Log my first cup" opens the drink composer once the full-screen cover has gone (<doc:Onboarding>).

While the app lock has locked the app, ``AppFeature`` holds the lock screen's state as an optional child, and ``AppView`` shows ``AppLockView`` in the tab bar's place. It isn't presented over the tabs, because a sheet such as the composer would sit above it, so showing it dismisses the composer. It shows only once onboarding is complete, and goes when the repository publishes the unlocked app (<doc:AppLock>).

System UI that a framework provides, such as the Mail composer or HealthKit's authorization sheet, is presented by the data source that wraps the framework, not by feature state. The feature learns the outcome through the repository (constitution Article I.6).

## Data and privacy

All user data stays on the device (constitution Article V.1). The drink log's sync to the user's private CloudKit database, which Article V.1 allows, is deferred to roadmap rank 23 (<doc:DrinkComposer>). List every piece of stored data here.

| Data | Stored in | Protection class | Why it's collected |
|------|-----------|------------------|--------------------|
| Logged drinks: type, quantity, caffeine, time consumed, the negligible mark, and the demo mark on the sample drinks Settings adds (<doc:Settings>) | A SwiftData store in the app container, on the device only (``SwiftDataDrinkLogDataSource``) | iOS's default, `NSFileProtectionCompleteUntilFirstUserAuthentication`, chosen by the owner on 2026-09-11 (Article V.4). Siri needs the store while the device is locked after its first unlock. | The decay curve and the drink log. The user logs each drink. |
| Resting heart rate: one day's average, read from Apple Health (``HealthKitRestingHeartRateDataSource``) | Not stored. It's read from Health when needed and held only in memory, and never synced to iCloud (Article V.3.4). | Not written by the app | To set heart rate against caffeine habits, as the brief asks. The Apple Health card shows today's, and the half-life estimator uses it to allow for nights that went badly for other reasons (<doc:RestingHeartRate>, <doc:AppleHealthCard>, <doc:HalfLifeEstimator>). |
| Sleep: stage intervals read from Apple Health (``HealthKitSleepDataSource``) | Not stored. It's read from Health when needed and held only in memory, and never synced to iCloud (Article V.3.4). | Not written by the app | To set sleep against caffeine timing, as the brief asks. The Apple Health card shows last night's time asleep, or time in bed when no sleep was recorded, and the half-life estimator scores each night by its deep sleep and time awake (<doc:SleepData>, <doc:AppleHealthCard>, <doc:HalfLifeEstimator>). The Sleep screen sets each night's time asleep and time to fall asleep against the caffeine at sleep onset (<doc:Insights>). |
| Step count: one day's total, read from Apple Health (``HealthKitStepCountDataSource``) | Not stored. It's read from Health when needed and held only in memory, and never synced to iCloud (Article V.3.4). | Not written by the app | To set activity against caffeine habits, as the brief asks. The Apple Health card shows today's, and the half-life estimator uses it to allow for nights that went badly for other reasons (<doc:StepCount>, <doc:AppleHealthCard>, <doc:HalfLifeEstimator>). |
| Onboarding's profile: name, birth year, the factors that change the half-life, the starting half-life, the bedtime, and whether onboarding is complete | `Profile.json` in Application Support, on the device only (``FileProfileDataSource``) | `NSFileProtectionComplete` | The greeting, the recommended sleep range, and the personal decay model. The factors can include a pregnancy or liver disease, so they're health data (<doc:Onboarding>). |
| The personal half-life estimate: the half-life, its 80% range, the starting half-life it started from, the number of nights used, and when it was calculated | `HalfLifeEstimate.json` in Application Support, on the device only, and left out of iCloud backups (``FileHalfLifeEstimateDataSource``) | `NSFileProtectionComplete` | The personal decay model. It's derived from Health's sleep, so it's never synced to or backed up in iCloud (Article V.3.4). The Health data it's calculated from isn't stored (<doc:HalfLifeEstimator>). |
| The widget snapshot: the caffeine forecast, the bedtime, the three favourites, when the latest drink was consumed, and whether onboarding is complete (<doc:Widgets>) | `WidgetSnapshot.json` in the App Group container, on the device only, and left out of iCloud backups (``FileWidgetSnapshotDataSource``) | `NSFileProtectionCompleteUntilFirstUserAuthentication` (Article V.4), because WidgetKit can ask the widget extension for a timeline while the phone is locked | The two Home Screen widgets. It's derived from the drink log, the profile, and the half-life estimated from Health data, so it's never synced to or backed up in iCloud (Article V.3.4). |
| Whether Face ID has been asked for | `PermissionHistory.json` in Application Support (``FilePermissionHistoryDataSource``) | `NSFileProtectionComplete` | The Face ID row's status, because iOS reports Face ID as available both before and after it's allowed |
| The "Feel right?" answers on the Insights tab's first card: each answer, the finding's confidence, headline, and sentence, and when it was given (<doc:Insights>) | `InsightFeedback.json` in Application Support, on the device only (``FileInsightFeedbackDataSource``). It never syncs. | `NSFileProtectionComplete` | To dismiss the card, or stop asking, until the finding's confidence changes, and to tell the on-device model which finding the user disagreed with, so it takes a different approach. The answers are the user's reaction to their own sleep, so they're never synced or logged (Articles V.1 and XI.6). |
| Whether the demo Health data switch is on (<doc:AppleHealthCard>) | `DemoHealthData.json` in Application Support, on the device only (``FileDemoHealthDataFlagDataSource``). It never syncs. | iOS's default, `NSFileProtectionCompleteUntilFirstUserAuthentication`. It's the app's feature flag, not the user's data. | Showing made-up Health data on the Apple Health card, when the user turns the demo on |
| Whether the app lock is on (<doc:AppLock>) | `AppLock.json` in Application Support (``FileAppLockSettingDataSource``). It never syncs. Whether the app is locked lives only in memory. | `NSFileProtectionComplete` | Locking the app at launch and in the background, when the user turned the lock on |
| The language model's instructions, tool calls, and responses (<doc:LanguageModel>) | Memory only, for the one instruction. Nothing is persisted, and the model runs on the device. | Not written by the app | To answer the instruction. They carry health data, so they're never logged (Article XI.6). |
| Bug report log attachment (designed in <doc:Logging>, not yet built) | Memory only, handed to the Mail composer as data. Mail keeps its own copy once the draft is sent or saved. | Not written by the app | Attached to a bug report that the user chooses to send. It holds no health values (Article XI). |
| Unsent crash reports (designed in <doc:Logging>, not yet built) | Application Support, until a draft carrying them is sent | `NSFileProtectionComplete` | Attached to the next bug report the user sends. MetricKit's crash diagnostic: call stacks, exception codes, and device and OS metadata. No health values (Article XI.6.5). |

### Purpose strings

A purpose string is the text iOS shows when Half-Life asks for access to a protected resource. The app declares four.

| Key | Shown when Half-Life asks to |
|-----|------------------------------|
| `NSHealthShareUsageDescription` | Read Health data |
| `NSHealthUpdateUsageDescription` | Save caffeine to Health |
| `NSHealthClinicalHealthRecordsShareUsageDescription` | Read clinical health records. Reading them also needs the HealthKit capability's Clinical Health Records option, which the app doesn't have yet. |
| `NSFaceIDUsageDescription` | Use Face ID, which unlocks the app lock (<doc:AppLock>) |

The text lives in `InfoPlist.xcstrings`, the String Catalog for the Info.plist, so it's localized like every other user-facing string (constitution Articles V.3.2 and VII.1).

- **`Info.plist` still declares each key**, with the value `Localized in InfoPlist.xcstrings`. App Store validation and the frameworks look for the key in the Info.plist itself, and a key that exists only in the catalog doesn't appear there. Don't enter purpose strings in the target's build settings or in Xcode's capability editor, which writes them into `project.pbxproj` as `INFOPLIST_KEY_…` settings.
- **The catalog's text replaces the placeholder** in every localization that translates the key. A localization that doesn't translate it shows the Info.plist's placeholder, not the English text. So every localization translates every purpose string before it ships.
- **The entries are manual.** Xcode's localization sync leaves manual entries alone. It adds `CFBundleName` to the catalog by itself, and that entry is kept so the sync doesn't change the file. `CFBundleDisplayName`, "Half-Life", is a manual entry, with a placeholder in `Info.plist` like the purpose strings, so that `ShortcutsLink` names the app (<doc:Onboarding>).

`PurposeStringTests` checks this:

- **PURPOSE-1:** `Info.plist` declares every key.
- **PURPOSE-2:** every localization the app ships translates every key.
- **PURPOSE-3:** the lookup the system uses returns the catalog's text, not the placeholder.
- **PURPOSE-4:** `Info.plist` declares no other purpose string, so the app asks for no access it doesn't use (Article V.2).

The app declares no `NSSiriUsageDescription` and has no Siri entitlement. Both are for SiriKit, whose Intents extensions ask the user's permission to send data to Siri. App Intents and App Shortcuts need neither. The owner removed them on 2026-09-12 (<doc:AppIntents>).
