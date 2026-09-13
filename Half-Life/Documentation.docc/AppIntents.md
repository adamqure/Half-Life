# App Intents

How Siri, Shortcuts, Spotlight, Apple Intelligence, the Action Button, and the one-tap widget log drinks and answer questions about caffeine, through the same use cases the screens use.

## Overview

App Intents are roadmap rank 14. They let the user log a drink and ask about their caffeine without opening the app: by voice, by typing to Siri, from a shortcut, with the Action Button, or from a widget. They also carry the brief's "text the app" bonus. The roadmap puts that bonus "on a better substrate": typing to Siri stands in for texting a number, which would need a server that constitution Article V.1 rules out. The brief's "ask the text message when the optimal time to sleep would be" becomes "When should I go to sleep?", answered with the decay graph.

**Status: built on 2026-09-13.** The build follows the owner's decisions (see "Decisions"), with one change the build forced: intents take the target's default isolation instead of writing `nonisolated` (see "Isolation"). Before release, the sleep-time snippet still needs its Accessibility Inspector check (INTENT-A11Y-1).

**The intents add no business logic.** Each intent is a thin entry point. It calls a use case that already exists, and phrases what comes back. Every number Siri says comes from the same repository and business rule as the number on a screen, so the two can't disagree.

## Architecture

```
 Siri, spoken or typed · Shortcuts · Spotlight · Apple Intelligence · Action Button · one-tap widget
                │  an App Shortcut phrase, or an intent run with its parameters
                ▼
 ┌─ Presentation ── Half-Life/AppIntents/ ── imports AppIntents, runs in the app's own process
 │
 │   HalfLifeShortcuts: AppShortcutsProvider ─── phrases, from AppShortcuts.xcstrings
 │
 │   LogDrinkIntent ────────────┐   drink: DrinkTypeAppEnum, quantity: Int?   (also LiveActivityIntent)
 │   GetCaffeineStatusIntent ───┤
 │   GetLastCupIntent ──────────┤   perform() reads a use case with @Dependencies.Dependency,
 │   GetCaffeineIntakeIntent ───┤   day: Date?     and returns an IntentDialog and a value
 │   GetSleepTimeIntent ────────┤   ─▶ SleepTimeSnippetView (@MainActor): the decay graph
 │   AskHalfLifeIntent ─────────┤   question: String
 │                              │
 └──────────────────────────────┼──────────────────────────────────────────────────────────────
                                ▼
 ┌─ Domain ── existing use cases, the same app-scoped instances the reducers get
 │
 │   LogDrinkUseCase                    ◀── LogDrinkIntent
 │   ObserveCaffeineStatusUseCase       ◀── GetCaffeineStatusIntent   takes the first value
 │   ObserveCaffeineCutoffUseCase       ◀── GetLastCupIntent          takes the first value
 │   ObserveTimeOfDayUseCase            ◀── GetCaffeineIntakeIntent   takes the first value: now
 │   ObserveDrinkLogDayUseCase          ◀── GetCaffeineIntakeIntent   takes the first value
 │   ObserveSleepWindowUseCase          ◀── GetSleepTimeIntent        takes the first value
 │   RespondToInstructionUseCase        ◀── AskHalfLifeIntent         origin: .appIntent
 │
 └──────────────────────────────┬──────────────────────────────────────────────────────────────
                                ▼
 ┌─ Data ── app-scoped repositories and data sources, unchanged
 │
 │   DrinkLogRepository ─────────┬─▶ DrinkLogDataSource (SwiftData) ── signals each change ──▶
 │   CaffeineDecayRepository ────┘     every repository re-reads, and open screens update
 │   CaffeineDecayRepository ──────▶ FileProfileDataSource (bedtime), EstimatedHalfLifeDataSource
 │   CurrentTimeRepository ────────▶ ClockDataSource
 │   LanguageModelRepository ──────▶ FoundationModelLanguageModelDataSource
 │                                     its tools read the repositories above,
 │                                     and its logDrink tool calls LogDrinkUseCase
 └─────────────────────────────────────────────────────────────────────────────────────────────
```

The four kinds of request, end to end:

```
 Log:    "Log a latte in Half-Life" ─▶ LogDrinkIntent ─▶ LogDrinkUseCase ─▶ DrinkLogRepository.log (DrinkLogRule)
           ─▶ DrinkLogDataSource.store ─▶ signal ─▶ each repository re-reads ─▶ IntentDialog: what was logged

 Query:  "How much caffeine is in me in Half-Life?" ─▶ GetCaffeineStatusIntent ─▶ ObserveCaffeineStatusUseCase
           ─▶ the first CaffeineStatus the stream sends ─▶ IntentDialog, and the status as a value

 Sleep:  "When should I go to sleep in Half-Life?" ─▶ GetSleepTimeIntent ─▶ ObserveSleepWindowUseCase
           ─▶ the first SleepWindow ─▶ IntentDialog, and a snippet with the decay graph and the window

 Ask:    "Ask Half-Life" ─▶ Siri asks "What would you like to know?" ─▶ AskHalfLifeIntent
           ├─ Apple Intelligence available ─▶ RespondToInstructionUseCase ─▶ LanguageModelRepository
           │     ─▶ one session, with the read-only tools and logDrink ─▶ the model's answer ─▶ IntentDialog
           └─ unavailable ─▶ continueInForeground: "Open Half-Life?" ─▶ the app opens
```

A failure never reaches the user as a bare error. Each intent throws an ``IntentFailure``, whose message Siri and Shortcuts show: a drink the rule refused, a drink that couldn't be saved, a figure that isn't available, or an answer the model couldn't give.

### Where the intents sit

Constitution Article I.18 covers intents, as amended on 2026-09-12.

- **Intents are Presentation without a reducer.** Like reducers, they depend only on Domain use cases, never on a repository or a data source. `AppIntents` is a presentation framework, like SwiftUI, so importing it doesn't make an intent a data source. Domain never imports it. An intent has no screen and no state that outlives it, so a TCA store would add nothing, and it calls its use case directly.
- **Reads take the first value.** Each `Observe…` use case's stream sends the current value as soon as it's subscribed to (Article I.12). An intent reads that first value with `firstValue()`, the same `AsyncStream` helper the Language Model's tools use, and stops, which ends the subscription. There's no new use case and no new repository operation. The intake intent reads the current time the same way, from ``ObserveTimeOfDayUseCase``, because only the clock data source reads the clock.
- **Writes flow the usual way.** A drink that ``LogDrinkUseCase`` stores reaches the curve, the totals, and the favourites through the drink log data source they share, as it does from the composer.
- **Every intent runs in the app's process.** The system launches the app in the background when it isn't running, so intents reach the same app-scoped repositories as the screens. ``LogDrinkIntent`` also conforms to `LiveActivityIntent`, so a widget's button runs it in the app's process too, not the widget extension's (see "Decisions"). The app stays the only process that writes the drink store. Each intent's `supportedModes` is `.background`, so nothing opens the app. ``AskHalfLifeIntent`` adds `.foreground(.dynamic)`, so it can offer to open the app when Apple Intelligence is unavailable.
- **The app target links AppIntents.framework.** Importing the framework isn't enough. Without the explicit link in the target's Frameworks build phase, the build's metadata processor reported "No AppIntents.framework dependency found" and skipped extraction, so the system would never have seen the intents. With the link, it writes `Metadata.appintents` into the app.

### How an intent reaches its use case

Intents get their use cases from swift-dependencies, through the same `DependencyValues` keys that reducers use (constitution Articles I.15 and I.18). A live intent therefore gets the one app-scoped repository behind each use case. Tests override the use case with `withDependencies` when they create the intent, and the property wrapper keeps those values.

There's one pitfall, found in the iOS 26.5 SDK's `AppIntents.swiftinterface`. `AppIntent` conforms to `_SupportsAppDependencies`, and an extension on that protocol declares `typealias Dependency = AppIntents.AppDependency`. Inside an intent, a bare `@Dependency(\.logDrink)` therefore resolves to Apple's `AppDependency`, not swift-dependencies' property wrapper. Intents write the module name, which resolves through TCA's re-export, with `import ComposableArchitecture` alone:

```swift
struct LogDrinkIntent: AppIntent, LiveActivityIntent {
    static let title: LocalizedStringResource = "Log a Drink"
    static let supportedModes: IntentModes = .background
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresLocalDeviceAuthentication

    @Parameter(title: "Drink") var drink: DrinkTypeAppEnum
    @Parameter(title: "Quantity") var quantity: Int?

    // App Intents' `Dependency` typealias shadows swift-dependencies' inside an intent, so the module is named.
    @Dependencies.Dependency(\.calendar) private var calendar
    @Dependencies.Dependency(\.logDrink) private var logDrink

    init() {}

    /// For the one-tap widget's button.
    init(drink: DrinkTypeAppEnum, quantity: Int) {
        self.drink = drink
        self.quantity = quantity
    }

    func perform() async throws -> some IntentResult & ProvidesDialog { … }
}
```

