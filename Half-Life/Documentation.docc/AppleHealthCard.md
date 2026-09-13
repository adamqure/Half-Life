# Apple Health Card

The last card on the Today screen: last night's sleep, today's steps, and today's resting heart rate, each shown only when there's one to show.

## Overview

The brief asks Half-Life to pull sleep, steps, and other data from Apple Health. The Today screen's Apple Health card is where that data first appears. It sits at the bottom of the screen, under the history card (<doc:TodayScreen>).

Health access is opt-in, and HealthKit can return any subset of the three metrics, or none. So the card shows only the metrics that have a value, and it's hidden when none does. It never stands in for a missing metric, because HealthKit doesn't tell an app whether read access was denied (<doc:SleepData>, "Access and missing data"). A 0 or a dash would claim something the app doesn't know.

A switch in Settings replaces Apple Health with demo data sources, so the card can be tried without Health data: in the simulator, in UI tests, and on TestFlight by a reviewer without an Apple Watch.

**Status: built** on 2026-09-13, from the design the owner approved on 2026-09-12. "What the build changed" lists where the build differs from the design.

## What the prototype shows

The prototype's card (screenshot 09) reads "LAST NIGHT 6h 42m" and "STEPS 8,420", with "from Apple Health" at its trailing edge.

| Prototype | Half-Life | Why |
|-----------|-----------|-----|
| Always shown | Shown only when a metric has a value | Health access is opt-in, and a missing value can't be told apart from a denial |
| Last night and steps | Last night, steps, and resting heart rate | The brief asks about heart rate, and onboarding already asks to read it (<doc:Onboarding>) |
| "from Apple Health" in the card | "From Apple Health" as the eyebrow above the card, like "One tap" and "Logged today". "Demo Health data" when the demo switch is on. | The brief asks the app to "say clearly what's seeded vs. live" |
| Sleep only | Time asleep, or time in bed, labeled as such, when no tracker recorded sleep | Time in bed isn't sleep, and the card mustn't present it as sleep |

## The owner's decisions

The owner made these decisions on 2026-09-12, between 22:50 and 22:54.

| Question | Decision | Rejected |
|----------|----------|----------|
| Which resting heart rate | Today's only, hidden until Health has one. A reading can't be guaranteed on any given day. | The latest reading from today or yesterday, labeled with its day |
| A night with time in bed but no sleep recorded | Shown as "In bed", with a note that it isn't sleep. Time in bed is used in analysis only alongside sleep data. On its own it says nothing about sleep. | Showing it as sleep. Showing no sleep at all. |
| Where the card goes | The bottom of the Today screen, under the history card, as in the prototype | Under the tile row |
| Demo Health data | Demo data sources that stand in for HealthKit, switched on by a feature flag | Writing demo samples into Apple Health, which would need write access the app doesn't ask for |
| The feature flag | A switch in Settings' Demo data section, stored on the device, off by default | A build configuration. Following the demo drinks. A launch environment key. |

The AI recommended each of these. The card states facts only: it says nothing like "a short night", and doesn't set sleep against caffeine. Interpretation, and how sure the app is of it, belongs to insight cards (roadmap rank 12) and the Insights tab (rank 15, <doc:Insights>).

## What the build changed

The owner asked for the build on 2026-09-13, to validate the HealthKit reads on a device. It follows the design, with these changes:

- **Settings' Demo data screen became its own pushed screen** while the card was built, so the switch sits on that screen, under the demo drinks' card. The screen's feature is ``DemoDataFeature``, which runs ``DemoHistoryFeature`` and ``DemoHealthDataFeature`` side by side. The Settings session suggested it, because the pushed screen gets its store from the navigation path, not from Settings' root.
- **The switch is a `SettingsOption`, not a `Toggle`,** because native toggles failed the accessibility audit on Settings' cards (<doc:Settings>).
- **Under a UI test, the switch is stored in a new temporary file,** not in memory, and Health access counts as already requested, through ``RequestedHealthAccessDataSource``, so the simulated Health data is read at once.
- **The launch key has no `none` value.** An empty list, or no key, means no Health data.
- **``SleepNightRule`` shares its code.** Its `sessions(of:)` and `unionLength(of:within:)` are now internal statics, and `SleepStageInterval.Stage.isAsleep` is internal. Its behavior didn't change, and its tests still pass.
- **One helper starts every new observer query,** `HKHealthStore.observeHalfLife(_:handler:)`, which the step count and resting heart rate data sources use.
- **The demo resting heart rate source signals at every whole minute too,** like the demo steps, so today's reading appears at 9am without a restart.
- **A late cup, for the demo script,** is 90 mg or more from 3pm on, ``DemoHealthScript``'s definition.

## Domain

### HealthSummary

What the card shows. Every metric is optional, so any subset can be shown.

| Property | Type | Meaning |
|----------|------|---------|
| `lastNight` | `LastNightSleep?` | The night that ended this morning, or `nil` if Health has no sleep or time in bed for it |
| `stepsToday` | `Int?` | Today's steps so far, or `nil` if Health has none. `0` only when Health recorded zero (<doc:StepCount>). |
| `restingHeartRateToday` | `Double?` | Today's average resting heart rate, in beats per minute, or `nil` if Health has none yet |
| `isDemo` | `Bool` | Whether the values came from the demo data sources |

`isEmpty` is `true` when all three metrics are `nil`. The card is hidden then.

### LastNightSleep

What the card shows for last night: one of two cases.

| Case | Value | Card |
|------|-------|------|
| `asleep` | Time asleep, in seconds | "Last night", with the time asleep |
| `inBedOnly` | Time in bed, in seconds | "In bed", with the time in bed and the note "Time in bed, not sleep." |

- **`inBedOnly` is only for a night with no sleep recorded.** The iPhone's sleep schedule records time in bed without an Apple Watch, and that's this case. When a night has both, the card shows the time asleep.
- **Time in bed on its own says nothing about sleep, so analysis never uses it.** The half-life estimator reads nights through ``SleepNightRule``, which ignores time in bed (<doc:HalfLifeEstimator>). Time in bed can refine a night that has sleep, for example into time to fall asleep. That's an open question in the estimator's article.

### LastNightSleepRule

`LastNightSleepRule` is the business rule that finds last night in ``SleepStageInterval`` values. The half-life estimator built ``SleepNightRule`` first, and this rule agrees with it on what a night is:

- **The same sessions.** Intervals are grouped into sessions exactly as ``SleepNightRule`` groups them: asleep and awake stretches stay in one session while each starts no more than an hour after the session so far ends. The two rules share that code, so they can't drift apart.
- **A night has at least 3 hours of sleep,** ``SleepNightRule``'s threshold. A shorter session is a nap, so an afternoon nap never replaces last night.
- **Last night is the latest session whose last sleep ends from noon yesterday to noon today,** in the given calendar. So the card shows the same night at 7am and at 9pm. The noon boundary is the AI's choice and still to be confirmed.
- **Time asleep is measured as ``SleepNightRule`` measures it for its 3-hour check:** the union of the asleep stretches from the first sleep to the last, with overlapping trackers counted once. Time awake and time in bed add nothing. ``SleepNight`` doesn't carry this figure, so the two rules share the measurement, not a field.

It differs from ``SleepNightRule`` in two ways, both because the card only reports what Health recorded:

- **Sleep recorded without stages counts.** A tracker that records only "asleep" gives no deep sleep for the estimator to score, but its time asleep is real.
- **Time in bed is the fallback.** With no sleep session in the window, the time in bed ending in the window is grouped the same way. The latest group with at least 3 hours gives `inBedOnly`.

With neither, there's no last night. Like the other rules, it holds no state and reads no clock.

## Data

### Data sources

The repository reads three kinds of Health data through the existing protocols, with a live HealthKit implementation and a demo one for each. It also reads a flag data source for the demo switch.

