# Today Screen

The screen a user opens the app to: a greeting, the caffeine in their system now, and what they've had today.

## Overview

The Today screen is roadmap rank 4, "the only thing a reviewer opens the app and sees." It's a root feature, `TodayFeature`, composed of one child feature per card. Each child observes its own data through use cases, so the cards are independent of each other (constitution Article I.4–6).

| Feature | Shows | Use cases | Repositories | Status |
|---------|-------|-----------|--------------|--------|
| `DailyGreetingFeature` | A greeting for the time of day, with the user's name, and today's date | `ObserveUserProfileUseCase`, `ObserveTimeOfDayUseCase` | `UserProfileRepository`, `CurrentTimeRepository` | Built, and shown in the Today slot of the app's root, `AppFeature` |
| `CaffeineDecayFeature` | The caffeine in your system now, two tips, and the decay curve | ``ObserveCaffeineCurveUseCase``, `ObserveCaffeineStatusUseCase`, `ObserveTimeOfDayUseCase` | ``CaffeineDecayRepository``, `CurrentTimeRepository` | Built, and shown under the greeting |
| ``CaffeineIntakeTodayFeature`` | Today's total. The prototype's bar waits for a daily ceiling (see "Today tile" below) | ``ObserveCaffeineIntakeTodayUseCase`` | ``DrinkLogRepository`` | Built, and shown in the leading half of the tile row under the decay card |
| ``LastCupFeature`` | The cutoff: the latest time the usual drink still leaves no more than the sleep threshold at bedtime (<doc:CaffeineCutoff>) | ``ObserveCaffeineCutoffUseCase`` | ``CaffeineDecayRepository`` | Built, and shown in the trailing half of the tile row, beside the "Today" tile |
| ``OneTapLogFeature`` | The three favourite drinks, each logged in one tap (<doc:OneTapLog>) | ``ObserveFavouriteDrinksUseCase``, ``LogDrinkUseCase`` | ``FavouriteDrinksRepository``, ``DrinkLogRepository`` | Built, and shown under the tile row, headed "One tap" |
| ``DrinkLogHistoryFeature`` | One day of the drink log, its total, buttons for the day before and after, and deleting a drink (see "History card" below) | ``ObserveDrinkLogDayUseCase``, ``DeleteDrinkUseCase``, `ObserveTimeOfDayUseCase` | ``DrinkLogRepository``, `CurrentTimeRepository` | Built, and shown at the bottom of the screen, under the one-tap row |
| ``HealthSummaryFeature`` | Last night's sleep, or time in bed, today's steps, and today's resting heart rate, each only when Health has it (<doc:AppleHealthCard>) | ``ObserveHealthSummaryUseCase`` | ``HealthDataRepository`` | Built, and shown at the bottom of the screen, under the history card. It's hidden when there's nothing to show. |

The owner set this composition and each feature's repositories on 2026-09-11. The greeting and the decay card came first because they don't need the drink log, which the drink composer's work built (<doc:DrinkComposer>). The "Today" tile followed on 2026-09-12, and the other three followed it the same day.

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

What the user has told the app about themselves. Onboarding fills it in (<doc:Onboarding>). The greeting uses only the `name`, which is `nil` until the user gives it. On 2026-09-11 the owner moved the name to a low-priority item in the roadmap's backlog, because the greeting works without it. On 2026-09-12 the owner added it to the onboarding survey (roadmap rank 6), along with the age and the factors that change the half-life. The bedtime keeps its own data source (<doc:Onboarding>).

### Repositories and data sources

| Repository | Publishes | Data source |
|------------|-----------|-------------|
| `CurrentTimeRepository` | The current time as soon as it's subscribed to, then again at the start of every whole minute | `ClockDataSource` |
| `UserProfileRepository` | The current `UserProfile` as soon as it's subscribed to | `UserProfileDataSource` |

