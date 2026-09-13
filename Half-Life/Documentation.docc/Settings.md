# Settings

The Settings tab: the onboarding answers, reviewed and changed, the three permissions, and 30 days of demo drinks.

## Overview

Settings is roadmap rank 21. The demo history is rank 8, the demo seed generator. The owner asked for both together on 2026-09-12, as "a pivot point", ahead of the roadmap's order.

Settings is one of the app's tabs, beside Today. Its root is a list of six rows, each with its current value where it has one, and each row opens its own screen (see "Navigation"). The root ends with the app's version and build (see "The app version"). The six rows:

| Section | Shows | Changes |
|---------|-------|---------|
| About you | The name and age onboarding saved | The name, when the user presses Return or leaves the field. The age, as soon as it's chosen. |
| Caffeine and your body | An option for each factor that changes the half-life, without the half-life they give (<doc:Onboarding>) | Each factor, as soon as it's chosen or unchosen. Pregnancy asks for the trimester first. |
| Bedtime | The bedtime | The bedtime, as soon as it's chosen |
| Permissions | Apple Health, notifications, and Face ID or Touch ID, each with its status | Each permission, from its Allow button, or in the Settings app from its Open Settings button |
| App lock | Whether the app lock is on, as an option named for the device's Face ID or Touch ID (``AppLockSettingsSection``) | Turns the lock on, asking for Face ID first if it hasn't been asked for, or off (<doc:AppLock>) |
| Demo data | Whether the log holds demo drinks, and whether the demo Health data switch is on | Adds 30 days of demo drinks, or removes them. Turns the demo Health data switch on or off (<doc:AppleHealthCard>). |

### The owner's decisions

The owner answered six questions on 2026-09-12, between 22:15 and 22:23.

| Question | Decision | Rejected |
|----------|----------|----------|
| How Settings is reached | A second tab in the system tab bar. Robots find the tab bar's buttons by their label, which needed an amendment to constitution Article II.6 (see "Navigation"). | UI tests opening the tab through a launch key, which the AI recommended. A gear button on the Today screen. |
| How the demo user works | Demo drinks go into the real drink log, each marked as a demo drink, and Settings removes them. | A separate demo user with its own profile and log, which the AI recommended. A demo button on the Welcome screen too. |
| What the demo contains | Drinks only. Health data waits for a feature that reads it, because nothing reads sleep, steps, or heart rate yet (constitution Article III.1). | Seeded sleep, steps, and resting heart rate. |
| What the demo does to the profile | Nothing. The user's name, age, factors, and bedtime stay as they are. | Filling blank fields. Overwriting the profile, which removing the demo couldn't undo. |
| Whether the demo includes today | Yes, the drinks the script has today, up to the current time, so the Today screen's cards show them at once. | Ending yesterday. |
| How the answers are edited | A native form in Settings | Reusing onboarding's screens, which the AI recommended |
| How Settings looks, after the audit failed the form | The app's own style, like onboarding: an eyebrow over each section, cards, option rows for the factors, a wheel for the age, and a time picker for the bedtime. The owner chose this at about 23:27 (see "What changed while building"). The bedtime's two wheels became the system's compact time picker on 2026-09-13, with onboarding's (<doc:Onboarding>). | Keeping the form, with a narrow audit exception, which the AI recommended. The form with custom headers, rows, and pickers. |
| How long the demo covers | 30 days before today. The owner decided this at 23:10 for the Insights tab, whose comparison card uses the last 30 days, and the Insights session relayed it. | 14 days, the "2 weeks" of the request, which the first build had |
| How the tab titles are defined | An enum in `AppViewAccessibilityID.swift` whose raw values are the titles' String Catalog keys, so neither the app nor the tests hard-code the text. The owner chose this at about 23:13, and Article II.6 was reworded to match (see "Navigation"). | English titles as raw values. The `static let` English titles of the first refinement. |
| How the tab is organized | A root list of six rows, each opening its own screen: About you, Caffeine and your body, Bedtime, Permissions, App lock, and Demo data. Each screen is the section Settings already had. The owner asked for submenus at 00:10 on 2026-09-13, and chose both options the AI recommended except one: App lock and Demo data became submenus too, rather than staying on the root. | Pushing onboarding's own step screens. Keeping App lock and Demo data on the root. |
| How the audit treats the top of a scrolled screen | At the end of its scroll, Caffeine and your body, a little taller than the phone, has its title under the navigation bar's fade, and the audit read the faded title as low contrast. The second audit of `auditAccessibilityAboveTheTabBar()` now ignores a contrast issue there only for an element that the first audit checked in full, because at rest it sat wholly above the bottom fade. It mirrors the tab bar's exception (<doc:OneTapLog>). The owner chose this, which the AI recommended, at 00:50 on 2026-09-13. | Hiding the top scroll-edge effect on the pushed screens. Pinning the title above the scrolling content, which would put the first option under the bar instead. |
| Whether Settings shows the half-life | Never. On 2026-09-13 the owner decided that the app doesn't share its half-life calculation with the user. Caffeine and your body lost the "Your starting half-life" card, and its row on the root lost its value (<doc:Onboarding>, "The owner's decisions"). The owner asked for the card to go, and chose to remove the row's value too, which the AI recommended. | Removing only the card |