| Protocol | Live | Demo | Added for the card |
|----------|------|------|--------------------|
| ``SleepDataSource`` | ``HealthKitSleepDataSource`` | `DemoSleepDataSource` | The demo implementation |
| ``StepCountDataSource`` | ``HealthKitStepCountDataSource`` | `DemoStepCountDataSource` | `changes()`, on both implementations (STEPS-6 to STEPS-8 in <doc:StepCount>) |
| ``RestingHeartRateDataSource`` | ``HealthKitRestingHeartRateDataSource`` | `DemoRestingHeartRateDataSource` | `changes()`, on both implementations (RHR-6 to RHR-8 in <doc:RestingHeartRate>) |
| `DemoHealthDataFlagDataSource` | `FileDemoHealthDataFlagDataSource` | — | Whether the demo switch is on |

- **Steps and resting heart rate get `changes()`,** an observer query per subscriber, like the one sleep already has. Without it, today's steps would stop at the count they had when the card first read them.
- **Only Data code touches HealthKit.** The demo data sources touch no framework, so the demo, tests, and previews never read real Health data (constitution Articles I.14 and V.3.5).

### The demo data

The demo data sources answer from a fixed script, so the same day always gives the same values. It covers the same 30 days before today as the demo drinks, plus today, and nothing earlier. The owner extended the demo from 14 days to 30 on 2026-09-12, so the Insights tab's 30-day view has a full month (<doc:Settings>, "The script"). The demo drinks and the demo Health data have separate switches, but they're scripted to go together: the Health script knows which days the drink script ends late.

- **Sleep.** Each night has one `inBed` interval, about 10:45pm to 6:45am, and sleep stages inside it, in 90-minute cycles: more deep sleep early and more REM late, with a short `awake` interval.
  - The nights after the drink script's late-cup days start later and have less deep sleep. The Health script follows whichever days the drink script ends late, so the two stay in step when the drink script changes. So Insights and the estimator have a timing effect to find, and the estimator can be checked against a known answer (roadmap rank 8).
  - One night, 10 nights ago, has time in bed and no sleep, which exercises `inBedOnly` and its exclusion from analysis.
- **Steps.** Each past day has a scripted total, from about 4,000 to 12,000. Today's grows with the time of day: the day's total, scaled by how much of the day from 7am to 10pm has passed. So the demo step data source reads ``ClockDataSource``, and its `changes()` signals at every whole minute.
- **Resting heart rate.** Each day has a scripted average, from about 56 to 63 bpm, a few beats higher after a short night. Today's appears only from 9:00am, which exercises "hidden until Health has one".
- **Nothing is written to Apple Health**, and the app still asks for read access only.

### The demo switch

- `DemoHealthDataFlagDataSource` returns whether the switch is on, stores a new value, and signals each change.
- `FileDemoHealthDataFlagDataSource` stores it in a small file in Application Support, on the device only, like ``FilePermissionHistoryDataSource``. It isn't the user's data, so it isn't synced. It's off until the user turns it on.
- UserDefaults was ruled out for the same reason as for the profile: it's a required-reason API, and the app has no privacy manifest yet (<doc:Onboarding>).

### HealthDataRepository

`HealthDataRepository`, implemented by the actor `LiveHealthDataRepository`, is the source of truth for the Health data the app shows (constitution Articles I.11 to I.13). It executes `LastNightSleepRule` (Article I.10).

| Operation | Does |
|-----------|------|
| `summary(in:)` | Streams today's `HealthSummary` in the given calendar: the current one as soon as it's subscribed to, then each change |
| `usesDemoData()` | Streams whether the demo switch is on: the current answer first, then each change |
| `setUsesDemoData(_:)` | Turns the demo switch on or off through the flag data source |