- **`CurrentTimeRepository`** is shared with the drink composer, which reads its `now()` to time a logged drink (<doc:DrinkComposer>). The owner chose on 2026-09-11 to reuse it rather than add a second clock repository for the greeting, and the drink composer's work built it. Its data is the clock, so it publishes every minute on purpose. That's unlike ``CaffeineDecayRepository``'s curve, which never recalculates on a timer.
- **`ClockDataSource`** is the only code that reads the system clock. Its `minutes()` stream yields the current time as soon as it's subscribed to, and then once at every whole minute. The live `SystemClockDataSource` sleeps until the next minute starts. If the app is suspended past a minute, it yields the time it wakes at, so it never publishes a stale minute. The decay card's status stream will share this data source.
- **`UserProfileDataSource`** returns the stored profile, or `nil` when nothing has been stored. ``FileProfileDataSource`` stores it in a protected file, and signals each change, so the greeting follows the name onboarding saves (<doc:Onboarding>).

### ObserveTimeOfDayUseCase

It turns each minute that `CurrentTimeRepository` streams into a `TimeOfDay`, with the period from `DayPeriodRule`. Use cases that execute a business rule are exceptions the owner approved; everywhere else, repositories do (constitution Article I.10). The owner chose this one on 2026-09-11, over a second clock repository. `ObserveRestingHeartRateComparisonUseCase` and `ObserveStepsComparisonUseCase` followed on 2026-09-13, each combining two repositories' streams (<doc:Insights>).

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

- `status(in:)` publishes a status as soon as it's subscribed to. After that, it publishes a new one at every whole minute from `ClockDataSource`, and whenever the drink data source signals a change (REPO-7 to REPO-10 in <doc:CaffeineDecayModel>). It also publishes a new one when the bedtime or the half-life changes, because the profile data source signals after each store (REPO-11 and REPO-12 in <doc:Onboarding>).
- The figure and the tips come from ``CaffeineStatusRule``, a Domain business rule that the repository executes, so no feature evaluates the decay function (VIEW-1 in <doc:CaffeineDecayModel>). It sums levels with ``CaffeineDecayRule``, so the figure, the tips, and the curve always agree. The current level replaces VIEW-3's "found by date" lookup.
- "Half of your last cup is gone by" follows Bateman absorption (rank 5), which replaced instant absorption on 2026-09-12. That changed the rule, not the entity. The cup is half gone once its own level falls back to half its dose, after its peak. ``CaffeineDecayRule`` finds that moment by bisection, because the Bateman function has no closed-form inverse.
- A drink logged this minute counts as in your system, although none of its caffeine has reached the body yet. So the card shows its tips, not "Nothing in your system right now", while the figure is still 0 mg.
- **The bedtime** is a ``Bedtime``: a time of day, not a date. Until onboarding (rank 6) or Settings (<doc:Settings>) stores one, it's 10:30pm, the prototype's example. The repository reads it from `BedtimeDataSource`, and ``FileProfileDataSource`` returns the one onboarding saved, or that default when nothing is saved. The Last Cup card's cutoff will share it.
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

`State.timeSpan` is the curve's window: from its first level to one spacing past its last, where the window ends, or `nil` until the curve has two levels (DECAY-6). The levels are evenly spaced, and each stands for the interval up to the next, so a 24-hour window's two ends share a clock time. The view labels the curve's ends with it, and pins the chart's time axis to it.

### The card

- **The figure** is the level now, rounded to whole milligrams, in `metricHero` light (80 pt at the default size, scaled with `@ScaledMetric(relativeTo: .largeTitle)`) and the accent color. Its "mg" is set at 45% of that size in `textSecondary`. The amount is a `Measurement` formatted with `usage: .asProvided`, so it stays in milligrams in every locale (constitution Article VII.3). The figure appears once the first status arrives.
- **The sentence** uses the same whole-milligram amounts, and clock times formatted for the locale.
- **The curve** shows the whole 24-hour window in Swift Charts: an area under a 2.5 pt `dataCaffeine` line, with a dashed rule and a dot at the current level. It's 160 pt high (`Sizing.curveHeight`), and Swift Charts draws no axes.
- **The curve's times** sit under its left and right edges: the start and end of its window, each as a day and a clock time, such as "Today, 3:50 AM" and "Tomorrow, 3:50 AM". They're in `caption` `textSecondary` with monospaced digits. A `DateFormatter` with the short date and time styles and `doesRelativeDateFormatting` writes them, so the day names and the order come from the locale (constitution Article VII.3). The chart's time axis is pinned to `State.timeSpan`, so each label sits exactly under the edge it names. The amount axis stays unlabelled, because the figure above says what the curve measures.
  - The owner asked for them on 2026-09-13, because the curve had no context along its time axis.
  - The first build showed only the clock times of the first and last levels, such as "3:50 AM" and "3:49 AM". The owner pointed out that they read as a minute apart on a 24-hour curve. They were offered a day and time, a weekday and time, relative hours such as "12h ago", or ticks every 6 hours, and chose a day and time. Relative hours would drift, because the curve recalculates only when its data changes, not as time passes.
  - The window's end is one minute past its last level, a sliver of the chart's width, so both ends show the same clock time.
  - At large Dynamic Type sizes each label wraps rather than truncating.
