# Today Screen

The screen a user opens the app to: a greeting, the caffeine in their system now, and what they've had today.

## Overview

The Today screen is roadmap rank 4, "the only thing a reviewer opens the app and sees." It's a root feature, `TodayFeature`, composed of one child feature per card. Each child observes its own data through use cases, so the cards are independent of each other (constitution Article I.4–6).

| Feature | Shows | Use cases | Repositories | Status |
|---------|-------|-----------|--------------|--------|
| `DailyGreetingFeature` | A greeting for the time of day, with the user's name, and today's date | `ObserveUserProfileUseCase`, `ObserveTimeOfDayUseCase` | `UserProfileRepository`, `CurrentTimeRepository` | Built, and shown in the Today slot of the app's root, `AppFeature` |
| `CaffeineDecayFeature` | The caffeine in your system now, two tips, and the decay curve | ``ObserveCaffeineCurveUseCase``, `ObserveCaffeineStatusUseCase`, `ObserveTimeOfDayUseCase` | ``CaffeineDecayRepository``, `CurrentTimeRepository` | Built, and shown under the greeting |
| `CaffeineIntakeTodayFeature` | Today's total, with a bar | Not yet designed | `DrinkLogRepository` | Waits for `DrinkLogRepository` |
| `LastCupFeature` | When the last drink was, against the cutoff | Not yet designed | `DrinkLogRepository`, plus a cutoff repository | Waits for `DrinkLogRepository` and the cutoff rule |
| `OneTapLogFeature` | The three or four most common drinks, each logged in one tap | `LogDrinkUseCase`, plus one to observe favourites | `DrinkLogRepository` | Waits for `DrinkLogRepository` |
| `HistoryFeature` | The drinks logged today | Not yet designed | `DrinkLogRepository` | Waits for `DrinkLogRepository` |

The owner set this composition and each feature's repositories on 2026-09-11. The greeting and the decay card come first because they don't need the drink log, which the drink composer's work is building (<doc:DrinkComposer>). The other four follow once `DrinkLogRepository` exists.

The whole screen is one screen for UI tests, so it has one robot, `TodayRobot` (constitution Article II.5). Each child view keeps its own identifiers in its own `<View>AccessibilityID` file, and `TodayRobot` uses them all.

## Daily greeting

The prototype's header reads "GOOD AFTERNOON" above "Sunday, Aug 23" (screenshot 07). Half-Life adds the user's name when it knows it: "Good afternoon, Alex."

### DayPeriod

The part of the day a greeting is for.

| Case | From | Until | Greeting |
|------|------|-------|----------|
| `morning` | 5:00am | 12:00pm | "Good morning" |
| `afternoon` | 12:00pm | 5:00pm | "Good afternoon" |
| `evening` | 5:00pm | 5:00am | "Good evening" |

Each period includes its start and excludes its end. There's no night period, because "Good night" is a farewell in English. The boundaries are the AI's choice and still to be confirmed.

`DayPeriodRule` is the business rule that finds the period for a moment. It reads the hour and minute in a given calendar, so the period follows the user's time zone. Like ``CaffeineDecayRule``, it reads no clock.

### TimeOfDay

One minute on the clock: its `date`, and the `period` it falls in. `ObserveTimeOfDayUseCase` produces one for each minute that `CurrentTimeRepository` streams.

### UserProfile

What the user has told the app about themselves. For now that's only an optional `name`, which is `nil` until the user gives it. The onboarding survey (roadmap rank 6) doesn't ask for it. On 2026-09-11 the owner moved the name to a low-priority item in the roadmap's backlog, because the greeting works without it. Onboarding adds the bedtime and goals when it's built (constitution Article III.1).

### Repositories and data sources

| Repository | Publishes | Data source |
|------------|-----------|-------------|
| `CurrentTimeRepository` | The current time as soon as it's subscribed to, then again at the start of every whole minute | `ClockDataSource` |
| `UserProfileRepository` | The current `UserProfile` as soon as it's subscribed to | `UserProfileDataSource` |

- **`CurrentTimeRepository`** is shared with the drink composer, which reads its `now()` to time a logged drink (<doc:DrinkComposer>). The owner chose on 2026-09-11 to reuse it rather than add a second clock repository for the greeting, and the drink composer's work built it. Its data is the clock, so it publishes every minute on purpose. That's unlike ``CaffeineDecayRepository``'s curve, which never recalculates on a timer.
- **`ClockDataSource`** is the only code that reads the system clock. Its `minutes()` stream yields the current time as soon as it's subscribed to, and then once at every whole minute. The live `SystemClockDataSource` sleeps until the next minute starts. If the app is suspended past a minute, it yields the time it wakes at, so it never publishes a stale minute. The decay card's status stream will share this data source.
- **`UserProfileDataSource`** returns the stored profile, or `nil` when nothing has been stored. Nothing stores a profile yet, so the live `EmptyUserProfileDataSource` always returns `nil`. Onboarding replaces it with real storage and adds change signals, following the shared-data-source pattern in <doc:Architecture>.

