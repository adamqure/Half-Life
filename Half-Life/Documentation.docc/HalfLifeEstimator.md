# Half-Life Estimator

How Half-Life estimates the user's own caffeine half-life, starting from the survey and updating it with their nights.

## Overview

The half-life is the decay model's one per-user parameter (<doc:CaffeineDecayModel>). Onboarding's survey sets a starting value from what the user reports about themselves (<doc:Onboarding>). The estimator (roadmap rank 9) updates that value with the user's own data: the drinks they log, and the sleep, steps, and resting heart rate that Apple Health records.

Health data can't measure a half-life. A half-life is how fast the liver clears caffeine, and only repeated blood or saliva samples measure that directly. What Health does record is how the user slept, and how much caffeine was left in them when they fell asleep depends on their half-life. So the estimator asks which half-life best explains which of the user's nights were disturbed, and weighs the answer against the survey's starting value. When the nights can't tell, the estimate stays at the starting value, and its range stays wide.

The decay curve adopts the estimate automatically. The estimate is stored on the device and recalculated every week, and at once when the survey's answers change.

### Decisions

The owner made these decisions on 2026-09-12:

| Question | Decision |
|----------|----------|
| Which sleep measure the fit explains | A combined score: deep sleep and time awake, each measured against the user's own average |
| Whether the curve adopts the estimate | Yes, automatically. The decay model reads it through its half-life data source. |
| Whether the estimate is stored | Yes. It's recalculated every week, and at once when the survey's starting half-life changes. |
| How many nights the data needs before it can move the estimate | 14 |
| Whether to read pregnancy and contraception from Health | No. The survey's answers stay the only source for them. |
| Whether this change shows the estimate to the user | No. ``ObserveHalfLifeEstimateUseCase`` exposes it for a later feature. |

## What's known about caffeine in the body

- **Absorption.** Caffeine reaches the body within about an hour of drinking. The decay model already models this (<doc:CaffeineDecayModel>).
- **Clearance.** The liver clears caffeine at a rate proportional to the amount present, and the half-life describes that rate. Healthy adults ranged from 2.3 to 9.9 hours in one study (Blanchard 1983). The factors known to change it by more than 25%, such as smoking, estrogen, and pregnancy, are the ones the survey asks about (<doc:Onboarding>).
- **Sleep.** Caffeine taken hours before bed still disturbs sleep. In one trial, 400 mg taken six hours before bed cut measured sleep by more than an hour, and the participants didn't notice (Drake 2013). A meta-analysis found that caffeine cut total sleep by 45 minutes and sleep efficiency by 7%, and added 9 minutes to falling asleep and 12 minutes of waking after sleep onset. It recommended drinking coffee at least 8.8 hours before bed (Gardiner 2023).
- **Sensitivity is separate from clearance.** A common variation in the adenosine A2A receptor gene contributes to how strongly caffeine affects a person's sleep (Rétey 2007). Two people who clear caffeine equally fast can sleep very differently after the same cup.

### What each signal can tell the estimator

| Signal | Can it measure the half-life? | What the estimator does with it |
|--------|-------------------------------|---------------------------------|
| The survey's factors | Yes, as a starting value: they're the known large causes of a longer or shorter half-life | Centres the prior |
| Sleep stages | Only indirectly. A disturbed night reflects the caffeine left at sleep onset, which depends on the half-life, and also the user's sensitivity. | The outcome the fit explains |
| Resting heart rate | No. It's one number per day, so it can't follow a level that changes within hours. | Explains nights that went badly for other reasons |
| Steps | No | Explains nights that went badly for other reasons |

## Why the estimate moves slowly

Two problems limit what the nights can say.

1. **Sensitivity and half-life look alike.** A long half-life with low sensitivity disturbs the same nights as a short half-life with high sensitivity. Only variety in *when* the user drinks separates them. If someone drinks at 8am and 1pm every day, every candidate half-life predicts the same pattern of disturbed nights, and nothing can choose between them.
2. **Nights are noisy.** The same person's deep sleep and time awake vary from night to night for many reasons, and a typical cup's effect is of the same order.

A simulation on 2026-09-12 measured how far the estimate moves. It generated nights with the tests' scenario generator, from a true half-life of 8 hours, against the standard prior of 5.5 hours, 40 times for each row. The effect sizes and noise are assumptions made for the simulation, not measurements. The simulation was a scratch test and wasn't kept.