> Note: At 22:54 the same day, in the Apple Health card's design, the owner decided that a separate "Use demo Health data" switch in this tab swaps Apple Health for made-up sleep, steps, and resting heart rate (<doc:AppleHealthCard>). It supersedes the "Drinks only" decision for Health data. It's built: its own feature, ``DemoHealthDataFeature``, is an option under the demo drinks' card on the Demo data screen, so the two stay independent. The screen's feature, ``DemoDataFeature``, runs both side by side. The Apple Health card's session built it on 2026-09-13 (<doc:AppleHealthCard>).

### What the brief asks for

- **"Don't build … settings screens for their own sake."** Each section here has a reason. Onboarding's answers go stale: a pregnancy moves through its trimesters and ends, and a smoker who quits clears caffeine more slowly within about a week (<doc:Onboarding>, "Still to decide"). A permission declined during onboarding has nowhere else to be granted. And the brief asks for the demo history.
- **"Seed 2-4 weeks of plausible history … Say clearly what's seeded vs. live."** Every demo drink is marked, the history card labels each one "Demo", and Settings says whether the log holds any.

### Left out

- **The half-life override.** The roadmap's rank 21 lists "HealthKit status, bedtime, and the half-life override". The owner's request didn't include the override, and the personal half-life estimator (rank 9) will decide how an override combines with its estimate.
- **Send logs.** The <doc:Logging> article designs a log export for Settings. The owner didn't ask for it here, so it's still designed and not built.

## The demo history

### The script

The demo is a fixed script of local clock times, drinks, and quantities (``DemoHistoryRule``). It covers the 30 calendar days before today, and today up to the current time. Only the drinks' identifiers change from one run to the next.

| Day | Drinks |
|-----|--------|
| 30 days ago | 7:45am latte, 2 shots; 10:30am drip coffee |
| 29 | 7:40am latte, 2 shots; **3:45pm cold brew, 2 cups** |
| 28 | 8:00am latte, 2 shots; 11:00am americano, 2 shots |
| 27 | 7:50am latte, 2 shots; 1:30pm black tea |
| 26 | 9:30am cappuccino, 2 shots; 2:00pm matcha |
| 25 | 10:00am cappuccino, 2 shots; **4:00pm drip coffee** |
| 24 | 7:45am latte, 2 shots; 10:45am drip coffee; 4:30pm cola |
| 23 | 7:40am latte, 2 shots; 12:30pm green tea |
| 22 | 7:55am latte, 2 shots; **3:30pm cold brew, 2 cups** |
| 21 | 6:50am drip coffee; 9:30am latte, 2 shots; 2:15pm energy drink; **5:00pm espresso, 2 shots** |
| 20 | 9:45am cappuccino, 2 shots |
| 19 | 10:15am flat white, 2 shots; **3:30pm drip coffee** |
| 18 | 7:45am latte, 2 shots; 11:00am drip coffee |
| 17 | 7:40am latte, 2 shots; **4:15pm cold brew** |
| 16 | 7:50am latte, 2 shots; **3:00pm latte, 2 shots** |
| 15 | 8:05am latte, 2 shots; 11:30am green tea |
| 14 | 7:45am latte, 2 shots; 10:30am drip coffee |
| 13 | 7:40am latte, 2 shots; **3:45pm cold brew, 2 cups** |
| 12 | 8:00am latte, 2 shots; 11:00am americano, 2 shots |
| 11 | 7:50am latte, 2 shots; 1:30pm black tea |
| 10 | 9:30am cappuccino, 2 shots; 2:00pm matcha |
| 9 | 10:00am cappuccino, 2 shots |
| 8 | 7:45am latte, 2 shots; 10:45am drip coffee; 4:30pm cola |
| 7 | 7:40am latte, 2 shots; 12:30pm green tea |
| 6 | 7:55am latte, 2 shots; **3:30pm cold brew, 2 cups** |
| 5 | 6:50am drip coffee; 9:30am latte, 2 shots; 2:15pm energy drink; **5:00pm espresso, 2 shots** |
| 4 | 9:45am cappuccino, 2 shots |
| 3 | 10:15am flat white, 2 shots; 1:30pm black tea |
| 2 | 7:45am latte, 2 shots; 11:00am drip coffee |
| Yesterday | 7:40am latte, 2 shots; **4:15pm cold brew** |
| Today | 7:45am latte, 2 shots; 10:30am drip coffee; 2:30pm green tea, each only once its time has passed |

