# Insights

The Insights tab: what the caffeine the user logged means for tonight's sleep, and what their own nights say about it.

## Overview

The brief asks for correlations between caffeine and Apple Health's data, shown "cleanly, and beautifully", and for a longitudinal profile of the user's habits. The prototype put these on a Patterns screen. Half-Life calls the tab **Insights**, because it answers the app's one question, *when*, rather than charting totals. It sits between Today and Settings in the tab bar, as `AppTab.insights`.

The tab has four cards:

| Card | What it shows | Status |
|------|---------------|--------|
| What we noticed | An optional finding about the user's own nights, which the on-device language model puts into words, with "Feel right?" | **Built.** |
| Best time to sleep tonight | When the caffeine already logged falls below the sleep threshold, and a 90-minute window to fall asleep in | **Built** |
| The last 7 days | Each day's caffeine against the sleep that followed it, with a selectable day | **Built**, with sleep from `HealthDataRepository` (<doc:AppleHealthCard>) |
| Against your caffeine | A button for each kind of Health data with any data (sleep, steps, and resting heart rate), each opening its own screen | **Built,** with a screen for each kind (see "Sleep", "Steps", and "Resting heart rate") |

**The rules calculate, and the model only phrases.** Every number on the tab comes from a business rule, so nothing on it can disagree with the Today screen. The model writes sentences around numbers it's given, and never works one out (<doc:LanguageModel>).

## What changed from the prototype

| Prototype (screenshots 12 and 13) | Half-Life | Why |
|-----------------------------------|-----------|-----|
| "Patterns" | "Insights" | The owner's choice. The tab reads the user's data, and doesn't only chart it. |
| A 7D / 30D / 90D picker | None. The 7-day card covers 7 days, and the comparisons 30 days. | Each card has the range that suits it. A picker added a choice without adding an answer. |
| "Caffeine after 2:30pm costs you 41 min of deep sleep" | Facts from a rule, phrased by the model, with how many nights back them | The app never claims minutes of sleep lost (<doc:CaffeineCutoff>, "How confident the app is"). The brief grades *Honesty*. |
| Caffeine "drops under 55 mg" | The sleep threshold: the user's caffeine tolerance once their nights show one, and 40 mg until then | 55 mg is unsourced. The threshold is the one the cutoff uses, from the same data source, so the window and the "Last cup" tile always agree (<doc:CaffeineCutoff>). |
| A bar from 6pm to 5:33am with a "best window" | A line chart of the caffeine from 6pm to 4am, the threshold, and the window | The curve shows *why* the window is where it is. |
| "Strong link", "Moderate link", "Weak link" beside each comparison | A button per kind, with its symbol, which opens that kind's screen | The owner's choice on 2026-09-13. A week of nights can't support "strong", and the comparison belongs on the kind's own screen, with room to say how many nights back it. |
| Deep sleep, time to fall asleep, and steps | Sleep, steps, and resting heart rate: one button per kind of data read from HealthKit. Deep sleep and time to fall asleep belong on the sleep screen. | The brief asks about heart rate. The owner chose one button per HealthKit kind on 2026-09-13. |
| "Deep sleep −41 min" and "Time to fall asleep +18 min" | A Sleep screen: each night's time asleep and time to fall asleep charted against the caffeine at sleep onset, the averages either side of the threshold, and a caffeine tolerance that sets the threshold | The owner's design on 2026-09-13. Caffeine at sleep onset asks the app's one question, *when*, directly. Time asleep works with every tracker, where deep sleep needs one that records stages. The screen never claims minutes lost. |

## The owner's decisions

The owner made these decisions on 2026-09-12, from 22:43 to 23:10.