| Nights | Deep sleep lost per mg at sleep onset | Nightly noise | Median estimate | Range covers 8 hours | Range width against the prior's |
|-------:|--------------------------------------:|--------------:|----------------:|---------------------:|--------------------------------:|
| 28 | 0.3 min | 5 min | 7.2 h | 40 of 40 | 53% |
| 28 | 0.15 min | 10 min | 6.2 h | 37 of 40 | 84% |
| 28 | 0.1 min | 15 min | 5.7 h | 39 of 40 | 95% |
| 56 | 0.1 min | 15 min | 5.8 h | 34 of 40 | 91% |
| 90 | 0.1 min | 15 min | 5.9 h | 32 of 40 | 89% |
| 28 | None | 15 min | 5.5 h | 40 of 40 | 100% |

With a clear effect, the estimate finds the truth. With the noise real nights are likely to have, it barely moves from the survey's value, even after three months, and its range stays nearly as wide as the prior's. The estimate is honest about that: its range, not just its middle, is what a feature should show.

## The night rule

``SleepNightRule`` turns Health's sleep intervals into ``SleepNight`` values. It settles the night rule the <doc:SleepData> article left open.

- **Sessions, not calendar windows.** Stretches of sleep, and of time awake that a tracker recorded during sleep, belong to one session while each starts no more than an hour after the session so far ends. Time awake holds a session together, so a long awakening doesn't split a disturbed night into two quiet ones.
- **A night has at least 3 hours of sleep.** Shorter sessions are naps.
- **A night has stages.** A session recorded only as "asleep", for example by the iPhone's sleep schedule, has no deep sleep to score, so it isn't a night.
- **The night runs from its first sleep to its last.** Time in bed doesn't count as sleep. Time awake counts only between the first and last sleep, so lying awake before sleep isn't counted. The rule can't measure how long it took to fall asleep.
- **Overlaps count once.** Where an iPhone and an Apple Watch both recorded the same stretch, the rule counts it once.

## The estimate

``HalfLifeEstimationRule`` makes the ``HalfLifeEstimate``. It's a Bayesian update on a grid of candidate half-lives.

1. **Usable nights.** A night counts once drinks have been logged for 2 days before it, so drinks from before the user started logging don't go missing from its caffeine. After 48 hours, less than 0.3% of a drink is left at the standard half-life. With fewer than 14 usable nights, the estimate is the prior.
2. **The disruption score.** For each night, the time awake and the deep sleep are each standardized across the usable nights. The score is the time awake minus the deep sleep, standardized again.
3. **The prior.** The candidates are 121 half-lives, evenly spaced on a log scale from 1 to 100 hours. The prior is a log-normal centred on the survey's half-life, with a standard deviation of 0.4 on the natural log. Healthy adults' range of 2.3 to 9.9 hours spans about 3.6 of those standard deviations.
4. **The caffeine at sleep onset.** For each candidate, ``CaffeineDecayRule`` gives the caffeine at each night's sleep onset from the drinks in the week before it. After a week, less than 6% of a drink is left, even at 40 hours. The amounts are standardized. A candidate whose amounts vary by less than 1 mg across the nights says nothing, and gets no caffeine column.
5. **The evidence.** For each candidate, a Bayesian linear regression explains the scores `y` with the columns `X`: the caffeine, whether the night ended on a weekend, the day's steps, and the day's resting heart rate. Each coefficient has a standard normal prior in units of the noise, and the noise variance has an inverse gamma prior with shape 2 and scale 1. With `A = I + XᵀX`, `β = A⁻¹Xᵀy`, `a = 2 + n/2`, and `b = 1 + (yᵀy − yᵀXβ)/2`, the log evidence, up to a constant every candidate shares, is `−½·log|A| − a·log b`. Caffeine is only allowed to disturb sleep, so the evidence is also multiplied by twice the posterior probability that caffeine's coefficient is positive. That probability uses a normal approximation to the posterior's Student t distribution, which has more than 30 degrees of freedom here.
6. **The result.** The prior times the evidence gives the posterior over the candidates. The estimate's half-life is the posterior's median, and its range runs from the 10th to the 90th percentile. Each candidate's weight is spread evenly over its step on the log scale. All three are clamped to the 3 to 40 hours of ``HalfLifePriorRule``.

**Only the caffeine's pattern counts, not its amount.** The caffeine column is standardized, so a candidate can't explain the nights by predicting more caffeine. Only the pattern of which nights had more counts. How strongly an amount disturbs sleep is the user's sensitivity, which the estimate doesn't know, so an amount can't tell the half-life apart from it. Without variety in timing, every candidate gives the same pattern, and the estimate is exactly the prior.

**The day before a night.** Steps and resting heart rate come from the calendar day that contains the moment 6 hours before sleep onset, so a night that starts after midnight belongs to the day before. A day with no value counts as the average.

## The repository