- **The timing varies from day to day.** 11 of the 30 days end with a cup of 90 mg or more from 3pm on (in bold), enough to leave more than the 40 mg sleep threshold at a 10:30pm bedtime for most of them (<doc:CaffeineCutoff>). 17 stop before 3pm, and 2 end with a small cola. The Insights tab compares nights on either side of the threshold, and the half-life estimator needs the same variety: with the same timing every day, a longer half-life can't be told apart from a stronger sensitivity. The estimator's session asked for this, and for the fixed times.
- **Two heavy days.** 21 days ago and 5 days ago each have four drinks, 425 mg in all.
- **The last 14 days are the first build's script.** It covered 14 days until the owner's 23:10 decision, and the 16 days before them were added then.
- **The caffeine is the catalog's.** Each drink carries what its type and quantity give (<doc:DrinkComposer>), so a demo latte is the same 125.4 mg as a logged one.
- **Local clock times.** The script follows the given calendar, so 7:45am is 7:45am wherever the user is.

### Where the demo drinks go

The owner chose the real drink log (see "The owner's decisions").

- **Each demo drink is marked.** ``LoggedDrink/isDemo`` is `true` for a demo drink, and a drink the user logs is never marked. The mark is stored as `DrinkRecord.isDemo`. It has a default value, so drinks stored before it existed read as the user's own.
- **They count like any drink.** The decay curve, today's total, the cutoff, and the one-tap favourites all include them. That's the point of a demo: the Today screen shows the app working. The history card labels each one "Demo", so the user can always tell them apart.
- **Adding the demo again replaces it**, so it never doubles. The drinks are regenerated for the current time.
- **Removing the demo deletes only demo drinks.** The user's own drinks stay, including any logged while the demo was there.
- **They stay on the device**, like every drink. The drink log's CloudKit sync is deferred (<doc:DrinkComposer>). If it returns, the demo drinks will sync like any drink: a demo added on one device will appear on the user's other devices, and removing it on one will remove it from all. The separate demo user the AI recommended would have kept the demo on one device even then. The owner chose the simpler design.
- **They aren't Health data.** Nothing is written to Apple Health.

## Presentation

### Features

| Feature | Responsibility | Use cases |
|---------|----------------|-----------|
| ``SettingsFeature`` | The tab. It scopes one feature per group of sections, and shows the app's version and build. | ``ObserveAppVersionUseCase`` |
| ``ProfileSettingsFeature`` | About you, Caffeine and your body, and Bedtime | ``ObserveUserProfileUseCase``, ``ObserveTimeOfDayUseCase``, ``SaveAboutYouUseCase``, ``SaveHalfLifeFactorsUseCase``, ``SaveBedtimeUseCase`` |
| ``PermissionsFeature`` | The Permissions section. It's onboarding's permissions step, reused. Settings never sends its `continueTapped`. | ``ObservePermissionsUseCase``, the three request use cases, ``RefreshPermissionsUseCase``, ``OpenAppSettingsUseCase`` |
| ``AppLockSettingsFeature`` | The App lock section (<doc:AppLock>) | ``ObserveAppLockUseCase``, ``ObservePermissionsUseCase``, ``TurnOnAppLockUseCase``, ``TurnOffAppLockUseCase`` |
| ``DemoHistoryFeature`` | The demo drinks, on the Demo data screen, and the root's summary of them | ``ObserveDemoHistoryUseCase``, ``AddDemoHistoryUseCase``, ``RemoveDemoHistoryUseCase`` |
| ``DemoDataFeature`` | The Demo data screen: the demo drinks and the demo Health data switch, side by side | None of its own |
| ``DemoHealthDataFeature`` | The demo Health data switch (<doc:AppleHealthCard>) | ``ObserveDemoHealthDataUseCase``, ``SetDemoHealthDataUseCase`` |