| Question | Decision |
|----------|----------|
| The window's start | When caffeine clears. When it clears before the user's bedtime, the card says so, and the window starts at the bedtime. |
| The window's length | 90 minutes, one sleep cycle |
| Caffeine that clears after 4am | The chart extends to the window's end |
| "Feel right?" | Every answer is stored on the device, "Yes" included, for the model's text. "Yes" hides only the question. "Not really" dismisses the card until its facts change. |
| The comparisons' period | The last 30 days |
| Resting heart rate | A row in the comparisons |
| Demo data | The demo drinks and demo Health data cover 30 days (<doc:Settings>, <doc:AppleHealthCard>) |
| Reaching the tab in UI tests | `AppRobot` finds the tab's button by its title, from `AppTab` (constitution Article II.6) |
| The comparisons card (2026-09-13, about 10:22) | A set of buttons, one per kind of Health data the app reads: sleep, steps, and resting heart rate. Each shows the kind's symbol instead of a link strength, and opens its own screen. It drifts from the prototype on purpose. |
| The kinds' screens (the same time) | Navigation first. Their content is to be designed with the owner once the navigation is built. |
| The resting heart rate screen (12:03, in half-life-28's session) | The next day's resting heart rate after caffeine nights, against the other days, over 30 days. A headline, the two groups, and a 30-day dot chart. A finding only with 5 days in each group, and a pattern only beyond twice the standard error. A use case that combines two repositories' streams and executes the rule. |
| One caffeine night (confirmed at 12:30, in half-life-28's session) | Caffeine at the recorded sleep onset, over the threshold, or at the bedtime with no recorded sleep, from one shared stream, which ``SleepToleranceRepository`` publishes (see "Resting heart rate") |
| The Sleep screen (answered at 12:00 and 12:12) | Two analyses over the last 30 days: time asleep against the caffeine at sleep onset, which finds the user's caffeine tolerance, and the time to fall asleep against it. A scatter chart of nights, and 5 nights on each side before a difference shows (see "Sleep"). |
| The caffeine tolerance (the same time) | Where time asleep starts to drop, clamped to 20 to 80 mg either way, adopted automatically as the sleep threshold in place of 40 mg, and set by the demo's nights while the demo switch is on (see "Sleep") |

## What we noticed

The first card is one finding about the user's own nights, which the rules work out and Apple Intelligence's on-device model puts into words. It's optional: it's hidden while the model is unavailable, including in a language the model doesn't support (<doc:LanguageModel>), without enough nights, and after the user says it doesn't feel right. **Status: built** on 2026-09-13. Its audit with the card showing fails for a known reason (see "Known issues"). The owner decided its design on 2026-09-13, from 11:16 to 12:1x.

### The finding

Over the last 30 days, it compares the nights the user fell asleep with more than the sleep threshold in their body, against the nights with the threshold or less, by **time asleep**.

The Sleep screen's analysis finds the nights and compares them (``SleepToleranceRule``), and card 1 turns its comparison into the finding (``SleepPatternRule``):

- **A night** is a stretch of sleep of at least 3 hours, grouped as ``SleepNightRule`` groups them, from any tracker, with or without stages. Time in bed alone isn't sleep, so it doesn't count. A night counts if it ended in the 30 days, and began once drinks had been logged for 2 days.
- **Its caffeine** is ``CaffeineDecayRule``'s level at the moment Health says the user **fell asleep**: the start of the night's first stretch of sleep. It uses the drinks of the week before, and the curve's half-life and absorption.
- **The threshold** is the user's learned tolerance, or 40 mg without one.
- **The direction** compares the two groups' average time asleep: **shorter** or **longer** on the nights over the threshold, or **about the same** when the averages are less than **15 minutes** apart.
- **The confidence** comes from the smaller group: fewer than 5 nights is too few, and the card is hidden; 5 to 9 is **"an early sign"**; 10 or more is **"consistent so far"**.

The finding never says caffeine caused anything, never says how much sleep was lost, and never gives advice. It gives the model the direction only, not the averages.

### The model's prompts

The owner reviewed and approved these on 2026-09-13. At 15:43 the same day, the owner moved the facts from the `compareCaffeineTiming` tool into the prompt, after a context audit (<doc:LanguageModel>). So the rules that named the tool now name the facts. At 17:15, the owner found a headline that only named the grouping of nights, and a sentence that only listed the counts, and asked for a headline that says what the finding means, with a sentence that explains it. So the facts gained a "What it means" line, which the rules word for each direction, and the headline and sentence rules changed. The line says "slept longer", not "slept better", because the finding compares time asleep, not how well the user slept. At 17:38, the owner's log showed that the model refused that first version (`refusal`, not the context window). It asked what the facts meant for the user's sleep, and its line generalized ("you tend to sleep longer"), which reads to the model like interpreting the user's health. So the line now describes the user's own nights in the past tense, a rule says where the facts come from, and the owner reworded the prompt to ask what the app has discovered from the data. That was refused too. At 17:46 the owner chose to have the rules write the headline, such as "You get more sleep at 40 mg or less", and the model write only the sentence on how the nights support it, because the model had written counts of nights without a refusal before the refinement. The "What it means" line, and the rule about where the facts come from, were dropped, because neither stopped the refusal and both added health framing. The headline says "more", not "the most", because the finding compares only two groups of nights.

- **The session's instructions** are the standing rules every session gets (<doc:LanguageModel>), including "Answer in" the user's language, named from the locale, with every number taken from the facts, plus these:

  ```text
  You're writing the one finding on the user's Insights card, from the facts in the prompt.
  Use the facts' headline as the headline, in the user's language.
  Write one sentence of at most 25 words that says how the nights in the facts support the headline.
  Use the facts' confidence words exactly: "an early sign" or "consistent so far".
  Describe a pattern in the user's nights. Never say caffeine caused, cost, or took away sleep, and never say how much sleep the user lost.
  Don't give advice, and don't tell the user what to do.
  If the user disagreed with an earlier finding, take a different approach from that one.
  ```

- **The session has no tools.** The prompt gives the finding with every number already formatted.
- **The prompt** asks for the facts' headline and how the data supports it, then gives the facts:

  ```text
  Write today's finding for the user's Insights card: the facts' headline, and one sentence that says how the data supports it.
  ```

  ```text
  The facts:
  Period: the last 30 days, Aug 14 to Sep 12.
  Caffeine when you fell asleep: over 40 mg on 6 nights, 40 mg or under on 17 nights.
  Nights counted: 23.
  Time asleep: shorter on the nights over 40 mg than on the others.
  Headline: You get more sleep at 40 mg or less.
  Confidence: an early sign.
  7 nights aren't counted: no sleep was recorded, or no drinks were logged before them yet.
  ```

  The rules write the headline for each direction:

  | Direction | Headline |
  |-----------|----------|
  | Shorter on the nights over the threshold | You get more sleep at 40 mg or less |
  | Longer on the nights over the threshold | You get more sleep above 40 mg |
  | About the same | Your sleep is about the same either side of 40 mg |

  After a "Not really", it adds the finding the user disagreed with:

  ```text
  The user disagreed with this earlier finding:
  Headline: "…"
  Sentence: "…"
  Take a different approach from the one in that finding.
  ```

- **The answer** is guided generation into two fields, capped at 150 tokens. The headline's guide asks for the facts' headline, in the user's language. The sentence's guide asks for one sentence of at most 25 words that says how the nights in the facts support the headline, with the confidence words. The rules write the headline for the finding's own direction, so the model never has to choose one. The Foundation Models layer gains guided generation for it.
- **A number check** discards any answer that holds a number the facts don't, and the card stays hidden. So the facts give the total nights too, which the owner added on 2026-09-13, and the model copies the sum rather than calculating it.

### "Feel right?"

- **"Yes"** hides the question, and the card stays.
- **"Not really"** hides the card until the confidence changes.
- **Every answer is stored,** with the finding's confidence, headline, and sentence, in a file on the device only, protected with `NSFileProtectionComplete` and never synced or logged. It's the user's reaction to their own sleep. The last "Not really" goes into the next prompt.

### One definition, one source

On 2026-09-13 the owner decided:
- **Every comparison on the tab shares one definition of a caffeine night:** caffeine at the sleep onset Health recorded, over the sleep threshold. The Steps and Resting heart rate screens fall back to the bedtime on days with no recorded sleep.
- **The sleep threshold is the user's learned tolerance.** The Sleep screen learns it, and it applies app-wide (see "Sleep").
- **Card 1 builds on the Sleep screen's analysis** of caffeine at sleep onset against time asleep, rather than a repository of its own. So there's one source for those numbers.

### How it's built, in slices

1. **The finding's rule:** `SleepPattern` and `SleepPatternRule`. Built. It first found its own nights, which duplicated the Sleep screen's analysis, so once that landed, on 2026-09-13, it kept only the step from the analysis to the finding.
2. **The data:** the Sleep screen's analysis, through ``ObserveSleepCaffeineAnalysisUseCase``, and the answers' file data source. Built.
3. **The model:** an insight's session with the rules above, the facts in the prompt, guided generation, and the number check. Built (<doc:LanguageModel>). The card passes the finding it holds with the request, and the prompt gives it, so the model's words can't disagree with the card. It first gave the facts through a `compareCaffeineTiming` tool, which the owner replaced on 2026-09-13, so the model has no tool to call again and again.
4. **The card:** ``ObserveInsightCardUseCase``, ``WhatWeNoticedFeature``, and ``WhatWeNoticedView`` are built. ``InsightsView`` shows the card first, and starts its task, because a hidden view can't start its own. Its UI tests use the simulated model under a launch key (<doc:LanguageModel>), with the demo's nights.

## Best time to sleep tonight

The card answers one question: when will the caffeine already logged be out of the way tonight?

### The night

The card is always about one night, which runs from **6pm to 4am** in the user's calendar. From 6pm until 4am it's the night already running, and from 4am until 6pm it's the coming one. So at 3am the card still shows the night the user is in, and at 5am it moves on.

The night's bedtime is the first time the user's bedtime comes round at or after 6pm, so a bedtime of 12:30am belongs to the night before it.

### When caffeine clears

``SleepWindowRule`` asks ``CaffeineDecayRule`` for the level at every whole minute from 6pm to noon the next day. Caffeine **clears** at the first whole minute after which every level is at or below the sleep threshold.

- **The clearing time is the minute after the last one over the threshold,** not the first under it. A cup at 8pm starts from nothing, rises over the threshold, and falls again. The card waits for that fall.
- **With nothing over the threshold from 6pm on,** caffeine has cleared by 6pm.
- **With caffeine still over the threshold at noon,** it doesn't clear, and there's no window. With the standard half-life, that takes a very large or very late dose. It happens mostly with a long personal half-life.
- **The threshold** comes from ``SleepThresholdDataSource``, the same data source the cutoff reads, so the two always agree.

### The window

The window lasts **90 minutes**, about one sleep cycle. It starts at the later of the clearing time and the bedtime:

| Caffeine clears | The window starts | The card says |
|-----------------|-------------------|---------------|
| By the bedtime | At the bedtime | Caffeine should be under 40 mg by your bedtime |
| After the bedtime | When caffeine clears | Caffeine should drop under 40 mg at about 12:24 AM, after your bedtime |
| Not by noon | There's no window | Caffeine should stay over 40 mg until after noon tomorrow |

### The chart

The chart shows the level at every minute from 6pm to **4am**, or to the window's end when that's later. With no window, it runs to noon. It draws:

- the caffeine as a line, in `dataCaffeine`
- the threshold as a dashed rule, labeled with its amount
- the window as a shaded band, in `dataSleep`

Its start and end are labeled with their times, so the window's position doesn't depend on color (constitution Article VI.3). VoiceOver reads the chart as one element, with the card's summary as its value.

### Confidence

The window is a starting point, not a measurement of the user. The footnote says so, and names where the threshold comes from, as the owner decided on 2026-09-13. Once the user's nights show a trend: "35 mg is where your time asleep starts to drop, from the trend in your recent nights." Until then: "Until your nights show a trend, this is 40 mg, a level clinical sleep studies support for the average person." The learned threshold comes from time asleep alone, so the footnote doesn't mention time to fall asleep (``SleepThreshold/Source``). It never says "safe", and never promises better sleep (<doc:CaffeineCutoff>, "How confident the app is").

The card's sentence is a localized template for now. The design gives it a sentence phrased by the language model, around the same numbers. The template stays as the fallback while the model is unavailable.

### Domain and data

- **``SleepWindow``** holds the night's evening, its bedtime, the clearing time or `nil`, the window or `nil`, the chart's end, the threshold, and the chart's levels. `clearsBeforeBedtime` is `true` when caffeine clears at or before the bedtime.
- **``SleepWindowRule``** calculates it from the intakes, the kinetics, the threshold, the bedtime, the current time, and a calendar. It holds no state and reads no clock.
- **``CaffeineDecayRepository/sleepWindow(in:)``** streams it. ``LiveCaffeineDecayRepository`` reads the same inputs as the cutoff, apart from the usual drink. It recalculates on the same events: a change the drink log, the half-life, or the bedtime signals, and each whole minute. It sends a subscriber a window only when it differs from the last one sent, so the minutes send nothing until the night changes at 4am.
- **``ObserveSleepWindowUseCase``** streams the windows for the calendar it's given.

### Presentation

- **``InsightsFeature``** is the tab's feature. ``AppFeature`` scopes it at `State.insights`. For now it holds one child: ``SleepWindowFeature``, at `State.sleepWindow`.
- **``SleepWindowFeature``** has one command, `task`, which subscribes through ``ObserveSleepWindowUseCase`` in the `\.calendar` dependency. Each window becomes a `windowUpdated` action, which the reducer stores in `State`.
- **``InsightsView``** stacks its cards in a scroll view over the page gradient, under the title "Insights". ``SleepWindowView`` is the card. It draws its chart, and phrases its summary, with ``SleepWindowChart``, which Siri's answer to "When should I go to sleep?" shares, so the two always look and read the same (<doc:AppIntents>).

### Accessibility identifiers

`InsightsViewAccessibilityID`: `screen`, `content`, `sleepWindowCard`, `sleepWindowTimes`, `sleepWindowSummary`, and `sleepWindowChart`, and for the last 7 days, `weekCard`, a column for each day from `weekColumn7DaysAgo` to `weekColumn1DayAgo` (listed in order as `weekColumns`), `weekDetailTitle`, `weekDetailCaffeine`, `weekDetailSleep`, `weekDetailLastCup`, `weekSleepSource`, and `weekSleepNote`, and for the Health data card, `healthDataCard`, `healthDataSleepButton`, `healthDataStepsButton`, and `healthDataRestingHeartRateButton`. `InsightsRobot` uses them, with its Health data commands in `InsightsRobot+HealthData.swift`. For "What we noticed", they're `noticedCard`, `noticedHeadline`, `noticedSentence`, `noticedDemo`, `feelRightYes`, and `feelRightNotReally`, with its commands in `InsightsRobot+WhatWeNoticed.swift`. Each kind's screen has its own identifiers, listed in its section ("Sleep", "Steps", and "Resting heart rate").

## The last 7 days

The card sets each of the last 7 days' caffeine against the sleep that followed it, from Apple Health, or from the demo while Settings' demo Health data switch is on (<doc:AppleHealthCard>).

### What it shows

- **A column for each of the 7 days before today,** oldest first, yesterday last. Today is left out, because its night hasn't happened yet, as the owner decided on 2026-09-13. Each is a button with the day's caffeine as a bar, scaled to the week's largest day, over its weekday. A day with no caffeine keeps a short stub, so every column can be seen and chosen. Once there's sleep, the night's time asleep hangs below the weekday as a second bar, scaled to the week's longest night.
- **The chosen day's details** under the columns: its name ("Today", "Yesterday", or its weekday), its caffeine, its sleep, and its last cup, or "None". Today is chosen until the user chooses another day, and again once the chosen day leaves the week at midnight.
- **Under the details,** "Sleep from Apple Health" or "Demo sleep data" says where the sleep comes from (the brief asks the app to "say clearly what's seeded vs. live"). With no sleep for any night, the sleep detail and bars are left out, and a note says "Sleep appears here when Apple Health has it."

The chosen column has a bold label, a full-color bar, and an outline, so it never depends on color alone (constitution Article VI.3). VoiceOver reads each column as its day's name and caffeine, and the chosen one as selected. At accessibility text sizes, the weekdays shorten to one letter and the details stack.

### Sleep

- **Each day pairs with the night that follows it:** the night whose last sleep ends from noon that day to noon the next, as ``LastNightSleepRule`` finds it for the Today card (<doc:AppleHealthCard>). So the two cards always agree on a night. Today's night hasn't happened, so today's sleep reads "Tonight".
- **A past night with nothing recorded** reads "Not recorded". It never reads 0, because HealthKit doesn't reveal whether read access was denied.
- **A night with time in bed and no sleep** gets no sleep bar, because time in bed isn't sleep, and its details are labeled "In bed" instead of "Slept". This is the AI's choice, still to be confirmed.
- **With no sleep from Health at all,** the card still shows the caffeine, with the note above. This is the AI's choice, still to be confirmed.
- **Sleep is read once,** for every night together, from noon the day before the first night to noon today, where last night's window ends. The Today card reads to the same noon, so a night that hasn't finished gives both the same answer.

### Domain and data

- **``DrinkLogDayRule/days(endingOn:count:from:calendar:)``** gives the last `count` days, oldest first, each as the rule's single day, so the card and the Today screen's history card always agree.
- **``DrinkLogRepository/recentDays(_:in:)``** streams them. ``LiveDrinkLogRepository`` recalculates after each change the data source signals and at the first minute of each new day, and sends a subscriber the days only when they change. It reads every drink, including the ones the decay repository marked negligible, because a day's total counts every drink.
- **``ObserveDrinkLogWeekUseCase``** streams the last 7 days for the calendar it's given.
- **``LastSevenDaysFeature``** holds the days and the chosen day. `task` subscribes, each set becomes a `daysUpdated` action, and `daySelected` chooses a day. `selected` is the chosen day while it's in the week, or today.
- **``SleepHistoryRule``** finds each day's night with ``LastNightSleepRule``, and gives the range to read sleep for. ``SleepHistory`` holds the nights, and whether they're the demo's.
- **``HealthDataRepository/sleepHistory(days:in:)``** streams the history. ``LiveHealthDataRepository`` reads the data sources the summary reads, on the same events: a change they signal, the demo switch, Health access becoming requested, and the first minute of a new day. It sends a subscriber a history only when it changes, and while Health access hasn't been requested, every night is empty. The code is in `LiveHealthDataRepository+SleepHistory.swift`. The summary's requirements, HREPO-1 to HREPO-8, are in <doc:AppleHealthCard>.
- **``ObserveSleepWeekUseCase``** streams the last 7 nights. ``LastSevenDaysFeature``'s `task` runs it beside the drinks, and each history becomes a `sleepUpdated` action. `night(after:)` finds a day's night.
- **``LastSevenDaysView``** is the card, under the sleep window.

## Against your caffeine

The card is a set of buttons, one for each kind of Health data the app reads from HealthKit: **sleep**, **steps**, and **resting heart rate**. Each opens its kind's screen, which sets that kind against the user's caffeine (see "Sleep", "Steps", and "Resting heart rate").

### What it shows

- **A button for each kind with any data** in the last 30 days, in a fixed order: sleep, steps, then resting heart rate. A kind with no data has no button, and with none, the card and its heading "Against your caffeine" aren't in the layout at all.
- **Each button** shows the kind's SF Symbol, the Today card's, in its data color on a light tile (`bed.double.fill` in `dataSleep`, `figure.walk` in `dataActivity`, `heart.fill` in `dataHeart`), then its name and a chevron. The name says what the button is, so color is never the only signal (constitution Article VI.3), and the symbols are hidden from VoiceOver.
- **Tapping a button** pushes the kind's screen onto the tab's navigation stack. Its name is a heading in the content, not the navigation bar's title, so its robot can find it by identifier (Article II.6).

### When a kind has data

``HealthDataAvailabilityRule`` decides. **Sleep** is available when Health recorded any sleep, with or without a stage. Time in bed or awake alone isn't sleep (<doc:AppleHealthCard>), so it doesn't count. **Steps** and **resting heart rate** are available when any day has a value, and a step count of 0 is a value. HealthKit doesn't reveal a denial, so a kind the user didn't allow looks like a kind with no data, and has no button.

### Domain and data

- **``HealthDataKind``** is the three kinds, in the buttons' order.
- **``HealthDataRepository/availableKinds(days:in:)``** streams the kinds with data. ``LiveHealthDataRepository`` reads the sleep since the first day in one query, and each day's steps and resting heart rate from today back, stopping at the first day with a value. It reads the data sources the summary reads, on the same events, follows the demo switch, and sends a subscriber the kinds only when they change. While Health access hasn't been requested, no kind is available. The code is in `LiveHealthDataRepository+Availability.swift`.
- **``ObserveAvailableHealthDataUseCase``** streams the kinds for the last 30 days.

### Presentation

- **``HealthDataListFeature``** holds the available kinds. `task` subscribes, each set becomes a `kindsUpdated` action, and `kindTapped` is the button a user tapped. `kinds` is the buttons, in order, and `isShown` hides the card with none. ``InsightsView`` starts its `task`, because a hidden card can't start its own.
- **``InsightsFeature``** answers `kindTapped` by pushing that kind's screen onto its `StackState` path, through its `Path` reducer (constitution Article I.6): ``SleepDetailFeature``, ``StepsDetailFeature``, or ``HeartRateDetailFeature``.
- **``HealthDataListView``** is the card, under the last 7 days.

## Sleep

The Sleep screen answers two questions about the user's own nights: how much caffeine can be in them when they fall asleep before their time asleep drops, and does more of it go with taking longer to fall asleep? The sleep button on the "Against your caffeine" card opens it. **Status: built.**

### The owner's decisions

The owner designed the screen with the AI on 2026-09-13, answering at 12:00 and 12:12.

| Question | Decision |
|----------|----------|
| What the screen analyses | Two things, over the last 30 days: each night's time asleep against the caffeine in the body at sleep onset, which finds the user's caffeine tolerance, and the time to fall asleep against the same caffeine |
| The tolerance | "The caffeine level the user gets the best sleep at", driving the cutoff and the charts' threshold in place of the standard one. Taken literally, the best sleep is almost always at about 0 mg, so the owner chose where time asleep starts to drop. |
| Its limits | 20 to 80 mg, either way |
| Adopting it | Automatically, as the personal half-life is (<doc:HalfLifeEstimator>) |
| The demo | The demo's nights set it while the demo switch is on, so a reviewer sees it move the cutoff |
| How many nights | 5 on each side of the threshold before a difference shows |
| The chart | A scatter of nights |
| The analysis's wording (14:47) | It describes the user's sleep and doesn't mention the cutoff, which the Today screen shows. With a tolerance, it's hedged: "Sleep is shaped by many things, but the trend in your nights is that with more than 35 mg in you at sleep onset, you sleep less." The owner's note said "you sleep more". The AI pointed out that the tolerance exists only when sleep falls, and the owner chose "less". The no-drop sentence drops the cutoff too. |
| The analysis card (~14:5x, between the AI's clock readings at 14:48 and 14:58) | The analysis moves out of the time asleep card into a card of its own above both charts, and its message describes both. The time to fall asleep is named longer or shorter only when the averages differ by more than 5 minutes, and "about as quickly" otherwise. |

The owner's message gave the standard threshold as 45 mg. It's 40 mg in the app (<doc:CaffeineCutoff>), and the tolerance replaces that.

### Nights

- **A night** is a session of sleep, grouped as ``SleepNightRule`` groups it, with at least 3 hours of sleep, recorded with or without stages. It runs from its first sleep to its last, and its time asleep counts overlapping trackers once. So an iPhone's sleep schedule, which records no stages, gives nights too.
- **The period** is today and the 29 days before it, in the user's calendar. A night counts when it ended in it, before the current time.
- **A night counts once drinks have been logged for 2 days before it,** as for the half-life estimator, so a night from before the user started logging doesn't read as 0 mg. With no drinks, there are no nights.
- **The caffeine at sleep onset** is ``CaffeineDecayRule``'s level at the night's first sleep, from the drinks of the week before it, with the curve's half-life, so it agrees with the Today screen.
- **The time to fall asleep** runs from the start of the time in bed that holds the onset, to the onset. Only a night with time in bed around its onset has one.
- **Drinks.** With the demo switch off, demo drinks are left out, because real sleep says nothing about them. With it on, every drink counts, because the demo's nights follow the demo's drinks.

### The caffeine tolerance

The tolerance is where the user's time asleep starts to drop.

1. Each whole 5 mg from 20 to 80 mg is a candidate.
2. For each candidate, a "hockey-stick" line is fitted to the nights by least squares: level up to the candidate, then sloping.
3. A candidate needs 5 nights on each side, and a line that falls. Caffeine is only allowed to shorten sleep, so a flat or rising line says nothing.
4. The candidate whose line leaves the least squared error is the tolerance. On a tie, the lower one wins.

With no candidate that qualifies, there's no tolerance, and the threshold stays at 40 mg.

**The app adopts it automatically.** ``LiveSleepToleranceRepository`` stores it, and ``PersonalSleepThresholdDataSource`` serves it to the decay model as the sleep threshold. So the "Last cup" tile, the drink composer's warning, the cutoff reminders, the sleep window, and every comparison on this tab switch to it together (<doc:CaffeineCutoff>). ``AppFeature`` keeps it current from launch, so the Sleep screen doesn't have to be open. The screen itself doesn't mention the cutoff: the owner chose on 2026-09-13 that it describes the user's sleep, and leaves the cutoff to the Today screen.

**How confident it is.** A tolerance from 30 nights is a starting point, not a measurement. Time asleep varies from night to night for many reasons, and a fit can find a small drop by chance. The limits keep one noisy month from moving the cutoff to the morning or to dawn. The screen shows how many nights sit on each side, and calls what it shows "a pattern in your own nights, not proof that caffeine caused it" (<doc:CaffeineCutoff>, "How confident the app is").

### What it shows

- The title, "Sleep", with the sleep symbol.
- **The analysis card,** "What your nights show", above both charts. A headline about time asleep, and a sentence that describes both charts: time asleep, and the time to fall asleep, on the nights over the threshold in use. With a tolerance, it's hedged ("Sleep is shaped by many things, but the trend in your nights is…"), and it never mentions the cutoff. The time to fall asleep is named longer or shorter only when the averages differ by more than 5 minutes.
- **The time asleep card.** A scatter chart with a dot for each night, its caffeine at sleep onset across and its time asleep up, with the threshold in use as a dashed rule. Under it, each side's average time asleep, with its number of nights, once each side has 5.
- **The time to fall asleep card.** The same chart and averages for the nights with time in bed. Without them, a note says why: too few nights, or no time in bed recorded.
- **A footnote,** on a card's surface: what the screen compares, that it's a pattern, not proof, and "Sleep from Apple Health" or "Demo sleep data".

| Finding | Headline | Sentence |
|---------|----------|----------|
| A tolerance | Your sleep holds up to about 55 mg | Sleep is shaped by many things, but the trend in your nights is that with more than 55 mg in you at sleep onset, you sleep less and take longer to fall asleep. With the time to fall asleep about the same, shorter, or not yet comparable, the sentence says that instead. |
| 5 nights on each side of 40 mg, but no drop | Your sleep hasn't dropped with caffeine so far | More caffeine at sleep onset hasn't gone with less sleep, or with taking longer to fall asleep, in your nights so far. With a longer or shorter time to fall asleep, or too few nights with time in bed, the sentence says that instead. |
| Too few nights | Not enough nights to say yet | This needs at least 5 nights on each side of 40 mg to compare your time asleep and how quickly you fall asleep. So far, 12 at or under it and 3 over it. |

Nights at or under the threshold are circles in `dataSleep`, and nights over it are triangles in `dataCaffeine`, and a legend names them, so the groups never depend on color alone (constitution Article VI.3). VoiceOver reads each chart as one element, with the averages, or the number of nights, as its value. At accessibility text sizes, the averages stack.

### Demo data

With both demo switches on, the demo's 30 days give a tolerance and both comparisons (DEMOTOL-1), so the screen, and "What we noticed", have something to say. The demo's late cups leave the nights after them later to start and shorter (<doc:AppleHealthCard>).

### Domain and data

- **``SleepToleranceRule``** finds the nights, the tolerance, and the comparisons. It holds no state and reads no clock. It also gives every recognised night's onset, before the period too, for ``CaffeineNightRule``, so the tab has one night definition.
- **``SleepCaffeineAnalysis``** holds the nights (``SleepCaffeineNight``), the tolerance (``SleepTolerance``), the two comparisons (``SleepComparison``), the period, its 30 days, and whether the sleep is the demo's. Its `threshold` is the tolerance, or the standard one.
- **``SleepToleranceRepository``** publishes the analysis, and each night's caffeine (see "Resting heart rate"). ``LiveSleepToleranceRepository`` reads Apple Health's sleep, or the demo's while the switch is on, and waits for Health access as ``HealthDataRepository`` does. It shares the demo switch with it, through ``DemoHealthDataFlagDataSourceKey``. It recalculates after a change to the drinks, the half-life, the bedtime, the switch, or the chosen sleep, at the first minute of a new day, and when Health access is first requested. It stores the tolerance, none included, whenever it changes, and sends each subscriber a value only when it changed. Its caffeine nights are in `LiveSleepToleranceRepository+CaffeineNights.swift`, and storing the tolerance in `LiveSleepToleranceRepository+Storage.swift`.
- **``FileSleepToleranceDataSource``** stores the tolerance in `SleepTolerance.json`, and ``PersonalSleepThresholdDataSource`` serves it to ``CaffeineDecayRepository``, which now also recalculates when the threshold changes.
- **``ObserveSleepCaffeineAnalysisUseCase``** streams the analysis, **``ObserveCaffeineNightsUseCase``** streams 31 caffeine nights, and **``KeepSleepToleranceCurrentUseCase``** keeps the tolerance current for as long as it runs.

### Presentation

- **``SleepDetailFeature``** holds the analysis. `task` subscribes, and each analysis becomes an `analysisUpdated` action. `finding` is the tolerance, no drop, or too few nights, counted on each side of the threshold in use, `nightsWithTimeInBed` counts the nights with a time to fall asleep, and `fallingAsleep` is longer, shorter, about the same, or unknown, with a 5-minute band.
- **``InsightsFeature``** pushes it onto its path when the sleep button is tapped, as the `sleep` case of its `Path`.
- **``SleepDetailView``** is the screen, and ``SleepCaffeineChart`` draws each chart.

### Accessibility identifiers

`SleepDetailViewAccessibilityID`: `screen`, `title`, `analysisCard`, `finding`, `timeAsleepCard`, `timeAsleepChart`, `timeAsleepComparison`, `fallingAsleepCard`, `fallingAsleepNote`, `fallingAsleepChart`, `fallingAsleepComparison`, and `source`. `SleepDetailRobot` uses them.

### Privacy and logging

The tolerance is the only thing the screen stores. It's derived from sleep, so it stays on the device, with complete file protection, left out of iCloud backups, and never synced (constitution Articles V.3.4 and V.4). No value, count, night, or tolerance is logged (Article XI.6). Storing the tolerance logs a fixed message at `debug`, and a failure to read or store logs its error's domain and code at `error` (Article XI.7).

## Steps

The steps screen answers one question: does the user walk less the day after a caffeine night? The steps button on the "Against your caffeine" card opens it.

### What it compares

- **A caffeine night** is one with more than the sleep threshold of caffeine in the body when the user fell asleep, as Health recorded it, or at their bedtime when Health has no sleep for that night. Every Insights comparison shares this definition. ``CaffeineNightRule`` decides it once, and ``CaffeineNight/isCaffeineNight`` carries it.
- **Each of the 30 whole days before today** is set against the night before it. Today is left out, because its steps are still growing.
- **A day follows a caffeine night** when the night that began on the day before it was one, because that night's cost lands on the next day.
- **A day with no steps** counts on neither side, and shows in the chart as a gap.

### How confident it is

The verdict names a difference only when it's larger than the user's day-to-day swing explains.

| Verdict | When |
|---------|------|
| Too few days to compare yet | Either side has fewer than 5 days with steps |
| No clear difference | The difference is within twice its standard error |
| About 1,500 fewer (or more) steps after a caffeine night | The difference is beyond twice its standard error |

- **The standard error** comes from each side's own spread, so a user whose steps swing widely needs a bigger difference before the screen names one.
- **A named difference** is rounded to the nearest hundred steps, and the screen calls it "a pattern, not proof caffeine caused it". It never says caffeine caused it (<doc:CaffeineCutoff>, "How confident the app is").
- **Both sides' averages and day counts** always show, so the user can weigh the numbers themselves.

### What it shows

- The title "Steps", and the question "Do you walk less the day after a caffeine night?"
- **The verdict card:** the verdict, what it means, each side's average steps and day count ("None yet" for a side with no days), and what a caffeine night is, in words: "more than your recommended caffeine in you when you fell asleep, or at your bedtime if Apple Health has no sleep that night". "Your recommended caffeine" is the sleep threshold.
- **The chart card:** a bar for each day's steps. A day after a caffeine night has a stronger color and a coffee cup above its bar, `cup.and.saucer.fill`, the symbol the espresso drinks use, so the mark never depends on color alone (constitution Article VI.3). The first and last dates sit under it, and a legend explains the marks. VoiceOver reads the chart as one element, whose value is both sides' averages and day counts.
- "Steps from Apple Health" or "Demo steps" says where the steps come from.

At accessibility text sizes, the averages stack.

### The owner's decisions

The owner made these decisions on 2026-09-13.

| Question | Decision |
|----------|----------|
| What the screen compares (12:03) | Steps on the day after a caffeine night, against the other days, over the last 30 days. It was first the day after a "late cup", 90 mg or more from 3pm. |
| The caffeine night (12:23) | The definition every Insights comparison shares, in place of the late cup |
| The layout (12:03) | A verdict, and a strip of the 30 days |
| When a difference is named (12:03) | Beyond twice its standard error, with at least 5 days on each side |
| The demo (12:03) | The demo's steps keep no link to caffeine. Its sleep and resting heart rate change after caffeine, and its steps don't, so the screen doesn't invent a link where the demo has none. |
| Where the comparison is calculated (12:12) | In ``ObserveStepsComparisonUseCase``, which combines two repositories' streams. It's the second use case to execute a business rule, after ``ObserveTimeOfDayUseCase``. |
| The caffeine night's wording and mark (14:52) | The screen says what a caffeine night is in words, "more than your recommended caffeine", rather than the threshold's amount. The chart marks the days after one with a coffee cup, which says caffeine, in place of a moon, which said sleep. |

### Domain and data

- **``StepHistory``** holds the steps of each whole day before today, and whether they're the demo's. ``HealthDataRepository/stepHistory(days:in:)`` streams it. ``LiveHealthDataRepository`` reads each day's steps from the data sources the summary reads, on the same events, and sends a subscriber a history only when it changes. While Health access hasn't been requested, no day has steps. The code is in `LiveHealthDataRepository+StepHistory.swift`.
- **``StepsComparisonRule``** sets the days after a caffeine night against the others. **``StepsComparison``** holds the days, both sides, the verdict, the threshold, and whether the steps are the demo's.
- **``ObserveStepsComparisonUseCase``** combines the 31 caffeine nights from ``SleepToleranceRepository`` with the 30 days of steps, executes the rule on each pair, and sends a comparison only when it changes.

### Presentation

- **``InsightsFeature``** answers the steps button by pushing ``StepsDetailFeature`` onto its path, as `Path.steps`.
- **``StepsDetailFeature``**'s `task` subscribes to the comparison in the `\.calendar` dependency, and each comparison becomes a `comparisonUpdated` action.
- **``StepsDetailView``** is the screen. `StepsDetailViewAccessibilityID` has `screen`, `title`, `verdict`, `afterCaffeine`, `otherDays`, `definition`, `chart`, and `source`, which `StepsDetailRobot` uses.

## Resting heart rate

The screen the resting heart rate button opens. It asks one question: is the user's resting heart rate different on the day after a night that began with caffeine in them?

### Caffeine nights

Every comparison on the tab reads the same nights, so the Sleep, Steps, and Resting heart rate screens and "What we noticed" never disagree. The owner decided this on 2026-09-13, at about 12:20 in half-life-1c's session, and confirmed it for this screen at 12:30.

- **A night is measured when it began.** Its caffeine is ``CaffeineDecayRule``'s level at the sleep onset Apple Health recorded. A day's night is the first onset from noon that day to noon the next, so an onset after midnight belongs to the day before it. The onsets are the nights ``SleepToleranceRule`` recognises, so the Sleep screen's definition of a night is the only one.
- **A night with no recorded sleep falls back to the bedtime:** the first time the user's bedtime comes round at or after 6pm that day, as for the sleep window. Such a night is marked `.bedtime`, so a comparison of sleep that happened can leave it out.
- **A caffeine night** is one whose caffeine is over the sleep threshold, strictly. The threshold is the one the cutoff uses: the user's caffeine tolerance once the Sleep screen has found it, or 40 mg until then.
- **Every intake counts,** including the ones the decay repository has since marked negligible, because they counted that night.

``CaffeineNightRule`` calculates the nights, ``CaffeineNight`` and ``CaffeineNightHistory`` hold them, and ``SleepToleranceRepository`` publishes them with `caffeineNights(days:in:)`.

At 12:03 the owner had first chosen caffeine at the bedtime for this screen. That rule still exists, but only as the fallback for nights with no recorded sleep.

### What it compares

- **Each of the last 30 days with a resting heart rate** pairs with the night before it. A day with no reading, or with no night before it in the history, is left out. HealthKit doesn't reveal a denial, so a day the user didn't allow looks like a day with no reading.
- **The days split in two:** those after a caffeine night, and the others.
- **What the days show,** judged against the user's own day-to-day variation, as the owner chose at 12:03:

| The days | The screen says |
|----------|-----------------|
| Fewer than 5 in either group | "Not enough days yet", with how many each group has so far |
| A difference more than twice its standard error, and at least 1 bpm | The difference, such as "+3 bpm", and whether it was higher or lower |
| Anything else | "No clear difference": the heart rate stayed within its usual day-to-day range |

The standard error is Welch's: each group's sample variance over its size, summed, then square-rooted. The 1 bpm floor is the AI's addition, still to be confirmed. The screen shows whole beats per minute, so a smaller difference would read "+0 bpm". The rule never assumes a direction. A lower heart rate after caffeine nights is reported the same way.

The demo script raises the next day's resting heart rate by 3 bpm after a late cup, so the demo data shows a pattern. A simulation of the script, with the standard half-life, found the days after a caffeine night 2.5 to 3.1 bpm higher at thresholds from 40 to 60 mg, each more than twice its standard error. It's a simulation of the script, not a reading of the app.

### What it shows

- **A headline:** the difference in large type, or the finding in words, with a sentence under it that names the threshold.
- **The two groups,** side by side: each one's average and how many days it has. At accessibility text sizes they stack.
- **A dot for each day** over the last 30 days: filled after a caffeine night, hollow after the others. The fill, not the color, tells the groups apart (constitution Article VI.3), and a legend says what each means. VoiceOver reads the chart as one element, with both groups' averages as its value.
- **A footnote:** "A pattern in your own days, not proof that caffeine caused it. Resting heart rate also moves with exercise, illness, alcohol, and stress." When some nights had no recorded sleep, it says how many were measured at the bedtime. Under it, "Heart rate and sleep from Apple Health", or "Demo heart rate and sleep" while Settings' demo Health data switch is on (the brief asks the app to "say clearly what's seeded vs. live").

The app never says "strong link", never claims minutes or beats caused by caffeine, and never calls a finding safe. The brief grades *Honesty* (<doc:CaffeineCutoff>, "How confident the app is").

### Domain and data

- **``RestingHeartRateHistory``** holds each day's reading, oldest first, and whether it's the demo's. ``HealthDataRepository/restingHeartRates(days:in:)`` streams it. ``LiveHealthDataRepository`` reads each day's average from the chosen resting heart rate data source, on the summary's events, and sends a subscriber a history only when it changes. While Health access hasn't been requested, no day has a reading. The code is in `LiveHealthDataRepository+RestingHeartRate.swift`.
- **``RestingHeartRateComparisonRule``** pairs the days with the nights, and finds the groups and what they show. ``RestingHeartRateComparison`` holds the result.
- **``ObserveRestingHeartRateComparisonUseCase``** combines the latest caffeine nights, from ``SleepToleranceRepository``, with the latest resting heart rates, from ``HealthDataRepository``. It executes the rule once both have arrived, and again whenever either changes, and sends a comparison only when it differs from the last. It's one of the use cases that execute a business rule, each an exception the owner approved. The owner chose this one at 12:03 over giving one repository the other's data (<doc:Architecture>).

### Presentation

- **``HeartRateDetailFeature``** has one command, `task`, which subscribes through the use case in the `\.calendar` dependency. Each comparison becomes a `comparisonUpdated` action, which the reducer stores in `State`.
- **``InsightsFeature``** answers the resting heart rate button's `kindTapped` by pushing the feature onto its path, as `Path.restingHeartRate`.
- **``HeartRateDetailView``** is the screen. Its title is a heading in the content, like the other Health data screens, so its robot finds it by identifier.
- **Accessibility identifiers:** `HeartRateDetailViewAccessibilityID`: `screen`, `title`, `headline`, `headlineDetail`, `afterCaffeine`, `otherDays`, `chart`, `footnote`, and `source`, which `HeartRateDetailRobot` uses.

### Privacy and logging

Nothing on the screen is stored. The heart rates are read from Health when they're needed, and held only in memory (constitution Article V.3.4). No value, count, or finding is logged (Article XI.6).

## Privacy and logging

- **Nothing on the tab is stored,** apart from the caffeine tolerance (see "Sleep"), and the "Feel right?" answers, when that card is built. Those stay on the device, and aren't synced, because they're about the user's sleep (constitution Articles V.1 and V.3.4).
- **Values are never logged** (Article XI.6). That covers the clearing time, the window, and the levels, which are all derived from caffeine intake.
- **A failure to read the window's inputs is logged at `error`,** with the error's domain and code only.

## Testable requirements

Each requirement is written so that one test can prove it.

### SleepWindowRule

Unit-tested directly. The rule is pure, so its tests need no fakes. They check it against ``CaffeineDecayRule``'s levels.

| ID | Requirement |
|----|-------------|
| SLEEPWIN-1 | The night runs from 6pm to 4am in the given calendar. From 6pm until 4am it's the night already running, and from 4am until 6pm it's the coming one. |
| SLEEPWIN-2 | Caffeine clears at the first whole minute, from 6pm on, after which every whole minute's level until noon is at or below the threshold. With none over it, it clears at 6pm. A higher threshold clears sooner. |
| SLEEPWIN-3 | The bedtime is the first time the user's bedtime comes round at or after 6pm. |
| SLEEPWIN-4 | When caffeine clears after the bedtime, the window starts when it clears, and lasts 90 minutes. |
| SLEEPWIN-5 | When caffeine clears at or before the bedtime, the window starts at the bedtime, and lasts 90 minutes. |
| SLEEPWIN-6 | The chart ends at 4am, or at the window's end when that's later. |
| SLEEPWIN-7 | The chart holds ``CaffeineDecayRule``'s level at every whole minute from 6pm to its end. |
| SLEEPWIN-8 | When caffeine is still over the threshold at noon, there's no clearing time and no window, and the chart ends at noon. |
| SLEEPWIN-9 | The window starts on a whole minute. |

### The repository

Tested against fake data sources and a fake clock.

| ID | Requirement |
|----|-------------|
| SWREPO-1 | A new subscriber immediately receives the window for the current time, from ``SleepWindowRule``, with the intakes that still count, the kinetics, the threshold, and the bedtime, in the subscriber's calendar. |
| SWREPO-2 | After a change the drink log signals, a subscriber receives the recalculated window when it differs from the last one sent. |
| SWREPO-3 | A minute that doesn't change the window sends nothing. The minute the night changes, at 4am, sends the coming night's window. |
| SWREPO-4 | When an input can't be read, nothing is sent. |

### Use case, registration, and features

| ID | Requirement |
|----|-------------|
| SWUSE-1 | ``ObserveSleepWindowUseCase`` streams every window the repository publishes for the calendar it's given, in order. |
| DEP-SLEEPWIN | The use case holds the one app-scoped ``CaffeineDecayRepository``, and reports an issue in a test that doesn't override it. |
| SWCARD-1 | ``SleepWindowFeature``'s `task` subscribes to the window in the `\.calendar` dependency, and each window is reduced into `State`. |
| INSIGHTS-1 | ``InsightsFeature`` runs ``SleepWindowFeature`` at `State.sleepWindow`, and ``AppFeature`` runs ``InsightsFeature`` at `State.insights`. |
| INSIGHTS-2 | ``InsightsFeature`` runs ``LastSevenDaysFeature`` at `State.lastSevenDays`. |

### UI

| ID | Requirement |
|----|-------------|
| UI-INS-1 | The Insights tab opens from the tab bar, and Today opens again from its own. |
| UI-INS-2 | With the empty drink log UI tests start with, the card shows a window that starts at the bedtime, and says caffeine should be under the threshold by then. |
| UI-INS-3 | The Insights tab passes the accessibility audit. |
| UI-INS-4 | With the empty drink log UI tests start with, the last 7 days card has a column for each of the 7 days before today, and yesterday is chosen, with 0 mg and no last cup. With no Health data, it shows no sleep, and the note. |
| UI-INS-5 | A drink logged today isn't in the week, which ends yesterday. |
| UI-INS-6 | Choosing the column for 2 days ago shows its weekday and its caffeine. |
| UI-INS-7 | With last night's sleep in Apple Health, yesterday, the day chosen, shows last night's 7 hours. |
| UI-INS-8 | With last night's sleep in Apple Health, the Insights tab passes the accessibility audit. |
| UI-INS-9 | With no Health data, there's no Health data card. |
| UI-INS-10 | Each kind with data has a button: with sleep, steps, and resting heart rate, all three, and with only steps, only steps. |
| UI-INS-11 | Tapping the sleep button opens the Sleep screen. With last night's sleep and the empty drink log UI tests start with, no night counts, so it has too few nights to say, no chart, a note on the time to fall asleep, and "Sleep from Apple Health". |
| UI-INS-12 | The Sleep screen passes the accessibility audit. |
| UI-INS-13 | With the simulated model and both demo switches on, "What we noticed" shows a finding in the model's words, says it comes from the demo Health data, and asks "Feel right?". |
| UI-INS-14 | "Yes" keeps the finding, without the question. |
| UI-INS-15 | "Not really" hides the card. |
| UI-INS-16 | Without the language model, there's no card, even with the demo's nights. |
| UI-INS-17 | The tab passes the accessibility audit with the card showing. |
| UI-INS-18 | Until the user's nights show a trend, the sleep window's footnote says its threshold is one clinical sleep studies support for the average person. |
| UI-INS-19 | With the demo's nights, which show a trend, the footnote says the threshold comes from the user's time asleep. |
| UI-INS-20 | With the demo drinks, yesterday, the day chosen, has a last cup. |

### The last 7 days

| ID | Requirement |
|----|-------------|
| RECENTRULE-1 | ``DrinkLogDayRule/days(endingOn:count:from:calendar:)`` gives `count` days, oldest first, ending with the one the date falls in. |
| RECENTRULE-2 | Each day equals ``DrinkLogDayRule/day(containing:from:calendar:)``'s day, so a day with no drinks is empty. |
| RECENTRULE-3 | The days follow the calendar's time zone. |
| RECENTREPO-1 | A new subscriber immediately gets the days up to the current day, counting every drink, including the ones marked negligible. |
| RECENTREPO-2 | After a change the data source signals, a subscriber gets the days when they differ from the last ones sent. |
| RECENTREPO-3 | The first minute of a new day sends the days moved on by one. Other minutes send nothing. |
| RECENTREPO-4 | Each subscriber gets its own count, in its own calendar. |
| WEEKUSE-1 | ``ObserveDrinkLogWeekUseCase`` asks the repository for the 8 days to today in the calendar it's given, and streams the 7 before today, in order. A change to today alone sends nothing. |
| DEP-WEEK | The use case holds the one app-scoped ``DrinkLogRepository``, and reports an issue in a test that doesn't override it. |
| WEEKCARD-1 | ``LastSevenDaysFeature``'s `task` subscribes to the week in the `\.calendar` dependency, and each week is reduced into `State`. |
| WEEKCARD-2 | With no day chosen, yesterday, the last day, is selected. |
| WEEKCARD-3 | Choosing a day selects it, until it leaves the week, and then yesterday is selected. |
| WEEKCARD-4 | `task` also subscribes to the sleep week in the `\.calendar` dependency, and each history is reduced into `State`. A day's night is the history's night for it. |
| SLEEPHIST-1 | ``SleepHistoryRule`` gives one night per day, oldest first, and each past day's night is ``LastNightSleepRule``'s night ending from noon that day to noon the next. |
| SLEEPHIST-2 | Today's night is always empty. |
| SLEEPHIST-3 | A day with no sleep and no time in bed has an empty night. |
| SLEEPHIST-4 | Sleep is read once, from noon the day before the first night to noon today. The days follow the calendar's time zone. |
| SHREPO-1 | A new subscriber to ``HealthDataRepository/sleepHistory(days:in:)`` immediately gets the history from Apple Health. |
| SHREPO-2 | With the demo switch on, the history comes from the demo data sources, marked as demo. |
| SHREPO-3 | While Health access hasn't been requested, every night is empty. At the first minute access is requested, the history is read and sent. |
| SHREPO-4 | A change the sleep data source signals sends the new history. |
| SHREPO-5 | The first minute of a new day sends the history moved on by a day. Other minutes send nothing. |
| SHREPO-6 | Sleep that can't be read gives empty nights. |
| SLEEPUSE-1 | ``ObserveSleepWeekUseCase`` asks the repository for the nights after the 8 days to today in the calendar it's given, and streams the 7 before tonight's, in order. A history that doesn't change them sends nothing. |
| DEP-SLEEPWEEK | The use case holds the one app-scoped ``HealthDataRepository``, and reports an issue in a test that doesn't override it. |

### What we noticed

| ID | Requirement |
|----|-------------|
| PATTERN-1 | ``SleepPatternRule`` groups the nights as the analysis's comparison of time asleep does. Without one, it counts the nights over the threshold by their caffeine at sleep onset, a night at the threshold being under it, and they're too few. |
| PATTERN-2 | The nights over the threshold are shorter or longer when the groups' average time asleep is at least 15 minutes apart, and about the same otherwise. |
| PATTERN-3 | The smaller group's nights, on either side, set the confidence: fewer than 5 too few, 5 to 9 an early sign, 10 or more consistent so far. |
| PATTERN-4 | The threshold is the analysis's: the tolerance, or 40 mg without one. |
| PATTERN-5 | The days without a counted night aren't counted. |
| PATTERN-6 | The finding covers the analysis's period and days. |

What a night is, its caffeine, and its time asleep are the Sleep screen's requirements, TOL-1 to TOL-10. Until 2026-09-13, card 1 found its own nights, under PATTERN-1 to PATTERN-3 and PATTERN-7, and the owner decided card 1 would build on the Sleep screen's analysis instead.
| NUMCHECK-1 | ``InsightNumberRule`` passes a finding whose every number is in the facts. |
| NUMCHECK-2 | A number the facts don't hold fails the finding. |
| NUMCHECK-3 | A finding with no numbers passes. Numbers written as words aren't caught. |
| NUMCHECK-4 | Digits in any script are the same numbers, so "٦" is 6. |
| FEEDBACK-1 | With no answers, ``InsightFeedbackRule`` shows the card and asks "Feel right?". |
| FEEDBACK-2 | A "Not really" dismisses the card until the confidence changes. |
| FEEDBACK-3 | A "Yes" keeps the card but stops asking until the confidence changes. |
| FEEDBACK-4 | The next prompt's disagreement is the latest "Not really", at any confidence. |
| FEEDSTORE-1 | With no file, ``FileInsightFeedbackDataSource`` has no answers. |
| FEEDSTORE-2 | Every answer is kept, in order, across instances. |
| FEEDSTORE-3 | The file is written atomically, with `NSFileProtectionComplete`. |
| FEEDSTORE-4 | A file that can't be read throws. |
| FEEDSTORE-5 | The default file is `InsightFeedback.json` in Application Support. |
| FEEDREPO-1 | A new subscriber to ``InsightFeedbackRepository/feedback()`` gets the stored answers. |
| FEEDREPO-2 | A recorded answer is stored, and every subscriber gets the new set. |
| FEEDREPO-3 | An answer that can't be stored throws, and changes nothing. |
| FEEDUSE-1 | ``ObserveInsightFeedbackUseCase`` streams the repository's answers. |
| FEEDUSE-2 | ``RecordInsightFeedbackUseCase`` stores the answer, with the finding it answered, at the time ``CurrentTimeRepository`` gives, and passes on the repository's error. Features don't read the clock. |
| DEP-FEEDBACK | Both use cases hold the one app-scoped ``InsightFeedbackRepository``, and report an issue in a test that doesn't override them. |
| CARD-1 | With the model available and at least 5 nights on each side, ``ObserveInsightCardUseCase`` sends the card with the finding ``SleepPatternRule`` derives, asking "Feel right?", and saying whether the nights are the demo's. |
| CARD-2 | While the model is unavailable, it sends `nil`, and the card is hidden. |
| CARD-3 | With too few nights, it sends `nil`. |
| CARD-4 | After a "Not really" at the finding's confidence, it sends `nil`. After a "Yes", the card stays, without the question. |
| CARD-5 | After a "Not really" at another confidence, the card asks again, and carries that answer for the next prompt. |
| CARD-6 | It waits until the analysis, the answers, and the availability have each arrived, and sends a card only when it changes. |
| DEP-CARD | ``ObserveInsightCardUseCase`` holds the app-scoped sleep tolerance, insight feedback, and language model repositories, and reports an issue in a test that doesn't override it. |
| NOTICED-1 | ``WhatWeNoticedFeature``'s `task` subscribes to the card, reduces each value into `State`, and asks ``WriteInsightUseCase`` for the insight for the card's request: its finding, and the last disagreement. |
| NOTICED-2 | A card for the same request keeps its insight, so a "Yes" hides only the question. |
| NOTICED-3 | A card with a new request clears the insight, and writes a new one. |
| NOTICED-4 | A hidden card is hidden. |
| NOTICED-5 | When the insight can't be written, or fails the number check, the card has no insight, and stays hidden. |
| NOTICED-6 | An insight written for an earlier request is dropped. |
| NOTICED-7 | An answer is recorded through ``RecordInsightFeedbackUseCase``, with the card's confidence and the insight. Without an insight there's nothing to answer, and a failure to store it is logged. |
| INSIGHTS-7 | ``InsightsFeature`` runs ``WhatWeNoticedFeature`` at `State.whatWeNoticed`. |

### Against your caffeine

| ID | Requirement |
|----|-------------|
| AVAIL-1 | Sleep is available when Health recorded any sleep, with or without a stage. Time in bed or awake alone doesn't count. |
| AVAIL-2 | Steps and resting heart rate are available when any day has a value, 0 included. |
| AVAIL-3 | The kinds are in a fixed order: sleep, steps, then resting heart rate. |
| AVREPO-1 | A new subscriber to ``HealthDataRepository/availableKinds(days:in:)`` immediately gets the kinds Apple Health has data for, and only those. |
| AVREPO-2 | With the demo switch on, the kinds are the demo's. |
| AVREPO-3 | Until Health access is requested, no kind is available. At the first minute it is, the kinds are read and sent. |
| AVREPO-4 | A change a data source signals sends the new kinds, only when they change. |
| AVUSE-1 | ``ObserveAvailableHealthDataUseCase`` streams the repository's kinds for the last 30 days, in the calendar it's given. |
| DEP-AVAIL | The use case holds the one app-scoped ``HealthDataRepository``, and reports an issue in a test that doesn't override it. |
| HCARD4-1 | ``HealthDataListFeature``'s `task` subscribes to the kinds in the `\.calendar` dependency, and each set is reduced into `State`. |
| HCARD4-2 | The buttons are the available kinds, in order, and the card shows only when there's one. |
| INSIGHTS-3 | ``InsightsFeature`` runs ``HealthDataListFeature`` at `State.healthData`. |
| INSIGHTS-4 | Tapping the sleep button pushes the Sleep screen, ``SleepDetailFeature``, onto the tab's path. |

### Sleep

``SleepToleranceRule`` is unit-tested directly, and needs no fakes. The repository and its data sources are tested against fake data sources and a stepped clock. The UI requirements are UI-INS-11 and UI-INS-12.

| ID | Requirement |
|----|-------------|
| TOL-1 | A night is a session with at least 3 hours of sleep, recorded with or without stages. It runs from its first sleep to its last, and its time asleep counts overlapping trackers once. A nap, or time in bed alone, isn't a night. |
| TOL-2 | A night counts when it ended in the period, today and the 29 days before it in the calendar, before the current time, and began once drinks had been logged for 2 days. With no drinks there are none. They're in order of onset, and sleep is read from a day before the period. |
| TOL-3 | A night's caffeine at sleep onset is ``CaffeineDecayRule``'s level at its onset. |
| TOL-4 | The time to fall asleep runs from the start of the time in bed that holds the onset. Without one, it's unknown. |
| TOL-5 | The tolerance is the caffeine at sleep onset above which time asleep starts to drop. |
| TOL-6 | With fewer than 5 nights on either side of every candidate, there's no tolerance. |
| TOL-7 | When time asleep stays level or rises with caffeine, there's no tolerance. |
| TOL-8 | The tolerance is a whole 5 mg from 20 to 80 mg. |
| TOL-9 | Time asleep is compared on each side of the threshold in use, the tolerance or 40 mg, once each side has 5 nights. |
| TOL-10 | The time to fall asleep is compared the same way, among the nights that have it. |
| TOL-11 | The onsets are every recognised night's, in the period or before it, once 2 days of drinks are logged. |
| TOLREPO-1 | A new subscriber immediately gets the analysis of Apple Health's sleep, with the user's own drinks and the curve's kinetics. |
| TOLREPO-2 | With the demo switch on, the sleep is the demo's, every drink counts, and the analysis is marked demo. Turning the switch on sends the demo's analysis. |
| TOLREPO-3 | Until Health access is requested, there are no nights. At the first minute it is, the analysis is read and sent. |
| TOLREPO-4 | A change the drink log or the half-life signals sends the new analysis, only when it changed. |
| TOLREPO-5 | The tolerance is stored before the analysis is sent, whenever it differs from the stored one, none included. |
| TOLREPO-6 | When an input can't be read, nothing is sent or stored. |
| TOLREPO-7 | The first minute of a new day sends the new period's analysis. Other minutes read nothing. |
| TOLREPO-8 | A new caffeine nights subscriber gets ``CaffeineNightRule``'s nights for its days and calendar, judged against the threshold in use. |
| TOLREPO-9 | A bedtime change sends the new nights. |
| TOLREPO-10 | Nights before the analysis's period still get their recorded onsets. |
| TOLREPO-11 | A change that leaves the nights alone sends nothing. |
| TOLFILE-1 | With no file, there's no tolerance. |
| TOLFILE-2 | A stored tolerance, or none, reads back from any instance, and a store signals every subscriber. |
| TOLFILE-3 | The file is written atomically with complete protection, and left out of backups. It's `SleepTolerance.json` in Application Support. |
| TOLFILE-4 | A damaged file, or a tolerance outside 20 to 80 mg, throws. |
| TOLSRC-1 | ``PersonalSleepThresholdDataSource``'s threshold is the stored tolerance. |
| TOLSRC-2 | Without one, or when it can't be read, it's the standard 40 mg. |
| TOLSRC-3 | It signals when a tolerance is stored. |
| TOLDECAY-1 | A change the threshold data source signals sends ``CaffeineDecayRepository``'s cutoff for the new threshold. |
| TOLUSE-1 | ``ObserveSleepCaffeineAnalysisUseCase`` streams every analysis the repository publishes, in order. |
| TOLUSE-2 | ``KeepSleepToleranceCurrentUseCase`` subscribes until the stream ends. |
| TOLUSE-3 | ``ObserveCaffeineNightsUseCase`` streams the repository's 31 nights in the calendar it's given. |
| DEP-TOL | The use cases hold the one app-scoped ``SleepToleranceRepository``, and each reports an issue in a test that doesn't override it. |
| TOLAPP-1 | Launching keeps the tolerance current. |
| SLEEPSCREEN-1 | ``SleepDetailFeature``'s `task` subscribes to the analysis, and each is reduced into `State`. |
| SLEEPSCREEN-2 | The finding is the tolerance, no drop with 5 nights on each side of the threshold, or too few nights, with each side's count. |
| SLEEPSCREEN-3 | The time to fall asleep counts only the nights with time in bed. |
| SLEEPSCREEN-4 | The analysis card's sentence describes both charts, is hedged when it names a trend, and never mentions the cutoff. |
| SLEEPSCREEN-5 | The time to fall asleep reads longer or shorter only beyond 5 minutes, about the same within them, and unknown without a comparison. |
| DEMOTOL-1 | The demo's drinks and nights give a tolerance and both comparisons. |

### Steps

| ID | Requirement |
|----|-------------|
| STEPSRULE-1 | A day follows a caffeine night when the night of the day before it was one, matched by calendar day. The comparison carries the threshold, and whether the steps are the demo's. |
| STEPSRULE-2 | A day with no steps stays in the days, and counts on neither side. |
| STEPSRULE-3 | Each side has its days' average steps and its day count, or none with no days. |
| STEPSRULE-4 | With fewer than 5 days with steps on either side, there are too few days to compare. |
| STEPSRULE-5 | A difference within twice its standard error is no clear difference. |
| STEPSRULE-6 | A difference beyond twice its standard error is that many fewer, or more, steps after a caffeine night. |
| STEPSREPO-1 | A new subscriber to ``HealthDataRepository/stepHistory(days:in:)`` immediately gets the steps of each of the 30 days before today, from Apple Health, with none for a day Health has none for. |
| STEPSREPO-2 | With the demo switch on, the steps are the demo's, marked as demo. |
| STEPSREPO-3 | Until Health access is requested, no day has steps. At the first minute it is, the steps are read and sent. |
| STEPSREPO-4 | A change a data source signals sends the new steps, only when they change. |
| STEPSREPO-5 | The first minute of a new day sends the history moved on by a day. Other minutes send nothing. |
| STEPSREPO-6 | Steps that can't be read give empty days. |
| STEPSUSE-1 | ``ObserveStepsComparisonUseCase`` streams the rule's comparison of the 31 caffeine nights and the 30 days of steps, in the calendar it's given. |
| STEPSUSE-2 | After either stream sends, the latest of each is compared. |
| STEPSUSE-3 | A change that leaves the comparison as it was sends nothing. |
| DEP-STEPS | The use case holds the app-scoped repositories, and reports an issue in a test that doesn't override them. |
| STEPSCARD-1 | ``StepsDetailFeature``'s `task` subscribes to the comparison in the `\.calendar` dependency, and each comparison is reduced into `State`. |
| INSIGHTS-6 | Tapping the steps button pushes the steps screen onto the tab's path. |
| UI-STEPS-1 | Tapping the steps button opens the steps screen, with its chart. |
| UI-STEPS-2 | With the empty drink log UI tests start with, there are too few days to compare, no day follows a caffeine night, and the other days average the simulated 8,420 steps over 30 days. |
| UI-STEPS-3 | The steps screen passes the accessibility audit. |
| UI-STEPS-4 | The screen says what a caffeine night is, in words: more than the recommended caffeine at sleep, or at bedtime without recorded sleep. |

### Resting heart rate

| ID | Requirement |
|----|-------------|
| CNIGHT-1 | ``CaffeineNightRule`` gives one night per day before today, oldest first, the night after yesterday last. |
| CNIGHT-2 | A night with a recorded onset from noon that day to noon the next is measured at the first such onset, as `.sleepOnset`. |
| CNIGHT-3 | A night with none is measured at the first bedtime at or after 6pm that day, as `.bedtime`. |
| CNIGHT-4 | Each night's caffeine is ``CaffeineDecayRule``'s level at its moment, from every intake. |
| CNIGHT-5 | The threshold, and whether the sleep is the demo's, are carried. |
| CNIGHT-6 | The days follow the calendar's time zone. |
| CNIGHT-7 | A night is a caffeine night only when its caffeine is over the threshold. |
| RHRREPO-1 | A new subscriber to ``HealthDataRepository/restingHeartRates(days:in:)`` immediately gets each day's reading from Apple Health, oldest first. |
| RHRREPO-2 | With the demo switch on, the readings are the demo's, marked as demo. |
| RHRREPO-3 | Until Health access is requested, no day has a reading. At the first minute it is, the readings are read and sent. |
| RHRREPO-4 | A change a data source signals sends the new readings, only when they change. |
| RHRREPO-5 | The first minute of a new day sends the readings moved on by a day. Other minutes send nothing. |
| RHRREPO-6 | A reading that can't be read is missing. |
| RHRCOMP-1 | Each day with a reading pairs with the night before it, and follows a caffeine night when that night is one. Days with no reading or no night before them are left out. |
| RHRCOMP-2 | Each group has its day count and average, and an empty group has no average. |
| RHRCOMP-3 | With fewer than 5 days in either group, there aren't enough days. |
| RHRCOMP-4 | A difference more than twice its standard error, and at least 1 bpm, is a pattern, higher or lower. |
| RHRCOMP-5 | A difference within twice its standard error isn't clear. |
| RHRCOMP-6 | A difference under 1 bpm isn't clear, however consistent. |
| RHRCOMP-7 | Whether the heart rates are the demo's is carried. |
| RHRUSE-1 | ``ObserveRestingHeartRateComparisonUseCase`` streams the rule's comparison of the last 30 days, in the calendar it's given, once both repositories have sent a value. |
| RHRUSE-2 | A new value from either repository sends the comparison of the latest two. |
| RHRUSE-3 | A comparison the same as the last one sent isn't sent again. |
| DEP-RHRCOMP | The use case holds the one app-scoped ``SleepToleranceRepository`` and the one app-scoped ``HealthDataRepository``, and reports an issue in a test that doesn't override it. |
| RHRSCREEN-1 | ``HeartRateDetailFeature``'s `task` subscribes to the comparison in the `\.calendar` dependency, and each comparison is reduced into `State`. |
| INSIGHTS-5 | Tapping the resting heart rate button pushes the resting heart rate screen onto the tab's path. |
| UI-RHR-1 | The resting heart rate button opens the screen. With nothing logged, there aren't enough days yet, and the heart rate is Apple Health's. |
| UI-RHR-2 | The screen passes the accessibility audit. |
| UI-RHR-3 | With the demo drinks and the demo Health data, the screen shows both groups, the chart, and the footnote, and says the data is the demo's. |

## Known issues

The owner chose on 2026-09-13, at 11:09, to record these and move on, as for Settings' layout bug (<doc:Settings>). The audits stay red until they're fixed.

- **The Insights tab's audit fails after scrolling to the end** (UI-INS-3, UI-INS-8, and UI-INS-17). It flags the sleep window chart's "6:00 PM" label, at y 149, just below the navigation bar, whose bottom is at y 116. The owner's top-fade exception is meant to cover that spot, but the shared audit helper, `Robot+TabBarAudit.swift`, misses it. The helper follows the screen's first text, which here is the large "Insights" navigation title. The title collapses by 46 points and then stops, while the content keeps scrolling. So the helper stops scrolling too soon, and it measures where the content started, and how far it moved, from the title instead of the content. The same should hold on any screen with a large title. A probe in a scratch copy printed these numbers. The helper's author, half-life-d8, had ended, so the report wasn't delivered. With "What we noticed" showing (UI-INS-17), the sleep window card sits lower. So the second audit flags its chart's "6:00 PM" and "4:00 AM" labels and its footnote, at y 818 to 879, which the stopped scroll leaves in the tab bar's fade. The first audit, which checks the card itself, passes. A probe in a scratch copy printed these on 2026-09-13.
- **UI-INS-12, resolved on 2026-09-13.** The generic screen that failed it is gone. The cause, found while building the Sleep screen: the audit fails long body text laid straight on the page gradient, wherever it sits. A probe in a scratch copy printed the failing element each time: the Sleep screen's subtitle at y 197, just under the navigation bar, and then, moved into the footnote, the same sentence at y 524, far from any bar. Text on a card's surface passes, so the footnote sits on one, and UI-INS-12 now passes on the Sleep screen.
- **The resting heart rate screen's audit fails after scrolling to the end** (UI-RHR-2). The owner chose on 2026-09-13, at 13:07, to record it and move on. At rest, the audit passes: it flags only the log button and the chart's legend behind the tab bar, which the audit helper ignores. At first, the full audit timed out at the end of the scroll ("Audit failed to complete in time"), and a probe in a scratch copy found the contrast check flagging the footnote, which sat straight on the page gradient. After half-life-ff's finding for UI-INS-12 (below), the footnote moved onto a card. The timeout and the footnote's failure went away (13:38). One issue remains: at the end of the scroll, the chart card's "THE LAST 30 DAYS" eyebrow (`textSecondary` on the card) reads "Contrast nearly passed". The groups' eyebrows above it, in the same style, pass, and so do the Sleep screen's in both audit passes, which points to the eyebrow's position rather than its color. At the end of the scroll it may sit in the navigation bar's top fade, which the audit helper doesn't exempt for it. That's untested. A probe of its frame against the helper's `contentTop` and `scrolledBy`, in a scratch copy, would confirm it. half-life-e4's probe of the Steps screen found the same kind of failure there: at the end of the scroll, the bar's top fade reached about 50 pt below where the title rested, past the helper's top exception. If that exception is widened, which e4 has asked the owner about, this issue may clear too.
- **The steps screen fails its audit after scrolling to the end** (UI-STEPS-3). At rest, the whole screen passes: the audit flags only text behind the tab bar, which the shared helper ignores. At the end of the scroll, it flags the text just under the navigation bar, in the bar's scroll-edge fade: the question, the verdict card's heading, the verdict, and its explanation. A probe in a scratch copy of `Robot+TabBarAudit.swift` printed them at y 18 to 193, with the content resting at y 144. The helper's top exception, which the owner approved on 2026-09-13, ignores only text above where the content rested, so it ignores the first three and not the explanation, at y 151 to 193. The same text passes at rest, so the fade reaches about 50 points below the exception's line. The owner chose on 2026-09-13, at 14:01, to record it and leave the test failing, rather than widen the helper's exception for every screen or change the layout.

## Still to decide

- **A minimum drop for the tolerance.** The tolerance needs only a falling line, so a small drop found by chance in noisy nights can set one. A minimum drop, such as 15 minutes at the most caffeine seen, or a test of significance, would claim less. This is the AI's choice, still to be confirmed.
- **How often the tolerance moves.** It's recalculated whenever its inputs change, so the cutoff can move in 5 mg steps from day to day. The half-life estimate recalculates weekly instead. This is the AI's choice, still to be confirmed.
- **The time to fall asleep needs time in bed,** which an Apple Watch alone usually doesn't record. Many users will see only the note, until the iPhone's sleep schedule records it.

- **The last card can't scroll clear of the log button.** The tab's scroll view, inside its navigation stack, leaves room at the bottom only for the home indicator, not for the tab bar and the log button above it. So at the end of the scroll, the last card's bottom edge sits behind the button. Settings' pushed screens have the same bug, and there the owner chose on 2026-09-13 to record it and not fix it (<doc:Settings>). Whether to fix it on Insights is the owner's decision. A fix shouldn't hard-code the padding, because the bar's height changes with the text size.

- **Rounding.** The clearing time is to the minute, like the prototype's "2:33am". The model's uncertainty is hours, not minutes, so a rounder time, such as the quarter hour, might claim less. This is the AI's choice, still to be confirmed.
- **Daytime bedtimes.** Settings allows any bedtime. A bedtime from 4am to 6pm comes round only the next day, so the window can land far from the chart. Shift work isn't in the brief's scope.
- **The model's sentence** for the window, and the three designed cards, as listed above.
