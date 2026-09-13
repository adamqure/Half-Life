# Caffeine Decay Model

How Half-Life calculates the caffeine in your body at any moment, from the drinks you've logged.

## Overview

Every caffeine figure in the app comes from one function: the amount of caffeine in the body at time `t`. That includes the "in your system now" number, the decay curve, and the level at bedtime. This article defines that function, explains why it was chosen, and sets its starting constants.

The model makes four choices:

1. **First-order absorption.** A drink's caffeine doesn't reach the body the moment it's swallowed. It passes from the stomach into the bloodstream at a rate proportional to the caffeine still in the stomach, so a fixed *fraction* of what's left there moves across each minute.
2. **First-order elimination.** The body clears a fixed fraction of the caffeine *in the body* each hour, not a fixed amount. Caffeine still in the stomach isn't cleared, because it hasn't reached the liver yet.
3. **Superposition.** The caffeine from several drinks is the sum of each drink's own curve.
4. **Negligible intakes are dropped.** Once a drink is past its peak and its caffeine falls below 0.5 mg, it stops counting.

Together, the first two give each drink the **Bateman function**. Its level starts at 0, rises to a peak about an hour after drinking, and then decays exponentially.

The model has two parameters, both half-lives:

- The **half-life** (`T½`) is how long the body takes to clear half the caffeine in it. It starts at 5.5 hours for everyone and can later be tuned per user (see "Tuning the half-life" below).
- The **absorption half-life** (`T½a`) is how long the stomach takes to pass half the caffeine still in it into the body. It's 13 minutes for everyone (see "The absorption rate" below).

The first version of this model assumed instant absorption: a drink's whole dose entered the body at the moment it was consumed. Bateman absorption (roadmap rank 5) replaced it on 2026-09-12, at the owner's request. The single-drink worked example below shows both, side by side.

## The decay function

### One drink

A drink's caffeine sits in one of two places: the stomach, or the body. A drink of `D` milligrams consumed at time `t₀` puts all `D` in the stomach. After that, with `τ = t − t₀` the time since it was consumed:

```
G(τ)  = D · e^(−ka · τ)              caffeine still in the stomach
dA/dτ = ka · G(τ) − ke · A(τ)        what arrives in the body, minus what the body clears
```

Elimination acts only on `A`, the caffeine that has reached the body. Solving with `A = 0` at `τ = 0` gives the Bateman function:

```
A(t) = D · ka / (ka − ke) · (e^(−ke · τ) − e^(−ka · τ))    when t ≥ t₀
A(t) = 0                                                   when t < t₀

ke = ln 2 / T½      ka = ln 2 / T½a      τ = t − t₀
```

The rule uses the equivalent half-life form, which needs no logarithms:

```
A(t) = D · T½ / (T½ − T½a) · (2^(−τ / T½) − 2^(−τ / T½a))
```

When the two half-lives are equal, both forms divide by zero. The rule then uses the function's limit, `A(t) = D · ke · τ · e^(−ke · τ)`. Real caffeine is nowhere near this case, but a tuned rate could be, so the rule handles it.

| Symbol | Meaning | Unit |
|--------|---------|------|
| `A(t)` | Caffeine in the body at time `t` | mg |
| `G(τ)` | Caffeine still in the stomach, `τ` after the drink | mg |
| `D` | Caffeine in the drink (dose) | mg |
| `t₀` | Time the drink was consumed | time |
| `t` | Time being evaluated | time |
| `τ` | Time since the drink was consumed, `t − t₀` | hours |
| `T½` | Elimination half-life | hours |
| `T½a` | Absorption half-life | minutes |
| `ke` | Elimination rate constant | per hour |
| `ka` | Absorption rate constant | per hour |

### The peak

A drink's level rises while more caffeine arrives than the body clears, and it peaks when the two are equal. That happens `p` after it's consumed:

```
p = ln(ka / ke) / (ka − ke)
  = T½a · T½ · log₂(T½ / T½a) / (T½ − T½a)
```

With the standard constants, every drink peaks **63.14 minutes** after it's consumed, whatever its size, at **87.58%** of its dose. It never reaches 100%, because the body starts clearing the first caffeine before the last has arrived. At its peak, a drink holds exactly what instant absorption would have left by then. After its peak, its level only falls.

### Once absorbed, a drink decays as if it arrived late

The stomach term `e^(−ka · τ)` shrinks about 25 times faster than the body term. 99% of a drink has left the stomach 86 minutes after it's consumed. From then on, a drink decays like an instantly absorbed dose that arrived `δ` after it was actually drunk:

```
A(t) ≈ D · 2^(−(τ − δ) / T½)      once the drink is absorbed

δ = T½ · log₂(T½ / (T½ − T½a)) ≈ 19.13 minutes
```

That's the most useful way to picture the change from instant absorption. For the first hour or so, Bateman shows less caffeine, because the drink is still arriving. After that, it shows slightly more, as if every drink had been drunk 19 minutes later.

### Several drinks: superposition

The total at time `t` is the sum of every drink consumed at or before `t`:

