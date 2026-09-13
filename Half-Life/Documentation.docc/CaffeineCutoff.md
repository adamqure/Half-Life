# Caffeine Cutoff

The latest time today that the user's usual drink still leaves little enough caffeine in them at bedtime: the Today screen's "Last cup" tile.

## Overview

The brief's question is *when*, not *how much*: "The interesting insight isn't your daily total; it's the decay curve and where your bedtime falls on it." The cutoff turns that curve into one time the user can act on: "Last cup by 2:30 PM."

The owner set its shape on 2026-09-12:

- **It's about the user's usual drink.** The cup it's sized for is the user's most logged drink and quantity, the first of the one-tap favourites. With nothing logged, it's the first starter favourite.
- **It starts from the caffeine already in the user.** Every drink logged so far counts. So a big morning moves the afternoon's cutoff earlier, and a day can run out of room for another cup.
- **The threshold is the user's own once their nights show it.** It's how much caffeine can be in the body at bedtime. The Sleep screen's caffeine tolerance, the most caffeine at sleep onset before the user's time asleep starts to drop, sets it, within 20 to 80 mg (<doc:Insights>, "Sleep"). Until the nights show one, it's 40 mg, the value the research below supports. The owner confirmed 40 mg on 2026-09-12, and chose on 2026-09-13 that the tolerance replaces it automatically. This is the personal sensitivity threshold, roadmap rank 22, built early at the owner's request.
- **The tile shows the cutoff itself.** It shows "By 2:30 PM", or "No more today" when another cup would leave too much at bedtime. The owner chose this over the prototype's tile, which shows when the last drink was, against the cutoff (screenshot 07).

The cutoff was first designed as part of onboarding's bedtime step. At 12:18 on 2026-09-12 the owner took it out of onboarding, so it's built here, for the Today screen, instead (<doc:Onboarding>).

## The question

Given the drinks already logged, the user's kinetics, their bedtime, and the threshold, the cutoff is the latest time `t`, from now until the next bedtime, such that:

```
level at bedtime (every intake logged + one usual cup at t) ≤ threshold
```

The level is ``CaffeineDecayRule``'s, under the same Bateman absorption as the decay curve, so the tile and the curve always agree (<doc:CaffeineDecayModel>).

### The cup has to peak by bedtime

Under Bateman absorption, a cup drunk at bedtime adds nothing *at* bedtime, because none of it has reached the body yet. The level at bedtime alone would call that cup fine, although its caffeine arrives while the user is trying to fall asleep.

So the rule only considers cups that peak by bedtime: consumed at least the peak delay before it, which is 63 minutes with the standard constants (RULE-9 in <doc:CaffeineDecayModel>). This fixes the loophole, and it makes the question well behaved:

- **Every intake that counts has peaked by bedtime.** Logged drinks were consumed no later than now (``DrinkLogRule``), and the latest cup considered is the peak delay before bedtime. So the cutoff only exists when now is at least that long before bedtime, and then every drink peaks before bedtime.
- **After its peak, a drink's level only falls.** So the level at bedtime is the most caffeine the user has at any time from then on. Checking bedtime is enough.
- **The later the cup, the more of it is left at bedtime.** Between now and the peak delay before bedtime, the level at bedtime rises the later the cup is drunk. So the times that work are one unbroken stretch, from now to the cutoff, and the rule finds its end by bisection, like the half-gone time (RULE-8 in <doc:CaffeineDecayModel>).

### The answer

- **The cutoff rounds down to the half hour.** The owner chose this on 2026-09-12, over the quarter hour, so the tile reads like the prototype's "2:30pm". The rule rounds the exact moment down to :00 or :30 in the user's calendar, so it can only be earlier than the exact one, and a cup at the cutoff always leaves at most the threshold. In a time zone offset by 45 minutes, such as Nepal's, the half hours are the local ones.
- **Once the rounded time has passed, there's no cutoff.** That's true although a cup up to the exact moment would still fit, because the tile never shows a time that's already gone. The cutoff still shows during its own minute.
- **A small enough drink runs to the peak delay.** When even a cup drunk the peak delay before bedtime leaves no more than the threshold, the cutoff is that moment, rounded down. With the standard constants, the latest cup that peaks by a 10:30pm bedtime is at 9:26pm, so the cutoff is 9:00pm. One cup of green tea (28.4 mg) never reaches 40 mg on its own. This matches Gardiner 2023, which found that a cup of black tea "can be consumed at any time prior to bedtime without significantly reducing total sleep time."
- **Sometimes there's no cutoff.** When even a cup drunk now would leave more than the threshold, or now is later than the peak delay before bedtime, there's no cutoff, and the tile says "No more today".
- **The bedtime is the next one.** It's the first time the user's bedtime comes round at or after the current time, in the user's calendar, as the decay card uses (BED-3 in <doc:TodayScreen>). After tonight's bedtime, the cutoff is for tomorrow night's.
- **The cup is the catalog's estimate.** A cup not yet drunk is sized from ``DrinkType``'s caffeine per unit times the favourite's quantity. Drinks already logged keep the caffeine they were logged with.