The rejected alternative is Apple's `AppDependencyManager`, with `@AppDependency`. It's first-party (Article III.2), but it's a second registry with no test or preview values, and it could hold a different repository than the store does.

When the widget target exists, ``LogDrinkIntent`` and ``DrinkTypeAppEnum`` join it, and a `WIDGET_EXTENSION` compilation condition leaves out the dependency and makes `perform()` throw there. It never runs there, because `LiveActivityIntent` sends it to the app (<doc:Widgets>).

### Isolation

Constitution Article IV.1.4 covers this, as the owner revised it on 2026-09-13.

- **Intents, their entities, the shortcuts provider, and ``DrinkTypeAppEnum`` take the target's `nonisolated` default, without writing it.** Written on a type with `@Parameter` or `@Property` properties, `nonisolated` makes the compiler warn "'nonisolated' cannot be applied to mutable stored properties; this is an error in the Swift 6 language mode". The first build hit it on every such property. Their `perform()` awaits `Sendable` use cases and actor repositories, and touches no UI.
- **They're never `@MainActor`.** The SwiftLint rule `app_intent_main_actor` rejects a `@MainActor` struct, enum, or class that conforms to `AppIntent`, `SnippetIntent`, `LiveActivityIntent`, `AppShortcutsProvider`, `AppEnum`, `AppEntity`, or `TransientAppEntity`.
- **The sleep-time snippet's view is `@MainActor`**, like every view, and the `ui_explicit_main_actor` rule covers it. Its initializer is `nonisolated`, so the intent can build it off the main actor. ``SleepWindowChart``'s is too.
- **``IntentDialogFormat`` and ``IntentFailure`` still say `nonisolated`.** They hold only constants, so the keyword compiles cleanly, as it does on Domain types.

## Folder structure

```
Half-Life/AppIntents/
├── HalfLifeShortcuts.swift          AppShortcutsProvider: each shortcut's intent, phrases, title, and symbol
├── DrinkTypeAppEnum.swift           An AppEnum mirror of DrinkType. It joins the widget target when that exists.
├── IntentDialogFormat.swift         Builds each sentence from Domain values. Pure, and unit-tested.
├── IntentFailure.swift              Why an intent failed, with the message Siri shows
├── IntentValues.swift               The transient entities the read intents return (see "Apple Intelligence")
├── LogDrinkIntent.swift             It joins the widget target when that exists.
├── GetCaffeineStatusIntent.swift
├── GetLastCupIntent.swift
├── GetCaffeineIntakeIntent.swift
├── GetSleepTimeIntent.swift
├── SleepTimeSnippetView.swift       The snippet: the Insights card's chart, with previews
└── AskHalfLifeIntent.swift
Half-Life/Features/Insights/SleepWindowChart.swift   The chart the Insights card and the snippet both draw
Half-Life/AppShortcuts.xcstrings     The App Shortcut phrases (constitution Article VII.1.3)
```

## Intents

The phrases are English. Every phrase includes the app's name, `\(.applicationName)`, which App Shortcuts require.