- **VoiceOver** reads the heading and the time as one element, "In your system now, 3:24 PM", then the figure's amount in full, "85 milligrams". The curve's label is "Caffeine over the day", and Swift Charts adds its own audio graph. The curve's times follow as one element, "From Today, 3:50 AM to Tomorrow, 3:50 AM".
  - That element combines its text rather than ignoring it, so it keeps the static-text trait. Built with its text ignored, it had no traits, and the accessibility audit failed it as a control with too small a hit area.
  - The first build hid the heading from VoiceOver, because the figure repeated it. The accessibility audit flags visible text that VoiceOver can't reach ("Potentially inaccessible text"), so the heading is readable and the figure no longer repeats it.
- **The AI chose, still to be confirmed:**
  - the wording "Nothing in your system right now." when nothing is counting
  - showing the whole window rather than, say, the next few hours
  - rounding every amount to whole milligrams, with "about" in the sentence rather than a range

## Today tile

The prototype's "TODAY" tile shows the caffeine logged so far today, "192 mg", above a bar (screenshot 07). Half-Life's tile shows the total only.

- **No bar yet.** A bar needs a daily ceiling, and nothing stores one. On 2026-09-12 the owner chose the total alone over a bar against a standard 400 mg ceiling. The AI's question said onboarding would ask for a ceiling, but the onboarding design, written the same morning, cut that question because no feature used a ceiling yet (<doc:Onboarding>). So where a ceiling comes from is still to decide.
- **Half width.** The tile takes the leading half of a two-tile row under the decay card, as in the prototype. The "Last cup" tile takes the trailing half (<doc:CaffeineCutoff>). At accessibility text sizes the row stacks, and each tile spans the card's width. The owner chose this on 2026-09-12, over a full-width tile that would narrow when Last Cup arrived.

### DailyCaffeineIntake

The caffeine the user logged on one calendar day.

| Property | Type | Meaning |
|----------|------|---------|
| `day` | `Date` | The day's midnight, in the calendar it was calculated in |
| `milligrams` | `Double` | The caffeine in every drink consumed that day, as each was logged |

### DailyCaffeineIntakeRule

A Domain business rule that totals the drinks consumed on the calendar day a moment falls in.

- **A day runs from midnight to midnight** in the given calendar: its midnight is included, and the next midnight isn't. So the day follows the user's time zone, and it lasts 23 or 25 hours on the days the clocks change.
- **Each drink counts with the milligrams it was logged with.** That includes drinks the decay model has marked negligible, since the total is about what was drunk, not what's left.
- **A drink counts by when it was consumed**, not when it was logged. A drink logged after midnight as "2h ago" counts toward yesterday.
- Like ``DayPeriodRule``, it reads no clock and holds no state.

### Where the total comes from

``DrinkLogRepository`` publishes it on a second stream, `intakeToday(in:)`, and executes ``DailyCaffeineIntakeRule`` itself (constitution Article I.10).

