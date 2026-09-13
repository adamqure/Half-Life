# Drink Composer

The Domain entities and repository behind logging a drink, shared by the composer, one-tap favourites, and Siri.

## Overview

The drink composer is how a user records the caffeine they've had (roadmap rank 2). It's the first of three entry points that record a drink. The others are one-tap favourites (rank 3) and App Intents, which include Siri (rank 14). All three produce the same entity and go through the same use case and repository. The decay curve learns about each drink from the data source it shares with that repository. This article defines those shared pieces, and extracts them from the brief and the prototype.

The composer doesn't build a drink from parts, as the prototype's "Build it" grid does. The user picks a drink from a row of tiles that scrolls sideways, then adjusts its quantity with a stepper. One-tap favourites show the three drinks the user logs most, on the Today screen and above the composer's tiles (<doc:OneTapLog>).

This article covers the Domain layer, the repository, the data flow from the list to the decay curve, and the composer screen.

> Note: The Domain layer and the current time are built: ``DrinkType``, ``ServingUnit``, ``LoggedDrink``, ``DrinkLogRule``, the ``DrinkLogRepository`` and ``CurrentTimeRepository`` protocols, ``LogDrinkUseCase``, ``ClockDataSource``, ``SystemClockDataSource``, and ``LiveCurrentTimeRepository``. The drink log data source is built too: ``DrinkLogDataSource``, implemented by ``SwiftDataDrinkLogDataSource``. So is the composer: ``DrinkComposerFeature`` and ``DrinkComposerView``, presented from the root ``AppFeature``, and the drink log repository's implementation, ``LiveDrinkLogRepository``. Add stores drinks through it. One-tap favourites are built too (<doc:OneTapLog>).

## What the brief and prototype ask for

Each prototype element either becomes part of an entity, stays in presentation, or is cut.

| Prototype element (screenshots 07, 09–11) | Becomes |
|-------------------------------------------|---------|
| "Build it" tiles: Espresso, Drip coffee, Latte, Cold brew, Matcha, Black tea | `DrinkType` cases. The grid is replaced by a row of tiles, one per case, that scrolls sideways. |
| "Latte · 2 shots", with the Shots stepper | `LoggedDrink.quantity`, counted in the drink's `ServingUnit` |
| "128 mg" and "Add 128 mg" | `LoggedDrink.milligrams`, estimated as the drink's caffeine per unit × quantity |
| "When": Now, 1h ago, 2h ago, 4h ago | `LogDrinkUseCase.Input.secondsAgo`. The use case subtracts it from the current time to get `LoggedDrink.consumedAt`. |
| "Logged today": time, drink, mg, and × | A list of `LoggedDrink`s, from `DrinkLogRepository` |
| One-tap favourites: Double espresso, Oat flat white, Cold brew | The three drinks, each with its quantity, that the user logs most, derived from the log, with starters until there are three. Nothing extra is stored (<doc:OneTapLog>). |
| The ring icon on each tile | Replaced by an icon for each drink (see "Iconography") |
| "Oat" in "Oat flat white" | Cut. Milk doesn't change the caffeine, and the app answers one question: *when*. |
| The post-cutoff warning ("about 51 mg will still be in you at bedtime") | Not part of these entities. Built on 2026-09-12 as the composer's cutoff warning ("The cutoff warning" below, and <doc:CaffeineCutoff>). |

The brief limits the drink list: "Don't build … a drink database beyond ~15 common items." The catalog below has 13.

## Entities

Each entity is a plain `Sendable`, `Equatable` value type that imports only Foundation (constitution Article I.10). None of them holds user-facing text or icons. Names, unit labels, and icons live in presentation (see "Presentation").

### DrinkType

An enum with one case per drink in the catalog. It's `CaseIterable`, and the order of `allCases` is the list's display order.

| Property | Type | Meaning |
|----------|------|---------|
| `rawValue` | `String` | Stored with every logged drink. Never changed or reused once shipped. |
| `unit` | `ServingUnit` | What the quantity counts: shots, cups, or cans. |
| `milligramsPerUnit` | `Double` | The estimated caffeine in one unit. Always greater than zero. |
| `defaultQuantity` | `Int` | The quantity the composer starts at. At least 1. |

It has one operation: `estimatedMilligrams(quantity:)`, which returns `milligramsPerUnit × quantity`.

A drink's type is an enum rather than data loaded at runtime, because the list is fixed and short, and App Intents needs it at compile time. An App Intent parameter that offers a fixed list is an `AppEnum`, whose cases and display names are static. If users could ever add their own drinks, the catalog would move into a repository.

Once shipped, cases are never removed and raw values never change. Stored drinks refer to them.

### ServingUnit

What a drink's quantity counts.

| Case | Used for | One unit is |
|------|----------|-------------|
| `shot` | Espresso drinks | One espresso shot, 1 US fl oz (about 30 mL) |
| `cup` | Brewed coffee and tea | 8 US fl oz (about 237 mL). For matcha, one drink made with a level teaspoon of powder. |
| `can` | Canned drinks | The drink's standard can, which differs by drink (see "Catalog") |