- **It holds both sets of data sources,** live and demo, and reads whichever the switch selects. Turning the switch re-reads everything and publishes the result, so the card changes without restarting the app.
- **Live, it reads only once Health access is `requested`.** It reads the status from the ``HealthAuthorizationDataSource`` that ``PermissionsRepository`` also uses. Before that, it publishes an empty summary and checks the status again at each whole minute. The check is local, not a Health query. So it never sends a query HealthKit would refuse for undetermined access, and the card appears within a minute of the user allowing Health in Settings.
- **The demo needs no Health access.** It works in the simulator, and when the user declined Health.
- **It re-reads** when any of the three data sources signals a change, at the first minute of a new day, when the switch turns, and when Health access becomes `requested`.
- **Each subscriber gets only changes.** The repository remembers the last summary it sent each subscriber and skips an equal one (Article I.12).
- **Each metric fails on its own.** A metric whose query throws is `nil` in the summary, and the others still show. The data source has already logged the error, with its domain and code only.

### ObserveHealthSummaryUseCase and the demo switch's use cases

| Use case | Does | Repository |
|----------|------|------------|
| `ObserveHealthSummaryUseCase` | Streams the summary for the calendar it's given | `HealthDataRepository` |
| `ObserveDemoHealthDataUseCase` | Streams whether the demo switch is on | `HealthDataRepository` |
| `SetDemoHealthDataUseCase` | Turns the demo switch on or off, and passes on any error | `HealthDataRepository` |

Each is registered in a new `HealthDataDependencies.swift`, built from the repository's key (constitution Article I.15).

## Presentation

### HealthSummaryFeature

A child of ``TodayFeature``, scoped at `State.healthSummary`.

- **Its only command is `task`,** which subscribes through `ObserveHealthSummaryUseCase` in the `\.calendar` dependency. Each summary becomes a `summaryUpdated` action, and the reducer stores it in `State`.
- **`isShown`** is `true` when a summary has arrived and isn't empty.
- **A hidden card can't start its own observation.** A view that isn't on screen never runs `.task`, so if the card started its own, it would never appear. ``TodayView`` sends `.healthSummary(.task)` from its scroll view's `.task` instead, which is always on screen.

### DemoHealthDataFeature

A child of ``DemoDataFeature``, the feature of Settings' Demo data screen, beside ``DemoHistoryFeature``. The two demos stay independent.

- **The option** reads "Use demo Health data", with the line "Shows made-up sleep, steps, and resting heart rate on the Today screen in place of Apple Health's. Nothing is written to Health." It's a `SettingsOption`, under the demo drinks' card, chosen while the switch is on.
- **It follows the repository's answer, not the tap** (constitution Article I.5). Another tap while a change is under way does nothing. A failed change says "The demo Health data couldn't be changed. Try again." under the option until the next try. The repository logs the failure, so the reducer doesn't.
- ``DemoHistorySettingsView`` starts both features' observations from its own `.task`s.

### The card

- **The eyebrow** above the card reads "From Apple Health", or "Demo Health data" while the switch is on. It has the header trait.
- **The card** uses `surfaceMuted`, which the Design System reserves for the Apple Health summary card.
- **One cell per metric that has a value,** in a row of one, two, or three equal cells with dividers between them. At accessibility text sizes the cells stack, each at full width (constitution Article VI.2).

| Cell | Label | Figure | Symbol |
|------|-------|--------|--------|
| Sleep | "Last night" | Time asleep, such as "6h 42m" | `bed.double.fill` in `dataSleep` |
| Time in bed only | "In bed" | Time in bed, such as "7h 10m", above the note "Time in bed, not sleep." | `bed.double.fill` in `dataSleep` |
| Steps | "Steps today" | Such as "8,420" | `figure.walk` in `dataActivity` |
| Resting heart rate | "Resting HR" | Rounded to a whole beat, such as "58 bpm" | `heart.fill` in `dataHeart` |