The use cases that save the profile are onboarding's. Settings saves the same answers through them.

### Saving as the user goes

Settings follows the app's one-way data flow (constitution Article I.5), as onboarding does.

- **The factors follow the repository.** An option saves at once, and the section changes only when the repository publishes the saved factors.
- **The name, age, and bedtime are the form's own editing state** (Article I.2). They're filled from every profile the repository publishes, with two exceptions. A name being typed isn't replaced until it's committed. And while a save is under way, a published profile doesn't move any field, so a picker being turned doesn't jump back to a value that was just replaced.
- **The name saves when it's committed**, when the user presses Return or leaves the field, not on every keystroke. A name that wasn't changed saves nothing. The field wraps, as onboarding's does, because the audit flagged a one-line field as clippable. A wrapping field types a newline on Return instead of submitting, so the reducer takes a newline as the commit, and removes it.
- **The age and the bedtime save as soon as they're chosen.** The age saves with the name as it's shown, because the two are saved together (``SaveAboutYouUseCase``).
- **A failed save puts the fields back** to what the repository last published, and the failure is logged. The factors never changed in the first place.

### Demo data

- The section's button reads "Add 30 days of demo drinks" while the log holds none, and "Remove demo drinks" while it does. Which one shows follows the repository's answer, not the tap.
- While a change is under way, the button is disabled, and another tap does nothing.
- A failed change says so under the button, "The demo drinks couldn't be changed. Try again.", until the next try.
- The demo Health data switch is an option under the demo drinks' card, with its own failure message (<doc:AppleHealthCard>).

### The app version

The owner asked for it at 15:47 on 2026-09-13, "for my sanity". The last line of Settings' root reads "Version 1.0 (1)", so a screenshot or a TestFlight report shows which build it came from.

- **It comes through the layers, like any data.** ``BundleAppVersionDataSource`` reads `CFBundleShortVersionString` and `CFBundleVersion` from the app's Info.plist. It's the only code that does (constitution Article I.14). ``LiveAppVersionRepository`` reads it once, when it's created. Its stream sends the version once, then finishes, because the version never changes while the app runs. ``SettingsFeature`` observes it through ``ObserveAppVersionUseCase``, from the root's `task`.
- **Without both keys, the line doesn't show.** A built app always has them, but the line never shows half a version.
- **The numbers are the build settings'**, `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION`, which the generated Info.plist fills in. They're shown as they are. They're identifiers, not quantities, so they aren't formatted as numbers (Article VII.3).
- **It's one line of footnote text in `textPrimary` on the page**, like the sections' notes, so it passes the audit. VoiceOver reads it as text. Its copy is one sentence in the String Catalog, "Version %@ (%@)", so a translator can move the numbers.
- **It isn't a setting.** It's a line under the rows, not a row or a screen, so it doesn't add a settings screen for its own sake.

## Navigation

Settings is the second tab in ``AppView``'s system tab bar. The log button stays above the bar on both tabs.

### Settings' own screens

Settings is hierarchical. ``SettingsFeature`` holds a `StackState` path, as onboarding does (constitution Article I.6), and ``SettingsView`` shows it in a `NavigationStack`:

| Row | Its value on the root | The screen it pushes | The screen's feature |
|-----|-----------------------|----------------------|----------------------|
| About you | The name, when there is one | ``AboutYouSettingsView`` | ``ProfileSettingsFeature`` |
| Caffeine and your body | None. The half-life isn't shown (see "The owner's decisions"). | ``FactorsSettingsView`` | ``ProfileSettingsFeature`` |
| Bedtime | The bedtime, such as "10:30 PM" | ``BedtimeSettingsView`` | ``ProfileSettingsFeature`` |
| Permissions | None | ``PermissionSettingsView`` | ``PermissionsFeature`` |
| App lock | "On" or "Off" | ``AppLockSettingsView``, around ``AppLockSettingsSection`` | ``AppLockSettingsFeature`` |
| Demo data | "Added" while the log holds demo drinks | ``DemoHistorySettingsView`` | ``DemoDataFeature``, which runs ``DemoHistoryFeature`` and ``DemoHealthDataFeature`` |