> Note: This refines the owner's rule of "shots if coffee, cups if not". Drip coffee, cold brew, and instant coffee are coffee, but they aren't made from shots. Cola and energy drinks come in cans of different sizes. The owner accepted the refinement on 2026-09-11.

### LoggedDrink

One drink the user consumed. It's `Identifiable`.

| Property | Type | Meaning |
|----------|------|---------|
| `id` | `UUID` | Identifies the drink, so it can be listed, and later deleted or edited. A new drink gets a new `UUID` by default. |
| `type` | `DrinkType` | Which drink. |
| `quantity` | `Int` | How many units of the drink's `ServingUnit`. At least 1, which ``DrinkLogRule`` enforces. |
| `milligrams` | `Double` | The total estimated caffeine. Always greater than zero. |
| `consumedAt` | `Date` | When the drink was consumed. |

- **`milligrams` is stored, not recalculated.** It's `type.estimatedMilligrams(quantity:)` at the moment the drink is logged. If a later version corrects a drink's caffeine per unit, drinks already logged keep their amounts, so history and past curves don't change.
- **`consumedAt` is when the drink was consumed, not when it was logged.** This follows `CaffeineIntake` (<doc:CaffeineDecayModel>). The two differ whenever the user picks "1h ago".
- **A logged drink comes down to one caffeine intake.** Its `intake` property returns a `CaffeineIntake` with the same `id`, `milligrams`, and `consumedAt`. That's all the decay model needs. The shared `id` means that deleting a drink (rank 20) identifies its intake too.

```swift
/// One drink the user consumed.
struct LoggedDrink: Identifiable, Equatable, Sendable {
    let id: UUID
    let type: DrinkType
    let quantity: Int
    let milligrams: Double
    let consumedAt: Date

    init(id: UUID = UUID(), type: DrinkType, quantity: Int, milligrams: Double, consumedAt: Date)

    /// The caffeine this drink put into the body, for the decay model.
    var intake: CaffeineIntake {
        CaffeineIntake(id: id, milligrams: milligrams, consumedAt: consumedAt)
    }
}
```

## Catalog

These are the drinks, with their estimated caffeine. Each estimate comes from the most direct source found on 2026-09-11. For brewed drinks, that's the USDA's FoodData Central (SR Legacy), converted from milligrams per 100 g at 29.57 g per US fl oz. For branded canned drinks, it's the maker's declared amount. The estimates keep the source's precision, up to one decimal place, and presentation rounds them for display (constitution Article VII.3).

| Case | Unit | Caffeine per unit | Default quantity | Source |
|------|------|------------------:|-----------------:|--------|
| `espresso` | shot | 62.7 mg | 1 | USDA 171891, espresso: 212 mg/100 g × 29.6 g |
| `americano` | shot | 62.7 mg | 2 | As espresso |
| `latte` | shot | 62.7 mg | 2 | As espresso. The prototype also starts at 2 shots. |
| `cappuccino` | shot | 62.7 mg | 2 | As espresso |
| `flatWhite` | shot | 62.7 mg | 2 | As espresso |
| `dripCoffee` | cup | 94.6 mg | 1 | USDA 171890, brewed coffee: 40 mg/100 g × 236.6 g |
| `coldBrew` | cup | 102.5 mg | 2 | Starbucks Cold Brew, 205 mg per 16 fl oz Grande, via Caffeine Informer (starbucks.com's page didn't render). USDA has no cold brew entry. |
| `instantCoffee` | cup | 61.5 mg | 1 | USDA 174130, instant coffee prepared with water: 26 mg/100 g × 236.6 g |
| `blackTea` | cup | 47.3 mg | 1 | USDA 173227, brewed black tea: 20 mg/100 g × 236.6 g |
| `greenTea` | cup | 28.4 mg | 1 | USDA 171917, brewed green tea: 12 mg/100 g × 236.6 g |
| `matcha` | cup | 63.3 mg | 1 | The midpoint of 18.9–44.4 mg/g (Koláčková et al. 2020, cited by Kochman et al. 2020) × 2 g, a level teaspoon |
| `cola` | can (12 fl oz, 355 mL) | 34 mg | 1 | Coca-Cola: 34 mg per 12 oz can. USDA 174852 gives 33.1 mg. |
| `energyDrink` | can (250 mL, 8.4 fl oz) | 80 mg | 1 | Red Bull: 80 mg per 250 mL can. USDA 173210 gives about 75 mg. |

Worked examples: a latte at 2 shots is 125.40 mg, and cold brew at 2 cups is 205.00 mg. The prototype's latte shows 128 mg because it uses 64 mg per shot.

### How far the estimates can be off

One number per unit hides a wide spread, which matters for the brief's *Honesty* criterion. The spread comes from the drink, not the model:

| Drink | Sourced spread | Source |
|-------|----------------|--------|
| Brewed coffee | 75–165 mg per 8 fl oz | FDA: 113–247 mg per 12 fl oz |
| Black tea | 47 mg per 8 fl oz | FDA: 71 mg per 12 fl oz, which matches USDA |
| Green tea | 25 mg per 8 fl oz | FDA: 37 mg per 12 fl oz |
| Matcha | 37.8–88.8 mg per 2 g | Koláčková et al. 2020 |
| Caffeinated soft drinks | 23–83 mg per 12 fl oz | FDA |
| Energy drinks | 41–246 mg per 12 fl oz | FDA |

Red Bull and Monster both hold about 32 mg per 100 mL, so a 500 mL Monster (160 mg) logs as 2 cans. Uncertainty rendering (rank 16) may later show these ranges. Until then, the catalog keeps one estimate per unit.

### Left out

| Drink | Why |
|-------|-----|
| Mocha | Its chocolate adds caffeine, and no source was found for how much. Counting only its shots would understate it. |
| Decaf coffee | 2–15 mg per 8 fl oz (FDA). It barely registers on the curve. |
| Diet cola, chai latte, yerba mate | Candidates for the two slots left under the brief's ~15. Not yet sourced. |

## Repository

### DrinkLogRepository

The single source of truth for the drinks the user has logged. It's app-scoped and concurrency-safe (constitution Article I.11–13), and it keeps every logged drink in memory. At three drinks a day, a year of history is about 1,100 drinks.

```swift
/// The record of every drink the user has logged.
protocol DrinkLogRepository: Sendable {
    /// Streams every logged drink, oldest first, starting with the current set.
    func loggedDrinks() -> AsyncStream<[LoggedDrink]>

    /// Stores a drink. The updated set is published when the data source signals the change.
    func log(_ drink: LoggedDrink) async throws
}
```

- **It publishes the whole log.** Features and use cases narrow it: Today (rank 4) shows today's drinks, one-tap favourites count the most common ones, and the Insights tab (rank 15) reads weeks at a time.
- **It publishes what the data source holds.** `log(_:)` has the drink data source store the drink. The data source then signals a change, and the repository re-reads its drinks and publishes them. If storing fails, `log(_:)` throws, no change is signalled, and nothing is published. The log never shows a drink that wasn't saved.
- **It checks every drink with ``DrinkLogRule``** before storing it, using the current time. A drink the rule rejects throws the rule's violation and is never stored. Every entry point gets the same checks, in one place.
- **Deleting is built, and editing comes later.** The Today screen's history card added `delete(_:)` and `day(containing:in:)` on 2026-09-12 (<doc:TodayScreen>). Undo (rank 20) and retroactive timing (rank 17) add their own methods when they're built (constitution Article III.1).

### DrinkLogRule

The business rule that decides whether a drink may be logged. Like ``CaffeineDecayRule``, it holds no state and reads no clock, so the current time is an input.

- A quantity below 1 throws `Violation.quantityBelowOne`.
- A `consumedAt` later than the current time throws `Violation.consumedInFuture`. Exactly the current time is accepted.
- The quantity is checked first, so a drink that breaks both rules reports its quantity.

The owner chose on 2026-09-11 to put both checks in the repository's rule, rather than in the use case.

### LogDrinkUseCase

The single use case that all three entry points call.

It conforms to `UseCase`, so its one operation is `execute(_:)`, which takes one `Input` (constitution Article I.7). The input carries the drink type, the quantity, and how many seconds ago the drink was consumed. There's no output.

```swift
/// Records a drink the user consumed.
struct LogDrinkUseCase: UseCase {
    /// The drink to record.
    struct Input: Sendable, Equatable {
        let type: DrinkType
        let quantity: Int
        let secondsAgo: TimeInterval
    }

    let currentTime: any CurrentTimeRepository
    let drinkLog: any DrinkLogRepository

    func execute(_ input: Input) async throws
}
```

1. It reads the current time from ``CurrentTimeRepository``.
2. It creates the `LoggedDrink`, with a new `UUID`, `milligrams` from `type.estimatedMilligrams(quantity:)`, and `consumedAt` set to the current time minus `secondsAgo`.
3. It calls `log(_:)`, and passes on any error the repository throws.

It doesn't check the drink itself, because the repository's rule does. It doesn't tell the decay curve about the drink either. The curve hears about it from the data source (see "Data flow").

### Entry points

| Entry point | Drink type | Quantity | `secondsAgo` |
|-------------|------------|----------|--------------|
| Composer (rank 2) | The row picked from the list | Starts at the drink's `defaultQuantity`, and a stepper adjusts it | 0, or the "When" choice: 3,600, 7,200, or 14,400 |
| One-tap favourite (rank 3) | One of the three favourites | The favourite's own: a favourite is a drink and a quantity together | 0 |
| App Intent or Siri (rank 14) | An `AppEnum` parameter that mirrors `DrinkType` | Optional, defaulting to the drink's `defaultQuantity` | 0 |

