# One-Tap Log

The user's three favourite drinks, each logged in one tap on the Today screen and in the drink composer.

## Overview

The brief's first requirement is "Log a drink in one tap." One-tap favourites are roadmap rank 3. A row of three buttons shows the drinks the user logs most. One tap logs that drink, at that quantity, as consumed now. There's no confirmation step, so the button confirms the log after it's saved.

The row appears in two places:

- **The Today screen**, under the decay card and its tiles, headed "One tap". Each button shows the drink's icon, name, quantity, and caffeine.
- **The drink composer**, under its header, in a slim style that shows only the name, quantity, and caffeine. A tap logs the drink and closes the composer, as Add does (<doc:DrinkComposer>).

It's built from these pieces:

- ``FavouriteDrink`` and ``FavouriteDrinksRule``, in the Domain.
- ``FavouriteDrinksRepository``, implemented by ``LiveFavouriteDrinksRepository`` over the shared ``DrinkLogDataSource``.
- ``ObserveFavouriteDrinksUseCase``, and the existing ``LogDrinkUseCase``.
- ``OneTapLogFeature`` and ``OneTapLogView``, which ``TodayFeature`` and ``DrinkComposerFeature`` each compose.

## What the prototype shows

| Prototype element (screenshots 07 and 10) | Becomes |
|-------------------------------------------|---------|
| "ONE TAP": Double espresso 128 mg, Oat flat white 64 mg, Cold brew 205 mg | The three favourites the user logs most. Until the log has three, starters fill the row: 2 espresso shots, 2 flat white shots, and 2 cups of cold brew (125, 125, and 205 mg). |
| "Double espresso", "Oat flat white" | The drink's name and quantity, such as "Espresso, 2 shots". The catalog has no double espresso, and milk is cut (<doc:DrinkComposer>). |
| The letter in each tile (E, F, C) | The drink's SF Symbol, the one the composer's tiles use, in a `dataCaffeineSubtle` icon tile |
| "All drinks" | Cut. The tab bar's "Log a drink" tab opens the composer, which lists every drink. |
| The composer's "Tap a favourite, or build it below." and "128 mg · one tap" | The composer's slim row, with no heading or subtitle, so the sheet stays compact |

## Decisions

The owner decided these on 2026-09-12:

| Question | Decision | Rejected |
|----------|----------|----------|
| What counts as one favourite | A drink and its quantity together. "Latte, 2 shots" and "Latte, 3 shots" are different favourites, so each button logs exactly what the user usually has. | The drink alone, at the quantity it's most often logged at. Two sizes of one drink couldn't both show. |
| Over what period | Every drink ever logged. The favourites change only when the log does, so nothing recalculates as days pass. | The last 30 days. That would follow changing habits, but the repository would have to recalculate as days pass, and the row would empty after a month away. |
| Ties | The favourite consumed most recently ranks first. | Catalog order |
| Fewer than three favourites | The starters fill the empty slots. The row is titled "One tap", not "Your favourites", so it doesn't claim to know the user's habits before it does (the brief's *Honesty* criterion). | Showing only what's been logged, and hiding the row until something has |
| Feedback after a tap | For 2 seconds the button shows a checkmark and "Logged", the device plays the success haptic, and VoiceOver announces it. It guards against a second tap from a user who isn't sure the first one worked. | A haptic only, or no feedback |
| A tap in the composer | Logs the drink and closes the composer, like Add | Logging and staying open |
| The composer's layout | A slim row under the header, so the sheet stays under three quarters of the screen. At accessibility text sizes, it moves under the panel. | The full row, with a taller sheet and relaxed tests |
| The floating log button | Replaced by the system tab bar, with the log button as its bottom accessory. The floating button covered the Today screen's one-tap row. | A bar behind the button, the favourites docked beside it, a custom tab bar, or a "Log a drink" tab (see "The tab bar") |
| Text under the tab bar | The Today and root audits run twice. At launch they ignore contrast only for elements that reach under the bar or into its fade, 44 pt above the log button, and for issues with no element. Then, scrolled to the end, they ignore nothing. Since 2026-09-13, the second audit ignores contrast under the navigation bar's fade, only for elements the first audit checked in full (<doc:Settings>). | Skipping the contrast check for the whole Today screen, or ignoring element-less issues with no second audit |

The AI chose these, still to be confirmed:

- A tie at the same moment goes to catalog order, then to the smaller quantity, so the order never depends on how the log is sorted.
- The confirmation lasts 2 seconds.
- A failed save shows the composer's message: "The drink couldn't be saved. Try again."
- The Today tab's symbol, `sun.max`, and the log button's, `plus`.
- The log button's look: a dark `actionPrimary` capsule filling the tab bar's accessory, like the prototype's primary buttons.

## Domain

### FavouriteDrink

A drink the user can log in one tap. It's a plain `Hashable`, `Sendable` value (constitution Article I.10).

| Property | Type | Meaning |
|----------|------|---------|
| `type` | ``DrinkType`` | Which drink |
| `quantity` | `Int` | How many units of the drink's ``ServingUnit`` one tap logs. At least 1. |

It holds no caffeine amount. Presentation shows `type.estimatedMilligrams(quantity:)`, which is what ``LogDrinkUseCase`` stores for the new drink.

### FavouriteDrinksRule

The business rule that picks the favourites. Like ``DrinkLogRule``, it holds no state and reads no clock.

1. It counts every drink it's given by drink and quantity together.
2. It ranks the most logged first. A tie goes to the favourite consumed most recently, then to catalog order, then to the smaller quantity.
3. It keeps the first three (`count`).
4. If fewer than three remain, it adds the `starters` in order, skipping any already there. So it always returns exactly three distinct favourites.

The starters are the prototype's three one-tap drinks: `espresso` × 2 for its double espresso, `flatWhite` × 2, and `coldBrew` × 2.

## Repository

``FavouriteDrinksRepository`` is the source of truth for the favourites. ``LiveFavouriteDrinksRepository`` is an actor, off the main actor (constitution Article I.13).

```
 Command:  Favourite ─▶ OneTapLogFeature ─▶ LogDrinkUseCase (now) ─▶ DrinkLogRepository.log (rule) ─▶ DrinkLogDataSource.store
 Update:   DrinkLogDataSource change ─▶ FavouriteDrinksRepository: read every drink ─▶ FavouriteDrinksRule ─▶ AsyncStream<[FavouriteDrink]>
```

- **It shares the drink log data source** with ``DrinkLogRepository`` and ``CaffeineDecayRepository``, following the shared-data-source pattern in <doc:Architecture>. A drink logged or deleted by any entry point updates the favourites with no extra wiring. The owner asked for a repository of its own, rather than a second stream on ``DrinkLogRepository``.
- **A new subscriber gets the current favourites at once**, and every subscriber gets them again after each change the data source signals (constitution Article I.12). It listens to the data source once, for every subscriber.
- **It reads every drink**, including those the decay repository has marked negligible. A drink from last year counts as much as today's.
- **A failed read publishes nothing.** It logs the error's domain and code, and the next change recovers.

Nothing new is stored. The favourites are calculated from the drink log whenever it changes, and held only in memory.

## Presentation

### OneTapLogFeature

| `State` property | Meaning |
|------------------|---------|
| `favourites` | The favourites, most logged first, as the repository last published them |
| `logging` | The favourite being saved. While it's set, a tap does nothing, so no tap logs a second drink by accident. |
| `justLogged` | The favourite whose confirmation is showing |
| `saveFailed` | Whether the last save failed |

- `task` observes the favourites through ``ObserveFavouriteDrinksUseCase``. The view starts it from `.task`, so each copy of the row observes for as long as it's on screen.
- `favouriteTapped` logs the favourite's drink and quantity through ``LogDrinkUseCase``, with `secondsAgo` of 0. The row never writes favourites into `State` itself; the new favourites arrive from the repository (constitution Article I.5).
- After a successful save, `justLogged` shows the confirmation for `confirmationDuration`, 2 seconds, on TCA's continuous clock. The row then sends `delegate(.drinkLogged)`. Another log during a confirmation moves the confirmation to the new favourite and restarts it.
- After a failed save, the row shows the error, and the next tap clears it. The reducer logs the error's domain and code.

``DrinkComposerFeature`` closes when its row sends `delegate(.drinkLogged)`. ``TodayFeature`` ignores it.

### OneTapLogView

``OneTapLogView`` has two styles:

- **`cards`**, on the Today screen: a "One tap" heading, with the header trait, and each button's icon, name, and "2 shots · 125 mg".
- **`slim`**, in the composer: no heading and no icon.

The three buttons share a row, each at the same height, and stack from the xxLarge text size, where the layout switches on the text size rather than through `ViewThatFits`, which fails the audit's Dynamic Type check (<doc:DrinkComposer>). Their text wraps rather than truncating (constitution Article VI.2). Each button is at least 44 pt.

- **VoiceOver** reads each button's label as the drink and quantity, "Espresso, 2 shots". Its value is the caffeine, "125 milligrams", or "Logged" during the confirmation, and its hint is "Logs this drink now."
- **After a tap**, the button's icon becomes a checkmark and its detail reads "Logged" in `textAccent`. The change is in text as well as color (Article VI.3). The device plays the success haptic, and VoiceOver announces "Logged Espresso, 2 shots".
- **In the composer**, the slim row sits under the header, grouped with it, so the sheet stays under three quarters of the screen. At accessibility text sizes it moves under the panel, because its stacked buttons would push the panel off screen. The favourites are then a scroll away, and the Today screen still shows them.

### The tab bar

``AppView`` is a system `TabView` with one tab, Today. The log button is the tab bar's bottom accessory, just above the bar, and presents the composer as before. The Insights tab (rank 15) and Settings joined it later.

The owner made these choices on 2026-09-12, in this order:

1. **The floating log button went.** At rest, it covered the Today screen's middle one-tap button, and the accessibility audit failed on the covered text's contrast. The owner asked for a proper tab bar, and chose the system `TabView` over one drawn like the prototype's.
2. **The log button became the bar's accessory, not a tab.** A "Log a drink" tab that presents the composer and keeps Today selected worked, but the system tab bar's buttons carry only their labels. Neither `.accessibilityIdentifier` on the `Tab` nor on its label reached them, so a robot couldn't find the tab by identifier (constitution Article II.6). The accessory is an ordinary SwiftUI button with `AppViewAccessibilityID.logButton`. ``AppFeature`` kept its `logButtonTapped` action.
3. **The audit ignores contrast under the bar.** The Today screen scrolls under the tab bar, so at launch its lowest cards sit behind it. The audit then fails on their contrast, whatever the bar's style: a hard scroll edge (`.scrollEdgeEffectStyle(.hard, for: .bottom)`) didn't help. The Today and root audits call `auditAccessibilityAboveTheTabBar()`, which audits twice. The first audit, at launch, ignores contrast issues only for elements whose frame reaches into the bar's fade, within 44 pt above the log button's top edge, or below it, and for issues the audit can't tie to an element. Every other issue still fails. The helper then swipes up until the screen's first text stops moving, and the second audit, with nothing under the bar, ignores nothing. So every card that was behind the bar at launch is checked in full. Since 2026-09-13, the second audit ignores contrast under the navigation bar's fade, only for elements the first audit checked in full (<doc:Settings>). Before each audit, the helper waits for a still screen: it takes screenshots until two in a row are identical, or 20 have been taken. Since 2026-09-13, it waits for three in a row, or 30 (<doc:Settings>). Without that wait, audits taken while the bar's glass and the scroll edge effect were still animating failed contrast now and then, on text that passed a second or two later. The owner chose the wait on 2026-09-12. One intermittent failure remains, and the owner chose on 2026-09-12 to record it and change nothing. Now and then, about once in 25 runs with the wait, an audit reports "Dynamic Type font sizes are partially unsupported" on nearly every text on the screen at once: the greeting, the decay card, both tiles, the one-tap row, and the history card. That's the whole screen missing the audit's text-size probe, most likely a timing race with a render, not a gap in any one view. The largest-text UI tests, which check the real behavior, have passed every time. If it appears, rerun the suite.

The first audit never excuses the log button itself. Two fixes let the audits pass, both found by printing each issue's element and frame:

- **The log button is an opaque capsule**, `actionPrimary` with `textOnEmphasis` text. On the accessory's glass alone, its label's contrast depended on what scrolled behind it, and the audit failed it.
- **The tab bar's tint is `textAccent`.** The selected tab's label is small text, and in the brighter `AccentColor` (#B87333), meant for graphics, it failed contrast as an issue with no element.

The first version ignored only issues with an element under the bar. After the onboarding and history merges, the audits failed every time on one contrast issue with no element. It appeared only while cards sat under the bar: with a settled scroll to the end, the same screen had no issues at all. It's most likely a decorative icon that VoiceOver doesn't see. The owner chose the two-pass audit on 2026-09-12, over tracking the element down with the audits failing meanwhile, or ignoring element-less issues with no second audit.

Later that day, the owner gave UI tests an empty drink log. The shorter "Last cup" tile then moved everything up 20 pt, and at launch the "ONE TAP" heading sat at y 713–728. That's above the log button's top edge (737), in the bar's soft fade, where the audit read it as low contrast. The history session saw the same band, with text up to about 40 pt above the button. The owner chose to excuse the fade too, 44 pt above the button, over moving content out of the band, which any card that changes height could undo.

## Privacy and logging

- The favourites are derived from the drink log, which is health data. They're calculated in memory and never stored, so they add nothing to the Architecture article's "Data and privacy" table.
- No favourite, drink, or count is ever logged, at any level (constitution Article XI.6.1). A failed save is logged at `error` with the error's domain and code, and its description as `.private` (XI.6.4). A successful one-tap log is a routine health event, so it isn't logged (XI.7).

## Testable requirements

### FavouriteDrinksRule

| ID | Requirement |
|----|-------------|
| FAV-1 | Drinks are counted by drink and quantity together, most logged first, and only the first three are kept. |
| FAV-2 | A tie goes to the favourite consumed most recently, then to catalog order, then to the smaller quantity. The order of the drinks given doesn't matter. |
| FAV-3 | Every drink counts, however long ago it was logged. |
| FAV-4 | Slots the log can't fill take the starters, in order, skipping any already a favourite. |
| FAV-5 | With nothing logged, the favourites are the starters: 2 espresso shots, 2 flat white shots, and 2 cups of cold brew. |

### FavouriteDrinksRepository

Tested against `FakeDrinkLogDataSource`.

| ID | Requirement |
|----|-------------|
| FAVREPO-1 | A new subscriber gets the favourites of every drink the data source holds, including drinks marked negligible, and every subscriber gets new favourites after each change. It listens to the data source once. |
| FAVREPO-2 | With nothing logged, it publishes the starters. |
| FAVREPO-3 | A failed read publishes nothing, and the next change, once the drinks can be read, publishes the favourites. |

### Use case and registrations

| ID | Requirement |
|----|-------------|
| OBSFAV-1 | ``ObserveFavouriteDrinksUseCase`` streams every set of favourites the repository publishes, in order. |
| FAVDEP-1 | In a test, observing the favourites through the use case or the repository without overriding them reports an issue. |
| FAVDEP-2 | `\.favouriteDrinksRepository` is a ``LiveFavouriteDrinksRepository``, and `\.observeFavouriteDrinks` holds that one app-scoped repository. Checked in the preview context, inside the serialized `SwiftDataStoreTests`. |

### OneTapLogFeature

Tested with an exhaustive `TestStore`, with the use cases built on fakes and a test clock.

| ID | Requirement |
|----|-------------|
| ONETAP-1 | `task` observes the favourites, and each set is reduced into `State`. |
| ONETAP-2 | A tap logs the favourite's drink and quantity, consumed now, through ``LogDrinkUseCase``. |
| ONETAP-3 | After the save, the favourite shows as logged for 2 seconds, and the row tells its parent a drink was logged. |
| ONETAP-4 | A failed save shows the error and no confirmation, and the next tap clears it. |
| ONETAP-5 | A tap does nothing while a favourite is being saved. |
| ONETAP-6 | Another log during a confirmation moves the confirmation to the new favourite and restarts it. |
| ONETAP-7 | ``TodayFeature`` composes the row: its actions reach ``OneTapLogFeature``, and its state appears under `oneTapLog`. |

The composer's requirement, COMP-12, and the tab bar's, ROOT-1 and ROOT-4, are in <doc:DrinkComposer>.

### UI

| ID | Requirement |
|----|-------------|
| ONETAP-UI-1 | One tap on the Today screen's first favourite logs it. The button says it was logged, and its caffeine is added to the "Today" tile's total. |
| ONETAP-UI-2 | One tap on a favourite in the composer logs it and closes the composer. |

`TodayRobot` and `DrinkComposerRobot` each look for the row's buttons only inside their own screen, because both screens show the row. The Today screen's and the composer's accessibility audits cover the row.

## Still to decide

- **Undo.** A one-tap log has no confirmation step. Delete + undo (roadmap rank 20) adds a way to take one back.
- **The starters.** They're the prototype's three for everyone. Onboarding (rank 6) could pick them from the user's answers.
- **Small screens.** On a phone shorter than the iPhone 17 Pro, the Today screen's row can sit below the fold, so one tap takes a scroll first.