With nothing logged, the standard constants, and a 10:30pm bedtime, the exact cutoff for two espresso shots in a latte (125.4 mg) is 1:06pm, shown as 1:00pm. For one shot (62.7 mg), it's 6:36pm, shown as 6:30pm.

## The sleep threshold

The threshold is the most caffeine the cutoff allows in the body at bedtime: the user's caffeine tolerance once their nights show one (<doc:Insights>, "Sleep"), and **40 mg** until then. The research below is where the 40 mg comes from.

### What the research says

No study measures a safe amount in the body at bedtime directly. The studies give doses and timings, or plasma concentrations. So each figure below is converted into an amount in the body at bedtime, under Half-Life's model with the standard 5.5-hour half-life. The conversions are the AI's derivations, not figures the authors reported.

| Source | Design | Dose and timing | Outcome | Left in the body at bedtime |
|--------|--------|-----------------|---------|----------------------------|
| Gardiner 2023 | Meta-analysis of 24 studies, with a meta-regression on dose and timing | 107 mg coffee, 8.8 h before bed | The cutoff for total sleep time | About 37 mg |
| Gardiner 2023 | The same | 217.5 mg pre-workout serving, 13.2 h before bed | The same | About 43 mg |
| Gardiner 2025 | Randomised crossover, 23 men | 100 mg, 4 h before bed | No significant effect | About 63 mg |
| Gardiner 2025 | The same | 400 mg, 12 h before bed | Falling asleep took 15 minutes longer, and deep sleep was 21 minutes shorter | About 92 mg |
| Drake 2013 | Crossover, 12 adults, at home | 400 mg, 6 h before bed | Total sleep time down by more than an hour | About 196 mg |
| Landolt 1995 | 9 men | 200 mg at 7:10am, sleep at 11pm | Total sleep time and sleep efficiency reduced | About 28 mg, or 33–39 mg from the measured saliva level |
| Baur 2024 | 21 men, plasma caffeine measured during sleep | 160 mg, delayed release | Deep-sleep (delta) EEG reduced above about 7.4 µmol/L, and heart rate above about 4.3 µmol/L | About 60–70 mg, and about 35–41 mg |

Gardiner 2023 states the cutoffs this way: "To avoid reductions in total sleep time, a cup of coffee (typical caffeine content: 107 mg per 250 mL) must be consumed at least 8.8 h prior to bedtime and a standard serve of pre-workout supplement (typical caffeine content: 217.5 mg) must be consumed at least 13.2 h prior to bedtime."

### Why 40 mg

- **It matches the meta-analysis.** Gardiner 2023's two cutoffs, the best evidence on timing, both leave about 37–43 mg at bedtime under this model.
- **It sits between Baur 2024's two thresholds.** Heart rate changed above about 35–41 mg in the body, and deep-sleep EEG above about 60–70 mg.
- **It's below every dose with a measured effect,** apart from Landolt 1995's morning dose, whose authors offer another explanation: caffeine present while awake slows the build-up of sleep pressure.
- **The prototype's two numbers are unsourced.** Its onboarding uses about 25 mg ("quiet enough to sleep through"), and its Patterns screen uses 55 mg. The research found a source for neither. 25 mg is a defensible lower bound, from Landolt 1995, but it's stricter than the total-sleep-time evidence supports. 55 mg sits on the deep-sleep threshold, and on a null result from one small study.

The plausible range is **25–60 mg**.

### How the conversions were made