- **The figures are `textPrimary`,** in the `metric` style with monospaced digits. The symbols carry the data colors, and the label names the metric, so color is never the only signal (Article VI.3).
  - Data colors as text were rejected: by the AI's hand calculation, `dataSleepText` on `surfaceMuted` is about 4.25:1, below the 4.5:1 that the `metric` style needs.
  - As graphics, `dataSleep`, `dataActivity`, and `dataHeart` measure about 3.2, 3.9, and 4.5:1 on `surfaceMuted`, above the 3:1 that graphics need. `ColorTokenTests` checks these pairings.
- **A hairline in `controlTrack`** separates the cells. It's decorative, so VoiceOver skips it.
- **Formats are locale-aware** (Article VII.3). Durations use `Duration`'s `.units(allowed: [.hours, .minutes], width: .narrow)`, steps use number formatting, and "bpm" is a localized string with the number interpolated.
- **VoiceOver reads each cell as one element,** with its symbol hidden: "Last night, 6 hours 42 minutes asleep"; "In bed, 7 hours 10 minutes. Time in bed, not sleep."; "Steps today, 8,420"; "Resting heart rate, 58 beats per minute".
- **Hidden means gone.** With nothing to show, neither the eyebrow nor the card is in the layout, and the screen leaves no gap for them.

### Accessibility identifiers

`HealthSummaryViewAccessibilityID`: `title`, `card`, `lastNight`, `inBed`, `steps`, and `restingHeartRate`. It belongs to both targets. The card is part of the Today screen, so it has no `screen` identifier. `TodayRobot` uses these identifiers, from `TodayRobot+Health.swift`.

The switch's identifiers join the Demo data screen's: `DemoHistorySettingsViewAccessibilityID` gains `demoHealthDataOption` and `demoHealthDataError`, and `DemoHistorySettingsRobot` turns the switch with `turnDemoHealthData(on:)`.

## UI tests

A UI test can't grant Health access or add Health data. So under a UI test, the repository's live data sources are replaced by ``SimulatedHealthDataSource``, Health access by ``RequestedHealthAccessDataSource``, and the switch's file by a new temporary one, like the permission data sources (<doc:Onboarding>).

- **A launch environment key, `LaunchEnvironmentKey.healthData`,** chooses what the simulated Health holds: a comma-separated list of `sleep`, `inBed`, `steps`, and `heartRate`. Without the key, or with an empty list, it holds nothing, so the card stays hidden in the other UI tests.
- **The simulated data is fixed.** Last night runs from 11pm to 6am, 7 hours asleep, or 10:30pm to 6:30am in bed, today's steps are 8,420, and today's resting heart rate is 58 bpm.
- **The simulated sources answer as live Health would,** so the card reads "From Apple Health". The demo data sources are tested through the Settings switch instead (HUI-5).
- `XCUIApplication.launchPastOnboarding(withHealthData:)`, in `HealthCardUITests.swift`, sets the key.

## Privacy and logging

- **Health data is read, never stored.** The summary is held in memory only, and never synced to iCloud (constitution Article V.3.4).
- **The demo switch is the only new stored value.** It's on the device only, in its own file, and it isn't health data.
- **Values are never logged** (Article XI.6). That covers durations, counts, heart rates, and whether a metric was present, because a missing metric can reveal a denial.
- **Turning the switch is logged at `notice`,** "Demo Health data turned on" or "off", because a bug report needs to know which data the app was showing. A failed change is logged at `error`, with the error's domain and code only.
- **Reads and change signals aren't logged.** They're routine health events (Article XI.7). Failed queries are already logged by their data sources.

## Testable requirements

Each requirement is written so that one test can prove it.

### LastNightSleepRule

Unit-tested directly. The rule is pure, so its tests need no fakes. NIGHT-1 to NIGHT-6 are ``SleepNightRule``'s, in <doc:HalfLifeEstimator>.