| Intent | Phrases | Parameters | Use case | Answer |
|--------|---------|------------|----------|--------|
| ``LogDrinkIntent`` | "Log \(\.$drink) in \(.applicationName)", "Log a \(\.$drink) in \(.applicationName)", "Log a drink in \(.applicationName)" | `drink`, required, so Siri asks for it when the phrase doesn't name one. `quantity`, optional, defaulting to the drink's `defaultQuantity`. | ``LogDrinkUseCase``, consumed now (`secondsAgo` 0) | Basic: "Logged Latte, 2 shots: about 125 mg." A drink ``DrinkLogRule`` refuses fails with the reason. |
| ``GetCaffeineStatusIntent`` | "How much caffeine is in me in \(.applicationName)", "What's my caffeine level in \(.applicationName)" | None | ``ObserveCaffeineStatusUseCase`` | "About 85 mg in your system now. Down to about 34 mg by 10:30 PM." With no intake still counting, "Nothing in your system right now.", as the decay card says. |
| ``GetLastCupIntent`` | "When's my last cup in \(.applicationName)", "When should I stop drinking coffee in \(.applicationName)" | None | ``ObserveCaffeineCutoffUseCase`` | "Have your usual Latte, 2 shots, by 2:30 PM to be at 40 mg or less by your 10:30 PM bedtime." Or that there's no more today. |
| ``GetCaffeineIntakeIntent`` | "How much caffeine have I had in \(.applicationName)", "What did I drink today in \(.applicationName)" | `day`, optional, defaulting to today. Siri and Shortcuts can set it to any day. | ``ObserveTimeOfDayUseCase`` for now, then ``ObserveDrinkLogDayUseCase`` | "Today you've logged about 188 mg: Latte (2 shots) at 8:10 AM and Espresso (1 shot) at 1:05 PM, from the demo data." Yesterday and earlier days are named. |
| ``GetSleepTimeIntent`` | "When should I go to sleep in \(.applicationName)", "When can I sleep in \(.applicationName)" | None | ``ObserveSleepWindowUseCase`` | "Your best time to fall asleep is 11:10 PM to 12:40 AM. Caffeine should drop under 40 mg at about 11:10 PM, after your 10:30 PM bedtime." Plus a snippet with the decay graph (<doc:Insights>). |
| ``AskHalfLifeIntent`` | "Ask \(.applicationName) a question", "Ask \(.applicationName)" | `question`, a `String`, which Siri asks for: "What would you like to know?" | ``RespondToInstructionUseCase``, with a ``LanguageModelInstruction`` whose origin is `appIntent` | The model's answer, shown as it is. Its session gets the read-only tools and `logDrink`, so "I just had a cold brew" logs one (<doc:LanguageModel>). When Apple Intelligence is unavailable, it offers to open the app. |

- **Any question about intake has an answer.** The owner asked that the user can ask Half-Life anything about their intake. The structured intents answer the common questions, even without Apple Intelligence: the level now and at bedtime, the last cup, any day's drinks and total, and when to sleep. Ask Half-Life answers the rest in the user's own words. Without Apple Intelligence, it offers to open the app, where every figure is on screen.
- **The sleep time is the one answer with a graph.** ``GetSleepTimeIntent`` returns a result snippet, ``SleepTimeSnippetView``, with the decay curve from 6pm, the sleep threshold, and the window shaded. That's the Insights card's chart, ``SleepWindowChart``, split out of ``SleepWindowView`` so both can draw it. Every other intent replies in words only. Siri may not show a snippet at all, for example on AirPods or through Apple Intelligence, so the dialog says everything the graph does.
- **The drink catalog is an `AppEnum`.** ``DrinkTypeAppEnum`` has one case per ``DrinkType``, with the same raw values, and maps both ways with exhaustive switches, so a drink that isn't mirrored fails to compile. It's a mirror rather than `extension DrinkType: AppEnum`, for the same reason `GeneratedDrinkType` is one: the Domain type stays free of framework conformances. Its display names are the composer's names, under the same keys in `Localizable.xcstrings`.
- **Onboarding teaches the phrases.** There's no permission to ask for: App Shortcuts work as soon as the app is installed. So onboarding's "Use Siri and Shortcuts" step shows four phrases to try, and the button to Half-Life's shortcuts in the Shortcuts app (<doc:Onboarding>).
- **The Action Button is one press.** In the Shortcuts app, the user sets up "Log a Drink" with a drink chosen, and assigns it to the Action Button. One press logs it without opening the app, which matches the brief's one-tap logging.
- **Widgets build it too.** ``LogDrinkIntent`` has an `init(drink:quantity:)` beside the `init()` App Intents requires, so the one-tap widget can show `Button(intent: LogDrinkIntent(drink: …, quantity: …))`. The small widget always logs the user's top favourite, and has no configuration, so no widget uses ``DrinkTypeAppEnum`` except through this initializer (<doc:Widgets>).
- **Nothing is deleted outside the app.** No intent deletes a drink. Deleting stays in the app, where the history card asks the user to confirm.
- **Answers are honest.** The dialogs say "about", as the screens do, and give amounts in whole milligrams. The model phrases only what its tools report, and says when something isn't available.

## Apple Intelligence

The owner asked that the intents work with Apple Intelligence, not only with Siri's older phrase matching.