An App Intent calls the use case directly, without a reducer. How its `@Dependency` reaches the same app-scoped repository is designed with App Intents.

## Current time

The use case and the drink log's rule both need the current time. The owner decided on 2026-09-11 that one repository supplies it for the whole app. `CurrentTimeRepository` replaced the Today screen's planned `TimeOfDayRepository`, and `ObserveTimeOfDayUseCase` finds each minute's day period from its stream.

```
 SystemClockDataSource (Date.now, Task.sleep) ─▶ LiveCurrentTimeRepository ─┬─▶ LogDrinkUseCase: now()
                                                                               └─▶ ObserveTimeOfDayUseCase: currentTime()
```

- **``CurrentTimeRepository``** has a one-shot `now()`, and `currentTime()`, a stream that emits the current time immediately and then at every whole minute. The stream satisfies constitution Article I.12. Its data is the clock, so it publishes every minute on purpose.
- **``ClockDataSource``** is the only code that reads the system clock (constitution Article I.14). Its minute stream follows CLOCK-1 to CLOCK-4 in the Today Screen article, and this article adds `now()` (CLOCK-5).
- **``SystemClockDataSource``** reads `Date.now` and sleeps with `Task.sleep`. Both are injected, so tests control time. After each value, it sleeps until the next whole minute. If the app was suspended past that minute, it yields the time it wakes at.
- **``LiveCurrentTimeRepository``** is an actor off the main actor (constitution Article I.13) that passes the data source's values straight through.

## Data flow

A drink is stored once, written in one place, and read by two repositories.

```
 Command:  Row + stepper ─▶ Action ─▶ Reducer ─▶ LogDrinkUseCase (now) ─▶ DrinkLogRepository.log (rule) ─▶ DrinkLogDataSource.store
 Update:   DrinkLogDataSource change ─┬─▶ DrinkLogRepository: re-read drinks ─▶ AsyncStream<[LoggedDrink]>
                                   └─▶ CaffeineDecayRepository: re-read active intakes ─▶ rule ─▶ AsyncStream<[CaffeineLevel]>
```

- **One write.** The use case stores the drink through one repository. Nothing writes a second time just to tell the curve.
- **The data source informs.** The drink data source is the only code that stores drinks, so it knows when they change. After every successful store, it signals a change to every repository subscribed to it. Each repository re-reads what it needs through its own query. `DrinkLogRepository` reads every drink. `CaffeineDecayRepository` reads the intakes of drinks that aren't marked negligible (REPO-1 in <doc:CaffeineDecayModel>).
- **Repositories subscribe for their lifetime.** Each app-scoped repository subscribes when it's created, and keeps the subscription for the life of the app. Features still observe repositories only through `Observe…` use cases (constitution Article I.4).
- **Marks don't signal.** When the decay repository has the data source mark negligible intakes, no change is signalled. A mark changes nothing that any repository publishes (REPO-4), so a signal would only make the decay repository recalculate for nothing.
- **Later writers are covered.** Delete + undo (rank 20), retroactive timing (rank 17), and the demo seed (rank 8) write through the same data source, so the log and the curve follow them with no extra wiring. Deleting proved it: the history card's `delete(_:)` needed no change to either repository's listening (DELETE-3 in <doc:TodayScreen>).
- **A failure has one place to happen.** If storing fails, `log(_:)` throws, no change is signalled, and neither repository publishes. The reducer logs the error's domain and code (constitution Article XI.6.4).

### DrinkLogDataSource

A Data-layer protocol, ``DrinkLogDataSource``. Its implementation, ``SwiftDataDrinkLogDataSource``, is the only code that touches SwiftData (constitution Article I.14). It keeps the drinks in a store on the device only, with CloudKit off (see "Privacy and logging"). It's the intake data source that <doc:CaffeineDecayModel> describes: the decay repository maps the drinks it returns to their intakes.

| Operation | What it does |
|-----------|--------------|
| `store(_:)` | Stores a `LoggedDrink`, unmarked, then signals a change. |
| `delete(_:)` | Deletes the drink with the given identifier, marked or not, then signals a change. When no stored drink has the identifier, it changes nothing and signals nothing. |
| `drinks()` | Returns every stored drink, oldest first. |
| `nonNegligibleDrinks()` | Returns every drink that isn't marked negligible, oldest first. The decay repository maps each one to its `intake`. |
| `markNegligible(_:)` | Marks the given intakes negligible. It never clears a mark, deletes a drink, or signals a change. |
| `changes()` | Returns an `AsyncStream<Void>`, one per subscriber, that yields after each change. It's `async`, because the data source is an actor. |