| ID | Requirement |
|----|-------------|
| LASTNIGHT-1 | Last night is the latest session, grouped as ``SleepNightRule`` groups them, whose last sleep ends from noon yesterday, included, to noon today, excluded, in the given calendar. The same night is returned at any time of day. |
| LASTNIGHT-2 | Its time asleep is the union of its asleep stretches from the first sleep to the last. Overlapping trackers count once, and time awake and time in bed add nothing. For a night recorded with stages, it equals the time asleep ``SleepNightRule`` measures for its 3-hour check. |
| LASTNIGHT-3 | Sleep recorded without stages gives time asleep, though ``SleepNightRule`` makes no night of it. |
| LASTNIGHT-4 | A session with less than 3 hours of sleep is a nap, and isn't last night. |
| LASTNIGHT-5 | With no sleep session in the window, the latest group of time in bed ending in it, of at least 3 hours, gives `inBedOnly` with its length. A night with both sleep and time in bed gives `asleep`. |
| LASTNIGHT-6 | No sleep and no time in bed in the window give no last night. |
| LASTNIGHT-7 | A window the clocks change in is still noon to noon, 23 or 25 hours long. |

### HealthSummary

| ID | Requirement |
|----|-------------|
| HSUM-1 | A summary is empty exactly when it has no night, no steps, and no resting heart rate. A step count of `0` isn't empty. |

### Demo data sources

| ID | Requirement |
|----|-------------|
| DEMOHEALTH-1 | Every one of the 30 nights before today, and last night, has sleep, except the in-bed-only night of DEMOHEALTH-3. Nothing comes before them. |
| DEMOHEALTH-2 | Every night after one of the drink script's late-cup days has less deep sleep, and starts later, than every night after a day that stops by mid-afternoon. |
| DEMOHEALTH-3 | The night 10 nights ago has time in bed and no sleep. |
| DEMOHEALTH-4 | Today's steps grow with the clock, from none at 7:00am to the day's total at 10:00pm. The past days have their scripted totals. The step data source signals at every whole minute. |
| DEMOHEALTH-5 | Today has no resting heart rate before 9:00am, and has one from then on. |
| DEMOHEALTH-6 | The same day always gives the same values, in any time zone at the same local clock times. |

### Demo switch data source

| ID | Requirement |
|----|-------------|
| DEMOFLAG-1 | The switch is off until a value is stored. |
| DEMOFLAG-2 | A stored value is returned from then on, and survives a new instance of the data source. |
| DEMOFLAG-3 | Storing a value signals a change. Storing the value already stored signals nothing. |

### HealthDataRepository

Tested against fake data sources and a fake clock.

| ID | Requirement |
|----|-------------|
| HREPO-1 | A new subscriber immediately gets today's summary, with last night from `LastNightSleepRule`. |
| HREPO-2 | Any of the eight combinations of sleep, steps, and resting heart rate being present gives a summary with exactly those metrics. |
| HREPO-3 | A metric whose query throws is `nil`, and the others are still read. |
| HREPO-4 | Live, while Health access isn't `requested`, nothing is read and the summary is empty. At the first minute access is `requested`, the data is read and published. |
| HREPO-5 | A change signal from any of the three data sources re-reads the summary. The first minute of a new day re-reads it for the new day. |
| HREPO-6 | Each subscriber gets only changes. An equal summary isn't sent again. |
| HREPO-7 | With the switch on, the summary comes from the demo data sources, is marked demo, and needs no Health access. Turning the switch publishes the other set's summary. |
| HREPO-8 | `usesDemoData()` sends the current answer first, then each change. `setUsesDemoData(_:)` stores it through the flag data source, and a failed store throws and changes nothing. |

### Use cases and registrations

| ID | Requirement |
|----|-------------|
| HUSE-1 | `ObserveHealthSummaryUseCase` streams every summary the repository publishes for the calendar it's given, in order. |
| HUSE-2 | `ObserveDemoHealthDataUseCase` streams the repository's answers, and `SetDemoHealthDataUseCase` sets the switch through the repository and passes on its error. |
| DEP-HEALTH | Each of the three use cases holds the one app-scoped `HealthDataRepository`, and each reports an issue in a test that doesn't override it. |

### HealthSummaryFeature and DemoHealthDataFeature