```
A(t) = Σ  Dᵢ · f(t − tᵢ)
      i : tᵢ ≤ t

f(τ) = T½ / (T½ − T½a) · (2^(−τ / T½) − 2^(−τ / T½a))
```

`f(τ)` is the fraction of a dose in the body `τ` after it's consumed. Drinks consumed after `t` add nothing to `A(t)`.

Superposition is valid because both absorption and elimination are first-order, which makes the model **linear**. The fraction moved or cleared each minute doesn't depend on how much caffeine there is, so drinks don't interact. Each one follows its own curve, and the total is their sum. The curve doesn't jump at a drink. It rises over the hour after each one, then decays smoothly.

### When will I be below X?

Under instant absorption, the total after the last drink was a single exponential, so "*when* will I be below `X` mg?" had an exact closed-form answer. Under Bateman, each drink's curve is the difference of two exponentials, so the exact answer has to be found numerically. Once the last drink is absorbed, the total is a single exponential again, to a close approximation, and the closed form works from any moment `s` after that:

```
t = s + T½ · log₂(A(s) / X)         when A(s) > X
```

From 90 minutes after the last drink, the caffeine still in the stomach is under 1% of that drink's dose, so the answer can be off by at most that much, and the error keeps shrinking. The rule's one "when" answer, the half-gone time (RULE-8), uses bisection instead, so it's exact to within a millisecond at any time.

### Dropping negligible intakes

Mathematically, a drink never reaches zero. The rule stops counting a drink once its caffeine is **negligible**, which means below `ε` = 0.5 mg, but only once the drink is past its peak. A new drink starts at 0 mg and rises, so "below `ε`" on its own would drop every drink the moment it's logged:

```
A(t) = Σ  Dᵢ · f(t − tᵢ)
      i : tᵢ ≤ t,  and either  t < tᵢ + p  or  Dᵢ · f(t − tᵢ) ≥ ε
```

So **an intake counts from the moment it's consumed until it's past its peak and below `ε`**, and never again afterwards, because after its peak its level only falls. A drink consumed at exactly `t` counts, at 0 mg. It stops counting at about this time:

```
tᵢ + δ + T½ · log₂(Dᵢ / ε)
```

The rule doesn't use this formula. It checks each intake's level directly. For real doses, the formula matches it to well under a second.

"Negligible" means the amount is below the model's own precision. It isn't a statistical test, because the model is deterministic. The brief's 5–6 hour range alone moves the bedtime figure by about ±7 mg, so a remainder under 0.5 mg is well inside the model's error.

Dropping intakes has these effects:

- **The total steps down by less than 0.5 mg when an intake is dropped.** Whether the step shows depends on how presentation rounds. At two decimal places, a drink that's the only one still counting goes from 0.50 mg to 0.00 mg. Rounded to whole milligrams, the step is at most a 1 mg tick that comes slightly early.
- **The error stays small.** At any moment, the curve understates the true total by the sum of the dropped tails. Each tail was below 0.5 mg when it was dropped, and keeps shrinking.
- **The work is bounded.** Every intake drops out within about `δ + T½ · log₂(D / ε)`. At the default constants, that's under 2 days for a 200 mg drink and about 2.5 days even for 1,000 mg, and once an intake is marked negligible, the repository no longer fetches it. The window grows with the half-life: at 10 hours, 1,000 mg takes about 4.6 days.
- **The closed-form "when" answer can be slightly off for small targets.** Besides the stomach error above, it can miss by up to 0.5 mg for each intake dropped between `s` and `t`. That matters only for targets `X` of a few milligrams.
- **An intake of less than 0.5 mg counts only until its peak.** It never reaches 0.5 mg, so it's dropped the moment it peaks. Real drinks are well above this.

## Constants

| Constant | Starting value | Notes |
|----------|----------------|-------|
| Half-life `T½` | **5.5 hours** (19,800 s) | The midpoint of the brief's "roughly 5–6 hours". It's the model's per-user parameter. |
| Elimination rate `ke` | ln 2 / 5.5 h ≈ **0.1260 h⁻¹** (≈ 3.5007 × 10⁻⁵ s⁻¹) | Always derived from `T½`, never set or stored separately. |
| Absorption half-life `T½a` | **13 minutes** (780 s) | The owner's choice on 2026-09-12, from the research in "The absorption rate" below. It's the same for everyone and every drink. |
| Absorption rate `ka` | ln 2 / 13 min ≈ **3.199 h⁻¹** | Always derived from `T½a`, never set or stored separately. |
| Time to peak `p` | **63.14 minutes** (3,788.64 s) | Derived from both half-lives. Every drink peaks this long after it's consumed. |
| Absorption delay `δ` | **19.13 minutes** (1,148.07 s) | Derived from both half-lives. Once absorbed, a drink decays as if it had arrived this much later. |
| Negligible amount `ε` | **0.5 mg** | An intake past its peak stops counting once its caffeine falls below this. It's the same for everyone and isn't tuned. |
| Curve window | **12 hours** either side of the current time | The span the curve covers: 1,440 one-minute samples. The window is part of the Domain rule, because the rule decides negligibility at the window's first sample. |
| Curve spacing | **1 minute** (60 s) | The time between samples, which fall on whole clock minutes. People mostly look at the next few hours, so the curve starts at minute precision. It's a single constant so that it can be widened later. |