- **Tapping a row sends `rowTapped`, and the reducer pushes the row's screen** with fresh state (SET-3). The screen observes its own data, as each section did on the flat tab, so it shows the saved values as soon as it opens.
- **The root keeps three sections of its own**, for its rows' values: the profile, the app lock, and the demo drinks. Each follows its repository, so a change made on a pushed screen shows on the root when the user goes back.
- **The three profile screens share ``ProfileSettingsFeature``**, which already handles the name, age, factors, and bedtime. Each pushed screen has its own instance, and shows only its own part.
- **Each screen has its own view, identifier file, and robot** (constitution Articles II.5 and II.7). Its `screen` identifier is on its scroll view, which is also what its robot swipes. A container's identifier given to its only child replaced the child's own identifier, so no screen has a separate one for its scroll view.
- **Each pushed screen is laid out like onboarding's steps**: a large title on the solid page, its section's cards, and the navigation stack's own back button, so swiping back works too.

### The tab bar

The system tab bar's buttons carry no accessibility identifier, however it's set (<doc:OneTapLog>). So the owner amended constitution Article II.6 on 2026-09-12: the root screen's robot, `AppRobot`, finds each tab's button by its label, the tab's title in the development language. No other robot, and no other element, is found by label. `AppRobot.openSettings()` and `AppRobot.openToday()` are the only commands that use it.

The owner then chose how the titles are defined, so that neither the app nor the tests hard-code them (Article II.6 was reworded to match):

- **`AppTab`**, in `AppViewAccessibilityID.swift`, has one case per tab. Each raw value is the title's key in `Localizable.xcstrings`, such as `appView.tab.settings`, not its text.
- **``AppView``** titles each tab with `AppTab.title()`, the key's text in the app's own catalog.
- **`AppRobot`** looks up the same key with `title(in:)`, in the UI test bundle's copy of the catalog in English. The catalog belongs to the UI test target for this.
- **The UI tests launch the app in English** (`-AppleLanguages (en)`), so the tab bar's labels match what the robot looks up.
- **TAB-1** checks that each key has text in the catalog. A missing key would show the key itself in the tab bar.

## Accessibility and localization

- **It's built like onboarding, which passes the audit.** The page is the canvas's solid top color. Each section's eyebrow and note sit on the page in `textPrimary`, and rows sit on `surfaceCard` cards. A factor is an option row with a check circle, the age is a SwiftUI wheel, the bedtime is the system's compact time picker, as in onboarding, and the permissions are onboarding's rows (<doc:Onboarding>, "Accessibility and localization").
- **A chosen option has the selected trait**, so VoiceOver doesn't rely on its fill, and its check circle changes shape as well as color.
- Every control has a visible label, and each Allow button tells VoiceOver which permission it's for.
- A status is written out, never shown by color alone (Article VI.3). A permission's status reads "Asked", "On", "Off", or "Not set up".
- The form scrolls, and every row wraps at the largest Dynamic Type sizes (Article VI.2).
- The history card's "Demo" label is text, part of the row VoiceOver reads.
- All copy is in `Localizable.xcstrings`. The bedtime is formatted with locale-aware APIs, through ``OnboardingFormat`` (Article VII.3).

## Privacy and logging

- **No new data is collected.** Settings changes the profile onboarding already stores (<doc:Onboarding>). The demo mark is one more value on each drink, in the drink store.
- **Nothing is logged about the answers**, as in onboarding (Article XI.6).
- **A failed save or demo change is logged at `error`**, with the error's domain and code only.
- **The app's version isn't user data.** Every user of a build sees the same one, and it isn't logged.

## What changed while building

- **The native form became the app's own style.** The first build was the native `Form` the owner chose. The accessibility audit failed it on iOS's own controls, on a still screen:
  - every switch row's label, "Dynamic Type font sizes are partially unsupported", although the labels grew to several lines at the largest text size, so the audit most likely means the switch itself, which doesn't scale;
  - the age menu picker's value, "Text clipped", with nothing visibly clipped;
  - the gray section headers, "Contrast nearly passed".

  The AI recommended keeping the form with a narrow exception for those three. The owner chose to rebuild Settings in the app's style instead, which uses the parts onboarding already passes the audit with. The reducers didn't change.
