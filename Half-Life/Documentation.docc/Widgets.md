# Widgets

Two Home Screen widgets: "One tap" logs a favourite drink without opening the app, and "In your system" shows the caffeine in your system now, with its curve.

## Overview

**Status: built, and working on a device.** On 2026-09-13 the owner reported that One tap's buttons didn't add drinks to the log. That was on the simulator, where widget intents don't run reliably (failure point C in "How the widgets behave"). On a physical device the same day, the owner confirmed that One tap logs drinks. The rest of the device checks, and the Accessibility Inspector check, are still open. On 2026-09-12 the owner asked for the widgets to be designed alongside App Intents (<doc:AppIntents>), so the two designs agree. On 2026-09-13 the owner asked for them to be built, once the intents were. The widgets are roadmap rank 25, "Widgets / Action Button", scored at 5 effort points. This work doesn't change the roadmap's order.

Each widget comes in small and medium sizes, on the Home Screen:

- **One tap** logs a favourite drink with one tap, through ``LogDrinkIntent``. The small widget logs the top favourite. The medium widget shows all three favourites, like the Today screen's row (<doc:OneTapLog>).
- **In your system** shows the level now and the decay curve, like the Today screen's decay card (<doc:TodayScreen>). A tap opens the app.

The widgets show only what the app has stored for them. They never write anything themselves, and every drink they log is logged in the app's own process.

## Decisions

The owner decided these on 2026-09-12:

| Question | Decision | Rejected |
|----------|----------|----------|
| What the widgets are | One tap, whose buttons run ``LogDrinkIntent`` for a drink, and In your system, the decay chart, which opens the app | — (the owner's brief for this design) |
| Where a widget's log runs | In the app's process. ``LogDrinkIntent`` adopts `LiveActivityIntent`, so the system launches the app in the background, without opening it, and performs the intent there. The widgets only read a snapshot the app stores. | In the widget extension, Apple's default. That makes the extension a second process that writes the drink store. It would need the store moved to an App Group, change signals between the two processes, and `Profile.json` and `HalfLifeEstimate.json` readable while the phone is locked. CloudKit wouldn't sync the drink until the app next ran. |
| Where the widgets appear | The Home Screen, in small and medium sizes | Lock Screen accessory widgets, and a Control Center control that the Action Button can run |
| How the constitution covers widgets | Amended with Article I.18–20: a widget is presentation without a reducer, and it's tested without robots. The App Intents session then widened I.18 and I.20 to cover App Intents too, at the owner's request. | Keeping the robot pattern, with UI tests that drive the Home Screen to add each widget and audit it |
| What the small One tap widget logs | Always the top favourite, with no configuration | A drink and quantity the user picks in Edit Widget |

The AI chose these, still to be confirmed:

- **The widgets' names in the gallery**, "One tap" and "In your system", after the Today screen's headings.
- **The timeline.** In your system's timeline has an entry every 5 minutes and lasts 12 hours. Each entry's curve spans the 6 hours before it and the 6 hours after.
- **"Latest drink 3:04 PM".** After a log, One tap shows when the latest drink was consumed. The design said "Last cup 3:04 PM", but in the app "Last cup" is the tile for the cutoff, the latest time to drink, so the widget would have said something different under the same words. There's no 2-second "Logged" state like the app's, because a timeline can't time one reliably.
- **Setup.** Until onboarding is complete, both widgets say "Finish setting up Half-Life", and a tap opens the app.
- **The gallery** shows sample data, the starters and a made-up curve, not the user's own.
- **The drink names and symbols** stay in `DrinkPresentation.swift`, which the widget target shares with `DrinkComposerViewAccessibilityID.swift`. The design moved them to a file of their own. Sharing the composer's identifier file too left the composer's files unchanged.
- **The forecast's limits.** It starts 12 hours before the current 5-minute mark, runs at least 24 hours, and never more than 7 days past the current mark. The cap only matters for a half-life far beyond any the survey or the estimator gives.

## Where a widget's log runs

Apple's [Adding interactivity to widgets and Live Activities](https://developer.apple.com/documentation/widgetkit/adding-interactivity-to-widgets-and-live-activities) says: "By default, the system runs the app intent in the same process as the widget extension. However, if the app intent's `openAppWhenRun` property is `true`, or if the intent conforms to `AudioPlaybackIntent`, `ForegroundContinuableIntent`, `LiveActivityIntent`, or `PushToTalkTransmissionIntent`, the system performs the app intent in the app's process."

- **`openAppWhenRun`** opens the app, so logging would take more than one tap. It's also deprecated in iOS 26's SDK (<doc:AppIntents>).
- **`ForegroundContinuableIntent`** is deprecated in favour of `supportedModes`, so it would leave a compiler warning (Article IX.2).
- **`AudioPlaybackIntent` and `PushToTalkTransmissionIntent`** are for audio.
- **[`LiveActivityIntent`](https://developer.apple.com/documentation/appintents/liveactivityintent):** "When the system performs the intent, the system launches your app process without opening the app, performs the intent, and starts the Live Activity."

So ``LogDrinkIntent`` adopts `LiveActivityIntent`, alongside its `supportedModes` of `.background`. The protocol exists for Live Activities. Half-Life adopts it only because of where the intent runs, and starts no Live Activity. The spike checks what that costs.

One process gives the design these benefits:

- **One writer.** Only the app's ``DrinkLogRepository`` writes the drink store. No second repository opens it, and no change has to be signalled between processes. The store stays where it is, outside any App Group.
- **Immediate sync, when sync returns.** The drink log's CloudKit sync is deferred (<doc:DrinkComposer>). Once it's back, CloudKit will export the drink right away, from the app's own store. By reports, a write from a widget extension doesn't sync until the app next runs.
- **Protection unchanged.** The extension never reads `Profile.json` or `HalfLifeEstimate.json`, so both keep `NSFileProtectionComplete`.
- **One path.** Siri, Shortcuts, and a widget's buttons all run the same intent, in the same process.

It also has costs:

- **A background launch.** When the app isn't running, each tap launches it in the background, which is slower than writing from the extension. `invalidatableContent()` dims the "Latest drink" line until the widget reloads.
- **A second compilation.** The intent's file compiles into the widget target too, because `Button(intent:)` needs its type. There, it has to build without the app's dependencies (see "LogDrinkIntent in the widget target").

### LogDrinkIntent in the widget target

Only `LogDrinkIntent.swift` and `DrinkTypeAppEnum.swift` join the widget target. ``HalfLifeShortcuts``, the App Shortcuts provider, stays in the app, so the extension doesn't declare App Shortcuts too.

The widget target defines the compilation condition `WIDGET_EXTENSION`. Under it, the intent imports neither ComposableArchitecture nor OSLog, and declares no dependency properties and no logger. Its `perform()` throws `OnlyTheAppLogsDrinks` rather than logging. The system never performs the intent in the extension, but if it ever did, a silent no-op would lose the drink. The throw sits behind a `logsInThisProcess` property that's always `false`, because a function with an opaque result type needs a `return` to infer the type from. The intent's parameters and its `init(drink:quantity:)` are the same in both targets.

## Architecture

```
 Log:      One tap button ─▶ LogDrinkIntent (app process) ─▶ LogDrinkUseCase ─▶ DrinkLogRepository ─▶ DrinkLogDataSource
 Publish:  Drink log, profile, or half-life change ─▶ WidgetSnapshotRepository (WidgetSnapshotRule)
             ─▶ WidgetSnapshotDataSource: store WidgetSnapshot.json ─▶ WidgetReloadDataSource: reload the widgets
 Render:   WidgetKit ─▶ HalfLifeTimelineProvider (extension) ─▶ ObserveWidgetTimelineUseCase
             ─▶ WidgetTimelineRepository (WidgetTimelineRule) ─▶ WidgetSnapshotDataSource: read ─▶ entries ─▶ views
```

### Domain

#### WidgetSnapshot

Everything the widgets show, as the app last calculated it. ``WidgetSnapshot`` is a plain `Sendable`, `Equatable` value (constitution Article I.10). The data source stores it in a format of its own.

| Property | Type | Meaning |
|----------|------|---------|
| `forecast` | `[CaffeineLevel]` | The level every 5 minutes, from 12 hours before the current 5-minute mark until no intake still counts. It always runs at least 12 hours past that mark. |
| `bedtime` | ``Bedtime`` | The bedtime, so each entry can find the next one |
| `favourites` | `[FavouriteDrink]` | The three one-tap favourites, most logged first |
| `latestDrinkAt` | `Date?` | When the latest drink was consumed, or `nil` if none has been logged |
| `isOnboardingComplete` | `Bool` | Whether the widgets show their content or the setup message |
| `writtenAt` | `Date` | When the app calculated it |

The forecast runs until the caffeine is gone, not across the in-app curve's fixed 12-hour window. Every new drink is logged in the app, which stores a new snapshot. So while nothing new is logged, the forecast stays right however long the app goes without running, and the widget never runs out of curve. At the default constants, a 200 mg drink stops counting in under 2 days (<doc:CaffeineDecayModel>). That's under 600 samples at 5-minute spacing.

#### WidgetSnapshotRule

``WidgetSnapshotRule`` calculates the snapshot:

- **The forecast.** It asks ``CaffeineDecayRule`` for the level at each whole 5-minute mark from 12 hours before the current mark. It stops at the first mark, at least 24 hours after the forecast's start, at which no intake still counts, and never later than 7 days after the current mark.
- **The favourites** come from ``FavouriteDrinksRule``.
- **The profile.** It takes the ``UserProfile``, for the bedtime and whether onboarding is complete. With no profile saved, the bedtime is the standard one and onboarding isn't complete.

Like the other rules, it holds no state and reads no clock.

#### WidgetTimeline and WidgetTimelineRule

``WidgetTimelineRule`` turns a snapshot, a start time, and a calendar into a ``WidgetTimeline``. The timeline has an entry at the start time, then one every 5 minutes for 12 hours, and asks WidgetKit for a new timeline at its end. Each ``WidgetTimelineEntry`` has a date and a ``WidgetContent``:

| Property | Meaning |
|----------|---------|
| `level` | The forecast's sample at or before the entry's date, or 0 after the forecast's last sample |
| `curve` | The forecast's samples from 6 hours before the entry's date to 6 hours after, with 0 at each 5-minute mark after the forecast ends |
| `levelAtBedtime` | The forecast's level at the next bedtime at or after the entry's date, from `Bedtime.next(atOrAfter:in:)` |
| `favourites`, `latestDrinkAt` | Copied from the snapshot |

With no snapshot, or until onboarding is complete, the timeline is a single entry with no content: the setup entry. Presentation only reads levels by date. It never evaluates the decay function (VIEW-1 in <doc:CaffeineDecayModel>).

### Repositories

**``WidgetSnapshotRepository``**, in the app, is implemented by ``LiveWidgetSnapshotRepository``. It's an actor, created once for the app (constitution Articles I.11–13).

- **Shared data sources.** It reads ``DrinkLogDataSource``, ``FileProfileDataSource`` as ``UserProfileDataSource``, ``EstimatedHalfLifeDataSource`` as ``HalfLifeDataSource``, ``AbsorptionRateDataSource``, and ``ClockDataSource``. The first three are shared with the repositories that read them too. It listens to the drink log's, the profile's, and the half-life's changes once, for every subscriber, following the shared-data-source pattern (<doc:Architecture>).
- **It recalculates after each change.** It stores the new snapshot, then asks for the widgets to be reloaded, in that order, and then publishes the snapshot on its `AsyncStream` (Article I.12).
- **One hook.** Changes to the data trigger it, not the intents, as the App Intents session suggested. So the composer, one tap, Siri, delete, demo data, Settings' bedtime and factors, and the estimate's refresh all update the widgets the same way.
- **A failure keeps the last snapshot.** A failed read or store publishes nothing and reloads nothing. A failed read is logged with its domain and code. A failed store is logged by the data source. The next change recovers.
- **It starts at launch.** `Half_LifeApp.init` sends ``AppFeature``'s `launched` action. Its effect runs ``KeepWidgetsCurrentUseCase`` for as long as the app runs, and that subscription keeps the repository listening. It starts from the app's `init`, not from a view, because the system can launch the app in the background, with no scene, to perform ``LogDrinkIntent`` (WSPIKE-3).

**``WidgetTimelineRepository``**, in the extension, is implemented by ``LiveWidgetTimelineRepository``. It reads the snapshot through ``WidgetSnapshotDataSource`` and executes ``WidgetTimelineRule``. Its stream publishes one timeline, calculated for the current time, and then finishes, because the extension's repositories live for one timeline (Article I.19). If no snapshot has been stored yet, or the read fails, it publishes the setup timeline. A failed read is logged.

### Data sources

| Data source | Wraps |
|-------------|-------|
| ``FileWidgetSnapshotDataSource``, implementing ``WidgetSnapshotDataSource`` | `WidgetSnapshot.json` in the App Group container `group.com.quillanq.Half-Life`, written atomically with `NSFileProtectionCompleteUntilFirstUserAuthentication` and left out of iCloud backups. The app writes it, and the extension only reads it. With no file, a read returns `nil`. |
| ``WidgetKitReloadDataSource``, implementing ``WidgetReloadDataSource`` | `WidgetCenter.shared.reloadAllTimelines()`. Only the app uses it, and it's the app's only WidgetKit code (Article I.14). |

`WidgetSnapshotDataSourceKey` chooses the app's file:

- **Normally**, it's the App Group file.
- **Under a UI test**, it's a temporary file, so UI tests never change what the simulator's widgets show.
- **Without the App Group container**, which happens only without the entitlement, it's a temporary file too, and the failure is logged.

The previews use a temporary file.

### Use cases

| Use case | Operation | Repository | Used by |
|----------|-----------|------------|---------|
| ``KeepWidgetsCurrentUseCase`` | Keeps the widget snapshot current for as long as it runs | ``WidgetSnapshotRepository`` | ``AppFeature`` |
| ``ObserveWidgetTimelineUseCase`` | Streams the widgets' timeline, in a given calendar | ``WidgetTimelineRepository`` | The widgets' timeline provider |

### The widget extension

- **Target.** `Half-LifeWidgets`, with the bundle identifier `com.quillanq.Half-Life.Widgets` and the folder `Half-LifeWidgets/`. The app embeds it, and both get the App Group entitlement. Its `Info.plist` declares the WidgetKit extension point.
- **Display name.** iOS won't install the app unless the extension's `Info.plist` has a `CFBundleDisplayName` ("Missing Info.plist value", seen 2026-09-13). The extension's build settings declare it with the placeholder `Localized in InfoPlist.xcstrings`, like the app's. The text, "Half-Life", is a manual entry in `Half-LifeWidgets/InfoPlist.xcstrings`, the extension's own catalog, so its purpose strings stay out of the extension (Article VII.1).
- **Bundle.** `HalfLifeWidgets`, the `WidgetBundle`, holds `OneTapWidget` and `CaffeineLevelWidget`. Each is a `StaticConfiguration` over `HalfLifeTimelineProvider`, which takes the first timeline ``ObserveWidgetTimelineUseCase`` publishes for each timeline WidgetKit asks for (Article I.18).
- **Isolation.** The widgets, the bundle, and their views are `@MainActor`, on the line above each declaration (Article IV.1.1).
- **Composition.** `WidgetCompositionRoot` builds the use case, the repository, and the data sources. The extension links no TCA, SwiftData, HealthKit, or swift-dependencies (Article I.19).
- **Shared files.** The extension compiles these from the app's folder, through a membership exception in the project:
  - the widget types in Domain and their entities, ``CaffeineLevel``, ``FavouriteDrink``, ``DrinkType``, ``ServingUnit``, ``Bedtime``, and ``UseCase``;
  - ``WidgetTimelineRule``, the timeline repository's protocol, and ``LiveWidgetTimelineRepository``;
  - the snapshot data source, and the clock data source;
  - `LogDrinkIntent.swift` and `DrinkTypeAppEnum.swift`;
  - `DrinkPresentation.swift`, for the drink names and symbols, and `DrinkComposerViewAccessibilityID.swift`, which it refers to;
  - `Logger+HalfLife.swift`, the Design System's constants, `Assets.xcassets`, and `Localizable.xcstrings`.
- **Documentation.** `docbuild` builds the extension's documentation too. The shared files' doc comments link to app symbols the extension doesn't have, such as ``LogDrinkUseCase``, which would be warnings there (Article VIII.3). So the extension sets `DOCC_MINIMUM_ACCESS_LEVEL` to `public`: its code is all internal, so its documentation holds no symbols. Its own small catalog, `Half-LifeWidgets/Documentation.docc`, points readers here.
- **Coverage.** The shared files' tests run in the app target, so they count toward coverage. Coverage counts only the app target, so the extension's own code isn't measured: the bundle, the widgets, the provider, the views, and the composition root. That code holds no logic beyond choosing what to show.

## How the widgets behave

These diagrams follow the code as built. The steps marked with a letter are where a tap can fail. The owner's report of drinks that weren't logged turned out to be C, the simulator: on a physical device, taps log drinks.

### A widget draws

WidgetKit asks for a timeline when a widget is added, when a timeline ends, and when anything reloads the widgets. The extension reads only the snapshot the app stored.

```
 WidgetKit (Home Screen)          Widget extension                              App Group container
        │                                │                                              │
    1   │── getTimeline ────────────────▶│ HalfLifeTimelineProvider                     │
        │                                │   ─▶ WidgetCompositionRoot                   │
        │                                │   ─▶ ObserveWidgetTimelineUseCase            │
        │                                │   ─▶ LiveWidgetTimelineRepository            │
    2   │                                │── read ─────────────────────────────────────▶│ WidgetSnapshot.json
        │                                │◀─ snapshot, or none ─────────────────────────│
    3   │                                │ WidgetTimelineRule: an entry every 5 minutes │
        │◀── timeline, reload in 12 h ───│ (no snapshot, or before onboarding: setup)   │
    4   │ draws each entry at its time   │                                              │
```

### A tap on One tap, as designed

``LogDrinkIntent`` is a `LiveActivityIntent`, so Apple documents that the system performs it in the app's process, launching the app in the background, without a scene, if it isn't running. Steps 7 and 8 race: the system's reload can read the snapshot before the app stores the new one.

```
 WidgetKit            App Intents (system)           Half-Life app                            Widget extension
     │                        │                            │                                         │
  1  │── tap: LogDrinkIntent(drink:quantity:) ────────────▶│                                         │
     │                        │                            │                                         │
  2  │                        │ authenticationPolicy:      │                                         │
     │                        │ is the phone unlocked?     │                                         │
  3  │                        │── perform in the app ─────▶│ launch without a scene, if not running  │
     │                        │                            │ Half_LifeApp.init ─▶ AppFeature.launched│
     │                        │                            │   ─▶ KeepWidgetsCurrentUseCase          │
  4  │                        │                            │ LogDrinkIntent.perform()                │
     │                        │                            │   ─▶ LogDrinkUseCase                    │
     │                        │                            │   ─▶ DrinkLogRepository.log             │
     │                        │                            │   ─▶ SwiftData save, then signal        │
  5  │                        │◀── dialog: "Logged …" ─────│                                         │
  6  │◀── reload the widget ──│                            │                                         │
  7  │── getTimeline ─────────────────────────────────────────────────────────────────────────────▶│ reads the snapshot
     │                        │                            │                                         │ (old or new)
  8  │                        │                            │ LiveWidgetSnapshotRepository:           │
     │                        │                            │ calculate, store WidgetSnapshot.json    │
  9  │◀── reloadAllTimelines ──────────────────────────────│                                         │
 10  │── getTimeline ─────────────────────────────────────────────────────────────────────────────▶│ reads the new snapshot
 11  │◀── timeline: "Latest drink 3:04 PM" ─────────────────────────────────────────────────────────│
```

### A tap that loses the drink

If the system performs the intent in the widget extension instead (A), the extension's copy of ``LogDrinkIntent``, compiled under `WIDGET_EXTENSION`, throws `OnlyTheAppLogsDrinks`. Nothing is logged, nothing changes on screen, and nothing is written to the unified log, because the extension's copy has no logger.

```
 WidgetKit            App Intents (system)           Half-Life app                            Widget extension
     │                        │                            │                                         │
  1  │── tap: LogDrinkIntent(drink:quantity:) ────────────▶│                                         │
  3′ │                        │── perform in the extension ─────────────────────────────────────────▶│ perform()
     │                        │                            │                                         │ throws
     │                        │◀── error ────────────────────────────────────────────────────────────│ OnlyTheAppLogsDrinks
  6  │◀── reload the widget ──│                            │                                         │
  7  │── getTimeline ─────────────────────────────────────────────────────────────────────────────▶│ the same snapshot
     │   The widget looks the same. No drink is saved, and the app never ran.                       │
```

### Where a tap can fail

| | Step | When it fails | What the user sees | How to tell |
|-|------|---------------|--------------------|-------------|
| A | 3 | The system performs the intent in the widget extension, not the app. Apple documents `LiveActivityIntent` as running in the app. A forum thread reports that on iOS 18, widget intents stopped reaching the app's process, and that `LiveActivityIntent` fixed it for Live Activities ([758784](https://developer.apple.com/forums/thread/758784)). Whether it also needs `NSSupportsLiveActivities` in the app's `Info.plist`, which the app doesn't declare, is unverified (WSPIKE-2). | Nothing | No "Logged" dialog, no drink, and nothing from ``LogDrinkIntent`` in Console. The extension's throw logs nothing today. A log line there would make this visible. |
| B | 3 | The app is alive in the background, suspended, and the system doesn't run `perform()` there. One forum report describes this, without an answer ([732771](https://developer.apple.com/forums/thread/732771)). | Nothing | The same as A. It happens when the app is in the app switcher, and not after it's force-quit. |
| C | 1–3 | The tap is on the simulator. Forum reports say widget intents don't run reliably there ([735159](https://developer.apple.com/forums/thread/735159)). | Nothing, or the app opens | It happens only on the simulator. |
| D | 2 | The phone is locked, as in StandBy. ``LogDrinkIntent`` requires local device authentication. | A request to unlock | The drink is logged after unlocking. |
| E | 4 | ``DrinkLogRule`` refuses the drink, or the save fails. | Nothing on the widget | The app process logs "Couldn't log a drink" at `error` for a failed save. A refused drink isn't logged. |
| F | 7–8 | The system's reload reads the snapshot before the app stores the new one (WSPIKE-4). | The old "Latest drink" line, until step 11 | The drink is in the app's log. |
| G | 8 | The snapshot repository can't read its data, or can't store the snapshot. | The old widget, until the next change | The drink is in the app's log. Console shows "Couldn't read the widgets' data" or "Couldn't store the widget snapshot". |

A, B, and C lose the drink. D asks first, and E through G log it but show it late or not at all. To tell A, B, and C apart:

- **Where the tap was.** Note whether it was on a device or the simulator, and whether Half-Life was running, in the background, or force-quit.
- **Console.** On the device, filter Console for the `com.quillanq.Half-Life` subsystem while tapping. With no ``LogDrinkIntent`` or snapshot entries at all, the app never ran: A, B, or C.
- **The extension.** A `notice`-level log line in the extension's `perform()`, before it throws, would show A directly. It isn't in the code yet.

## Presentation

### One tap

| Size | Shows |
|------|-------|
| Small | The top favourite: its symbol, its name, "2 shots · 125 mg", and "Latest drink 3:04 PM". The favourite's button fills the widget. |
| Medium | "One tap", the three favourites in a row, each a button like the Today screen's cards, and "Latest drink 3:04 PM" |

- **A tap logs.** Each button is `Button(intent: LogDrinkIntent(drink:quantity:))` for its favourite, which logs the drink as consumed now.
- **The widget updates.** When `perform()` returns, the system reloads the widget, and that reload doesn't count against the widget's daily budget ([Keeping a widget up to date](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date)). The "Latest drink" line has `invalidatableContent()`, so it dims until the new time shows.
- **The favourites can reorder** after a log, as the Today screen's do.
- **A locked phone asks first.** Every intent requires the device to be unlocked, with `authenticationPolicy` set to `.requiresLocalDeviceAuthentication` (<doc:AppIntents>). The widgets are on the Home Screen, which shows only while the phone is unlocked. In StandBy, though, a small widget can show while the phone is locked, and a tap there asks the user to unlock before the drink is logged.

### In your system

| Size | Shows |
|------|-------|
| Small | "IN YOUR SYSTEM NOW", the level in the accent color, and the curve with a dot at the current time |
| Medium | The same, with the decay card's first sentence: "Down to about 34 mg by 11:00 PM.", or "Nothing in your system right now." when the level rounds to 0 mg |

A tap opens the app. The widget sets no `widgetURL`, so the app opens where the user left it.

### Both widgets

- **Hidden while locked.** The level, the sentence, the curve, and the "Latest drink" line use `.privacySensitive()`, so iOS redacts them when it hides sensitive widget content, as it does for small widgets in StandBy while the phone is locked.
- **VoiceOver.**
  - One tap's buttons read as the Today screen's do: the label "Espresso, 2 shots", the value "125 milligrams", and the hint "Logs this drink now." They use the same String Catalog keys.
  - The level reads in full, such as "85 milligrams", after the heading.
  - The curve reads "Caffeine over the day".
  - The drink symbols and the setup message's cup are decorative.
- **Dynamic Type.** Text wraps rather than truncating. At accessibility text sizes, One tap's buttons drop their quantity line and keep the drink's name, and In your system drops the curve and keeps the figure and the sentence (Article VI.2).
- **Color.** The widgets use the app's semantic colors. No information is conveyed by color alone (Article VI.3).
- **Setup.** Until onboarding is complete, or while the app hasn't stored a snapshot yet, both widgets say "Finish setting up Half-Life", and a tap opens the app.
- **Localization.** Every string is in `Localizable.xcstrings`, which the extension compiles too, including the widgets' names and descriptions in the gallery. Numbers and times are formatted with `.formatted(…)`.
- **Previews.** Each widget has a preview at each size, with a timeline of three entries: the sample, nothing logged, and the setup state. A widget preview can't set the text size itself, so the largest accessibility size is checked with the canvas's Dynamic Type variants, and in WA11Y-1.

## Privacy and logging

- **The snapshot is health data.** It's derived from the drink log, the profile's bedtime, and the half-life estimated from Health's sleep data. It stays on the device, is never synced, and is left out of iCloud backups (Article V.3.4). Its row is in the Architecture article's "Data and privacy" table (<doc:Architecture>).
- **Its protection class is an Article V.4 exception.** WidgetKit asks the extension for a timeline whenever it chooses, including while the phone is locked, for example when a 12-hour timeline ends overnight. Under `NSFileProtectionComplete`, that read would fail. The widget would then show nothing new until the phone was unlocked and something reloaded it. `NSFileProtectionCompleteUntilFirstUserAuthentication` is the drink store's own class.
- **Nothing from a snapshot or a timeline is logged.** That means no level, time, favourite, or count (constitution Article XI.6.1). The repositories and data sources log failures at `error`, with the error's domain and code as `.public` (XI.6.4). A successful store or reload follows a routine health event, so it isn't logged (XI.7). The extension logs in the app's subsystem, through `Logger(for:)`.
- **Privacy manifest.** The app has no `PrivacyInfo.xcprivacy` yet (Article V.7). When one is added, the extension needs its own if it uses a required-reason API. The snapshot file is written with `FileManager`, and the extension reads no file timestamps and no `UserDefaults`.

## Unit tests and the app

The unit tests run hosted in the app, and swift-dependencies treats a process with XCTest loaded as a test. So the host app's own root store, created by `Half_LifeApp`, sends `launched` with test values, and ``KeepWidgetsCurrentUseCase``'s unimplemented repository reports an issue from outside any test. The host app's `AppView` already does the same with the profile and the app lock, and those issues don't fail the tests.

## Spike: check on a device

The design rests on behavior Apple documents for Live Activities. These questions need a physical device, because widget intents don't run reliably on the simulator:

| ID | Question |
|----|----------|
| WSPIKE-1 | Does a widget button running ``LogDrinkIntent``, with `LiveActivityIntent` and a `supportedModes` of `.background`, log the drink in the app's process without opening the app? **Yes, on a physical device (the owner, 2026-09-13).** Which app states were tried, running, in the background, or force-quit, wasn't recorded. |
| WSPIKE-2 | Does `LiveActivityIntent` need `NSSupportsLiveActivities` or anything else from ActivityKit when no Live Activity starts? It compiles without warnings alongside `supportedModes` (checked 2026-09-13). **It seems not.** The app doesn't declare the key, and drinks are logged on a device, which the extension's copy of the intent can't do. That's an inference from the owner's test, not a direct check. |
| WSPIKE-3 | Does a background launch for the intent run `Half_LifeApp.init`, so the snapshot repository starts without a scene? |
| WSPIKE-4 | Does the system's reload after `perform()` come before the new snapshot is stored? If it does, the widget shows the old snapshot until the repository's own reload. If that's noticeable, ``LogDrinkIntent`` would wait for the snapshot, which changes the App Intents design. |
| WSPIKE-5 | How long does a tap take to show in the widget when the app isn't running? |

If WSPIKE-1 or WSPIKE-2 fails, the design returns to the owner with the rejected option: logging in the widget extension. The App Group also has to be registered for the app's identifier in the developer account before a device build, which Xcode's automatic signing does.

## Testable requirements

### Domain

| ID | Requirement |
|----|-------------|
| WSNAP-1 | The forecast has a level at every whole 5-minute mark from 12 hours before the current mark, equal to ``CaffeineDecayRule``'s level at that mark. |
| WSNAP-2 | The forecast ends at the first mark, at least 24 hours after its start, at which no intake still counts, and never more than 7 days after the current mark. With nothing logged, it covers exactly 24 hours at 0 mg. |
| WSNAP-3 | The snapshot holds the forecast, the profile's bedtime, ``FavouriteDrinksRule``'s three favourites, when the latest drink was consumed, whether onboarding is complete, and when it was calculated. With no profile, the bedtime is the standard one and onboarding isn't complete. |
| WTL-1 | A timeline has an entry at its start and every 5 minutes after it for 12 hours, and asks for a new timeline at its end. |
| WTL-2 | Each entry's level is the forecast's sample at or before its date, or 0 after the forecast's last sample. |
| WTL-3 | Each entry's curve is the forecast's samples from 6 hours before its date to 6 hours after, with 0 at each mark after the forecast ends. |
| WTL-4 | Each entry's bedtime level is the forecast's level at the next bedtime at or after its date, in the given calendar, or 0 past the forecast. |
| WTL-5 | With no snapshot, or until onboarding is complete, the timeline is a single setup entry. |
| WTL-6 | Each entry's favourites and latest drink come from the snapshot. |
| WUSE-1 | ``KeepWidgetsCurrentUseCase`` subscribes to the repository's snapshots until the stream ends. |
| WUSE-2 | ``ObserveWidgetTimelineUseCase`` streams the repository's timeline, in the given calendar. |

### Repositories, data sources, and registrations

| ID | Requirement |
|----|-------------|
| WSREPO-1 | A new subscriber gets the snapshot for the current data at once. Every subscriber gets a new one after each change to the drink log, the profile, or the half-life. The repository listens to its data sources once. |
| WSREPO-2 | After each new snapshot, the repository stores it and then reloads the widgets, in that order. |
| WSREPO-3 | A failed read or store publishes nothing and reloads nothing, and the next change recovers. |
| WTLREPO-1 | The timeline repository publishes one timeline for the stored snapshot, then finishes. |
| WTLREPO-2 | With no snapshot stored, or after a failed read, it publishes the setup timeline. |
| WSDS-1 | A stored snapshot reads back equal, from a new instance, and a new one replaces the old. |
| WSDS-2 | The file is written atomically with `NSFileProtectionCompleteUntilFirstUserAuthentication`, and left out of backups. |
| WSDS-3 | With no file, a read returns `nil` rather than throwing. A damaged file throws. |
| WSDS-4 | The app's file is `WidgetSnapshot.json` in the `group.com.quillanq.Half-Life` App Group container. |
| WDEP-1 | Using the snapshot repository or ``KeepWidgetsCurrentUseCase`` in a test without overriding it reports an issue. |
| WDEP-2 | In previews, the repository is a ``LiveWidgetSnapshotRepository``, and ``KeepWidgetsCurrentUseCase`` holds that one app-scoped repository. |
| WDEP-3 | A UI test's launch stores the snapshot in a temporary file. Any other launch stores it in the App Group file. |

### Presentation

| ID | Requirement |
|----|-------------|
| WAPP-1 | ``AppFeature``'s `launched` action runs ``KeepWidgetsCurrentUseCase``. Tested with an exhaustive `TestStore`. |
| WPREVIEW-1 | Each widget has previews at each size: with data, with nothing logged, and in the setup state (Article I.20). |
| WA11Y-1 | Before release, each widget is checked with Accessibility Inspector at each size, and at the largest accessibility text size, and the result is recorded in this article (Article I.20). Not done yet. |

``LogDrinkIntent``'s own requirements, including that it logs through ``LogDrinkUseCase``, are in <doc:AppIntents>.

## Still to decide

- **App Review.** Whether App Review questions `LiveActivityIntent` in an app with no Live Activity can't be checked in advance.
- **A failed log.** What the widget shows when ``LogDrinkIntent`` throws. The spike checks whether the system shows the intent's error itself.
- **Undo.** A tap on the Home Screen has no confirmation, and a stray tap is likelier there than in the app. The drink can be deleted from the Today screen's history card. Delete and undo is roadmap rank 20.
- **Bug reports.** On iOS, `OSLogStore` reads only the current process's entries, as far as the AI knows. If so, the log export (<doc:Logging>) won't include the extension's. This needs checking.
- **The Lock Screen and the Action Button.** The owner left them out for now. The same snapshot and intent would serve them.