- **Doses and timings** go through ``CaffeineDecayRule`` with the standard constants. For example, 107 mg drunk 8.8 hours before bed leaves 36.7 mg. Simple exponential decay gives 107 × 2^(−8.8 / 5.5) = 35.3 mg. After about 4 hours, absorption adds only about 4%.
- **Plasma concentrations** use caffeine's molar mass, 194.19 g/mol, a volume of distribution of 0.6–0.7 L/kg, and a 70 kg adult. 7.4 µmol/L is 1.437 mg/L, which is 60.4 mg in 42 L and 70.4 mg in 49 L. StatPearls gives 0.6 L/kg for adults, and Abernethy 1985 measured 0.685–0.75 L/kg.
- **Landolt's saliva level** of 3 µmol/L is about 4.05 µmol/L in plasma, using a saliva-to-plasma ratio of 0.74 (Newton 1981). That's about 0.79 mg/L, or about 33 mg. Zylber-Katz 1984 reports a ratio of 0.79.
- **The brief's own example** is over the threshold. It says 200 mg drunk at 4pm leaves 80 mg at 11pm. Under this model, it's 86.2 mg. So the app would call that cold brew too late.

### Why it will be personal

People differ widely, so a population default can only be a starting point:

- **Clearance:** CYP1A2 "metabolizes 95% of the caffeine ingested", and its activity varies from person to person (Nehlig 2018). Smoking, pregnancy, and estrogen change the half-life, which onboarding's factors already account for (<doc:Onboarding>).
- **Sensitivity:** a variant of the adenosine receptor gene ADORA2A "contributes to subjective and objective responses to caffeine on sleep" (Rétey 2007).
- **Tolerance:** in habitual users taking 150 mg three times a day, "Neither polysomnography-derived total sleep time, sleep latency, sleep architecture nor subjective sleep quality differed" from placebo (Weibel 2021).
- **Age:** middle-aged adults are "generally more sensitive to the effects of a high dose of caffeine" (Robillard 2015).

The Sleep screen's caffeine tolerance is the first step: it moves the threshold to where the user's own time asleep starts to drop, once 5 nights on each side show it (<doc:Insights>, "Sleep").

### How the app talks about it