- **The demo covers 30 days, not 14.** See "The owner's decisions".
- **The tab titles are catalog keys.** See "Navigation".
- **Known issue: the pushed screens' last content stays under the bar.** At the end of Caffeine and your body's scroll, the half-life card's last line and the medical note sit under the Log button and the tab bar, where they can't be read. The scroll view leaves room only for the home indicator. So `testCaffeineAndYourBodyPassesTheAccessibilityAudit` fails every time. Its second audit finds the card's text still in the bar's fade, at y 713–751, where the fade starts at y 693. The other pushed screens are short enough that it doesn't show. The cause isn't found. `TodayView` builds its scroll view the same way and clears the bar. The one difference is that Settings' screens are inside a `NavigationStack`. On 2026-09-13 the owner chose to record it rather than fix it now. The AI had recommended a 30-minute box to fix it with system insets.

## UI tests

- **One robot per screen.** `SettingsRobot` drives the root, and opens each row's screen. Each pushed screen has its own: `AboutYouSettingsRobot`, `FactorsSettingsRobot`, `BedtimeSettingsRobot`, `PermissionSettingsRobot`, `AppLockSettingsRobot`, and `DemoHistorySettingsRobot`. Each uses its own view's `…AccessibilityID` file, is listed in `Robots.all`, and audits with `auditAccessibilityAboveTheTabBar()`, because every Settings screen scrolls under the log button and the tab bar like the Today screen.
- **Rows are scrolled into view first.** Before each command, the robot scrolls its element into the space below the status bar and above the log button, so a tap can't land on the log button.
- **The name is typed with a Return at the end**, which commits it, rather than by tapping the keyboard's Return key, which only a label could find.
- **`SettingsUITests` launches past onboarding**, with the UI tests' empty drink log and simulated permissions (LAUNCH-3 in <doc:Onboarding>), then opens the tab through `AppRobot`.
- **The demo test checks yesterday.** Today's demo drinks depend on the time the test runs: before 7:45am there are none. Yesterday always has two.
- **The version test checks its shape.** `verifyShowsTheAppVersion()` looks for a version and a build number, such as "1.0 (1)", not their values, because the UI test bundle's version isn't the app's.

## Testable requirements

Each requirement is written so that one test can prove it.

### Domain

| ID | Requirement |
|----|-------------|
| DRINK-3 | A drink is the user's own unless it's marked as a demo drink. The mark doesn't change its intake. |
| DEMO-1 | Every one of the 30 days before today has demo drinks, and none comes before them. It was 14 days until the owner's 23:10 decision. |
| DEMO-2 | Today holds only the script's drinks consumed by now. Just after midnight, it has none, and the 30 days stay. |
| DEMO-3 | Every demo drink is marked demo, could have been logged (``DrinkLogRule``), and carries the caffeine its type and quantity give. The drinks are oldest first, each with its own identifier. |
| DEMO-4 | At least 10 days end with a cup of 90 mg or more from 3pm on, and at least 10 have no drink from 3pm on. Before the 30-day decision it asked for three of each. |
| TAB-1 | Each tab's title comes from the String Catalog: its `AppTab` key's English text is "Today" or "Settings", never the key itself. |
| DEMO-5 | The drinks fall at the same local clock times in any time zone. |
| DEMO-6 | The same moment always gives the same drinks, apart from their identifiers. |
| DEMOUSE-1 | ``AddDemoHistoryUseCase`` asks the repository in the given calendar, and passes on its error. |
| DEMOUSE-2 | ``RemoveDemoHistoryUseCase`` asks the repository, and passes on its error. |
| DEMOUSE-3 | ``ObserveDemoHistoryUseCase`` streams the repository's answers. |
| VERUSE-1 | ``ObserveAppVersionUseCase`` streams the repository's version. |

### Data