### ObserveTimeOfDayUseCase

It turns each minute that `CurrentTimeRepository` streams into a `TimeOfDay`, with the period from `DayPeriodRule`. It's the only use case that executes a business rule; everywhere else, repositories do (constitution Article I.10). The owner chose this on 2026-09-11, over a second clock repository.

The calendar is the use case's input. The reducer passes TCA's `\.calendar` dependency, which is `Calendar.autoupdatingCurrent` in the live app, so a time-zone change shows up at the next minute. Tests pass a calendar with a fixed time zone.

### DailyGreetingFeature

Its only command is `task`, which subscribes to the profile and the time of day together. Each emitted value becomes an action, `profileUpdated` or `timeOfDayUpdated`, and the reducer stores the name and the time of day in `State`. Until the first time of day arrives, the view shows nothing.

The view combines the greeting and the date into one accessibility element with the header trait, so VoiceOver reads "Good afternoon, Alex, Sunday, Aug 23" as the screen's heading. The date is formatted with `Date.FormatStyle`, so it's locale-aware (constitution Article VII.3).

## Caffeine decay card

It shows three things from the prototype (screenshot 07):

- **The hero figure.** "In your system now: 85 mg," with the current time beside it.
- **Two tips.** "Down to about 34 mg by 11pm — half of your last cup is gone by 4:27pm." The owner chose these two tips on 2026-09-11.
- **The decay curve**, with a marker at the current time.

### Where the numbers come from

The owner decided on 2026-09-11 that ``CaffeineDecayRepository`` publishes the current level and the tips, recalculated every minute. That reverses REPO-2's "never recalculates on a timer" for these values only. The curve itself still recalculates only when its data changes, or for a new subscriber (<doc:CaffeineDecayModel>).

The repository has a second stream, `status(in:)`, of a new entity. The calendar it takes is the one the bedtime is a time of day in. The feature passes TCA's `\.calendar`, as the greeting does.

| `CaffeineStatus` property | Type | Meaning |
|---------------------------|------|---------|
| `level` | ``CaffeineLevel`` | The caffeine in the body at the current minute |
| `activeIntakes` | `[CaffeineIntake]` | The intakes still counting at the current minute (the drinks still in your system), including one consumed this minute, which is still 0 mg |
| `lastIntakeHalfGoneAt` | `Date?` | When the most recent intake's own level, after its peak, is down to half its dose. With the standard constants, that's 5 hours 49 minutes after it's consumed: one half-life plus 19 minutes, because its caffeine reached the body over time (RULE-8 in <doc:CaffeineDecayModel>). `nil` when that moment has passed or nothing is counting. |
| `levelAtBedtime` | ``CaffeineLevel``? | The level at the next bedtime |

- `status(in:)` publishes a status as soon as it's subscribed to. After that, it publishes a new one at every whole minute from `ClockDataSource`, and whenever the drink data source signals a change (REPO-7 to REPO-10 in <doc:CaffeineDecayModel>). Nothing can change the bedtime yet, so it signals nothing. The data source that stores one will add a signal.
- The figure and the tips come from ``CaffeineStatusRule``, a Domain business rule that the repository executes, so no feature evaluates the decay function (VIEW-1 in <doc:CaffeineDecayModel>). It sums levels with ``CaffeineDecayRule``, so the figure, the tips, and the curve always agree. The current level replaces VIEW-3's "found by date" lookup.
- "Half of your last cup is gone by" follows Bateman absorption (rank 5), which replaced instant absorption on 2026-09-12. That changed the rule, not the entity. The cup is half gone once its own level falls back to half its dose, after its peak. ``CaffeineDecayRule`` finds that moment by bisection, because the Bateman function has no closed-form inverse.
- A drink logged this minute counts as in your system, although none of its caffeine has reached the body yet. So the card shows its tips, not "Nothing in your system right now", while the figure is still 0 mg.
- **The bedtime** is a ``Bedtime``: a time of day, not a date. Until onboarding (rank 6) or Settings (rank 21) stores one, it's 10:30pm, the prototype's example. The repository reads it from `BedtimeDataSource`, and `StandardBedtimeDataSource` always returns that default, following the half-life data source's pattern. The Last Cup card's cutoff will share it.
  - This design first read the bedtime from the profile data source. A dedicated data source keeps the profile to what the user has told the app, and matches how the half-life is read.