Amounts are in milligrams. This article uses hours and minutes to keep the numbers readable. In code, times are Foundation `Date` values and durations are `TimeInterval` seconds, so the default half-life is 19,800 seconds and the default absorption half-life is 780 seconds.

## The absorption rate

Caffeine taken by mouth is absorbed quickly and almost completely, but studies disagree about how quickly. Most report the time to peak, `Tmax`, rather than `ka`. With the standard half-life, each `Tmax` implies a `ka`, calculated from the peak formula above:

| Study | What people took | Time to peak | `ka` |
|-------|------------------|--------------|------|
| Blanchard & Sawers, 1983 | 5 mg/kg of caffeine in water | 30 ± 8 min | ≈ 8.6 h⁻¹ (implied) |
| Liguori, Hughes & Grass, 1997 | 400 mg in coffee or cola | 42 and 39 min, measured in saliva | ≈ 5.5–6.1 h⁻¹ (implied) |
| White et al., 2016 | 160 mg in hot or cold coffee | 59–64 min | ≈ 3.1–3.5 h⁻¹ (implied) |
| White et al., 2016 | 160 mg in an energy drink | 70–82 min | ≈ 2.2–2.8 h⁻¹ (implied) |
| Kamimori et al., 2002 | 50–200 mg in capsules | 84–120 min | 1.29–2.36 h⁻¹ (measured) |
| Kamimori et al., 2002 | 50–200 mg in chewing gum | 44–80 min | 3.21–3.96 h⁻¹ (measured) |
| Bonati et al., 1982 | Caffeine in water, coffee, and soft drinks | 1–2 h | ≈ 1.3–3.4 h⁻¹ (implied) |

- The Institute of Medicine's review summarizes absorption as "99 percent being absorbed within 45 minutes of ingestion," with peaks "between 15 and 120 minutes after oral ingestion." It attributes the spread to gastric emptying and to other things eaten, such as fiber.
- A population study of 59 men found that the absorption rate varies by about 51% between people (Seng et al., 2009).
- White et al. found little difference between drinking a coffee over 2 minutes and over 20.

**Why 13 minutes.** The owner chose it on 2026-09-12. The three options offered were:

- 7.5 minutes, matching Liguori's coffee and cola;
- 10 minutes, the AI's recommendation, between the two coffee studies;
- 13 minutes, matching White et al.'s coffee.

White et al.'s is the most recent of these studies, and coffee is the drink people log most. With 13 minutes, a drink peaks 63 minutes after it's consumed, and 99% of it has left the stomach after 86 minutes.

### How much the absorption rate matters

This is 200 mg at 4:00pm, with the standard half-life:

| Absorption half-life | Peak after | Level at 4:30pm | Level at 11:00pm |
|---------------------:|-----------:|----------------:|-----------------:|
| Instant | 0 min | 187.79 mg | 82.78 mg |
| 5 min | 30.7 min | 187.50 mg | 84.05 mg |
| 7.5 min | 41.9 min | 179.36 mg | 84.70 mg |
| 10 min | 52.0 min | 167.87 mg | 85.36 mg |
| **13 min** | **63.1 min** | **153.43 mg** | **86.17 mg** |
| 20 min | 86.1 min | 124.63 mg | 88.12 mg |
| 30 min | 114.2 min | 96.56 mg | 91.04 mg |

The absorption rate decides the first hour or two: how fast a new cup shows up in the figure, and when it peaks. By bedtime, it moves the figure by a few milligrams, less than the brief's 5–6 hour range for the half-life does. So the half-life stays the parameter worth tuning per person, and one absorption rate for everyone is a fair start.

### Sources