Tested with an exhaustive `TestStore`, with the use cases overridden.

| ID | Requirement |
|----|-------------|
| HCARD-1 | `task` subscribes to the summary in the `\.calendar` dependency, and each summary is reduced into `State`. |
| HCARD-2 | `isShown` is `false` before the first summary and for an empty one, and `true` for a summary with any metric. |
| HDEMO-1 | The toggle shows the repository's answer. Turning it goes through `SetDemoHealthDataUseCase`, and the toggle waits for the repository. |
| HDEMO-2 | A failed change says so, until the next try. |

TODAY-5 in <doc:TodayScreen> covers the card's scope in ``TodayFeature``.

### UI

| ID | Requirement |
|----|-------------|
| HUI-1 | With no Health data, the Today screen has no Apple Health card and no eyebrow for it. |
| HUI-2 | With only steps and resting heart rate, the card shows those two cells and no sleep, under "From Apple Health". |
| HUI-3 | With sleep, steps, and resting heart rate, the card shows all three. |
| HUI-4 | With time in bed and no sleep, the card shows "In bed" with its note. |
| HUI-5 | Turning on "Use demo Health data" in Settings shows the card under "Demo Health data". Turning it off hides it again. |
| HUI-6 | The Today screen passes the accessibility audit with the card showing, with `auditAccessibilityAboveTheTabBar()`, which audits it at rest and again scrolled to its end (<doc:Architecture>). |
| LAUNCH-HEALTH | The launch environment's Health data key lists the simulated Health data a UI test's app holds, and ignores any other value. Without it, the app holds none. |
| SIMHEALTH-1 | The simulated Health data holds exactly the kinds it's given, and never changes. |

### Tests

`LastNightSleepRuleTests` covers LASTNIGHT-1 to LASTNIGHT-7, and `HealthSummaryTests` covers HSUM-1. `DemoHealthDataSourcesTests` covers DEMOHEALTH-1 to DEMOHEALTH-6, and `FileDemoHealthDataFlagDataSourceTests` covers DEMOFLAG-1 to DEMOFLAG-3, each with its own temporary file. `LiveHealthDataRepositoryTests` covers HREPO-1 to HREPO-8 against fakes that stand in for all three kinds of Health data and the switch, on a clock the test advances. `HealthDataUseCaseTests` covers HUSE-1 and HUSE-2, and `HealthDataDependencyTests` covers DEP-HEALTH. `HealthSummaryFeatureTests` covers HCARD-1, HCARD-2, and TODAY-5, and `DemoHealthDataFeatureTests` covers HDEMO-1 and HDEMO-2. `UITestLaunchConfigurationTests` covers LAUNCH-HEALTH, `SimulatedHealthDataSourceTests` covers SIMHEALTH-1, and `HealthCardUITests` covers HUI-1 to HUI-6. `HealthKitStepCountChangesTests` and `HealthKitRestingHeartRateChangesTests` cover STEPS-6 to STEPS-8 and RHR-6 to RHR-8.

The live HealthKit reads aren't unit-tested, because a test can't grant the test host access to Health. They're a manual check on a device: with Health access allowed, the card's figures should match the Health app's last night, steps, and resting heart rate for today.

## Still to decide

- **The noon boundary.** A shift worker who sleeps from 4am to 1pm wakes after noon, so that sleep becomes tonight's last night, not today's.
- **Merging trackers.** Both rules count sleep that any tracker recorded, once. Choosing one source per night, as the Health app does, would follow the user's priority order instead.
- **The demo switch and the estimator.** The switch reaches only this card's repository. The estimator keeps reading live Health, because an estimate fitted to demo sleep would be stored, and the decay curve would adopt it. Whether demo sleep should reach the estimator is the estimator article's open "Demo sleep" question.
- **How the device check goes.** The live reads can only be checked on a device with Health data, against the Health app.
- **Background delivery** (<doc:SleepData>). The card re-reads only while the app is running.