| ID | Requirement |
|----|-------------|
| SRC-1 | Every subscriber to `changes()` gets one signal after each successful `store(_:)`. |
| SRC-2 | A failed `store(_:)` throws and signals nothing. |
| SRC-3 | `markNegligible(_:)` signals nothing. |
| SRC-4 | `nonNegligibleDrinks()` returns each unmarked drink, with its `id`, and nothing for marked drinks. |
| SRC-5 | `delete(_:)` removes the drink with the given identifier from the store, marked or not, and keeps the others. The deletion persists. |
| SRC-6 | Every subscriber to `changes()` gets one signal after each successful `delete(_:)`. |
| SRC-7 | Deleting a drink that isn't stored changes nothing and signals nothing. |
| SRC-11 | The device's store stays on the device: its configuration names no CloudKit container. |

`SwiftDataDrinkLogDataSourceTests` covers SRC-1, SRC-3, and SRC-4 against an in-memory store, and SRC-11 from the device store's configuration, without opening the store. `SwiftDataDrinkLogDataSourceDeleteTests` covers SRC-5 to SRC-7. SRC-2 has no test, because an in-memory SwiftData store can't be made to fail a save. For the same reason, no test makes a deletion fail in the store. The repository's DELETE-2 covers a failed deletion with the fake data source.

## Presentation

Presentation maps each `DrinkType` to its user-facing parts. The Domain holds none of them.

- **Names and units** live in `Localizable.xcstrings` (constitution Article VII). Unit labels use plural variants ("1 shot", "2 shots"). One `LocalizedStringResource` per drink serves both the views and the `AppEnum`'s display names.
- **Caffeine amounts** are formatted with locale-aware APIs and rounded for display.
- **Icons** are described in "Iconography".

### Iconography

Every drink in the list and on the one-tap row gets an icon. The owner chose SF Symbols for now, because they're first-party. Custom symbols can replace them later without touching the Domain. The symbol set covers the drink families, but not each drink:

| Drinks | SF Symbol |
|--------|-----------|
| Espresso, americano, latte, cappuccino, flat white | `cup.and.saucer.fill` |
| Drip coffee, instant coffee | `mug.fill` |
| Cold brew | `takeoutbag.and.cup.and.straw.fill` |
| Black tea, green tea | `cup.and.heat.waves.fill` |
| Matcha | `leaf.fill` |
| Energy drink | `bolt.fill` |
| Cola | `takeoutbag.and.cup.and.straw.fill`, shared with cold brew. No symbol shows a can. |

Each icon sits next to the drink's name, so it's decorative and hidden from VoiceOver (constitution Article VI.1). The name carries the meaning, so shared icons don't make a drink ambiguous.

### The composer screen

The owner chose on 2026-09-11: one screen, opened as a sheet from the root's log button, closing after a successful Add.

On 2026-09-12 the owner changed the layout: the drinks scroll sideways as tiles, and the panel always shows. The sheet is only as tall as its content, and the composer draws its own compact header, "Log a drink" with a Close button, instead of the system navigation bar.

``DrinkComposerView`` shows a row of tiles that scrolls sideways, one per drink, each with its icon above its name. The chosen tile is dark, with a checkmark. Three tiles fill the row: two from the xLarge text size, and one at accessibility sizes. The row snaps to tile edges. Below the row, the chosen drink's panel always shows:

- The drink's name and its estimate, such as "125 mg", from ``DrinkComposerFeature``'s `estimatedMilligrams`.
- The quantity with its unit, such as "2 shots", with round buttons that add or remove one. Choosing a drink starts its quantity at the drink's `defaultQuantity`, and it never goes below 1.
- The "When" choices: Now, 1h, 2h, and 4h ago. The durations are formatted for the locale (constitution Article VII.3).
- "Add 125 mg", which logs the drink through ``LogDrinkUseCase`` and closes the composer. If the drink can't be saved, the composer stays open and shows a short message, and the reducer logs the error's domain and code (Article XI.6.4). Close leaves without logging.

A drink is always chosen. The composer opens on the last drink logged, meaning the most recently consumed one, with its quantity. It reads the log through `ObserveLoggedDrinksUseCase`. Until the log arrives, or when nothing has been logged, the composer shows one espresso shot. The log never replaces a drink or quantity the user has already chosen. The owner chose this on 2026-09-12.

The one-tap row joined the composer on 2026-09-12 (<doc:OneTapLog>). It sits under the header in its slim style: each favourite's name, quantity, and caffeine, with no heading or icon, so the sheet stays under three quarters of the screen. A tap logs the favourite as consumed now and closes the composer, as Add does. At accessibility text sizes, the row moves under the panel, so the panel's controls stay on screen.

A separator divides the one-tap row from the drink tiles, so the favourites read as their own group, apart from the drink being built. It's a hairline in `separatorOnCard`, inset to the screen margins, with a card gap (16 pt) above and below. It replaces the section gap (28 pt) that separated the row from the tiles. With a section gap on each side, the sheet was 669 pt tall on iPhone 17 Pro, more than three quarters of the screen (655.5 pt). At accessibility text sizes it moves with the row and stays between the row and the panel. It's decorative, so it's hidden from VoiceOver. The owner added it on 2026-09-12.