- **Siri reaches every intent through App Shortcuts,** with or without Apple Intelligence. The shortcuts need no setup. Each intent's title, description, and parameters are written for the system to match, and localized.
- **No app schema fits, so none is adopted.** Apple Intelligence understands an app's intents best when they adopt a schema from one of Apple's app schema domains, with `@AppIntent(schema:)`. None of the 23 domains Apple lists on 2026-09-12 covers health, fitness, food, or logging. The nearest, Assistant, only launches a conversational app from the side button, in Japan. Adopting a schema that doesn't match the domain's purpose is what Apple's guidance says not to do. If Apple adds a fitting domain, the intents adopt it then.
- **The read intents return values, not just words.** Each also returns its answer as a transient entity, through `ReturnsValue`: ``CaffeineStatusEntity``, ``CaffeineCutoffEntity``, ``CaffeineIntakeEntity``, and ``SleepTimeEntity``, each with plain properties such as whole milligrams and times. A shortcut can pass the value on, including to Shortcuts' Apple Intelligence actions, so the user can build on Half-Life's figures without the app parsing its own sentences. The values live only as long as the shortcut that asked for them.
- **Ask Half-Life is the app's own Apple Intelligence.** It answers with the on-device Foundation Models model, through the Language Model layer (<doc:LanguageModel>). When the model is unavailable, `perform()` calls `continueInForeground(_:alwaysConfirm:)`. Siri asks whether to open Half-Life, and if the user agrees, the app opens. The owner chose this over a reply that only says Apple Intelligence is unavailable.
- **Drinks aren't indexed in Spotlight.** Apple suggests indexing an app's entities in Spotlight's semantic index (`IndexedEntity`), so Apple Intelligence can find its content. For Half-Life, that would put each logged drink, with its time and caffeine, in a system-wide index. The owner decided on 2026-09-13 not to index them (Article V.2). The intents already answer any question about a day's drinks.
- **Siri doesn't read the Today screen yet.** On-screen awareness would let the user ask "how much of this is left at bedtime?" while looking at the Today screen. It needs an entity for what's on screen, and view annotations. The owner decided on 2026-09-13 not to add it yet. The status intent already answers the question.

## Localization

- **Dialogs, titles, descriptions, and parameter names** are `LocalizedStringResource`s in `Localizable.xcstrings`, each with a comment for translators. Each formatted value is interpolated into one whole sentence (constitution Article VII.2). Amounts and times are formatted with locale-aware APIs, in the calendar the intent runs in (VII.3). ``IntentDialogFormat`` builds them in Presentation. It can't reuse the Language Model's `LanguageModelFormat`, which is in Data.
- **App Shortcut phrases** live in `AppShortcuts.xcstrings`, the catalog App Intents reads them from, and every shipped localization translates them (Article VII.1.3). Xcode fills the catalog from ``HalfLifeShortcuts`` when it syncs the String Catalogs. Each shortcut's phrases are one entry, a set of values.
- **The model's answer** is in the user's language, as the Language Model article describes, so it's shown as it is, not looked up.

## Privacy and logging

- **Nothing leaves the device through Half-Life.** The intents run on the device, and the app makes no network request (constitution Article V.1). What the user says to Siri, and what Siri says back, are handled by Siri under Apple's own privacy terms.
- **Every intent needs the phone unlocked.** Each intent's `authenticationPolicy` is `requiresLocalDeviceAuthentication`, which Apple describes as requiring "the person to unlock the device running the intent". Every answer is health data, and anyone holding a locked phone could otherwise hear it or log drinks. It also means the profile, which is `NSFileProtectionComplete`, can always be read when an intent runs (<doc:Onboarding>). `requiresAuthentication` was rejected because the owner asked specifically for the phone to be unlocked.
- **Nothing an intent receives or says is logged.** Drinks, amounts, days, questions, and answers are health data (Article XI.6). A successful intent is a routine health event, so it isn't logged (XI.7). ``LogDrinkIntent`` and ``AskHalfLifeIntent`` log a failure at `error`, with the error's domain and code as `.public` and its description as `.private` (XI.6.4). Intents are Presentation, so they log through `Logger(for:)` like reducers (XI.3).
- **Donations aren't limited.** The system records the intents a user runs so that it can suggest them later. A donated "Log a Drink" carries the drink. The owner decided on 2026-09-12 not to limit donations: a drink is health data, but the owner judged it not sensitive enough to hold back from the system's own suggestions.
- **No Siri entitlement or Siri purpose string.** Apple's entitlement documentation says the App Store requires `com.apple.developer.siri` "for iOS or watchOS apps containing Intents app extensions that handle any Siri requests other than shortcut requests". `NSSiriUsageDescription` is for apps that "send user data to Siri" through SiriKit. Half-Life has no Intents extension, and App Intents need neither, so both were removed on 2026-09-12 (Article V.2).