- **The calendar is the subscriber's.** The feature passes TCA's `\.calendar`, as the greeting and the decay card do.
- **A subscriber gets the current day's intake as soon as it subscribes.** After that, it gets a new intake when the drink data source signals a change that alters the day's total, and at the first minute of each new day, when the total starts again from 0 mg.
- **Each subscriber gets only changes.** The repository remembers the last intake it sent each subscriber and skips an equal one. So logging a drink for yesterday, or a minute passing, sends nothing (constitution Article I.12).
- **The clock's minutes cost almost nothing.** ``LiveDrinkLogRepository`` follows ``ClockDataSource``'s minutes once it has an intake subscriber, but reads the drinks only at a minute when some subscriber's day has turned.
- **One subscription to the data source serves both streams.** The drinks and the intakes are recalculated from one read after each change.
- **The alternative wasn't used.** A use case could have combined ``ObserveLoggedDrinksUseCase`` with the current time and executed the rule itself, as ``ObserveTimeOfDayUseCase`` does. That use case is the one exception the owner allowed. A repository executes every other business rule, so this one does too.

### CaffeineIntakeTodayFeature

Its only command is `task`, which subscribes through ``ObserveCaffeineIntakeTodayUseCase``. Each intake becomes an `intakeUpdated` action, and the reducer stores it in `State`. Until the first intake arrives, the tile shows only its heading.

### The tile

- **The heading** is "TODAY", in the `eyebrow` style.
- **The amount** is rounded to whole milligrams and formatted with `CaffeineFormat.milligrams`, so it stays in milligrams in every locale (constitution Article VII.3). It's set in the Design System's `metric` style, 22 pt regular scaling with `title2`, with monospaced digits. A day with nothing logged shows "0 mg".
- **The amount wraps rather than truncating.** The half-width tile first failed the accessibility audit's text-clipping check on the amount ("may be clipped at larger Dynamic Type sizes"). Letting it grow vertically, as the decay card's heading and sentence do, fixed it.
- **VoiceOver** reads the tile as one element, "Today, 192 milligrams".
- The tile is a small card: `surfaceCard`, the `medium` corner radius, `cardPaddingCompact`, and the `card` elevation with its `borderCard` hairline.
- **The AI chose, still to be confirmed:**
  - The amount's color. It's `textAccent`, following the Design System's rule that caffeine figures set as text use it. The prototype sets it in near-black.
  - Showing "0 mg" rather than hiding the amount on a day with nothing logged.

## History card

The bottom of the Today screen shows one day of the drink log. It's the prototype's "Logged today" list (screenshot 09), with buttons to reach earlier days. The owner asked for it on 2026-09-12: the day's drinks, buttons to switch days, and a way to delete a drink. A deleted drink also leaves the decay curve and the day's total.

### DrinkLogDay

One calendar day of the log.

| Property | Type | Meaning |
|----------|------|---------|
| `intake` | ``DailyCaffeineIntake`` | The day's midnight, and the caffeine in every drink consumed that day |
| `drinks` | `[LoggedDrink]` | The drinks consumed that day, oldest first |

``DrinkLogDayRule`` is the business rule that picks a day out of the whole log. It asks ``DailyCaffeineIntakeRule`` for the day's intake, so the history card's total and the "Today" tile follow one definition of a day and its total. Drinks marked negligible are included, because the mark only tells the decay curve to skip them. Like the other rules, it holds no state and reads no clock.

### Where the day comes from

The owner chose on 2026-09-12 that ``DrinkLogRepository`` publishes the day. The alternatives were a use case that narrows the whole log, or the reducer filtering it. The repository gained two operations:

- **`day(containing:in:)`** streams the calendar day that a date falls in, in the given calendar. A new subscriber gets the day immediately. After that, it gets a new day only when a change that the drink data source signals alters it. A day is fixed, so the stream never follows the clock.
- **`delete(_:)`** has the drink data source delete the drink. The data source signals a change after a deletion, as it does after a store (SRC-5 to SRC-7 in <doc:DrinkComposer>).

### Deleting a drink

A deletion reaches everything that shows the drink through the data source the repositories share, following the drink composer's data flow (<doc:DrinkComposer>). No use case writes twice, and no repository tells another one.