The sheet's detent is measured from its content, plus the bottom safe area, so it follows the text size. When the content is taller than the screen, at the largest text sizes, the sheet reaches full height and scrolls. The tiles widen with the text size, and from xxLarge up the "When" choices stack, so none of it is cut off (Article VI.2). Every control is at least 44 pt. The chosen drink and "When" choice have the selected trait as well as a different color (Article VI.3).

These choices keep the screen passing the accessibility audit (Article VI.4), after it failed on each:

- **Nothing sits behind the panel.** The first layout scrolled a lazy list under a pinned panel, and VoiceOver and the audit still found the rows hidden behind it. Now the tiles scroll sideways, and nothing is pinned.
- **The panel's shadow is on its card only.** A shadow on the whole panel shadows every glyph, so the audit rejected its smaller text.
- **A chosen tile changes color without animation.** Animated, its light text would briefly sit on a light background.
- **No tile's name touches the screen's edge.** The audit checks any text whose frame touches the screen, even when it's clipped from view, and a sliver of a name fails the contrast check. So the row spans the screen, with the screen margins as content margins. Tiles are exact fractions of the space between the margins, and the row snaps to tile edges. At rest, the next tile's edge peeks in at the margin. Tiles are a card gap (16 pt) apart, so that tile's name starts about 4 pt beyond the screen at any width. With the item gap (12 pt), it touched the screen's last point and failed the audit.
- **Two checks are skipped, with the owner's approval.** On 2026-09-12 the owner approved skipping two of the audit's checks for the composer, and only those two. Both fail because the sheet is small, not because of anything in the composer:
  - **Text clipping.** A sheet fitted to its content fails it at any height short of the full screen. But screenshots at xxxLarge and AccessibilityXL show nothing is clipped: the sheet's height follows the text size, which the audit's static check can't see. `testLargestTextKeepsEveryControlOnScreen` checks the real behavior instead. It launches at AccessibilityXL and verifies that every control, including Add, is fully on screen.
  - **Element detection.** The Today screen's text shows, dimmed, above the small sheet. While a sheet is open, iOS hides the screen behind it from VoiceOver, so the audit finds text with no accessibility element. With a full-height sheet, the audit found no issues. The root screen's own audit covers the Today text. All of the composer's own text is SwiftUI `Text`, which always has an accessibility element.
- **The header and the chips scale with the text size.** The system navigation bar's Close button, and chips laid out by `ViewThatFits`, both failed the audit's Dynamic Type check. So the composer draws its own header, and the chips switch between a row and a column on the text size setting.

``AppFeature`` holds the composer in a `@Presents` property, so the sheet is state-driven (Article I.6). The composer closes itself through TCA's `dismiss` dependency.

### The cutoff warning

The owner asked on 2026-09-12 at 23:15 for a warning before a drink that breaks the caffeine cutoff is logged, and for it never to stop the drink being logged. It's roadmap rank 13, built early. The owner approved its wording at 23:28.

- **What it checks.** ``DrinkComposerFeature`` observes ``ObserveCutoffWarningUseCase`` for the chosen drink, quantity, and "When", in the calendar dependency. Each change of drink, quantity, or time observes the new choice's warning instead, and cancels the last. ``CaffeineCutoffRule`` decides (WARN-1 to WARN-5 in <doc:CaffeineCutoff>).
- **Where it shows.** Between the "When" choices and Add, in the caution colors the save error uses, with a warning symbol. ``CutoffWarningBanner`` draws it, and Add stays enabled.
- **What it says.** The heading is "After your cutoff". Then either "About 51 mg would still be in you at your 10:30 PM bedtime. Clinical sleep studies support under 40 mg for the average person." or, once the threshold is learned from the user's nights, "…Your time asleep starts to drop above 35 mg." (the owner's change on 2026-09-13, THRESH-5), or, for a drink less than its peak delay before bedtime, "This would still be rising at your 10:30 PM bedtime." The amount rounds up to the whole milligram, so it never shows at or under the threshold it's compared with. The wording follows the Caffeine Cutoff article's confidence language: it names what sleep studies suggest, not what the drink will do to the user's sleep.
- **Accessibility.** VoiceOver reads the heading and the reason as one element. The symbol is hidden, so the text carries the meaning, and the text isn't only colored (Article VI.3). It wraps at large text sizes.
- **The tile and the warning.** The "Last cup" tile rounds the cutoff down to the half hour, and the warning checks the exact amount. So a drink a few minutes past the tile's time may not warn. It never warns with an amount under the threshold.

## Privacy and logging

A logged drink is health data. Its type, quantity, amount, and time all come down to a caffeine intake.