## Testing

Constitution Article I.20 covers this.

- **Unit tests, in Swift Testing.** Each intent is a plain struct. A test creates it inside `withDependencies`, with its use case built on in-memory fake repositories, never live ones, sets its parameters, and calls `perform()`. Each fake publishes only for New York's time zone, so an intent that answers has used the calendar it was given. `perform()` returns an opaque `IntentResult`, so its dialog and value can't be read back. ``IntentDialogFormat`` and the entities' initializers are tested directly instead, in the `en_US` locale and New York's time zone, and `perform()` stays thin enough that the tests cover it.
- **Ask Half-Life's fallback** is tested through ``AskHalfLifeIntent/answer(_:respondToInstruction:format:openApp:)``, with a stand-in for opening the app.
- **The snippet has no robot.** It appears in Siri, outside the app that UI tests launch. It has SwiftUI previews at the default and the largest accessibility text size, and needs an Accessibility Inspector check before release, recorded here. VoiceOver reads the chart as one element, with the window's summary as its value, as the Insights card does.
- **No AppIntentsTesting.** Apple's AppIntentsTesting framework runs intents out of process, the way Siri does. It starts in iOS 27, and the app targets iOS 26.5.

## Testable requirements

### DrinkTypeAppEnum

| ID | Requirement |
|----|-------------|
| INTENT-ENUM-1 | There's one case per ``DrinkType``, with its raw value, which maps back to the same drink, and no other case. |
| INTENT-ENUM-2 | Each case shows the composer's name for its drink. |

### IntentDialogFormat and IntentFailure

Tested in New York's time zone and the `en_US` locale.

| ID | Requirement |
|----|-------------|
| INTENT-FORMAT-1 | A logged drink gives its name, quantity, and caffeine: "Logged Latte, 2 shots: about 125 mg." |
| INTENT-FORMAT-2 | The status gives the level now and at bedtime. Without a bedtime, it gives the level now. With no intake still counting, it's "Nothing in your system right now." |
| INTENT-FORMAT-3 | The cutoff gives the usual drink, the latest time, the threshold, and the bedtime. With no latest time, it says there's no more caffeine today. |
| INTENT-FORMAT-4 | A day gives its total and each drink with its time, marked when it's demo data, and calls the day "today", "yesterday", or its name. A day with no drinks says so. |
| INTENT-FORMAT-5 | The sleep window gives its times, and whether caffeine clears by the bedtime or after it. With no window, it says caffeine stays over the threshold until after noon. |
| INTENT-FORMAT-6 | Amounts are whole milligrams, and times are clock times in the calendar's time zone. |
| INTENT-FAIL-1 | Each ``IntentFailure`` says what went wrong. |

### Returned values

| ID | Requirement |
|----|-------------|
| INTENT-VALUE-1 | ``CaffeineStatusEntity`` has the level now and at bedtime, in whole milligrams, and the bedtime. |
| INTENT-VALUE-2 | ``CaffeineCutoffEntity`` has the usual drink and quantity, the latest cup, the bedtime, and the threshold. |
| INTENT-VALUE-3 | ``CaffeineIntakeEntity`` has the day, its total in whole milligrams, and the number of drinks. |
| INTENT-VALUE-4 | ``SleepTimeEntity`` has the window's start and end, when caffeine clears, and the bedtime. |

### Intents

Tested with the use cases built on fakes.