```
 Command:  × then Delete ─▶ Action ─▶ Reducer ─▶ DeleteDrinkUseCase ─▶ DrinkLogRepository.delete ─▶ DrinkLogDataSource.delete
 Update:   DrinkLogDataSource change ─┬─▶ DrinkLogRepository: re-read drinks ─▶ every drink, today's intake, each observed day
                                      ├─▶ CaffeineDecayRepository: re-read active intakes ─▶ rules ─▶ curve, status, cutoff
                                      └─▶ FavouriteDrinksRepository: re-read drinks ─▶ favourites
```

- **The curve and the status recalculate.** ``CaffeineDecayRepository`` re-reads the drinks that aren't marked negligible, so the deleted drink leaves the curve, the figure, and the tips. A drink already marked negligible adds nothing to them, so deleting it changes only the log.
- **The totals recalculate.** The "Today" tile's intake and the history card's day are recalculated from the drinks that remain.
- **Nothing is removed optimistically.** The reducer doesn't remove the drink from `State`. The card waits for the repository to publish the day without it (constitution Article I.5).
- **`DrinkDeletionTests` proves the path** with both live repositories over one data source, as the app wires them. Deleting the day of drinks' 3:00pm cup recalculates the curve, the status, and today's intake without it (DELETE-3).

### DeleteDrinkUseCase and ObserveDrinkLogDayUseCase

- **``DeleteDrinkUseCase``** takes a drink's identifier and deletes it through ``DrinkLogRepository``. It passes on any error the repository throws.
- **``ObserveDrinkLogDayUseCase``** takes a date and a calendar, and streams the repository's day. The reducer passes TCA's `\.calendar`, as the greeting does.

Both are registered in `DrinkLogDependencies.swift` as `\.deleteDrink` and `\.observeDrinkLogDay`, built from the drink log repository's key (constitution Article I.15).

### DrinkLogHistoryFeature

- **It opens on today.** It learns the day from `ObserveTimeOfDayUseCase`, like the greeting. When midnight passes, a card showing today moves to the new day. A card showing an earlier day stays on it, and that day is now one further back.
- **Previous and Next move a day at a time.** Next is disabled on today, so the card never shows a day that hasn't happened. Previous has no limit.
- **Today returns to today** from any earlier day. The owner asked for it on 2026-09-12. It shows only on an earlier day, to the left of Previous and Next.
- **Changing the day keeps the card in place.** The card keeps the last day in `State` until the next one arrives, and shows it invisible, untouchable, and hidden from VoiceOver in the meantime. The first build cleared the day at once. For a moment the card disappeared, the Today screen shrank, and the scroll view clamped its offset, which left the screen scrolled away from the card, 102 pt in the UI test. The owner reported it on 2026-09-12.
- **It observes only the day it shows.** Moving to another day cancels the old observation. So does the view leaving the screen, through `disappeared`, because the day's observation starts from an action after `task`, not from `task` alone. When the view comes back, `task` observes the day it was showing again.
- **Deleting asks first.** A drink's × turns into Keep and Delete. Only Delete reaches ``DeleteDrinkUseCase``. Moving to another day, or the drink leaving the day, ends the question. The owner chose a confirmation on 2026-09-12, because there's no undo until Delete + undo (roadmap rank 20).
- **A failed deletion says so.** The card shows "The drink couldn't be deleted. Try again." under the total until the next attempt. The reducer logs the error's domain and code, and never the drink (constitution Article XI.6.4).

### The card