- It's stored once, by the drink data source, in a SwiftData store on the device, and nowhere else. The same record carries the intake's negligible mark. The Architecture article's "Data and privacy" table lists it.
- **CloudKit sync is deferred.** The owner removed it on 2026-09-13. The store is configured with CloudKit off (SRC-11), and the app no longer has the iCloud and push entitlements or the remote notifications background mode. SwiftData syncs by default whenever the entitlements name an iCloud container, so the configuration turns sync off explicitly. Constitution Article V.1 still allows the drink log to sync to the user's private CloudKit database, so CloudKit backup (roadmap rank 23) can bring it back: the entitlements and background mode, the `.automatic` configuration, the container in the developer account, the schema deployed to Production, testing on a device signed in to iCloud, and the App Store privacy label. `DrinkRecord` still follows CloudKit's model rules, so turning sync on needs no migration.
- The store keeps iOS's default protection class, complete until first unlock (`NSFileProtectionCompleteUntilFirstUserAuthentication`). The owner chose it on 2026-09-11, as the weaker class that Article V.4 allows for background access. Once the device has been unlocked since it started up, Siri can read the store while the device is locked. Before that first unlock, the store is unreadable.
- None of its fields is ever logged, at any level (Article XI.6.1). A successful log is a routine health event, so it's logged at `debug` at most. A failed one is logged at `error`, with the error's domain and code and no values (Article XI.7).
- Siri can run an intent while the device is locked. With the store's default class, the intent can read and write the store once the device has been unlocked since it started up. Whether an intent should also require the device to be unlocked is decided with App Intents (rank 14).

## Testable requirements

Each requirement is written so that one test can prove it.

### DrinkType

| ID | Requirement |
|----|-------------|
| TYPE-1 | Every case has the unit, caffeine per unit, and default quantity listed in "Catalog", and the catalog covers every case. |
| TYPE-2 | Every case's raw value matches a pinned list, so renaming a case fails a test. |
| TYPE-3 | Every case's default quantity is at least 1, and its caffeine per unit is greater than zero. |
| TYPE-4 | `estimatedMilligrams(quantity:)` is `milligramsPerUnit × quantity`. A latte at 2 shots is 125.40 mg. |

### LoggedDrink

| ID | Requirement |
|----|-------------|
| DRINK-1 | `intake` has the drink's `id`, `milligrams`, and `consumedAt`. |
| DRINK-2 | A drink created without an `id` gets a new one, and a given `id` is kept. |

### DrinkLogRule

Unit-tested directly. The rule is pure, so its tests need no fakes.

| ID | Requirement |
|----|-------------|
| LOGRULE-1 | A quantity below 1 throws `quantityBelowOne`. |
| LOGRULE-2 | A `consumedAt` later than the current time throws `consumedInFuture`. |
| LOGRULE-3 | A drink consumed at or before the current time, with a quantity of at least 1, is accepted. |
| LOGRULE-4 | When both are wrong, it throws `quantityBelowOne`. |

### LogDrinkUseCase

Tested against in-memory fake repositories, with the clock stopped at a fixed time.

| ID | Requirement |
|----|-------------|
| USE-1 | It logs one `LoggedDrink` with the given type and quantity, `milligrams` equal to `type.estimatedMilligrams(quantity:)`, and `consumedAt` equal to the current time minus `secondsAgo`. |
| USE-2 | With `secondsAgo` of 0, `consumedAt` is exactly the current time. |
| USE-3 | Any error the repository throws, including a rule violation, reaches the caller. |

### DrinkLogRepository

Tested against a fake data source.

| ID | Requirement |
|----|-------------|
| DLOG-1 | Each new subscriber immediately gets every logged drink, oldest first, and then the updated set whenever the drink data source signals a change (constitution Article I.12). |
| DLOG-2 | `log(_:)` has the data source store the drink. If storing fails, it throws and publishes nothing. |
| DLOG-3 | A drink comes back with the `milligrams` it was logged with, never recalculated from the catalog. |
| DLOG-4 | `log(_:)` executes ``DrinkLogRule`` with the current time. A drink the rule rejects throws its violation and isn't stored. |

`LiveDrinkLogRepositoryTests` covers DLOG-1 to DLOG-4 against `FakeDrinkLogDataSource` and a stopped clock, plus a failed read that publishes nothing and recovers on the next change. ``LiveDrinkLogRepository`` reads the current time from ``ClockDataSource``, which it shares with ``LiveCurrentTimeRepository`` and ``LiveCaffeineDecayRepository``, rather than depending on ``CurrentTimeRepository``. The owner chose this on 2026-09-11, so no repository depends on another.

The repository also publishes the caffeine logged today, for the Today screen's "Today" tile. Its requirements, DLOG-5 to DLOG-9, are in <doc:TodayScreen>.

### Current time

| ID | Requirement |
|----|-------------|
| TIME-1 | ``LiveCurrentTimeRepository``'s `now()` returns the data source's time. |
| TIME-2 | Its `currentTime()` streams the data source's minutes, in order. |
| CLOCK-5 | ``SystemClockDataSource``'s `now()` reads its clock, which is `Date.now` by default. |

CLOCK-1 to CLOCK-4, the minute stream's requirements, are in the Today Screen article. `SystemClockDataSourceTests` covers all five.

### DrinkComposerFeature