``LiveHalfLifeEstimateRepository`` is the source of truth for the estimate. It's app-scoped, and an actor.

- **When it recalculates.** The estimate is due when none is stored, when it's a week old, or when the survey's starting half-life differs from the one the estimate started from. The repository checks when ``RefreshHalfLifeEstimateUseCase`` runs, which the decay card does when it appears, when a subscriber arrives, and when the survey's half-life changes. It never recalculates on a timer, and it ignores new sleep and new drinks until the estimate is due. An app left running for more than a week recalculates the next time the decay card appears.
- **What it reads.** The last 90 days of sleep, each night's steps and resting heart rate, every drink the user logged, the survey's starting half-life, and the absorption rate. Demo drinks, which Settings adds, are left out. They didn't happen, so real sleep says nothing about them.
- **When a read fails.** A step count or resting heart rate that can't be read counts as missing. If the sleep, the drinks, the survey's half-life, or the absorption rate can't be read, for example because the device is locked, nothing is stored and the old estimate stays until the next check.
- **Overlapping refreshes calculate once.** A check that arrives while one is running makes the running one check again when it finishes.

## How the curve adopts the estimate

``EstimatedHalfLifeDataSource`` is the ``HalfLifeDataSource`` behind ``CaffeineDecayRepository``. It returns the stored estimate's half-life when the estimate started from the survey's current half-life, and the survey's half-life otherwise. So a changed survey reaches the curve at once, even before the estimate is recalculated. It signals when either the estimate or the profile changes, so the decay repository recalculates the curve. The decay repository itself didn't change.

## Storage and privacy

- **On the device only.** ``FileHalfLifeEstimateDataSource`` stores the estimate as `HalfLifeEstimate.json` in Application Support. The file is protected with `NSFileProtectionComplete`. It's derived from Health data, so it's also left out of iCloud backups and never synced (constitution Articles V.3.4 and V.4). It's not part of the drink log's CloudKit store.
- **Health data is read, never stored.** The sleep, steps, and resting heart rate are held in memory while the estimate is calculated. Only the estimate is stored: the half-life, its range, the prior, the number of nights, and when it was calculated.
- **Previews and UI tests never read Health.** ``UnavailableHealthDataSource`` stands in for HealthKit there (Article V.3.5). Under a UI test, the estimate file is a new temporary file.
- **Nothing about the estimate is logged.** A half-life, and a count of nights, are health values (Article XI.6). A recalculation logs a fixed message at `debug`, and a failure logs its error's domain and code at `error`.

## Requirements

| ID | Requirement |
|----|-------------|
| NIGHT-1 | A night recorded with stages runs from its first sleep to its last, and totals its deep sleep and its time awake. |
| NIGHT-2 | Where trackers overlap, the overlap counts once. |
| NIGHT-3 | A gap of more than an hour between stretches of sleep or recorded time awake ends a session, and a gap of exactly an hour doesn't. A long awakening doesn't split a night. A session with less than 3 hours of sleep isn't a night. |
| NIGHT-4 | Sleep recorded without stages isn't a night. |
| NIGHT-5 | Time in bed doesn't count, and time awake before the first sleep or after the last doesn't count. |
| NIGHT-6 | Nights come back in order of onset. No intervals give no nights. |
| EST-1 | With no nights or no drinks, the estimate is the prior, with the prior's range and no nights used. |
| EST-2 | Fewer than 14 usable nights leave the prior. A night is usable once drinks have been logged for 2 days before it. |
| EST-3 | With a clear effect and varied timing, the range contains the true half-life, and the estimate is less than half as far from it as the prior, on a log scale. |
| EST-4 | Nights without steps or resting heart rate still count. |
| EST-5 | Without a caffeine effect, the estimate stays within 15% of the prior, and its range stays at least 70% as wide, on a log scale. |
| EST-6 | Without variety in timing, even a strong effect leaves the prior. |
| EST-7 | The half-life and its range stay within 3 to 40 hours. |
| EST-8 | The range contains the half-life. |
| ESTREPO-1 | With nothing stored, the repository calculates, stores, and publishes the estimate. |
| ESTREPO-2 | An estimate less than a week old, from the survey's current half-life, is published without reading Health. |
| ESTREPO-3 | An estimate a week old or more is recalculated. |
| ESTREPO-4 | An estimate from an older survey is recalculated at once, including when the survey changes while the repository runs. |
| ESTREPO-5 | It reads the last 90 days of sleep, each night's steps and resting heart rate from the day before, and leaves demo drinks out. |
| ESTREPO-6 | A step count that can't be read counts as missing. If sleep can't be read, nothing is stored and the old estimate stays. An estimate that can't be stored is still published. |
| ESTREPO-7 | Overlapping refreshes calculate once. |
| ESTREPO-8 | Every subscriber gets each recalculated estimate. |
| ESTFILE-1 | With no file, there's no estimate. |
| ESTFILE-2 | A stored estimate reads back exactly, from any instance, and a store signals every subscriber. |
| ESTFILE-3 | The file is written atomically with complete protection, and left out of backups. It's `HalfLifeEstimate.json` in Application Support. |
| ESTFILE-4 | A damaged file, or one with a value that isn't valid, throws. |
| ESTSRC-1 | The decay model gets the estimate's half-life when the estimate started from the survey's current half-life. |
| ESTSRC-2 | Otherwise, including when the estimate can't be read, it gets the survey's half-life. |
| ESTSRC-3 | It signals when the estimate or the survey changes. |
| NOHEALTH-1 | The stand-in for Health has no sleep, steps, or resting heart rate, and its sleep never changes. |
| DECAY-5 | The decay card's `task` refreshes the estimate. DECAY-1 to DECAY-4 are in <doc:TodayScreen>. |