- **The title** is an eyebrow above the card, like the prototype's "LOGGED TODAY": "Logged today", "Logged yesterday", or "Logged on" and the date, such as "Logged on Tuesday, Sep 8". It has the header trait. The date is formatted with `Date.FormatStyle` (constitution Article VII.3).
- **The day buttons** sit beside the title: round 44 pt buttons with a left and a right chevron, labeled "Previous day" and "Next day" for VoiceOver. A disabled Next has a dimmed chevron, and VoiceOver announces it as dimmed, so color isn't the only signal (Article VI.3).
- **Today** is a capsule in the style of Keep, 44 pt high, before the chevrons, with the hint "Shows the drinks logged today." At accessibility text sizes, the buttons sit under the title, so the title keeps its width.
- **Each row** shows the time, the drink's name above its quantity ("Latte" and "2 shots"), the caffeine in `textAccent`, and a ×. VoiceOver reads the time, name, quantity, and caffeine as one element, and the × as "Delete Latte at 9:15 AM". At accessibility text sizes, the row's details stack (Article VI.2).
- **A demo drink is labeled "Demo"**, in a small capsule under its quantity, so a drink Settings added is never mistaken for one the user logged. The label is text, so VoiceOver reads it with the row, and color isn't the signal (<doc:Settings>).
- **While a drink waits to be deleted**, its row shows Keep and Delete below its details, in place of the ×. Delete is the dark primary button, and its hint says it removes the drink from the log and the caffeine curve. The owner was offered a confirmation dialog. The AI built the confirmation into the row instead, so that every control carries an identifier from `DrinkLogHistoryViewAccessibilityID` for the robot to find it by (Article II.6–7). Whether a system dialog's buttons would expose identifiers wasn't tested.
- **The total** closes the card, such as "TOTAL 192 mg". A day with no drinks says "No drinks logged." above a total of 0 mg.
- **The AI chose, still to be confirmed:**
  - Previous going back without limit, rather than stopping at the first logged day
  - Today as a text button shown only on an earlier day, rather than always shown and disabled on today
  - drinks listed oldest first, as in the prototype
  - Keep and Delete in the row, rather than a system dialog
  - the wording "No drinks logged." and "Removes the drink from your log and your caffeine curve."
  - showing the total at the bottom of the card, although the "Today" tile shows today's too

### Privacy and logging

Deleting a drink removes its record from the SwiftData store on the device, which doesn't sync (<doc:DrinkComposer>). No copy is kept. A successful deletion is a routine health event, so it isn't logged. A failed one is logged at `error`, with the error's domain and code, and no drink data (Article XI.6–7).

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
| TODAY-3 | The "Today" tile's actions reach `CaffeineIntakeTodayFeature`, and its state changes appear under `TodayFeature.State.caffeineIntakeToday`. |
| TODAY-4 | The history card's actions reach `DrinkLogHistoryFeature`, and its state changes appear under `TodayFeature.State.history`. |
| TODAY-5 | The Apple Health card's actions reach `HealthSummaryFeature`, and its state changes appear under `TodayFeature.State.healthSummary` (<doc:AppleHealthCard>). |

### DailyCaffeineIntakeRule

Unit-tested directly. The rule is pure, so its tests need no fakes.

| ID | Requirement |
|----|-------------|
| INTAKE-1 | The intake is the sum of the milligrams of the drinks consumed on the calendar day that the given moment falls in, from its midnight, included, to the next midnight, excluded. Its `day` is that midnight. |
| INTAKE-2 | A day with no drinks is 0 mg. |
| INTAKE-3 | The day is the given calendar's: the same drinks can total differently in another time zone. |
| INTAKE-4 | A day the clocks change on is still one calendar day. A drink at 11:30pm on a 25-hour day counts. |

### DrinkLogRepository: today's intake

Tested against a fake drink log data source and a fake clock. DLOG-1 to DLOG-4 are in <doc:DrinkComposer>.

| ID | Requirement |
|----|-------------|
| DLOG-5 | A new subscriber immediately gets the current day's intake, counting drinks marked negligible too. |
| DLOG-6 | After the data source signals a change that alters the day's total, every subscriber gets the new intake. A change that leaves the total alone sends nothing. |
| DLOG-7 | At the first minute the clock streams on a new day, a subscriber gets the new day's intake. The other minutes send nothing. |
| DLOG-8 | Each subscriber's day is in its own calendar. |
| DLOG-9 | The drinks stream and the intake stream share one subscription to the data source's changes. |

### ObserveCaffeineIntakeTodayUseCase

| ID | Requirement |
|----|-------------|
| OBSINTAKE-1 | It streams every intake the repository publishes for the calendar it's given, in order. |

### CaffeineIntakeTodayFeature

Tested with an exhaustive `TestStore`, with the use case overridden.

| ID | Requirement |
|----|-------------|
| TILE-1 | `task` subscribes to today's intake in the `\.calendar` dependency, and each intake is reduced into `State`. |