| ID | Requirement |
|----|-------------|
| INTENT-LOG-1 | ``LogDrinkIntent`` logs the drink and quantity it's given, consumed now. |
| INTENT-LOG-2 | Without a quantity, it logs the drink's default quantity. |
| INTENT-LOG-3 | A drink ``DrinkLogRule`` refuses fails with ``IntentFailure/notLogged(_:)`` and the reason. |
| INTENT-LOG-4 | Any other error fails with ``IntentFailure/saveFailed``. |
| INTENT-QUERY-1 | ``GetCaffeineStatusIntent`` answers from the first status published in its calendar, and fails with ``IntentFailure/unavailable`` without one. |
| INTENT-QUERY-2 | ``GetLastCupIntent`` answers from the first cutoff, and fails without one. |
| INTENT-QUERY-3 | ``GetCaffeineIntakeIntent`` answers for today without a day, for the day it's given otherwise, and fails when the day isn't published. |
| INTENT-QUERY-4 | ``GetSleepTimeIntent`` answers from the first window, and fails without one. |
| INTENT-QUERY-5 | Every intent runs in the background, and only ``AskHalfLifeIntent`` can bring the app forward. |
| INTENT-AUTH-1 | Every intent requires the device to be unlocked. |
| INTENT-ASK-1 | ``AskHalfLifeIntent`` sends the question to the model as an App Intent instruction in the user's words, and answers with the model's response. |
| INTENT-ASK-2 | When the model is unavailable, it asks to open the app, and says it's opening Half-Life. |
| INTENT-ASK-3 | Any other error fails with ``IntentFailure/couldntAnswer``, and doesn't open the app. |
| INTENT-SHORTCUTS-1 | ``HalfLifeShortcuts`` has one App Shortcut per intent. |

### Snippet

| ID | Requirement |
|----|-------------|
| INTENT-A11Y-1 | Before release, ``SleepTimeSnippetView`` is checked with Accessibility Inspector, at the default and the largest text size, and the result is recorded here. **Not yet done.** |

## Out of scope

- **SiriKit's older `INIntent`s.** App Intents replace them.
- **Texting a phone number.** It would need a server and an SMS provider (Article V.1).
- **Deleting outside the app.** The owner decided on 2026-09-12 that drinks are deleted only in the app.
- **Widgets and controls** are designed in <doc:Widgets>. They run ``LogDrinkIntent``.

## Decisions

The owner decided these on 2026-09-12 and 2026-09-13. The widget's process was decided at 23:31 on 2026-09-12, as relayed by session half-life-3c. Most of the rest were decided at 23:40, and deleting at about 23:42. Spotlight and on-screen awareness were decided on 2026-09-13 at 00:04, and isolation at about 09:31.

| Question | Decision |
|----------|----------|
| The widget's process | ``LogDrinkIntent`` runs in the app's process, even from a widget. It adopts `LiveActivityIntent`, keeps `supportedModes` at `.background`, and joins the widget extension when that exists. Apple's "Adding interactivity to widgets and Live Activities" says a widget performs its intent in the extension's process, unless the intent conforms to `LiveActivityIntent` or one of a few other protocols. Whether `LiveActivityIntent` needs `NSSupportsLiveActivities` is a spike in <doc:Widgets>. |
| Intents in the constitution | Amended: Article I.18 makes App Intents and widgets presentation without a reducer, and I.20 tests Siri snippets like widgets. |
| App Shortcut phrases | Amended: Article VII.1.3 adds `AppShortcuts.xcstrings`. |
| The locked device | Every intent requires the phone to be unlocked: `requiresLocalDeviceAuthentication`. |
| Ask Half-Life without Apple Intelligence | It offers to open the app, with `continueInForeground`. |
| Questions about intake | The user can ask anything about their intake. ``GetCaffeineIntakeIntent`` answers for any day, and Ask Half-Life answers the rest. |
| The log's answer | Basic: the drink, its quantity, and its caffeine. |
| Snippets | Only the sleep-time answer shows one, with the decay graph. Everything else is spoken or written. |
| The Siri entitlement | Removed, with `NSSiriUsageDescription`. |
| Isolation and enforcement | Intents, their entities, the shortcuts provider, and `AppEnum`s take the target's `nonisolated` default, and a SwiftLint rule rejects `@MainActor` on them (Article IV.1.4, revised 2026-09-13). The first design wrote `nonisolated`, which the compiler warns about on types with `@Parameter` or `@Property` properties. |
| Donations | Not limited. |
| Deleting | Only in the app. |
| Spotlight's semantic index | Logged drinks aren't indexed. |
| On-screen awareness | Not yet: Siri doesn't read the Today screen. |

## Apple documentation

The framework:

- [App Intents](https://developer.apple.com/documentation/appintents)
- [Getting started with the App Intents framework](https://developer.apple.com/documentation/appintents/getting-started-with-the-app-intents-framework)
- [Creating your first app intent](https://developer.apple.com/documentation/appintents/creating-your-first-app-intent)
- [Adding parameters to an app intent](https://developer.apple.com/documentation/appintents/adding-parameters-to-an-app-intent)
- [Configuring the runtime behavior of your app intents](https://developer.apple.com/documentation/appintents/configuring-the-runtime-behavior-of-your-app-intents): `supportedModes`, foreground and background.

Types this design uses:

- [`AppIntent`](https://developer.apple.com/documentation/appintents/appintent), [`IntentParameter`](https://developer.apple.com/documentation/appintents/intentparameter), [`IntentModes`](https://developer.apple.com/documentation/appintents/intentmodes)
- [`IntentAuthenticationPolicy`](https://developer.apple.com/documentation/appintents/intentauthenticationpolicy): running while the device is locked.
- [`IntentResult`](https://developer.apple.com/documentation/appintents/intentresult), [`ProvidesDialog`](https://developer.apple.com/documentation/appintents/providesdialog), [`IntentDialog`](https://developer.apple.com/documentation/appintents/intentdialog), [`ReturnsValue`](https://developer.apple.com/documentation/appintents/returnsvalue)
- [`AppEnum`](https://developer.apple.com/documentation/appintents/appenum): a parameter with a fixed set of values.
- [`AppDependencyManager`](https://developer.apple.com/documentation/appintents/appdependencymanager) and [`AppDependency`](https://developer.apple.com/documentation/appintents/appdependency): Apple's dependency registry, rejected in favour of swift-dependencies.

Siri, Shortcuts, and the Action Button:

- [App Shortcuts](https://developer.apple.com/documentation/appintents/app-shortcuts), [`AppShortcutsProvider`](https://developer.apple.com/documentation/appintents/appshortcutsprovider), [`AppShortcut`](https://developer.apple.com/documentation/appintents/appshortcut), [`AppShortcutPhrase`](https://developer.apple.com/documentation/appintents/appshortcutphrase)
- [`SiriTipView`](https://developer.apple.com/documentation/appintents/siritipview) and [`ShortcutsLink`](https://developer.apple.com/documentation/appintents/shortcutslink): in-app hints, not part of this design.
- [Hardware interactions](https://developer.apple.com/documentation/appintents/hardware-interactions): the Action Button.
- [Donating your app's data and actions to the system](https://developer.apple.com/documentation/appintents/donating-your-apps-data-and-actions-to-the-system)
- [Siri entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.siri) and [`NSSiriUsageDescription`](https://developer.apple.com/documentation/bundleresources/information-property-list/nssiriusagedescription): SiriKit's, not needed for App Intents.

Apple Intelligence:

- [Apple Intelligence and Siri AI](https://developer.apple.com/documentation/appintents/apple-intelligence-and-siri-ai)
- [Making actions and content discoverable by Apple Intelligence](https://developer.apple.com/documentation/appintents/making-actions-and-content-discoverable-by-apple-intelligence)
- [App schema domains](https://developer.apple.com/documentation/appintents/app-schema-domains), and the [Assistant domain](https://developer.apple.com/documentation/appintents/app-schema-domain-assistant)
- [`TransientAppEntity`](https://developer.apple.com/documentation/appintents/transientappentity) and [`IndexedEntity`](https://developer.apple.com/documentation/appintents/indexedentity)
- [Foundation Models](https://developer.apple.com/documentation/foundationmodels), and <doc:LanguageModel> for how Half-Life uses it.

Snippets:

- [Displaying static and interactive snippets](https://developer.apple.com/documentation/appintents/displaying-static-and-interactive-snippets), [`ShowsSnippetView`](https://developer.apple.com/documentation/appintents/showssnippetview), [`SnippetIntent`](https://developer.apple.com/documentation/appintents/snippetintent)

Widgets:

- [Adding interactivity to widgets and Live Activities](https://developer.apple.com/documentation/widgetkit/adding-interactivity-to-widgets-and-live-activities): which process performs a widget's intent.
- [`LiveActivityIntent`](https://developer.apple.com/documentation/appintents/liveactivityintent)

Testing:

- [Verifying your App Intents implementation](https://developer.apple.com/documentation/appintents/verifying-your-app-intents-implementation)
- [AppIntentsTesting](https://developer.apple.com/documentation/appintentstesting): iOS 27 and later, so not yet usable here.

Videos:

- [Get to know App Intents](https://developer.apple.com/videos/play/wwdc2025/244/), WWDC25
- [Explore new advances in App Intents](https://developer.apple.com/videos/play/wwdc2025/275/), WWDC25: interactive snippets and `supportedModes`.