- **The next bedtime** is the first occurrence of the bedtime at or after the current minute. At 11:30pm, with a 10:30pm bedtime, that's tomorrow at 10:30pm. This is the AI's choice and still to be confirmed.

### CaffeineDecayFeature

`CaffeineDecayFeature` observes the curve, the status, and the time of day, and reduces each value into `State`. Its only command is `task`. `ObserveTimeOfDayUseCase` supplies the time shown beside the figure. The curve's "now" marker sits at the status's level, so the marker and the figure always agree.

`State.summary` chooses the card's sentence. It's presentation logic, so it lives in the feature and is tested there (DECAY-4):

| `summary` | When | Sentence |
|-----------|------|----------|
| `nil` | No status has arrived yet | None |
| `.clear` | No intake is counting | "Nothing in your system right now." |
| `.bedtimeAndHalfGone` | The last cup isn't half gone yet | "Down to about 34 mg by 11:00 PM — half of your last cup is gone by 4:27 PM." |
| `.bedtime` | The last cup is past half gone | "Down to about 34 mg by 11:00 PM." |

### The card

- **The figure** is the level now, rounded to whole milligrams, in `metricHero` light (80 pt at the default size, scaled with `@ScaledMetric(relativeTo: .largeTitle)`) and the accent color. Its "mg" is set at 45% of that size in `textSecondary`. The amount is a `Measurement` formatted with `usage: .asProvided`, so it stays in milligrams in every locale (constitution Article VII.3). The figure appears once the first status arrives.
- **The sentence** uses the same whole-milligram amounts, and clock times formatted for the locale.
- **The curve** shows the whole 24-hour window in Swift Charts: an area under a 2.5 pt `dataCaffeine` line, with a dashed rule and a dot at the current level. It's 160 pt high (`Sizing.curveHeight`), with no axes.
- **VoiceOver** reads the heading and the time as one element, "In your system now, 3:24 PM", then the figure's amount in full, "85 milligrams". The curve's label is "Caffeine over the day", and Swift Charts adds its own audio graph.
  - The first build hid the heading from VoiceOver, because the figure repeated it. The accessibility audit flags visible text that VoiceOver can't reach ("Potentially inaccessible text"), so the heading is readable and the figure no longer repeats it.
- **The AI chose, still to be confirmed:**
  - the wording "Nothing in your system right now." when nothing is counting
  - showing the whole window rather than, say, the next few hours
  - rounding every amount to whole milligrams, with "about" in the sentence rather than a range

## Testable requirements

Each requirement is written so that one test can prove it.

### DayPeriodRule

| ID | Requirement |
|----|-------------|
| PERIOD-1 | 5:00am to 11:59am is `morning`, 12:00pm to 4:59pm is `afternoon`, and 5:00pm to 4:59am is `evening`. Each boundary minute belongs to the period it starts. |
| PERIOD-2 | The period follows the given calendar's time zone: the same instant can be morning in one time zone and evening in another. |

### ClockDataSource

Built and tested by the drink composer's work, against these requirements.

| ID | Requirement |
|----|-------------|
| CLOCK-1 | `minutes()` yields the current time as soon as it's subscribed to. |
| CLOCK-2 | After each value, it sleeps until the next whole minute. |
| CLOCK-3 | After sleeping, it yields the later of the current time and the minute it slept until. |
| CLOCK-4 | If sleeping is cancelled, the stream finishes. |

### ObserveTimeOfDayUseCase

Tested against the fake current time repository.

| ID | Requirement |
|----|-------------|
| TOD-1 | Each minute that `CurrentTimeRepository` streams becomes a `TimeOfDay`, in order, with the period from `DayPeriodRule`. |
| TOD-2 | It finds the period in the calendar it's given. |

### UserProfileRepository

| ID | Requirement |
|----|-------------|
| PROF-1 | A new subscriber immediately gets the stored profile. |
| PROF-2 | When nothing is stored, it publishes a profile with no name. |

### DailyGreetingFeature

Tested with an exhaustive `TestStore`, with both use cases overridden.

| ID | Requirement |
|----|-------------|
| GREET-1 | `task` subscribes to the profile, and each profile's name is reduced into `State`. |
| GREET-2 | `task` subscribes to the time of day, and each time of day is reduced into `State`. |

### TodayFeature