### DrinkLogDayRule

Unit-tested directly. The rule is pure, so its tests need no fakes.

| ID | Requirement |
|----|-------------|
| HISTRULE-1 | The day holds exactly the drinks consumed on the calendar day that the given moment falls in, in the order given. A day with no drinks is empty, at 0 mg. |
| HISTRULE-2 | The day's midnight is included, and the next midnight isn't. |
| HISTRULE-3 | The day's intake is ``DailyCaffeineIntakeRule``'s for the same moment and calendar. |
| HISTRULE-4 | The day is the given calendar's: the same moment can fall on another day in another time zone. |

### DrinkLogRepository: a day of the log, and deleting

Tested against a fake drink log data source and a fake clock.

| ID | Requirement |
|----|-------------|
| DAYLOG-1 | A new subscriber immediately gets the day containing the moment it gives, in its own calendar, counting drinks marked negligible too. It can ask for any day, including a past one. |
| DAYLOG-2 | After the data source signals a change that alters a subscriber's day, the subscriber gets the new day. A change that leaves the day alone sends nothing. |
| DAYLOG-3 | The drinks, intake, and day streams share one subscription to the data source's changes. |
| DELETE-1 | `delete(_:)` has the data source delete the drink, and the change it signals updates every stream. |
| DELETE-2 | A failed deletion throws and publishes nothing. |
| DELETE-3 | With both live repositories over one data source, a deletion through ``DrinkLogRepository`` recalculates the decay curve, the caffeine status, and today's intake without the drink. |

### ObserveDrinkLogDayUseCase and DeleteDrinkUseCase

Tested against the fake drink log repository.

| ID | Requirement |
|----|-------------|
| HISTUSE-1 | ``ObserveDrinkLogDayUseCase`` streams every day the repository publishes for the date and calendar it's given, in order. |
| HISTUSE-2 | ``DeleteDrinkUseCase`` deletes the drink with the given identifier through the repository. |
| HISTUSE-3 | Any error the repository throws reaches the caller of ``DeleteDrinkUseCase``. |

### DrinkLogHistoryFeature

Tested with an exhaustive `TestStore`, with every use case built on fakes.

| ID | Requirement |
|----|-------------|
| HIST-1 | `task` follows the time of day, shows today, and observes its drinks. When the view comes back, `task` observes the day showing again. Leaving the screen stops the observation. |
| HIST-2 | Previous and Next move a day at a time, and each day is observed in place of the last. Next does nothing on today, and Previous does nothing before the first day arrives. |
| HIST-3 | At midnight, a card showing today moves to the new day. A card showing an earlier day stays on it, a day further back. Another minute on the same day changes nothing. |
| HIST-4 | A day other than the one showing is ignored. |
| HIST-5 | The × only asks. Delete reaches ``DeleteDrinkUseCase``, Keep doesn't, and confirming with nothing asked does nothing. |
| HIST-6 | A failed deletion shows an error until the next attempt. |
| HIST-7 | The question about a drink ends when the drink leaves the day, or the day changes. |
| HIST-8 | The title names today, yesterday, or the date, and Next is offered only before today. |
| HIST-9 | Today returns the card to today from an earlier day, and does nothing on today. It's offered only on an earlier day. |
| HIST-10 | Changing the day keeps the last day in `State` until the next one arrives, and the card knows it isn't showing its selected day until then. |

### Bedtime

| ID | Requirement |
|----|-------------|
| BED-1 | Until the user sets one, the bedtime is 10:30pm. |
| BED-2 | A bedtime is a real time of day, from 0:00 to 23:59. Anything else isn't created. |
| BED-3 | The next bedtime is the first time it comes round at or after a given moment, in a given calendar: tonight's before bedtime and exactly at it, and tomorrow's after it. The decay card and the cutoff (<doc:CaffeineCutoff>) both use it. |

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
| DECAY-6 | `timeSpan` is `nil` until the curve has two levels, and runs from its first level to one spacing past its last after that. |

### Dependency registrations