`SleepNightRuleTests` covers NIGHT-1 to NIGHT-6, and `HalfLifeEstimationRuleTests` covers EST-1 to EST-8, mostly with nights generated from a known half-life. `LiveHalfLifeEstimateRepositoryTests` covers ESTREPO-1 to ESTREPO-8 against fake data sources, so no test reads real Health data. `FileHalfLifeEstimateDataSourceTests`, `EstimatedHalfLifeDataSourceTests`, and `UnavailableHealthDataSourceTests` cover the data sources, and `CaffeineDecayFeatureTests` covers DECAY-5. `HalfLifeEstimateUseCaseTests` covers the use cases, and `HalfLifeEstimateDependencyTests` the registrations. The simulator doesn't report a file's protection class, so ESTFILE-3's protection is checked only on a device, and the logging isn't tested.

## Still to decide

- **Showing the estimate.** Nothing shows it yet. Uncertainty rendering (rank 16) and Settings (rank 21) could show the half-life with its range and the number of nights, for example "6.1 hours, likely 5 to 8, from 21 nights".
- **Demo sleep.** The demo history adds drinks but no sleep, so the demo shows the survey's half-life. The Apple Health card's design adds demo data sources for sleep, steps, and resting heart rate, scripted to go with the demo drinks, and a switch in Settings (<doc:AppleHealthCard>). When they're built, the estimator could read them while the switch is on, and count the demo drinks then, so the demo shows an estimate against a known answer. Nothing would be written to Health.
- **More outcomes.** Time to fall asleep needs in-bed samples that Apple Watch often doesn't record. Heart rate and heart rate variability during sleep are recorded through the night, but the estimator doesn't read them.
- **Feedback.** The "Feel right?" answer (rank 26) could feed the fit.
- **Sensitivity.** The regression's caffeine coefficient is the user's sensitivity, which the personal sensitivity threshold (rank 22) could build on.

## Sources

- Blanchard and Sawers, *Journal of Pharmacokinetics and Biopharmaceutics*, 1983. [PMID 6886969](https://europepmc.org/abstract/MED/6886969).
- Drake, Roehrs, Shambroom, and Roth, "Caffeine effects on sleep taken 0, 3, or 6 hours before going to bed", *Journal of Clinical Sleep Medicine*, 2013. [PMID 24235903](https://europepmc.org/abstract/MED/24235903).
- Gardiner and others, "The effect of caffeine on subsequent sleep: a systematic review and meta-analysis", *Sleep Medicine Reviews*, 2023. [PMID 36870101](https://europepmc.org/abstract/MED/36870101).
- Rétey and others, "A genetic variation in the adenosine A2A receptor gene (ADORA2A) contributes to individual sensitivity to caffeine effects on sleep", *Clinical Pharmacology & Therapeutics*, 2007. [PMID 17329997](https://europepmc.org/abstract/MED/17329997).

## Topics

### Entities

- ``SleepNight``
- ``HalfLifeEstimate``

### Business rules

- ``SleepNightRule``
- ``HalfLifeEstimationRule``

### Use cases

- ``ObserveHalfLifeEstimateUseCase``
- ``RefreshHalfLifeEstimateUseCase``

### Repository

- ``HalfLifeEstimateRepository``
- ``LiveHalfLifeEstimateRepository``

### Data sources

- ``HalfLifeEstimateDataSource``
- ``FileHalfLifeEstimateDataSource``
- ``EstimatedHalfLifeDataSource``
- ``UnavailableHealthDataSource``