- Blanchard J, Sawers SJ. [The absolute bioavailability of caffeine in man](https://pubmed.ncbi.nlm.nih.gov/6832208/). *European Journal of Clinical Pharmacology*, 1983.
- Bonati M, et al. Caffeine disposition after oral doses. *Clinical Pharmacology & Therapeutics*, 1982.
- Liguori A, Hughes JR, Grass JA. [Absorption and subjective effects of caffeine from coffee, cola and capsules](https://www.sciencedirect.com/science/article/abs/pii/S0091305797000038). *Pharmacology Biochemistry and Behavior*, 1997.
- Kamimori GH, et al. [The rate of absorption and relative bioavailability of caffeine administered in chewing gum versus capsules to normal healthy volunteers](https://www.sciencedirect.com/science/article/abs/pii/S0378517301009589). *International Journal of Pharmaceutics*, 2002.
- White JR Jr, et al. [Pharmacokinetic analysis and comparison of caffeine administered rapidly or slowly in coffee chilled or hot versus chilled energy drink in healthy young adults](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4898153/). *Clinical Toxicology*, 2016.
- Seng KY, et al. [Population pharmacokinetics of caffeine in healthy male adults using mixed-effects models](https://pubmed.ncbi.nlm.nih.gov/19125908/). 2009.
- Institute of Medicine. [Pharmacology of Caffeine](https://www.ncbi.nlm.nih.gov/books/NBK223808/), in *Caffeine for the Sustainment of Mental Task Performance*, 2001.

The AI read each study's abstract, and White et al.'s full text, on 2026-09-12. It didn't read the other studies' full texts.

## Entities

The model reads the first four Domain entities below and produces the fifth, ``CaffeineLevel``. Each is a plain `Sendable`, `Equatable` value type with no framework dependencies (constitution Article I.10). The entities describe what goes into the model and what comes out of it, not how the curve is calculated.

### CaffeineIntake

One drink's caffeine entering the body. It's `Identifiable`.

| Property | Type | Meaning |
|----------|------|---------|
| `id` | `UUID` | Identifies the intake, so it can be listed, edited, or deleted. |
| `milligrams` | `Double` | The dose `D`. Always greater than zero. |
| `consumedAt` | `Date` | The time `t₀` the drink was consumed. |

An intake records when the drink was *consumed*, not when it was logged. The two differ whenever someone logs after drinking, as with the composer's "1h ago" option or retroactive timing (roadmap rank 17). The model needs the moment the caffeine reached the stomach.

An intake holds only what the model needs. A drink's name, size, and other details belong to the drink composer's own types (see <doc:DrinkComposer>). An intake is just the caffeine those details come down to.

The negligible mark (see "Where the calculation lives") isn't part of `CaffeineIntake` either. The data source stores it alongside the intake, and the Domain never sees it.

### CaffeineHalfLife

The user's elimination half-life `T½`.

| Property | Type | Meaning |
|----------|------|---------|
| `seconds` | `TimeInterval` | The half-life. Always greater than zero. |

- A `standard` value of 19,800 s (5.5 h) applies until the user's own half-life is known.
- The elimination rate `ke` is derived from it as `ln 2 / seconds`, and is never stored.

This is a dedicated type rather than a bare `TimeInterval`. That keeps the greater-than-zero rule and the derivation of `ke` in one place, and gives the tuning features (roadmap ranks 6, 9, and 21) a single value to produce.

### CaffeineAbsorptionRate

How fast a drink's caffeine passes from the stomach into the body.

| Property | Type | Meaning |
|----------|------|---------|
| `halfLifeSeconds` | `TimeInterval` | The absorption half-life `T½a`. Always greater than zero. |

- A `standard` value of 780 s (13 minutes) applies to everyone.
- The absorption rate `ka` is derived from it as `ln 2 / halfLifeSeconds`, and is never stored.

The owner decided on 2026-09-11 that the absorption rate would be an entity of its own. It's stored as a half-life, like `CaffeineHalfLife`, so the model's two parameters read the same way and the rule can use the half-life form of the Bateman function.

### CaffeineKinetics

The model's two parameters together, as the rules take them.

| Property | Type | Meaning |
|----------|------|---------|
| `halfLife` | `CaffeineHalfLife` | The elimination half-life `T½`. |
| `absorption` | `CaffeineAbsorptionRate` | The absorption half-life `T½a`. |

- A `standard` value combines the two standard values.
- The repository reads each parameter from its own data source and combines them. Each is still its own entity, so the tuning features still produce a `CaffeineHalfLife`.

The owner chose this bundle on 2026-09-12. The second parameter would otherwise have given ``CaffeineStatusRule``'s one operation six parameters, one more than SwiftLint allows (constitution Article IX). The two parameters always travel together, so one value is also the clearer input.

### CaffeineLevel

The model's output: the caffeine in the body at one moment.

| Property | Type | Meaning |
|----------|------|---------|
| `date` | `Date` | The time `t` being evaluated. |
| `milligrams` | `Double` | `A(t)`. Never negative. |

A curve is an array of levels in time order. The Today screen's "in your system now" figure is a single level, and its chart is a curve.

### What Bateman absorption changed

| Entity | Instant absorption | Bateman absorption |
|--------|--------------------|--------------------|
| `CaffeineIntake` | Dose and time consumed | Unchanged |
| `CaffeineHalfLife` | Elimination half-life | Unchanged: the elimination half-life means the same thing in both models |
| `CaffeineLevel` | Milligrams at a moment | Unchanged |
| `CaffeineAbsorptionRate` | Didn't exist | New: the absorption half-life |
| `CaffeineKinetics` | Didn't exist | New: the half-life and the absorption rate together |

The new parameter is a new entity, so the other three didn't change. The rules' operations take a `CaffeineKinetics` where they took a `CaffeineHalfLife`, and the repository reads the absorption rate from a new data source.

### Units

Amounts are `Double` milligrams and durations are `TimeInterval` seconds, with the unit in each property's name. The model is pure arithmetic on these values, and `Date` arithmetic already uses `TimeInterval`. Wrapping the values in `Measurement` would add a conversion to every calculation and gain nothing inside the Domain. The model's values are specified and tested to two decimal places, and the rule doesn't round them. Presentation converts to `Measurement` when it formats a value, and can round further for display, for example to whole milligrams. Everything users see stays locale-aware (constitution Article VII.3).

## Where the calculation lives

The decay function lives in the Domain layer as a **business rule**. That's a stateless type, `CaffeineDecayRule`, that turns intakes, a half-life, and an absorption rate into caffeine levels. It depends only on the entities above and on Foundation.

- **``LiveCaffeineDecayRepository`` executes the rule.** It reads the drinks that aren't marked negligible from ``DrinkLogDataSource`` and maps them to their intakes. It reads the half-life from ``HalfLifeDataSource`` and the absorption rate from ``AbsorptionRateDataSource``, and combines them into a ``CaffeineKinetics``. It reads the current time from ``ClockDataSource``. Then it applies the rule for the current time, and publishes the resulting curve on its `AsyncStream`.
- **New intakes arrive from the data source.** Drinks are stored through `DrinkLogRepository` (see <doc:DrinkComposer>). The intake data source then signals a change to this repository, which re-fetches the intakes that aren't marked negligible, recalculates, and publishes the curve. Nothing adds an intake to this repository directly.
- **The half-life comes from a half-life data source.** ``FileProfileDataSource`` supplies the starting half-life that onboarding stored with the user's profile, or ``CaffeineHalfLife/standard`` until onboarding stores one (<doc:Onboarding>). It signals a change after each store, and the repository recalculates (REPO-11).
- **The absorption rate comes from an absorption rate data source.** ``StandardAbsorptionRateDataSource`` supplies ``CaffeineAbsorptionRate/standard``. On 2026-09-12 the owner chose a data source over a constant in the rule, so that a tuned rate can replace the standard one the way a tuned half-life will, without changing the repository.
- **The curve covers a fixed window.** It runs from 12 hours before the current time to 12 hours after: 1,440 levels, one per minute. The window belongs to the Domain, not to presentation, because the rule decides negligibility at the window's first sample.
- **The repository marks intakes that no longer count.** An intake is negligible once it's past its peak and below 0.5 mg at the window's first sample. When the rule returns such intakes, the repository has the data source mark them, so later fetches skip them. A mark is state on the intake that the data source stores, and it's never cleared. A marked intake adds nothing anywhere in the window, so marking only saves work: the curve is the same whether or not an intake has been marked yet.
- **Features observe the curve.** `ObserveCaffeineCurveUseCase` streams the curve to features (constitution Article I.4). There's no use case for the calculation itself: nothing asks for a calculation on its own, and features only need the curve.
- **The repository recalculates on refresh, not on a timer.** It recalculates when the data the curve comes from changes, and when a feature starts observing, which happens each time a view appears. The window reaches 12 hours ahead, so a curve stays usable for up to 12 hours after it's calculated. There's no need to recalculate 1,440 levels every minute.
  - **The caffeine status is the one exception.** On 2026-09-11 the owner decided that the repository also publishes the current level and the decay card's two tips, recalculated at every whole minute while anyone observes them, because they're about the current time (REPO-7 to REPO-10, and <doc:TodayScreen>). The curve itself still never recalculates on a timer.
- **Presentation chooses what to show.** Each feature shows the whole window or a part of it, such as the next few hours. It reads the current level from the sample for the current minute, found by date. That's the middle sample when the curve is calculated, and it moves later in the window as time passes. A feature can move its "now" marker along the curve it already has without asking for a new one. It never evaluates the decay function itself.
- **Bateman absorption changed the rule and added one input.** The rule's operations take a ``CaffeineKinetics`` where they took a half-life, and the repository reads the absorption rate from its data source. The use cases, the features, and the three original entities didn't change.
- **It's wired for the app.** `\.caffeineDecayRepository`, `\.observeCaffeineCurve`, and `\.observeCaffeineStatus` are registered in `CaffeineDecayDependencies.swift` (constitution Article I.15).
  - Live, the repository reads the device's store through the shared ``DrinkLogDataSourceKey``, with the shared ``ProfileDataSourceKey`` data source for the half-life and the bedtime, ``StandardAbsorptionRateDataSource``, and ``SystemClockDataSource``.
  - In previews, it reads an empty in-memory store.
  - In tests, using either value without overriding it reports an issue.

The rule has five operations. Each takes a ``CaffeineKinetics``, as well as what the table lists:

| Operation | Takes | Returns |
|-----------|-------|---------|
| Level | Intakes and a moment `t` | The `CaffeineLevel` at `t` |
| Counting | An intake and a moment `t` | Whether the intake counts at `t` |
| Curve | Intakes and the current time | `[CaffeineLevel]`: 1,440 levels, one per minute, across the window |
| Negligible intakes | Intakes and the current time | The intakes that are negligible at the window's first sample |
| Half gone | An intake | When the intake's own level falls to half its dose, after its peak |

The Level and Curve operations leave out negligible intakes (see "Dropping negligible intakes" above). ``CaffeineStatusRule`` uses Counting and Half gone for the decay card's tips (<doc:TodayScreen>).

The curve always holds 1,440 levels, however many intakes are counting. That's about 23 KB at 16 bytes per level. If the size ever becomes a problem, the spacing constant can be widened.

The repository publishes the **active curve**: the window around the current time. Past-day curves, like the Insights tab's, will read intakes through a separate path to the data source that includes marked ones. That path is designed separately.

Because marks are never cleared, a marked intake stays out of the active curve even when a later change would make it count again. The main case is a longer tuned half-life. The error this causes is small. At the default constants, a 200 mg intake is marked 59.86 hours after it's consumed. At that moment it would still hold 0.21 mg under a 6-hour half-life, 0.55 mg under 7 hours, or 1.15 mg under 8 hours, and those amounts keep shrinking.

Deferred:

- **When a view refreshes is a presentation concern, to revisit when the first feature shows the curve.** The repository calculates a fresh curve for each new subscriber. Presentation decides when to subscribe again, for example when the app returns to the foreground. A view's `.task` doesn't restart on foregrounding. So an app left in memory from 8am until 9pm would still hold the 8am curve, and that curve ends at 8pm.

## Testable requirements

Each requirement is written so that one test can prove it. Tests refer to requirements by their IDs.

### CaffeineDecayRule

Unit-tested directly. The rule is pure, so its tests need no fakes.

| ID | Requirement |
|----|-------------|
| RULE-1 | The level at `t` is the sum of `Dᵢ · T½ / (T½ − T½a) · (2^(−(t − tᵢ) / T½) − 2^(−(t − tᵢ) / T½a))` over the intakes that count at `t`. When the two half-lives are equal, it's the formula's limit, and nearly equal half-lives give nearly the same level. It matches every worked example below to two decimal places. |
| RULE-2 | An intake adds nothing before its `consumedAt`, and nothing at exactly `consumedAt`. With the standard constants, it peaks 63.14 minutes later, at 87.58% of its dose. |
| RULE-3 | An intake counts from exactly its `consumedAt` until it's past its peak and below 0.5 mg, including while it holds less than 0.5 mg on its way up. For example, a 128 mg intake counts 159,548 seconds after `consumedAt`, and not a second later. The Counting operation gives the same answer as the Level operation. |
| RULE-4 | Given the current time, the rule returns exactly the intakes that are past their peak and below 0.5 mg at the window's first sample. Being negligible is a normal result, so the rule returns it rather than throwing. An intake that isn't past its peak at the first sample, including one consumed later, is never negligible. |
| RULE-5 | The curve has exactly 1,440 levels. The first is at the current time rounded down to the minute, minus 12 hours, and the level at index 720 is for the current minute. With no intakes, every level is 0. |
| RULE-6 | The rule reads no clock and holds no state. The current time is an input, and the same inputs always give the same outputs. |
| RULE-7 | The curve's samples are exactly one minute apart, on whole clock minutes. The spacing and the window are constants. |
| RULE-8 | An intake is half gone at the first moment, at or after its peak, when its own level is at most half its dose, found to within a millisecond. With the standard constants, that's 20,948.07 seconds (5 hours 49 minutes 8 seconds) after it's consumed, for any dose. An intake that never reaches half its dose is half gone at its peak. |
| RULE-9 | The rule reports how long an intake takes to peak: 3,788.64 seconds (63.14 minutes) with the standard constants, for any dose. ``CaffeineCutoffRule`` uses it, so the cutoff only considers cups that peak by bedtime (<doc:CaffeineCutoff>). |

### CaffeineDecayRepository

Tested against a fake intake data source and a fixed current time.

| ID | Requirement |
|----|-------------|
| REPO-1 | It asks the data source only for intakes that aren't marked negligible. |
| REPO-2 | It publishes on an `AsyncStream` (constitution Article I.12). Each new subscriber immediately gets a curve calculated for the current time, and every subscriber gets a new curve whenever the data the curve comes from changes. It never recalculates the curve on a timer. The caffeine status is the one exception (REPO-8). |
| REPO-3 | When the rule returns intakes that are negligible at the window's first sample, it has the data source mark exactly those intakes, and no others. |
| REPO-4 | Every level in the published curve is the same whether or not negligible intakes have been marked yet. |
| REPO-5 | When the intake data source signals a change, it re-fetches the intakes that aren't marked negligible and publishes a recalculated curve to every subscriber. |
| REPO-6 | It calculates the curve and the status with the half-life and the absorption rate that it reads from their data sources. |
| REPO-7 | `status(in:)` publishes the caffeine status on an `AsyncStream`. Each new subscriber immediately gets a status that ``CaffeineStatusRule`` calculates for the current time, from the intakes that aren't marked negligible. |
| REPO-8 | After that, it publishes a new status for every minute the clock data source streams. The status is the one thing the repository recalculates on a timer, and the curve never follows the clock. |
| REPO-9 | When the intake data source signals a change, it publishes a recalculated status to every status subscriber, as well as a recalculated curve. |
| REPO-10 | It calculates the status with the bedtime it reads from the bedtime data source, in the calendar each subscriber gives. |

The repository's third stream, the cutoff, has its own requirements, CUTREPO-1 to CUTREPO-4, in <doc:CaffeineCutoff>.

### Intake data source

The intake data source is ``DrinkLogDataSource`` (<doc:DrinkComposer>), implemented by ``SwiftDataDrinkLogDataSource``. It stores drinks, and the repository maps the drinks it returns to their intakes. Tested against an in-memory store with CloudKit off.

| ID | Requirement |
|----|-------------|
| DATA-1 | `nonNegligibleDrinks()`, its query for the active curve, returns only drinks that aren't marked negligible. |
| DATA-2 | It marks the given intakes as negligible. The marks persist and are never cleared. |
| DATA-3 | Marking never deletes an intake. The full history stays stored for other features, such as past-day curves, which read it through a separate path. |
| DATA-4 | It stores a new intake unmarked. |
| DATA-5 | It signals a change to every subscribed repository after each successful store, and not after marking. |

### Half-life data source

Tested in isolation.

| ID | Requirement |
|----|-------------|
| HALF-1 | It returns the current half-life. When no value has been stored, that's `CaffeineHalfLife.standard` (5.5 hours). |

### Absorption rate data source

Tested in isolation.

| ID | Requirement |
|----|-------------|
| ABSORB-1 | It returns the current absorption rate. When no value has been stored, that's `CaffeineAbsorptionRate.standard` (13 minutes). |

The Architecture article's "Data and privacy" table lists the stored drink and its mark (constitution Article V.2). The absorption rate isn't user data: it's the same for everyone, and nothing stores it.

### Presentation

Tested with an exhaustive `TestStore`, with the `Observe…` use case overridden.

| ID | Requirement |
|----|-------------|
| VIEW-1 | A feature shows the curve's whole window or a part of it. It never evaluates the decay function itself. |
| VIEW-2 | Caffeine amounts are formatted with locale-aware APIs (constitution Article VII.3). Each feature chooses how far to round for display, up to the model's two decimal places. |
| VIEW-3 | A feature reads the current level from the sample for the current minute, found by date rather than at a fixed index. The Today screen's decay card reads it from the caffeine status instead (REPO-7, <doc:TodayScreen>). |

## Why this model

- **It matches how caffeine arrives.** Caffeine doesn't reach the bloodstream the moment it's swallowed. It's absorbed from the gut at a rate proportional to the caffeine still there, which is first-order absorption. Instant absorption overstated a new cup: 15 minutes after a 200 mg drink, it showed 193.80 mg against Bateman's 108.17 mg.
- **It matches how caffeine is cleared.** At everyday doses, the liver clears caffeine at a rate proportional to how much is in the body, so a fixed fraction goes each hour. That is first-order elimination, and it produces exponential decay once a drink is absorbed.
- **Neither half-life depends on the dose.** A 100 mg cup and a 400 mg cup both peak 63 minutes after they're consumed, and both are half gone after the same 5 hours 49 minutes. The brief's "200 mg" is the size of its example, not an input to either half-life.
- **It stays close to the brief.** 200 mg at 4:00pm leaves 86.17 mg at 11:00pm, where instant absorption gave 82.78 mg. The brief says "80 mg". Under this model that corresponds to a half-life of about 5.05 hours, still within its 5–6 hour range.
- **It's parameterized by half-lives.** The half-life is the number people understand and the literature reports, and it's the value the app will tune per user. The absorption half-life reads the same way. `ke` and `ka` are derived from them, so each has a single source of truth.
- **It's the simplest model that answers the question honestly** (constitution Article III.1). It has two parameters and one closed-form expression per drink, and it's cheap enough to evaluate at every point along the curve. Only the half-gone time needs a numerical search.

### How much the half-life matters

The brief's own range already moves the bedtime figure. Here is 200 mg at 4:00pm, evaluated at 11:00pm, with the standard absorption half-life:

| Half-life | Remaining at 11:00pm |
|-----------|----------------------|
| 5 hours | 79.22 mg |
| 5.5 hours | 86.17 mg |
| 6 hours | 92.43 mg |

Real people differ far more than that. Half-lives vary several-fold between individuals. Smoking shortens the half-life, while pregnancy, oral contraceptives, and liver impairment lengthen it. That's why the half-life has to be tunable.

## Assumptions and limitations

The app must not claim more precision than this model has (the brief's *Honesty* criterion). Its known simplifications:

- **One absorption rate for every drink and every person.** Food slows absorption, because it delays emptying the stomach. The studies above found capsules and energy drinks slower than coffee, and chewing gum faster, because gum is partly absorbed through the mouth. Between people, the rate varies by about half. The model uses a 13-minute absorption half-life for all of them, so a drink's first hour is its least certain stretch.
- **A drink is drunk in an instant.** The model starts absorbing a drink's whole dose at `consumedAt`, with no delay before absorption begins. Sipping a cup over 20 minutes spreads it out, but White et al. found that made little difference.
- **Complete absorption.** The whole labelled dose is assumed to reach the bloodstream. Caffeine taken by mouth is almost completely absorbed, so this is a small error. The larger uncertainty is how accurate the drink's caffeine estimate is in the first place.
- **Linear kinetics at every dose.** At very high intakes, elimination can slow down, which lengthens the effective half-life. The model ignores this.
- **A constant half-life.** The model applies one half-life at every hour of every day. It ignores changes from medication, illness, pregnancy, or time of day.
- **Amount, not concentration.** `A(t)` is milligrams in the whole body, not blood concentration. Using the amount avoids asking for body weight, but the same number of milligrams has a stronger effect on a smaller person.
- **Caffeine only.** The body converts caffeine into other compounds, mainly paraxanthine, and some of them are also stimulants. The model tracks caffeine alone.

## Rules at the edges

- A drink contributes nothing before the time it was consumed, and nothing at exactly that time. It peaks 63.14 minutes later.
- A drink consumed at the current minute counts, at 0 mg.
- A dose, the half-life, and the absorption half-life are always greater than zero. Inputs are validated before they reach the model.
- When the half-life and the absorption half-life are equal, the rule uses the Bateman function's limit.
- A drink stops counting once it's past its peak and below 0.5 mg. It still counts at exactly 0.5 mg. It's marked 12 hours later, when that's true at the window's first sample.

## Worked examples

These values were computed by a Python script from the formulas above, with `T½ = 5.5 h` and `T½a = 13 min`, and rounded to two decimal places, the precision the model is specified to. They're the reference cases for the model's unit tests (RULE-1).

### One 200 mg drink

The last column is the same drink under instant absorption, which the model used before Bateman.

| Hours since drinking | Fraction in the body | In the body | Instant absorption |
|---------------------:|---------------------:|------------:|-------------------:|
| 0 | 0.0000 | 0.00 mg | 200.00 mg |
| 0.25 | 0.5409 | 108.17 mg | 193.80 mg |
| 0.5 | 0.7672 | 153.43 mg | 187.79 mg |
| 1 | 0.8753 | 175.05 mg | 176.32 mg |
| 1.05 (the peak) | 0.8758 | 175.16 mg | 175.16 mg |
| 2 | 0.8073 | 161.47 mg | 155.44 mg |
| 4 | 0.6288 | 125.76 mg | 120.81 mg |
| 5.5 | 0.5205 | 104.10 mg | 100.00 mg |
| 7 | 0.4308 | 86.17 mg | 82.78 mg |
| 11 | 0.2603 | 52.05 mg | 50.00 mg |
| 16.5 | 0.1301 | 26.03 mg | 25.00 mg |
| 24 | 0.0506 | 10.11 mg | 9.72 mg |

### A day of drinks

The drinks: 128 mg at 8:00am, 64 mg at 10:45am, and 205 mg at 3:00pm.

| Time | From 8:00am | From 10:45am | From 3:00pm | Total |
|------|------------:|-------------:|------------:|------:|
| 7:59am | — | — | — | 0.00 mg |
| 8:00am | 0.00 | — | — | 0.00 mg |
| 8:30am | 98.20 | — | — | 98.20 mg |
| 10:45am | 94.20 | 0.00 | — | 94.20 mg |
| 12:00pm | 80.49 | 55.69 | — | 136.18 mg |
| 3:00pm | 55.15 | 39.00 | 0.00 | 94.14 mg |
| 4:00pm | 48.62 | 34.38 | 179.43 | 262.43 mg |
| 11:00pm | 20.12 | 14.23 | 77.87 | 112.22 mg |

Each column is rounded on its own, so a row's columns can add up to 0.01 mg more or less than its total, as at 3:00pm.

Two checks:

- Every drink is absorbed by 11:00pm, so the total equals the instant model's with each drink moved `δ` = 19.13 minutes later. Both give 112.22 mg.
- The total falls below 50 mg at about **5:25am** the next morning, found numerically. Under instant absorption, it was about 5:06am.

### When intakes drop out

| Dose | Stops counting after | Marked after |
|-----:|---------------------:|-------------:|
| 64 mg | 38.82 h | 50.82 h |
| 128 mg | 44.32 h | 56.32 h |
| 200 mg | 47.86 h | 59.86 h |
| 400 mg | 53.36 h | 65.36 h |

Each time is `δ` = 19.13 minutes later than it was under instant absorption. A 128 mg intake falls below 0.5 mg 159,548.07 seconds (44 hours 19 minutes 8 seconds) after it's consumed, so it counts at 159,548 seconds and not at 159,549. It's marked at 56 hours 20 minutes, the first minute when the window's first sample is past that moment. In the day of drinks above, the 8:00am drink stops counting at about 4:19am two days later.

### Half gone

Any intake is half gone 20,948.07 seconds (5 hours 49 minutes 8 seconds) after it's consumed: one half-life plus `δ`. The day of drinks' last cup, at 3:00pm, is half gone at about 8:49pm.

## Tuning the half-life

The half-life is the model's per-user parameter. Everyone starts at 5.5 hours. Later features refine it:

- The onboarding survey (roadmap rank 6) sets an informed starting value, from 3 to 40 hours (<doc:Onboarding>).
- The personal half-life estimator (rank 9) updates it with the user's own nights, and stores the estimate on the device. The decay repository reads the half-life through ``EstimatedHalfLifeDataSource``, so the curve adopts each estimate automatically (<doc:HalfLifeEstimator>).
- Settings (rank 21) lets the user override it.

The function itself doesn't change: it takes the half-life as an input.

The absorption rate could be tuned the same way, per person or per kind of drink, through its data source. Nothing on the roadmap does that yet.