The threshold comes from studies of other people, mostly small groups of healthy young men. So the app presents the cutoff as a starting point, not a fact about the user. Suitable language: "Sleep studies suggest most people's sleep isn't measurably affected below about 40 mg. We'll adjust this once we see your own sleep." The app avoids "safe" and "quiet enough to sleep through", and never claims a number of minutes of sleep lost (the brief's *Honesty* criterion). Once the user's nights show a trend, the threshold is learned from their time asleep instead, and the app says so wherever it names the number (THRESH-5).

### Caveats

- **Gardiner 2023's cutoff means "no longer statistically significant", not "no effect".** It's where the 95% confidence interval stops crossing zero, so a small effect can remain at the cutoff.
- **The 37–43 mg agreement is a derivation.** The meta-regression is linear in dose and time, and its authors didn't frame it as an amount left in the body.
- **The samples are narrow.** Most studies used healthy young adults, often men only, with low to moderate habitual intake. Gardiner 2023 notes its results "may not be generalisable to… older adults (>65 years), caffeine naïve individuals, or those with a high habitual caffeine intake."
- **Some sources weren't read in full.** The AI's research read the abstracts of Baur 2024 and Landolt 1995 but couldn't retrieve their full texts, and it read Gardiner 2025's bedtime saliva values only from a figure.

## Where the cutoff is calculated

``CaffeineDecayRepository`` publishes it on a third stream, `cutoff(in:)`, and executes ``CaffeineCutoffRule`` itself (constitution Article I.10).

- **The inputs** are the decay repository's own:
  - the intakes of the drinks that aren't marked negligible
  - the kinetics
  - the bedtime from ``BedtimeDataSource``
  - the current time from ``ClockDataSource``
  It adds two more: the threshold, from ``SleepThresholdDataSource``, and every logged drink, which it runs through ``FavouriteDrinksRule`` for the usual drink.
- **A subscriber gets the cutoff for the current time as soon as it subscribes.** After that, the repository recalculates at every whole minute and whenever the drink log signals a change. It also recalculates when the bedtime or the half-life changes, because onboarding's data source signals those through the same path.
- **Each subscriber gets only changes.** The repository remembers the last cutoff it sent each subscriber, and skips an equal one. The cutoff doesn't move from minute to minute, so in practice a new one goes out when a drink is logged, the bedtime changes, or the cutoff passes.
- **The derived values share one read.** The cutoff, the next nights' cutoffs, the composer's warning, and the sleep window (<doc:Insights>) are all calculated from the same inputs, read once for every subscriber, and each subscriber is sent a value only when its value changed.
- **The threshold has its own data source.** ``PersonalSleepThresholdDataSource`` returns the stored caffeine tolerance, or ``SleepThreshold/standard`` without one. It signals when a tolerance is stored, and the repository then recalculates at once, so the cutoff, the next nights' cutoffs, the composer's warning, and the sleep window all adopt it together (TOLDECAY-1 in <doc:Insights>). ``StandardSleepThresholdDataSource`` stands in where a repository is built without one, as in tests.

``ObserveCaffeineCutoffUseCase`` streams it, with the user's calendar as its input.

## The Last Cup tile

``LastCupFeature`` observes the cutoff, and ``LastCupView`` shows it in the trailing half of the Today screen's tile row, beside the "Today" tile (<doc:TodayScreen>).

- **The heading** is "LAST CUP", in the `eyebrow` style.
- **The answer** is "By 1:00 PM", with the time formatted for the locale, or "No more today". It's in the Design System's `metric` style, 22 pt regular scaling with `title2`, in `textPrimary`, because it's a time rather than a caffeine figure.
- **The drink it's for** is in the caption, such as "Your usual: Latte, 2 shots", in `footnote` and `textSecondary`. It says which cup the time is sized for, so the user can see why a smaller drink might still fit.
- **The answer and the caption wrap rather than truncating**, as the "Today" tile's amount does. At accessibility text sizes, the tiles stack and each spans the width.
- **VoiceOver** reads the tile as one element: "Last cup, By 1:00 PM, Your usual: Latte, 2 shots".
- **Until the first cutoff arrives,** the tile shows only its heading.
- **The owner approved the wording** on 2026-09-12: "By 1:00 PM", "No more today", and "Your usual:".
- **The tile doesn't name the threshold.** The confidence language above belongs with a detail view, or the insight cards (rank 12), rather than a half-width tile. This is the AI's choice, still to be confirmed.

## The pre-log warning

The drink composer warns before a drink that breaks the cutoff is logged, and never stops it being logged (roadmap rank 13). The owner asked for it on 2026-09-12 at 23:15, and approved its wording at 23:28 (<doc:DrinkComposer>).

``CaffeineCutoffRule/warning(_:consumedAt:calendar:)`` checks the drink the composer has chosen, at the time it says the drink was consumed, against the next bedtime at or after that time:

- **Still rising at bedtime.** A drink consumed less than the peak delay before bedtime hasn't peaked by then, however small it is. This is the same rule as the cutoff's, where the cup has to peak by bedtime.
- **Too much at bedtime.** Otherwise, the rule adds the drink to every intake already logged, and asks ``CaffeineDecayRule`` for the level at bedtime. More than the threshold warns, with that level.
- **No warning** otherwise.

It checks the exact amount, not the tile's half hour. The tile rounds the cutoff down, so a drink a few minutes past the tile's time can still leave less than the threshold. A warning then would quote an amount under the threshold it warns about. So a drink at the tile's time never warns, and a drink half an hour later always does (WARN-5).

A drink logged earlier than now is checked at its own time, and against the bedtime after it, with every drink logged since.

## Entities

### CutoffWarning

Why a drink breaks the cutoff.

| Case | Values | Meaning |
|------|--------|---------|
| `tooMuchAtBedtime` | `level: CaffeineLevel`, `threshold: SleepThreshold` | The level at bedtime, with the drink, is more than the threshold |
| `stillRisingAtBedtime` | `bedtime: Date` | The drink is consumed less than the peak delay before this bedtime |

### SleepThreshold

The most caffeine the cutoff allows in the body at bedtime.

| Property | Type | Meaning |
|----------|------|---------|
| `milligrams` | `Double` | The amount, always positive and finite. ``SleepThreshold/standard`` is 40 mg. |

### CaffeineCutoff

| Property | Type | Meaning |
|----------|------|---------|
| `drink` | ``FavouriteDrink`` | The drink it's sized for: the user's most logged drink and quantity |
| `latestCup` | `Date?` | The latest half hour the drink can be drunk by, or `nil` when there's no cutoff |
| `bedtime` | `Date` | The bedtime it's for: the next one at or after the current time |
| `threshold` | ``SleepThreshold`` | The threshold it's calculated with |

## Testable requirements

### SleepThreshold

| ID | Requirement |
|----|-------------|
| THRESH-1 | Until it's personalised, the threshold is 40 mg. |
| THRESH-2 | A threshold is a positive, finite amount. Anything else isn't created. |
| THRESH-3 | ``StandardSleepThresholdDataSource`` returns ``SleepThreshold/standard``. |
| THRESH-4 | ``StandardSleepThresholdDataSource``'s changes finish at once, because its threshold never changes. |
| THRESH-5 | ``SleepThreshold/standard`` comes from clinical sleep studies, and every other threshold is learned from the user's nights, so a learned 40 mg isn't the standard. |

### CaffeineCutoffRule

Unit-tested directly. The rule is pure, so its tests need no fakes. They check it against ``CaffeineDecayRule``'s levels.

| ID | Requirement |
|----|-------------|
| CUTOFF-1 | The cutoff is the latest moment when the usual drink, with every intake logged, leaves at most the threshold at the next bedtime, rounded down to the half hour in the given calendar. Half an hour later leaves more. It reports the drink, the bedtime, and the threshold it's for. |
| CUTOFF-2 | The caffeine already logged counts: it moves the cutoff earlier. |
| CUTOFF-3 | There's no cutoff when even a cup now would leave more than the threshold, or once the rounded cutoff's minute has passed. It still shows during its own minute. |
| CUTOFF-4 | The cup has to peak by bedtime. A drink too small to reach the threshold has its cutoff at the last half hour at or before a peak delay before bedtime, and there's no cutoff within the peak delay of bedtime. |
| CUTOFF-5 | After bedtime, the cutoff is for the next bedtime. |
| CUTOFF-6 | A longer half-life never gives a later cutoff, and a shorter one never gives an earlier one. |
| CUTOFF-7 | The bedtime is a time of day in the given calendar, and the cutoff rounds to that calendar's half hours. |
| CUTOFF-8 | The cup is the drink's catalog estimate for its quantity, so a bigger usual drink gives an earlier cutoff. |
| CUTOFF-9 | The cutoffs for several nights start with tonight's, and each later night's is the cutoff from the moment the bedtime before it has passed, with only the intakes already logged. With nothing logged, every night's cutoff is at the same time of day. Caffeine logged today weighs on tonight's cutoff much more than on tomorrow's. |

### The pre-log warning

Unit-tested directly, against ``CaffeineDecayRule``'s levels and the cutoff itself.

| ID | Requirement |
|----|-------------|
| WARN-1 | A drink that leaves at most the threshold at the next bedtime, and peaks by it, gets no warning. |
| WARN-2 | A drink that leaves more gets `tooMuchAtBedtime`, with the level at bedtime, from every intake logged plus the drink, and the threshold. Caffeine already logged counts. |
| WARN-3 | A drink consumed less than the peak delay before bedtime gets `stillRisingAtBedtime`, however small it is. |
| WARN-4 | The bedtime is the next one at or after the drink's time, in the given calendar. |
| WARN-5 | A drink at its own cutoff gets no warning, and the same drink half an hour later gets one. |

### CaffeineDecayRepository: the cutoff

Tested against fake data sources and a fake clock. REPO-1 to REPO-10 are in <doc:CaffeineDecayModel>.

| ID | Requirement |
|----|-------------|
| CUTREPO-1 | A new subscriber immediately gets the cutoff for the current time, calculated from the drinks that aren't marked negligible, the kinetics, the bedtime, and the threshold from its data source, in the subscriber's calendar. |
| CUTREPO-2 | The drink is the first favourite ``FavouriteDrinksRule`` finds in every logged drink, including drinks marked negligible. With nothing logged, it's the first starter. |
| CUTREPO-3 | After the drink log signals a change that alters the cutoff, every subscriber gets the new cutoff. |
| CUTREPO-4 | At each minute the clock streams, a subscriber gets a new cutoff only if it changed, such as when the cutoff passes. |
| CUTREPO-5 | `upcomingCutoffs(nights:in:)` streams the cutoffs for the next nights, as CUTOFF-9 calculates them, from the same inputs as `cutoff(in:)`. A new subscriber gets them at once, and after that only when a change to the drink log, or a minute, changes them. |
| WARNREPO-1 | `cutoffWarning(for:secondsAgo:in:)` gives a new subscriber the warning for the drink, consumed `secondsAgo` before the current time, from the same inputs as the cutoff, or `nil` when it fits. |
| WARNREPO-2 | After a change to the drink log that alters it, the subscriber gets the new warning. |
| WARNREPO-3 | At each minute the clock streams, a subscriber gets a new warning only if it changed, such as when the drink comes within its peak delay of bedtime. |

### ObserveCaffeineCutoffUseCase

| ID | Requirement |
|----|-------------|
| OBSCUTOFF-1 | It streams every cutoff the repository publishes for the calendar it's given, in order. |
| OBSWARN-1 | ``ObserveCutoffWarningUseCase`` streams every warning the repository publishes for the drink, how long ago, and the calendar it's given, in order. |

### Registration

| ID | Requirement |
|----|-------------|
| DEP-CUTOFF | `\.observeCaffeineCutoff` holds the app-scoped `\.caffeineDecayRepository`. The preview repository opens an in-memory store, so this test runs inside the serialized `SwiftDataStoreTests`. In tests, using the repository's `cutoff(in:)` or the use case without overriding it reports an issue. |
| DEP-WARN | `\.observeCutoffWarning` holds the app-scoped `\.caffeineDecayRepository`, and in tests, using it without overriding it reports an issue. Its preview test runs inside `SwiftDataStoreTests`, like DEP-CUTOFF's. |

### LastCupFeature

Tested with an exhaustive `TestStore`, with the use case overridden.

| ID | Requirement |
|----|-------------|
| LASTCUP-1 | `task` subscribes to the cutoff in the `\.calendar` dependency, and each cutoff is reduced into `State`. |
| TODAY-LASTCUP | The tile's actions reach `LastCupFeature` through ``TodayFeature``, and its state appears under `TodayFeature.State.lastCup`. |

### UI

| ID | Requirement |
|----|-------------|
| UI-LASTCUP | The Today screen shows the "Last cup" tile, with a time to have the usual drink by or "No more today", and the usual drink. Every UI launch starts with an empty drink log (LAUNCH-3 in <doc:Onboarding>), so the usual drink is the first starter. Which answer shows depends on the time of day. The screen's accessibility audit (UI-2 in <doc:TodayScreen>) includes the tile. |

## Still to decide

- **What happens after bedtime.** Showing tomorrow's cutoff after tonight's bedtime follows the decay card's "next bedtime", which is itself still to be confirmed (<doc:TodayScreen>).

## Sources

Every source below was retrieved during the AI's research on 2026-09-12. It read the abstract at least, and the full text where marked.

- Gardiner C, Weakley J, Burke LM, Roach GD, Sargent C, Maniar N, Townshend A, Halson SL. The effect of caffeine on subsequent sleep: a systematic review and meta-analysis. *Sleep Medicine Reviews*, 2023;69:101764. Full text read. <https://doi.org/10.1016/j.smrv.2023.101764> (open access: <https://eprints.leedsbeckett.ac.uk/id/eprint/9625/>)
- Gardiner C et al. *SLEEP*, 2025;48(4):zsae230. Full text read. <https://pmc.ncbi.nlm.nih.gov/articles/PMC11985402/>
- Drake C, Roehrs T, Shambroom J, Roth T. *Journal of Clinical Sleep Medicine*, 2013. Full text read, through a summarising fetch. <https://pmc.ncbi.nlm.nih.gov/articles/PMC3805807/>
- Landolt HP, Werth E, Borbély AA, Dijk DJ. *Brain Research*, 1995. Abstract only. <https://doi.org/10.1016/0006-8993(95)00040-w>
- Baur DM, Dornbierer DA, Landolt HP. *Journal of Sleep Research*, 2024. Abstract only. <https://doi.org/10.1111/jsr.14140>
- Rétey JV et al. *Clinical Pharmacology & Therapeutics*, 2007. <https://doi.org/10.1038/sj.clpt.6100102>
- Nehlig A. *Pharmacological Reviews*, 2018. <https://doi.org/10.1124/pr.117.014407>
- Abernethy DR, Todd EL. *European Journal of Clinical Pharmacology*, 1985. <https://doi.org/10.1007/bf00544361>
- Weibel J et al. *Scientific Reports*, 2021. <https://pmc.ncbi.nlm.nih.gov/articles/PMC7907384/>
- Robillard R et al. *Journal of Psychopharmacology*, 2015. <https://doi.org/10.1177/0269881115575535>
- Newton R et al. *European Journal of Clinical Pharmacology*, 1981. <https://doi.org/10.1007/bf00609587>
- Zylber-Katz E, Granit L, Levy M. *Clinical Pharmacology & Therapeutics*, 1984. <https://doi.org/10.1038/clpt.1984.151>
- Evans J, Richards JR, Battisti AS. Caffeine. *StatPearls*, updated 2024. <https://www.ncbi.nlm.nih.gov/books/NBK519490/>