Tested with an exhaustive `TestStore`, with `\.logDrink`, `\.observeLoggedDrinks`, and `\.observeCutoffWarning` built on fake repositories and `\.dismiss` overridden. Tests about something else override the warning with one that sends nothing.

| ID | Requirement |
|----|-------------|
| COMP-1 | Choosing a drink selects it and starts its quantity at the drink's `defaultQuantity`. |
| COMP-2 | The buttons add and remove one unit, and the quantity never goes below 1. |
| COMP-3 | "When" starts at Now, and each choice sets `secondsAgo`: 0, 3,600, 7,200, or 14,400. |
| COMP-4 | The estimate is the chosen drink's `estimatedMilligrams(quantity:)`. |
| COMP-5 | Add logs the chosen drink, quantity, and `secondsAgo` through ``LogDrinkUseCase``, then dismisses the composer. |
| COMP-6 | If logging fails, the composer shows the error and stays open. |
| COMP-7 | Choosing another drink, or trying again, clears the error. |
| COMP-8 | Add does nothing while a drink is being logged. |
| COMP-9 | Close dismisses the composer without logging. |
| COMP-10 | The composer opens on one espresso shot. On `task`, it takes the last drink logged, with its quantity, or keeps espresso when nothing has been logged. |
| COMP-11 | Once the user has chosen a drink or changed its quantity, the drink log no longer replaces the choice. |
| COMP-12 | When the composer's one-tap row logs a favourite, the composer closes. If the save fails, it stays open, and the row shows the error. |
| WARNCOMP-1 | `task` observes the cutoff warning for the chosen drink, quantity, and time, in the calendar dependency, and reduces each warning into `State`. |
| WARNCOMP-2 | Choosing a drink, changing its quantity, or choosing a time observes the new choice's warning. A quantity that can't go lower observes nothing new. |
| WARNCOMP-3 | A warning never stops Add. |

COMP-8 used to say Add does nothing before a drink is chosen. Now a drink is always chosen, so that case no longer exists.

### ObserveLoggedDrinksUseCase

| ID | Requirement |
|----|-------------|
| OBSERVE-1 | It streams every set of drinks the repository publishes, in order. |

### AppFeature

| ID | Requirement |
|----|-------------|
| ROOT-1 | The log button presents the composer. |
| ROOT-2 | Closing the composer dismisses it. |
| ROOT-3 | Logging a drink dismisses the composer. |

### Presentation

| ID | Requirement |
|----|-------------|
| SHOW-1 | Every drink's icon is the one in "Iconography", and is a system symbol. |
| SHOW-2 | Every drink has its own name. |
| SHOW-3 | Every drink tile has its own accessibility identifier. |
| SHOW-4 | Quantities and caffeine per unit name the unit, singular for one: "1 shot", "2 shots". |
| SHOW-5 | Caffeine is shown in whole milligrams, formatted for the locale, such as "125 mg". |

`DrinkComposerUITests` drives the composer through `DrinkComposerRobot`, which swipes the tiles to reach drinks off screen. The composer opens with exactly one drink chosen and its panel showing, in a sheet shorter than three quarters of the screen. A latte starts at 2 shots and 125 mg, the buttons change the estimate, "When" changes its choice, Close returns to the root screen, one tap on a favourite logs it and closes the composer (ONETAP-UI-2 in <doc:OneTapLog>), and the composer passes the accessibility audit (Article VI.4), except for the two approved checks above. Nine cups of cold brew now show the cutoff warning at any time of day, the composer passes the same audit with it showing, and Add still logs the drink (WARN-UI).

## Still to decide

- **Whether the change signal carries the data.** This design signals only that something changed, and each repository re-reads through its own query. The alternative sends the changed drinks. That saves a read, but hands the decay repository marked drinks that it would have to filter out itself.
- **The quantity's upper limit**, and whether half units are allowed. The quantity is a whole number of at least 1 for now.
- **The last two catalog slots**, and a sourced value for any drink added.

## Sources

Retrieved 2026-09-11.

- USDA FoodData Central, SR Legacy foods 171891, 171890, 174130, 173227, 171917, 174852, and 173210. Per-100 g values were retrieved through the FoodData Central API. The 29.6 g per fl oz weight is USDA's espresso portion.
- U.S. Food and Drug Administration, "Spilling the Beans: How Much Caffeine Is Too Much?" (content current as of 2024-08-28).
- The Coca-Cola Company, "What is caffeine?" (coca-cola.com FAQ).
- Red Bull, "How much caffeine is in a can of Red Bull Energy Drink?" (redbull.com).
- Caffeine Informer, "Caffeine in Starbucks Cold Brew Coffee", citing Starbucks' product page.
- Kochman J. et al., "Health Benefits and Chemical Composition of Matcha Green Tea: A Review", *Molecules* 26(1):85, 2020, citing Koláčková T. et al., 2020, for the 18.9–44.4 mg/g range. The 2 g level teaspoon comes from a matcha vendor's guide, not a study.