Each repository and use case is registered with live, test, and preview values (constitution Article I.15). A use case's values are built from its repository key's values directly, not through `@Dependency`. Dependency values are cached, so a lookup would capture whichever repository was current the first time, including one test's override.

| ID | Requirement |
|----|-------------|
| DEP-1 | `\.userProfileRepository` is a `LiveUserProfileRepository`, and `\.currentTimeRepository` is a `LiveCurrentTimeRepository`. Tests check this in the preview context, whose values are the live ones, because tests never read the live context. |
| DEP-2 | In a test, using a repository or use case that hasn't been overridden reports an issue. |
| DEP-3 | Each use case holds the one app-scoped repository that its repository key provides. |
| DEP-4 | `\.observeCaffeineStatus` holds the app-scoped `\.caffeineDecayRepository`. The preview repository opens an in-memory store, so this test runs inside the serialized `SwiftDataStoreTests`. |
| DEP-5 | `\.observeCaffeineIntakeToday` holds the app-scoped `\.drinkLogRepository`. Like DEP-4, it runs inside `SwiftDataStoreTests`. |
| DEP-6 | `\.observeDrinkLogDay` and `\.deleteDrink` hold the app-scoped `\.drinkLogRepository`. Like DEP-4, they run inside `SwiftDataStoreTests`. |

### UI

| ID | Requirement |
|----|-------------|
| UI-1 | Launching the app shows the Today screen, with a greeting for the time of day. |
| UI-2 | The Today screen passes the system accessibility audit (constitution Article VI.4), twice. At launch, contrast is ignored only for elements under the tab bar or in its fade, 44 pt above the log button, and for issues with no element. Scrolled to the end, contrast is ignored only for elements that reach above where the content started at rest, and only if the first audit checked them in full. The owner approved the first two on 2026-09-12 (<doc:OneTapLog>), and the last on 2026-09-13 (<doc:Settings>). |
| UI-3 | The Today screen shows the caffeine in your system now, in milligrams, and its decay curve, labelled with the day and clock time at each of its two ends. |
| UI-4 | The Today screen shows the caffeine logged today, in milligrams. |
| UI-5 | Logging a drink adds its caffeine to today's total. The test compares the total before and after logging one espresso shot, allowing 1 mg for rounding. Each UI test starts with an empty drink log (LAUNCH-3 in <doc:Onboarding>), but the comparison doesn't depend on that. It would fail if midnight passed between the two readings. |
| UI-6 | The history card opens on today, and lists a drink logged through the composer. |
| UI-7 | Deleting a drink asks first. Keep leaves the list alone, and Delete removes one drink. Each UI test starts with an empty drink log (LAUNCH-3 in <doc:Onboarding>), so the test logs a drink first. |
| UI-8 | The day buttons move to yesterday and back, and Next is disabled on today. |
| UI-10 | Today returns the card to today from two days back, and shows only on an earlier day. |
| UI-11 | Changing the day, back and then forward, leaves the card's title where it was on screen, within 1 pt. |
| UI-9 | The history card passes the accessibility audit, with and without a deletion waiting for confirmation. The test first scrolls until the card's total is above the log button, so the whole card is audited clear of the tab bar. It then audits with `auditAccessibilityAboveTheTabBar()`, like every screen in the root tab bar (<doc:Architecture>), so only the cards still under the bar are exempt from the contrast check. |

## Still to decide

- **The day periods' boundaries**, and whether a late-night greeting should differ from the evening one.
- **The next bedtime after bedtime has passed.** Tomorrow's, as designed, or no bedtime tip until morning.
- **The "Today" tile's bar**: whether it needs one, which ceiling it fills against, and how it shows a day over the ceiling without relying on color. The onboarding design suggests a ceiling could come from its half-life factors rather than a new question (<doc:Onboarding>).
- **How far back the history card goes.** Previous has no limit. It could stop at the first logged day.
- **Undo after deleting** (Delete + undo, rank 20). Until then, the history card asks before it deletes.
- **When the screen refreshes on returning to the foreground** (deferred in <doc:CaffeineDecayModel>). The time of day keeps ticking while the app is in memory, but `.task` doesn't restart on foregrounding.