| ID | Requirement |
|----|-------------|
| SRC-8 | A stored drink keeps whether it's a demo drink. |
| SRC-9 | Replacing the demo drinks deletes the old ones, keeps the user's own, and stores the new ones marked demo, in one save that persists, with one change signal. |
| SRC-10 | Removing the demo drinks when there are none changes nothing and signals nothing. Removing them when there are some signals once, and leaves the user's own. |
| DEMOREPO-1 | Adding the demo history stores ``DemoHistoryRule``'s drinks for the clock's current time, in place of the old demo drinks, and keeps the user's own. |
| DEMOREPO-2 | Removing the demo history deletes only the demo drinks. |
| DEMOREPO-3 | The demo history stream sends the current answer first, then an answer only when it changes. |
| DEMOREPO-4 | A failed replacement throws, and nothing changes. |
| DEP-DEMO | Each demo history use case holds the one app-scoped drink log repository, and each reports an issue in a test that doesn't override it, as does the drink log data source's replacement. |
| VER-1 | ``BundleAppVersionDataSource`` gives the Info.plist's version and build, and no version unless both are there. |
| VER-2 | By default, it reads the app's own bundle. |
| VERREPO-1 | The app version stream sends the data source's version once, then finishes. Without a version, it finishes without sending one. |
| DEP-VER | In previews, as live, ``ObserveAppVersionUseCase`` streams the app bundle's own version. It reports an issue in a test that doesn't override it. |

### Features

Each is tested with an exhaustive `TestStore`, with its use cases overridden.

| ID | Requirement |
|----|-------------|
| SET-1 | ``SettingsFeature``'s root runs the sections its rows summarize: the profile, the app lock, and the demo drinks. Before the tab became hierarchical, it ran the permissions section too. |
| SET-2 | ``AppFeature`` runs ``SettingsFeature``, for its tab. |
| SET-3 | Each row pushes its own screen onto the path, with fresh state: About you, Caffeine and your body, and Bedtime a ``ProfileSettingsFeature`` each, Permissions a ``PermissionsFeature``, App lock an ``AppLockSettingsFeature``, and Demo data a ``DemoDataFeature``. The Apple Health card's session changed Demo data's from ``DemoHistoryFeature`` on 2026-09-13, to add the demo Health data switch. |
| SET-4 | A pushed screen's actions run its feature. |
| SET-5 | Once its `task` starts, the root shows the app's version and build, from the repository. |
| SETPROF-1 | The profile sections show the saved profile, refilled from every profile the repository publishes. The age fills in once the current year is known, and a saved age outside the picker is left empty. |
| SETPROF-2 | The name saves when it's committed, with the age. A newline typed in the name commits it, without the newline. A name being typed isn't replaced by a published profile, and a name that wasn't changed saves nothing. |
| SETPROF-3 | The age and the bedtime save as soon as they're chosen. |
| SETPROF-4 | A profile published while a save is under way doesn't move the name, age, or bedtime. |
| SETPROF-5 | A failed save puts the name, age, and bedtime back to what was last published. |
| SETPROF-6 | A factor saves as soon as it's chosen or unchosen, with the others, and the sections change only when the repository publishes. |
| SETPROF-7 | Choosing pregnancy asks for the trimester before anything is saved. Unchoosing it removes it, or, while a trimester is being chosen, saves nothing. |
| SETDEMO-1 | The demo section shows whether the log holds demo drinks, from the repository. |
| SETDEMO-2 | Adding and removing go through their use cases, adding in the user's calendar, and the answer waits for the repository. |
| SETDEMO-3 | A failed change says so, until the next try. |
| SETDEMO-4 | A tap while a change is under way does nothing. |

### UI

| ID | Requirement |
|----|-------------|
| UI-SET-1 | Settings opens from its tab and shows the saved answers, such as the bedtime, and Today opens from its own tab. |
| UI-SET-2 | A name saved in Settings greets the user on the Today screen. |
| UI-SET-3 | A factor chosen in Settings shows as chosen once it's saved. Until 2026-09-13 it checked the starting half-life the factor gave, which the app no longer shows. |
| UI-SET-4 | Each permission shows the outcome of asking for it, from the simulated data sources. |
| UI-SET-5 | Adding the demo drinks fills the history card, each labeled "Demo", and Settings then offers to remove them. Removing them offers to add them again. The Today screen passes the audit with demo drinks showing. |
| UI-SET-6 | Each Settings screen, the root and all six it opens, passes the system accessibility audit (constitution Article VI.4), through `auditAccessibilityAboveTheTabBar()`. At the end of a screen's scroll, contrast is ignored only for elements under the navigation bar's fade that the first audit checked in full. The owner approved it on 2026-09-13. Caffeine and your body's audit fails until the known issue in "What changed while building" is fixed. |
| UI-SET-7 | The root's last line shows the app's version and build. |