| ID | Requirement |
|----|-------------|
| TODAY-1 | The greeting's actions reach `DailyGreetingFeature`, and its state changes appear under `TodayFeature.State.greeting`. |
| TODAY-2 | The decay card's actions reach `CaffeineDecayFeature`, and its state changes appear under `TodayFeature.State.caffeineDecay`. |

### Bedtime

| ID | Requirement |
|----|-------------|
| BED-1 | Until the user sets one, the bedtime is 10:30pm. |
| BED-2 | A bedtime is a real time of day, from 0:00 to 23:59. Anything else isn't created. |

### CaffeineStatusRule

Unit-tested directly, with the Caffeine Decay Model article's day of drinks. The rule is pure, so its tests need no fakes.

| ID | Requirement |
|----|-------------|
| STATUS-1 | The level is ``CaffeineDecayRule``'s level at the current time. At 4:00pm on the day of drinks, that's 262.43 mg. |
| STATUS-2 | The active intakes are the ones that ``CaffeineDecayRule`` says count at the current time, in the order given. An intake consumed at the current time counts, although it adds 0 mg. An intake consumed later, or one that's negligible now, isn't among them. |
| STATUS-3 | The last intake is half gone when ``CaffeineDecayRule`` says so: once its own level falls to half its dose, after its peak. For the day of drinks' 3:00pm cup, that's 20,948.07 seconds later, at about 8:49pm. Once that moment has passed, or when nothing is counting, there's no half-gone time. |
| STATUS-4 | The level at bedtime is ``CaffeineDecayRule``'s level at the next bedtime. |
| STATUS-5 | The next bedtime is the first at or after the current time: tonight's, exactly at bedtime, and tomorrow's after it. |
| STATUS-6 | The bedtime is a time of day in the given calendar's time zone. |

### Bedtime data source

| ID | Requirement |
|----|-------------|
| BEDSRC-1 | It returns the current bedtime. When no value has been stored, that's `Bedtime.standard` (10:30pm). |

### CaffeineDecayFeature

Tested with an exhaustive `TestStore`, with all three use cases overridden.

| ID | Requirement |
|----|-------------|
| DECAY-1 | `task` subscribes to the curve, and each curve is reduced into `State`. |
| DECAY-2 | `task` subscribes to the status, and each status is reduced into `State`. |
| DECAY-3 | `task` subscribes to the time of day, and each time of day is reduced into `State`. |
| DECAY-4 | `summary` is `nil` before the first status, `.clear` when nothing counts, both tips while the last cup is on its way to half gone, and only the level at bedtime after that. |

### Dependency registrations

Each repository and use case is registered with live, test, and preview values (constitution Article I.15). A use case's values are built from its repository key's values directly, not through `@Dependency`. Dependency values are cached, so a lookup would capture whichever repository was current the first time, including one test's override.

| ID | Requirement |
|----|-------------|
| DEP-1 | `\.userProfileRepository` is a `LiveUserProfileRepository`, and `\.currentTimeRepository` is a `LiveCurrentTimeRepository`. Tests check this in the preview context, whose values are the live ones, because tests never read the live context. |
| DEP-2 | In a test, using a repository or use case that hasn't been overridden reports an issue. |
| DEP-3 | Each use case holds the one app-scoped repository that its repository key provides. |
| DEP-4 | `\.observeCaffeineStatus` holds the app-scoped `\.caffeineDecayRepository`. The preview repository opens an in-memory store, so this test runs inside the serialized `SwiftDataStoreTests`. |

### UI

| ID | Requirement |
|----|-------------|
| UI-1 | Launching the app shows the Today screen, with a greeting for the time of day. |
| UI-2 | The Today screen passes the system accessibility audit (constitution Article VI.4). |
| UI-3 | The Today screen shows the caffeine in your system now, in milligrams, and its decay curve. |

## Still to decide

- **The day periods' boundaries**, and whether a late-night greeting should differ from the evening one.
- **The next bedtime after bedtime has passed.** Tomorrow's, as designed, or no bedtime tip until morning.
- **The cutoff rule** for the Last Cup card. The prototype derives 2:30pm from a 10:30pm bedtime ("A normal cup drunk at 2:30pm is down to about 25 mg by 10:30pm"). That needs a reference cup and a threshold, or a fixed number of hours before bedtime. It's decided with the Last Cup card and onboarding (rank 6).
- **How "most common" is counted** for one-tap favourites (also open in <doc:DrinkComposer>).
- **What History shows**: the prototype's "Logged today" list, with delete waiting for Delete + undo (rank 20), or the whole log.
- **When the screen refreshes on returning to the foreground** (deferred in <doc:CaffeineDecayModel>). The time of day keeps ticking while the app is in memory, but `.task` doesn't restart on foregrounding.
