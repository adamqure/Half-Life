# Onboarding

The first-run survey: who the user is, what changes how fast they clear caffeine, when they want to be asleep, and which permissions they grant.

## Overview

Onboarding is roadmap rank 6, the onboarding survey: "Produces the informed prior and the cutoff time. Day-one accuracy before any data exists." It runs once, on the first launch, before the Today screen. What it asks becomes the user's profile, their starting half-life, and their bedtime, so the decay card is personal from the first drink.

> Note: The owner asked for this design before any code, on 2026-09-12, and onboarding was built from it the same day. "What changed while building" lists where the build departs from the first design.

### What it asks, and why

The owner set the scope on 2026-09-12.

| Asks for | Used for | Required? |
|----------|----------|-----------|
| Name | The greeting: "Good afternoon, Alex." (<doc:TodayScreen>) | No |
| Age | The recommended sleep range that sleep insights compare against | No |
| What changes how fast the user clears caffeine | The starting half-life (see "HalfLifePriorRule") | No. "None of these" is the default. |
| Bedtime | The level at bedtime, and later the cutoff and the pre-log warning (rank 13) | No. It starts at 10:30pm (``Bedtime/standard``). |
| Apple Health, notifications, and Face ID | Reading sleep, steps, and resting heart rate. Notifications and Face ID have no feature yet (see "Risks the owner accepted"). | No. The app works fully without any of them (constitution Article V.3.3). |

Nothing blocks. Every step can be continued with nothing entered, so a user who skips everything lands on the Today screen with the standard model.

### The owner's decisions

The owner answered four questions on 2026-09-12:

1. **Apple Health is requested when the user taps**, from the permissions step, after the step explains each type. Constitution Article V.3.1 said "at the moment the feature needs them, never at launch", so it was amended the same day (see "Constitution amendment").
2. **Notifications and Face ID are requested in onboarding**, although no feature uses either yet. The cutoff notification is rank 19 and the biometric lock is rank 27. The AI recommended adding each row with its feature instead. The risks are recorded below.
3. **Age sets the recommended sleep range.** It doesn't change the half-life.
4. **The medical answers set the starting half-life, and are kept on the device**, so Settings (rank 21) can revise them later, for example when a pregnancy ends.

The name was a low-priority item in the roadmap's backlog, and the Today Screen article said onboarding wouldn't ask for it. The owner added it to onboarding on 2026-09-12. The backlog's design for it still applies: a text field with `.textContentType(.givenName)`, so AutoFill offers the first name from the user's contact card in one tap, with no permission.

## What the brief and prototype ask for

The prototype's onboarding is screenshots 01–06. The brief asks that every cut be explained ("If you cut something from the prototype, say why"). Each element is kept, changed, or cut.

| Prototype element | Becomes |
|-------------------|---------|
| 01: the logo, the wordmark, and "Log your coffee in one tap…" | Kept, as the Welcome step |
| 01: "Continue with Apple" and "Continue with email" | Cut. The brief rules out accounts ("One user, one device. No accounts infrastructure"). One "Get started" button replaces both. |
| 01: "Your caffeine and health data stays on your device." | Kept, reworded so it's true. The drink log syncs to the user's private iCloud database (constitution Article V.1), so the footer can't say all caffeine data stays on the device. For example: "Your health data stays on this iPhone. Your drink log syncs only to your own iCloud. No account needed." |
| 02: "What should we call you?" | Kept, and optional. Age joins it on one "About you" step. |
| 03: goals (Sleep better, Fewer jitters, Cut back gradually, Just curious) | Cut. The screen says the goals change "what we show you first", but nothing in the app would change. "Fewer jitters" belongs to the personal sensitivity threshold (rank 22), and nothing on the roadmap steps a ceiling down week by week. Collecting them would break Articles III.1 and V.2. |
| 03: the daily ceiling, 400 mg | Cut from onboarding, because no feature uses a ceiling yet. The Today total's bar may need one (see "Still to decide"). |
| 04: bedtime chips, 9:30pm to 12:00am | Replaced by a time picker for any time of day, so a shift worker's bedtime fits too. The owner chose this on 2026-09-12. |
| 04: the cutoff card | Cut from onboarding by the owner on 2026-09-12. The cutoff is built with the Today screen's Last Cup tile instead (see the Caffeine Cutoff article). |
| 04: "Roughly how much a day?" | Cut. Nothing uses it. The estimator (rank 9) learns from the log, and one-tap favourites come from logged drinks. |
| New: what changes how fast you clear caffeine | Added. Half-lives vary several-fold between people (<doc:CaffeineDecayModel>), and a few factors a user can report explain much of it. This is the "informed prior" the roadmap asks for. |
| 05: "Connect Apple Health", with a toggle per type | Kept, as one row of the permissions step. The toggles are cut. Health's own sheet already has a switch for each type, and HealthKit never tells an app which read types the user allowed, so the app's toggles would duplicate the sheet and could fall out of step with it. |
| 05: "We only read. Nothing is written back, and nothing leaves your phone." | Kept. Onboarding asks for no write access, and Health data is never synced (Article V.3.4). |
| 05: "Not now — I'll log manually" | Kept, as the step's Continue button, which works whether or not anything was allowed |
| New: the Notifications and Face ID rows | Added, at the owner's request |
| 06: "You're set, Test.", with a summary | Kept. It shows the name, the starting half-life, the bedtime, the recommended sleep range, and each permission's status. The goals and ceiling rows are cut with their steps. |
| 06: "Give it about ten days of logging — that's when the sleep pattern gets honest." | Replaced until the estimator (rank 9) decides how much data it needs. The app can't promise a number of days it hasn't designed (the brief's *Honesty* criterion). |
| 06: "Log my first cup" and "Take me to Today" | Kept |

## The flow

| Step | Screen | Asks | Saves |
|-----:|--------|------|-------|
| 1 | Welcome | Nothing | Nothing |
| 2 | About you | Name (optional), age (optional) | On Continue |
| 3 | Caffeine and your body | What changes how fast they clear caffeine, a multi-select that starts at "None of these" | As each choice changes |
| 4 | Bedtime | When they want to be asleep, on a time picker | On Continue |
| 5 | Permissions | Apple Health, notifications, Face ID | Each request is the system's own state |
| 6 | Summary | Nothing | Completes onboarding when the user leaves it |

- **The half-life comes before the bedtime.** The order was chosen for the bedtime step's cutoff card, which used the half-life. The owner took the cutoff out of onboarding on 2026-09-12 (see "What changed while building"), and the order stayed.
- **Steps 2 to 5 show their place and a back button.** The place is written out, "Step 1 of 4", rather than drawn as the prototype's dots, so it doesn't rely on color (Article VI.3). The back button is the navigation stack's own, so swiping back works too.
- **Onboarding ends when the user leaves the summary.** "Log my first cup" completes it and opens the drink composer, and "Take me to Today" completes it.
- **Quitting before the end restarts onboarding**, at Welcome, on the next launch. The answers saved so far fill the steps in.

### Saving as the user goes

Onboarding follows the app's one-way data flow (constitution Article I.5). No step holds a draft of the profile.

- **A factor is saved as soon as it's chosen.** The step reads it back through the repository's stream, so an option shows as chosen once the repository publishes it. The starting half-life card updates the same way, so it always shows the half-life the rule gave for what's saved.
- **Typed and picked answers are saved on Continue**: the name, the age, and the bedtime. They're the step's own editing state until then (Article I.2), so a half-typed name isn't saved. A step that's returned to fills in from the saved profile once, unless the user has already changed it.
- **A failed save doesn't block.** It's logged, and the user continues. The answer can be given again later, and until then the default applies.
- **Permissions are system state.** The permissions step asks through a use case, and learns the outcome through the permissions repository's stream (Article I.6).

## Domain

Every entity is a plain `Sendable`, `Equatable` value type that imports only Foundation (constitution Article I.10). None of them holds user-facing text.

### UserProfile

What the user has told the app about themselves, and the half-life that follows from it. Onboarding adds five properties to the existing entity. Every property has a default, so a profile with nothing given is `UserProfile()`.

| Property | Type | Default | Meaning |
|----------|------|---------|---------|
| `name` | `String?` | `nil` | The first name. It already existed. |
| `birthYear` | `Int?` | `nil` | The year the user's age implies |
| `halfLifeFactors` | `Set<HalfLifeFactor>` | Empty | What the user said changes how fast they clear caffeine. Empty means "None of these". |
| `bedtime` | ``Bedtime`` | ``Bedtime/standard`` | When the user wants to be asleep |
| `halfLife` | ``CaffeineHalfLife`` | ``CaffeineHalfLife/standard`` | The half-life the decay model uses for the user: the one `HalfLifePriorRule` gave for their factors |
| `hasCompletedOnboarding` | `Bool` | `false` | Whether the user has finished onboarding |

- **The bedtime and the half-life are in the profile, and are also served on their own.** The profile file stores them, and ``FileProfileDataSource`` serves them to ``CaffeineDecayRepository`` through ``BedtimeDataSource`` and ``HalfLifeDataSource``, as the Today Screen and Caffeine Decay Model articles designed. The bedtime step and the summary read them from the profile. This first design kept the bedtime out of the profile, and read it from the cutoff stream. With the cutoff gone, the profile was the simpler source.
- **The age is stored as a birth year**, the current year minus the age given, so it doesn't go stale. It can be a year off, which matters only in the year a user crosses a sleep range's boundary. The owner chose this on 2026-09-12.

### HalfLifeFactor

Something the user can report that changes how fast they clear caffeine. Each case changes the half-life by more than 25% in the studies in "HalfLifePriorRule", and is something a user knows about themselves.

| Case | What the step says |
|------|--------------------|
| `pregnant(Trimester)` | "I'm pregnant", then which trimester: `first`, `second`, or `third` |
| `estrogen` | "I take estrogen": the combined pill, the patch, or the ring, or hormone therapy |
| `smokes` | "I smoke cigarettes". Vaping and nicotine patches don't count, and the step says so: smoke speeds up caffeine clearance, and nicotine doesn't. |
| `cirrhosis` | "I have cirrhosis of the liver" |
| `fluvoxamine` | "I take fluvoxamine (Luvox)" |

The step starts with "None of these" chosen. `pregnant` and `estrogen` can both be chosen, but they share one mechanism, so the rule doesn't stack them.

### RecommendedSleep

The nightly sleep recommended for the user's age.

| Property | Type | Meaning |
|----------|------|---------|
| `minimumSeconds` | `TimeInterval` | The least recommended |
| `maximumSeconds` | `TimeInterval` | The most recommended |

When the age isn't known, it's the adult range. Nothing shows it yet except the summary. The Patterns screen (rank 15) and insight cards (rank 12) will compare sleep against it.

### Permissions

Each permission's status. All three are system state, read through their data sources.

| Property | Type | Cases |
|----------|------|-------|
| `health` | `HealthAccessStatus` | `notRequested`, `requested`, `unavailable` |
| `notifications` | `NotificationPermission` | `notRequested`, `allowed`, `denied` |
| `biometrics` | `BiometricPermission` | `notRequested`, `allowed`, `denied`, `notEnrolled`, `unavailable`, each with the device's `Biometry` (Face ID or Touch ID) where it has one |

- **Health has no "allowed" case, on purpose.** HealthKit doesn't tell an app whether the user allowed read access, so an app can't know. It only knows whether it has asked. So the row says it has asked, and points to the Health app to change what's shared. Claiming "Connected" would overstate what the app knows (the brief's *Honesty* criterion).
- **Provisional and ephemeral notification permission count as `allowed`.**
- **Touch ID devices get a Touch ID row.** iOS 26 still runs on the iPhone SE, which has Touch ID and no Face ID.

### Business rules

| Rule | Calculates | Executed by |
|------|------------|-------------|
| `HalfLifePriorRule` | The starting half-life, from the factors | ``UserProfileRepository``, when the factors are saved |
| `SleepNeedRule` | The recommended sleep range, from the birth year and the current date | ``UserProfileRepository`` |

#### HalfLifePriorRule

The starting half-life is the standard 5.5 hours times each factor's multiplier:

```
T½ = 5.5 h × m(pregnancy or estrogen) × m(smokes) × m(cirrhosis) × m(fluvoxamine)
```

- **Pregnancy and estrogen don't stack.** Both slow the same enzyme, so when both are chosen, only the larger multiplier applies.
- **The rest multiply.** Each one changes clearance independently, so their effects on the half-life multiply.
- **The result is clamped to 3 to 40 hours.** Smoking alone gives 3.3 hours. Fluvoxamine alone gives 33 hours, and it has been measured at 56. Above 40 hours the model's other uncertainties dwarf the half-life's, and intakes would keep counting for more than two weeks (<doc:CaffeineDecayModel>). This range is the one the Caffeine Decay Model article left to the tuning features.

| Factor | Multiplier | Starting half-life | Evidence |
|--------|-----------:|-------------------:|----------|
| None | ×1.0 | 5.5 h | — |
| Pregnant, first trimester | ×1.5 | 8.3 h | Caffeine clearance was 33% lower at 14–18 weeks than after the birth (Tracy 2005, 25 women followed through pregnancy). No primary study measured the first trimester itself. This is an upper bound, which errs toward an earlier cutoff. |
| Pregnant, second trimester | ×1.9 | 10.5 h | 48% lower at 24–28 weeks (Tracy 2005) |
| Pregnant, third trimester | ×2.7 | 14.9 h | 65% lower at 36–40 weeks (Tracy 2005, ×2.9). Clearance at term was 39% of normal (Parsons 1982, ×2.5). The half-life was 10.5 hours in the last 4 weeks, against 3.4 hours in women who weren't pregnant (Knutti 1981). |
| Estrogen | ×1.5 | 8.3 h | Low-dose combined pills: 7.9 hours against 5.4 (Abernethy 1985, 9 users and 9 matched controls). Older and other pills measured ×1.7 to ×2.2 (Patwardhan 1980, Balogh 1995). Hormone therapy measured about ×1.4 (Pollock 1999). The patch and the ring haven't been studied. They contain the same estrogen, so they're assumed to act the same. |
| Smokes | ×0.6 | 3.3 h | 3.5 hours against 6.0 (Parsons 1978, 13 and 13). Clearance falls 36% after quitting (Faber 2004). A nicotine patch changed nothing (Hukkanen 2011, randomized crossover). |
| Cirrhosis | ×2.5 | 13.8 h | 13.7 hours against 3.8 (Renner 1984, ×3.6), but only ×1.2 in a milder group (Desmond 1980). The effect depends on severity, so this is between the two. |
| Fluvoxamine | ×6.0 | 33 h | 31 hours against 5 (Jeppesen 1996, 8 people, ×6.2). Another study measured 56 hours against 4.9 (Culm-Merdek 2005, ×11). The FDA lists it as the one strong inhibitor of the enzyme that clears caffeine. |

Each multiplier is a starting point for one person, drawn from group averages. Healthy people alone vary from about 2.3 to 9.9 hours (Blanchard 1983, 16 men), so the step and the summary call the result a starting estimate. The personal half-life estimator (rank 9) replaces it once the user's own data can.

**Considered and left out.** Each of these was in the research, and each fell short:

| Factor | Why it's left out |
|--------|-------------------|
| Age | No significant difference between men of 71 and 20 (Blanchard 1983). The owner decided the same on 2026-09-12. |
| Progestin-only pills, implants, and IUDs | No caffeine study found. The estrogen option's copy says "with estrogen" so these users don't choose it. |
| Vaping, nicotine patches, and heated tobacco | Nicotine doesn't speed up clearance (Hukkanen 2011). Switching from cigarettes behaves like quitting (van der Plas 2020). |
| Fatty liver and hepatitis, without cirrhosis | No caffeine study found. |
| Ciprofloxacin (×1.5) and enoxacin (×6) | Antibiotic courses last days, so a stored answer would be wrong within a week or two. Enoxacin is rarely prescribed. |
| Cimetidine (×1.5–2.0) and other moderate inhibitors, such as mexiletine | A user can't be expected to know which of their medicines slow caffeine. Only fluvoxamine has an effect large enough to name. |
| Regular heavy drinking (×1.7) | One study of 10 people (George 1986), and an intrusive question for a first-run survey |
| Obesity | The half-life was longer, but not significantly, because clearance didn't change (Abernethy 1985). |
| Recently gave birth | Clearance returns to normal within days to a month. The sources disagree (Brazier 1983, Knutti 1981), and the answer would go stale quickly. |
| Grapefruit juice | One study found +31%, and another found no effect. |

#### SleepNeedRule

The recommended nightly sleep for the user's age, from the National Sleep Foundation's consensus (Hirshkowitz 2015).

| Age | Recommended | Also consistent with |
|-----|-------------|----------------------|
| 13–17 | 8–10 h | The AASM's pediatric consensus for 13 to 18 (Paruthi 2016) |
| 18–64 | 7–9 h | The AASM's "seven or more hours" for adults (Watson 2015) |
| 65 and over | 7–8 h | — |
| Not given | 7–9 h | The adult range |

- Each boundary age belongs to the range it starts: 18 is an adult, and 65 is an older adult.
- The age is the current year minus the birth year, so it can be a year ahead of the user's real age.
- The youngest age the step accepts is 13. Younger children aren't the app's audience, and their sleep and caffeine guidance is different. The AI chose this, and it's still to be confirmed.

### Use cases

| Use case | Operation | Repository |
|----------|-----------|------------|
| ``ObserveUserProfileUseCase`` | Streams the profile. Onboarding's steps read their saved answers and the starting half-life from it, and ``AppFeature`` reads the completion. | ``UserProfileRepository`` |
| ``SaveAboutYouUseCase`` | Saves the trimmed name, or none for a blank one, and the birth year the age implies in the given calendar | ``UserProfileRepository``, and ``CurrentTimeRepository`` for the year |
| ``SaveHalfLifeFactorsUseCase`` | Saves the factors. The repository derives the starting half-life from them and stores it. | ``UserProfileRepository`` |
| ``SaveBedtimeUseCase`` | Saves the bedtime | ``UserProfileRepository`` |
| ``CompleteOnboardingUseCase`` | Marks onboarding as complete. ``AppFeature`` executes it. | ``UserProfileRepository`` |
| ``ObserveRecommendedSleepUseCase`` | Streams the recommended sleep range, in the given calendar | ``UserProfileRepository`` |
| ``ObservePermissionsUseCase`` | Streams the three permissions' statuses | ``PermissionsRepository`` |
| ``RequestHealthAccessUseCase`` | Asks, in one sheet, to read sleep, steps, and resting heart rate | ``PermissionsRepository`` |
| ``RequestNotificationPermissionUseCase`` | Asks to send notifications | ``PermissionsRepository`` |
| ``RequestBiometricPermissionUseCase`` | Asks to use Face ID or Touch ID | ``PermissionsRepository`` |
| ``RefreshPermissionsUseCase`` | Re-reads the statuses, for example when the app returns from the Settings app | ``PermissionsRepository`` |
| ``OpenAppSettingsUseCase`` | Opens Half-Life's page in the Settings app, for a permission that's off | ``PermissionsRepository`` |

## Data

### Repositories

| Repository | Owns | Data sources |
|------------|------|--------------|
| ``UserProfileRepository`` (extended) | What the user has told the app: name, birth year, factors, and completion. It also writes the bedtime and the starting half-life, which ``CaffeineDecayRepository`` reads. | `FileProfileDataSource`, shared with ``CaffeineDecayRepository``; ``ClockDataSource`` |
| ``CaffeineDecayRepository`` (extended) | It re-reads the bedtime and half-life when their data source signals a change, and republishes the curve and the status (REPO-11 and REPO-12). | ``FileProfileDataSource``, behind the bedtime and half-life protocols, in place of the standard data sources it replaced |
| `PermissionsRepository` (new) | The three permissions' statuses | `HealthKitAuthorizationDataSource`, `UserNotificationsAuthorizationDataSource`, `LocalAuthenticationDataSource`, `FilePermissionHistoryDataSource` |

- **The profile's stream no longer finishes.** It publishes the current profile as soon as it's subscribed to, then every change (constitution Article I.12). Today it finishes after one value, because nothing could change the profile.
- **The starting half-life is stored.** When the factors are saved, ``UserProfileRepository`` executes `HalfLifePriorRule` and stores the result through ``HalfLifeDataSource``. ``CaffeineDecayRepository`` reads it from the same data source, as it reads the standard one today, and the data source's change signal tells it to recalculate. This is the shared-data-source pattern in <doc:Architecture>. The factors are stored too, so the prior can be recalculated if the rule changes. How the estimator (rank 9) and a Settings override (rank 21) combine with the prior is theirs to decide.
- **The permissions repository refreshes on request.** A notification or Face ID permission can change in the Settings app while Half-Life is in the background. The permissions step sends a refresh when the app becomes active, and the repository republishes if anything changed.

### Data sources

| Data source | Wraps |
|-------------|-------|
| `FileProfileDataSource`, implementing ``UserProfileDataSource``, ``BedtimeDataSource``, and ``HalfLifeDataSource`` | One JSON file in Application Support, written atomically with `NSFileProtectionComplete`. It stores the profile, the bedtime, and the starting half-life, and signals each subscribed repository after every successful write. One shared instance sits behind both repositories, like ``DrinkLogDataSourceKey``. It replaced the empty profile, standard bedtime, and standard half-life data sources. |
| `HealthKitAuthorizationDataSource` | `HKHealthStore.requestAuthorization(toShare:read:)` and `statusForAuthorizationRequest(toShare:read:)`, on `HKHealthStore.halfLife`. It presents Health's sheet itself (Article I.6), and it's the only data source that requests Health access (Article V.3.1). It asks to read sleep analysis, step count, and resting heart rate, and to write nothing. |
| `UserNotificationsAuthorizationDataSource` | `UNUserNotificationCenter`: the current settings' authorization status, and `requestAuthorization(options:)` for alerts and sounds |
| `LocalAuthenticationDataSource` | `LAContext`: `canEvaluatePolicy(_:error:)` and `biometryType` for the status, and `evaluatePolicy(_:localizedReason:)` for the request |
| `FilePermissionHistoryDataSource` | A small JSON file that records whether Face ID has been requested. iOS reports Face ID as available both before the app asks and after the user allows it, so the app has to remember that it asked. |

**Why a file, not SwiftData or UserDefaults.** The profile holds health information, such as a pregnancy, so it needs `NSFileProtectionComplete` (Article V.4), and it must not sync (Article V.1). The drink store syncs to CloudKit and uses a weaker class, so the profile can't share it, and a second SwiftData store for one record is more machinery than a file. UserDefaults can't be given `NSFileProtectionComplete`, and it's a required-reason API, which would need a privacy manifest the app doesn't have yet (Article V.7).

**`NSFileProtectionComplete` has a cost.** The file can't be read while the device is locked. The decay repository reads the bedtime and half-life only while a feature observes them, which happens in the foreground, so that's fine today. Siri (rank 14) answering "when should I sleep?" from the Lock Screen would need them, and would have to fail gracefully or argue for a weaker class then.

**Face ID has no separate permission request.** iOS shows the Face ID purpose string the first time the app evaluates a biometric policy, and then scans the user's face. So "requesting" Face ID is one authentication. Its only lasting effect is the permission, until the biometric lock (rank 27) uses it.

## Presentation

### Features

| Feature | Responsibility | Use cases |
|---------|----------------|-----------|
| ``OnboardingFeature`` | The flow. Welcome is the root of a navigation stack, and each later step is pushed onto a `StackState` path (constitution Article I.6). It tells ``AppFeature`` when the user asked to log their first cup. | None of its own |
| ``AboutYouFeature`` | Step 2: the name and age | ``ObserveUserProfileUseCase``, ``ObserveTimeOfDayUseCase`` (for the current year, to fill in the age), ``SaveAboutYouUseCase`` |
| ``HalfLifeFactorsFeature`` | Step 3: the factors, and the starting half-life they give | ``ObserveUserProfileUseCase``, ``SaveHalfLifeFactorsUseCase`` |
| ``BedtimeFeature`` | Step 4: the bedtime, on a time picker | ``ObserveUserProfileUseCase``, ``SaveBedtimeUseCase`` |
| ``PermissionsFeature`` | Step 5: one row per permission, with its status and an action | ``ObservePermissionsUseCase``, the three request use cases, ``RefreshPermissionsUseCase``, ``OpenAppSettingsUseCase`` |
| ``OnboardingSummaryFeature`` | Step 6: the summary, and the two ways out | ``ObserveUserProfileUseCase``, ``ObserveRecommendedSleepUseCase``, ``ObservePermissionsUseCase`` |

Each step is its own feature, view, and screen, so each has its own robot (Article II.5) and its own exhaustive `TestStore` tests. One reducer for the whole flow would have been simpler to wire, but its state and tests would carry every step at once.

### The root

``AppFeature`` starts observing the profile when its view appears.

- **Until the first profile arrives**, ``AppView`` shows only its background, so the Today screen never flashes up behind onboarding.
- **While onboarding isn't complete**, ``AppFeature`` presents `OnboardingFeature` full screen, through a `@Presents` property.
- **Leaving the summary** reaches ``AppFeature`` as a delegate action, and ``AppFeature`` completes onboarding through ``CompleteOnboardingUseCase``. If that fails, the failure is logged and onboarding stays.
- **When the profile says it's complete**, ``AppFeature`` dismisses onboarding. The dismissal follows the repository, not the button (constitution Article I.5).
- **"Log my first cup"** is remembered by ``AppFeature``, which presents the drink composer once the full-screen cover has finished going away. ``AppView`` reports that through the cover's `onDismiss`, so the sheet isn't presented in the same update as the dismissal, which SwiftUI can drop.

### The permissions step

Each row shows an icon, the permission's name, one line on what it's for, and its status as text with a symbol, never as color alone (Article VI.3).

| Row | Not asked | After asking |
|-----|-----------|--------------|
| Apple Health: "Reads your sleep, steps, and resting heart rate. Nothing is written back, and your Health data never leaves this iPhone." | "Allow" button | "Asked", with a line pointing to the Health app to change what's shared. On a device without Health: "Not available on this device". |
| Notifications | "Allow" button | "On", or "Off" with a button to the Settings app |
| Face ID (or Touch ID): "Lets Half-Life check that it's you." | "Allow" button | "On", or "Off" with a button to the Settings app. On a device with none enrolled: "Not set up", with "Set up Face ID in the Settings app." With no biometrics at all, the row is hidden. |

Opening the Settings app goes through the permissions repository, to a data source, like every other piece of system UI (Article I.6).

### Accessibility and localization

- Each permission row's name is a heading. Its Allow button reads as "Allow Apple Health", "Allow notifications", or "Allow Face ID", and its status is one element, with its symbol hidden.
- Each step's place is written out, "Step 1 of 4", and read by VoiceOver.
- **Every onboarding screen has a solid page**, the canvas's top color, and text set directly on it uses `textPrimary`. Over the gradient, the accessibility audit's contrast check failed text on every pushed step, even `textPrimary` at over 10:1 by the tokens' values. On Welcome, the same check passed its small `textSecondary` footer on some runs and failed it on others. On the solid page, small `textSecondary` text such as "Step 3 of 4" still failed, although the tokens put it at 5.6:1. The audit seems to measure rendered pixels, which the gradient and small glyphs throw off. Text on cards keeps both tones, and passed throughout. A scratch diagnostic found each of these, and wasn't kept. The Design System article's page gradient still applies to the rest of the app.
- **The summary's buttons sit on the solid page, and onboarding's primary button has no shadow.** The audit failed "Take me to Today" for contrast while the summary could scroll under it, and again while the shadow of "Log my first cup" fell across it. The drink composer's Add button has no shadow either.
- **The name field wraps**, up to three lines. As a one-line field, the audit reported that its text could be clipped at larger Dynamic Type sizes.
- **The bedtime is two wheels**, hours and minutes, built from SwiftUI pickers, with hours in the locale's clock ("10 PM" or "22"). The system's time picker failed the audit's Dynamic Type check ("Dynamic Type font sizes are unsupported"). The age wheel, also a SwiftUI picker, passes.
- A selected chip or factor has the selected trait, so VoiceOver doesn't depend on its fill.
- Every step scrolls vertically, so nothing is lost at the largest Dynamic Type sizes (Article VI.2). **No screen scrolls sideways**: its content fits the screen's width, and UI-ONB-8 checks each screen with a sideways swipe, at the default and the largest text size. iOS 26's back gesture still works from anywhere on a pushed step, and slides the page sideways as it goes back. The owner chose on 2026-09-12 to keep it.
- All copy lives in `Localizable.xcstrings`. Half-lives, times, and sleep ranges are formatted with locale-aware APIs (Article VII.3).
- The factors step says plainly that Half-Life isn't medical advice, and suggests asking a doctor how much caffeine is right during pregnancy or with liver disease.

## Privacy and logging

### Stored data

The Architecture article's "Data and privacy" table lists the profile too.

| Data | Stored in | Protection class | Why it's collected |
|------|-----------|------------------|--------------------|
| Name | `FileProfileDataSource`'s file, on the device only | `NSFileProtectionComplete` | The greeting |
| Birth year | The same file | `NSFileProtectionComplete` | The recommended sleep range |
| Factors that change the half-life, which can include a pregnancy or liver disease | The same file | `NSFileProtectionComplete` | The starting half-life, and revising it later |
| Starting half-life | The same file | `NSFileProtectionComplete` | The decay model's per-user parameter |
| Bedtime | The same file | `NSFileProtectionComplete` | The level at bedtime |
| Onboarding completed | The same file | `NSFileProtectionComplete` | Showing onboarding only once |
| Face ID requested | `FilePermissionHistoryDataSource`'s file | `NSFileProtectionComplete` | The Face ID row's status |

None of it syncs to iCloud. The factors and the half-life derived from them are health data.

### Logging

Following Article XI and <doc:Logging>:

- **Never logged, at any level:** the name, the age or birth year, any factor, the starting half-life, or the bedtime. The factors and the half-life are health values (XI.6.1). The name, age, and bedtime are personal data that no diagnosis needs (XI.6.2).
- **`notice`:** ``LiveUserProfileRepository`` logs "Onboarding completed". ``LivePermissionsRepository`` logs each permission request, with its outcome as `.public` for notifications and Face ID. For Health, it logs only that the sheet was requested, since the outcome isn't known.
- **`error`:** a failed read or write of either file, and a failed permission request, with the error's domain and code as `.public` and nothing else (XI.6.4).

## What changed while building

The owner answered four more questions on 2026-09-12, before the build:

| Question | Decision |
|----------|----------|
| The multipliers, the no-stacking rule, and the 3 to 40 hour range | Used as proposed |
| The bedtime step's cutoff card | Left out of onboarding for now. The owner later had the cutoff built with the Today screen's Last Cup tile, in another session (the Caffeine Cutoff article). |
| How age is asked | A picker from 13 to 100, with "Prefer not to say", stored as a birth year |
| Bedtimes outside the prototype's chips | A time picker only, with no chips |

These changed the design in the build:

- **No cutoff in onboarding.** `CaffeineCutoff`, `CaffeineCutoffRule`, and `ObserveCaffeineCutoffUseCase` left this article, and so did their requirements.
- **The bedtime saves on Continue.** With no card depending on it, it's editing state until Continue, like the name and age. A time picker that saved on every turn, and waited for the repository, could also have jumped back while turning.
- **The profile carries the bedtime and the half-life.** The steps read them from the profile, not from the cutoff stream.
- **``AppFeature`` completes onboarding**, not the summary. The summary's delegate action can't be cancelled by the dismissal it causes, and the root is where the composer opens afterwards.
- **The steps' place is written out**, "Step 1 of 4", instead of dots.
- **Every onboarding screen has a solid page, with primary-tone text on it, and the bedtime is two wheels.** Both were needed to pass the accessibility audit. See "Accessibility and localization".
- **The permissions stack was built in parallel** by a subagent, against a contract this session set. It added ``UIKitSystemSettingsDataSource``, the simulated data sources for UI tests, and the Touch ID prompt's reason, "Allow Half-Life to check that it's you.", which doesn't promise the lock that isn't built.
- **`StandardBedtimeDataSource`, `StandardHalfLifeDataSource`, and `EmptyUserProfileDataSource` were removed**, with their tests. ``FileProfileDataSource`` returns the same standard values when nothing is stored, and its tests carry their requirements, BEDSRC-1 and HALF-1.

## Constitution amendment

The owner approved amending Article V.3.1 on 2026-09-12, so that a Health request the user starts from onboarding's permissions step counts as the moment the feature needs it. The amendment is recorded in the constitution's table.

## Risks the owner accepted

The owner chose on 2026-09-12 to request notifications and Face ID in onboarding, before any feature uses them. The AI recommended against it. The risks:

- **Nothing uses them yet.** Until the cutoff notification (rank 19) and the biometric lock (rank 27) are built, allowing either does nothing. Asking for access an app doesn't use goes against Apple's guidance to request permission only when a feature needs it, which App Review can enforce.
- **The purpose string promises a lock that doesn't exist.** The Face ID purpose string says "Half-Life uses Face ID to unlock the app", and there's no lock until rank 27. That's also a question for the brief's *Honesty* criterion.
- **The rows' copy has to be true either way.** A line such as "For cutoff reminders" describes a feature the build may never ship if time runs out before rank 19.
- **Article III.1** asks for no speculative features. A permission request with nothing behind it is close to one.

Adding each row when its feature ships avoids all four. The rows are designed to be independent, so that change stays small.

## UI tests

The UI tests launch the real app. Today, a fresh launch shows the Today screen. After onboarding, it shows onboarding, so the existing tests need a way past it.

- **A launch environment sets the starting state.** The key `HALF_LIFE_UI_TEST_PROFILE`, set to `completed` or `fresh`, makes the app keep the profile in a new temporary file, seeded accordingly, start with an empty drink log that lives only in memory, and simulate every permission (``UITestLaunchConfiguration``, and the simulated data sources in `App/UITesting/`). The key and its values live in `LaunchEnvironmentKey.swift`, which belongs to both targets, as the accessibility identifiers do (Article II.7). Previews use a temporary file too, seeded as having finished onboarding.
- **Every UI test launches through a helper.** `launchPastOnboarding()` and `launchAtOnboarding()`, in `Robot.swift`, set the key and launch. The existing tests launch past onboarding, so they still open on the Today screen.
- **System prompts aren't tested.** A UI test can't reliably answer Health's sheet, the notification alert, or the Face ID prompt, and the simulator's Face ID enrollment can't be set from a test. The fake permission data sources answer instead, and the real prompts are a manual check on a device.
- **Each step has a robot:** `WelcomeRobot`, `AboutYouRobot`, `HalfLifeFactorsRobot`, `BedtimeRobot`, `PermissionsRobot`, and `OnboardingSummaryRobot`, each in its own file, listed in `Robots.all`, and with an accessibility audit. `OnboardingUITests` drives them.
- **Each screen's scroll view has a `content` identifier**, which its robot swipes in `verifyScrollsOnlyVertically()`. The swipe starts in the right margin, where it can't press a full-width button such as Get started at the largest text sizes. Only labeled elements count, because iOS's own decorations, such as the dimming under the navigation bar, are wider than the screen.

## Testable requirements

Each requirement is written so that one test can prove it.

### Rules

| ID | Requirement |
|----|-------------|
| PRIOR-1 | With no factors, the starting half-life is ``CaffeineHalfLife/standard`` (5.5 hours). |
| PRIOR-2 | Each factor alone gives the starting half-life in the "HalfLifePriorRule" table. |
| PRIOR-3 | When pregnancy and estrogen are both chosen, only the larger multiplier applies. The other factors multiply. |
| PRIOR-4 | The result is never below 3 hours or above 40 hours. |
| SLEEPNEED-1 | Each age range gets its recommended sleep range: 13–17 is 8–10 hours, 18–64 is 7–9 hours, and 65 and over is 7–8 hours. Each boundary age belongs to the range it starts. |
| SLEEPNEED-2 | With no birth year, it's the adult range. |
| SLEEPNEED-3 | The age is the current year in the given calendar minus the birth year, so it follows the calendar's time zone at New Year. |

### Repositories and data sources

| ID | Requirement |
|----|-------------|
| PROF-3 | The profile stream publishes the current profile first, then every change, and doesn't finish. |
| PROF-4 | Saving the factors stores them and stores the half-life `HalfLifePriorRule` gives. |
| PROF-5 | Saving the name and age stores the name and the birth year the age implies. |
| PROF-6 | Saving the bedtime stores it, keeping the rest of the profile. |
| PROF-7 | Completing onboarding stores the completion, and the profile stream publishes it. |
| PROFFILE-1 | The file is written with `NSFileProtectionComplete`. |
| PROFFILE-2 | With no file, it returns no profile, ``Bedtime/standard``, and ``CaffeineHalfLife/standard``. |
| PROFFILE-3 | After a successful write, it signals every subscriber. After a failed one, it signals nothing and throws. |
| PROFFILE-4 | A stored profile reads back from a new instance on the same file, with every field and every factor. A damaged file throws rather than reading as nothing. |
| REPO-11 | When the half-life data source signals a change, ``CaffeineDecayRepository`` publishes a recalculated curve and status with the new half-life. |
| REPO-12 | When the bedtime data source signals a change, it publishes a recalculated status with the new bedtime. |
| LAUNCH-1 | With no launch environment key, the app isn't under a UI test. The key's two values choose a fresh or a completed profile, and any other value is ignored. |
| LAUNCH-2 | A UI test's completed profile has finished onboarding, a fresh one has nothing saved, and previews start past onboarding. |
| LAUNCH-3 | Under a UI test, with either profile, the drink log is an empty store that lives only in memory. So every UI test starts from the same log, and none writes to the simulator's own drinks. The owner chose this on 2026-09-12, after the drinks that UI tests left behind made the Today screen's audits flaky. |
| PERM-1 | The permissions stream publishes the current statuses first, then each change after a request or a refresh. |
| PERM-2 | Health is `notRequested` until its request has been made, and `requested` after, whatever the user chose. |
| PERM-3 | The Health request asks to read exactly sleep analysis, step count, and resting heart rate, and to write nothing. |
| PERM-4 | Face ID is `notRequested` until it's been requested, even though iOS reports it as available. |

### Features

Each is tested with an exhaustive `TestStore`, with its use cases overridden.

| ID | Requirement |
|----|-------------|
| ONB-1 | ``AppFeature`` presents onboarding when the profile isn't complete, and dismisses it when the profile says it is. |
| ONB-2 | ``AppFeature`` shows nothing until the first profile arrives. |
| ONB-3 | "Log my first cup" completes onboarding, and the composer opens once onboarding is dismissed. |
| ONB-4 | Continue pushes the next step, in the order in "The flow". |
| ONB-5 | About you and the bedtime step save on Continue. An empty field saves nothing, the fields fill in once from the saved profile unless the user has changed them, and a failed save still continues. |
| ONB-6 | Choosing a factor saves it at once, and the step's state changes only when the repository publishes. Pregnancy asks for its trimester before anything is saved. |
| ONB-7 | Each permission row's action calls its request use case, and the app becoming active calls the refresh. |

### UI

| ID | Requirement |
|----|-------------|
| UI-ONB-1 | A fresh launch shows Welcome, and skipping every step reaches the Today screen. |
| UI-ONB-2 | A name entered in About you appears on the summary and in the Today screen's greeting. |
| UI-ONB-3 | Every step passes the system accessibility audit (Article VI.4). |
| UI-ONB-4 | A launch with a completed profile shows the Today screen, as the existing tests expect. |
| UI-ONB-5 | A factor sets the starting half-life, on its step and on the summary: estrogen gives 8.3 hours, and a third-trimester pregnancy 14.9. |
| UI-ONB-6 | Each permission shows the outcome of asking for it, from the simulated data sources. |
| UI-ONB-7 | "Log my first cup" finishes onboarding and opens the drink composer (ONB-3). |
| UI-ONB-8 | Every onboarding screen scrolls only vertically, at the default and the largest accessibility text size. After a sideways swipe, all of its content still sits within the screen's width. |

## Still to decide

- **Whether a daily ceiling is needed.** The Today total's bar is drawn against something. The FDA's figure for healthy adults is 400 mg a day. For pregnancy, ACOG and EFSA say under 200 mg, and Health Canada says 300 mg. If the bar needs a ceiling, it could come from the factors rather than a new question.
- **The youngest age allowed.** The picker starts at 13, the AI's choice.
- **Answers that go stale.** A pregnancy moves through its trimesters and ends, and a smoker can quit, which lengthens their half-life within about a week (Faber 2004). Settings (rank 21) can revise the answers. The app could also ask again after a while. A due date would keep the trimester current by itself, but it's more sensitive data than the trimester.
- **Which medicines to name.** Only fluvoxamine is named. A general "a medicine that slows caffeine" option would be vaguer, but would cover the moderate inhibitors.
- **The purpose string for reading Health.** It says Half-Life "reads your caffeine", but nothing reads caffeine from Health. Article V.3.2 asks each purpose string to describe the specific use.
- **What the summary says about refinement**, once the estimator (rank 9) decides how much data it needs.

## Sources

An AI research agent read these on 2026-09-12. It read only the abstract, except where a source is marked "full text". The AI didn't read the sources itself, and the owner hasn't reviewed them. Each study is cited by its authors, journal, and year, with a link to its abstract.

### Pregnancy

- Tracy et al., *American Journal of Obstetrics and Gynecology*, 2005. [PMID 15696014](https://europepmc.org/abstract/MED/15696014).
- Knutti et al., *European Journal of Clinical Pharmacology*, 1981. [PMID 7341280](https://europepmc.org/abstract/MED/7341280).
- Parsons and Pelletier, *Canadian Medical Association Journal*, 1982. [PMID 7104915](https://europepmc.org/abstract/MED/7104915).
- Brazier et al., *Developmental Pharmacology and Therapeutics*, 1983. [PMID 6628163](https://europepmc.org/abstract/MED/6628163).

### Estrogen

- Abernethy and Todd, *European Journal of Clinical Pharmacology*, 1985. [PMID 4029248](https://europepmc.org/abstract/MED/4029248).
- Patwardhan et al., *Journal of Laboratory and Clinical Medicine*, 1980. [PMID 7359014](https://europepmc.org/abstract/MED/7359014).
- Balogh et al., *European Journal of Clinical Pharmacology*, 1995. [PMID 7589032](https://europepmc.org/abstract/MED/7589032).
- Pollock et al., *Journal of Clinical Pharmacology*, 1999. [PMID 10471985](https://europepmc.org/abstract/MED/10471985).

### Smoking and nicotine

- Parsons and Neims, *Clinical Pharmacology & Therapeutics*, 1978. [PMID 657717](https://europepmc.org/abstract/MED/657717).
- Faber and Fuhr, *Clinical Pharmacology & Therapeutics*, 2004. [PMID 15289794](https://europepmc.org/abstract/MED/15289794).
- Hukkanen et al., *British Journal of Clinical Pharmacology*, 2011. [PMC3243019](https://pmc.ncbi.nlm.nih.gov/articles/PMC3243019/). Full text.
- van der Plas et al., *Toxicology Reports*, 2020. [PMID 33204648](https://europepmc.org/abstract/MED/33204648). A review by industry authors.

### Liver disease

- Renner et al., *Hepatology*, 1984. [PMID 6420303](https://europepmc.org/abstract/MED/6420303).
- Desmond et al., *Digestive Diseases and Sciences*, 1980. [PMID 7371463](https://europepmc.org/abstract/MED/7371463).

### Medicines

- Jeppesen et al., *Pharmacogenetics*, 1996. [PMID 8807660](https://europepmc.org/abstract/MED/8807660).
- Culm-Merdek et al., *British Journal of Clinical Pharmacology*, 2005. [PMID 16236038](https://europepmc.org/abstract/MED/16236038).
- Harder et al., *American Journal of Medicine*, 1989. [PMID 2589393](https://europepmc.org/abstract/MED/2589393).
- May et al., *Clinical Pharmacology & Therapeutics*, 1982. [PMID 7075114](https://europepmc.org/abstract/MED/7075114).
- U.S. Food and Drug Administration, [examples of drugs that interact with CYP enzymes and transporter systems](https://www.fda.gov/drugs/drug-interactions-labeling/healthcare-professionals-fdas-examples-drugs-interact-cyp-enzymes-and-transporter-systems). Full text.

### Other factors

- Blanchard and Sawers, *Journal of Pharmacokinetics and Biopharmaceutics*, 1983. [PMID 6886969](https://europepmc.org/abstract/MED/6886969).
- George et al., *Clinical and Experimental Pharmacology and Physiology*, 1986. [PMID 3802578](https://europepmc.org/abstract/MED/3802578).
- Abernethy et al., *British Journal of Clinical Pharmacology*, 1985. [PMID 4027137](https://europepmc.org/abstract/MED/4027137).
- Fuhr et al., *British Journal of Clinical Pharmacology*, 1993. [PMID 8485024](https://europepmc.org/abstract/MED/8485024).

### Sleep and caffeine limits

- Hirshkowitz et al., *Sleep Health*, 2015. The National Sleep Foundation's recommendations. [PMID 29073398](https://europepmc.org/abstract/MED/29073398).
- American Academy of Sleep Medicine, [its 2015 statement on adult sleep](https://aasm.org/seven-or-more-hours-of-sleep-per-night-a-health-necessity-for-adults/) (Watson et al., 2015). Full text.
- Paruthi et al., *Journal of Clinical Sleep Medicine*, 2016. The AASM's pediatric recommendations, read from AASM's announcement rather than the article.
- U.S. Food and Drug Administration, ["Spilling the Beans: How Much Caffeine Is Too Much?"](https://www.fda.gov/consumers/consumer-updates/spilling-beans-how-much-caffeine-too-much). Full text.
- ACOG Committee Opinion 462, *Obstetrics & Gynecology*, 2010. [PMID 20664420](https://europepmc.org/abstract/MED/20664420).
- Health Canada, [caffeine in foods](https://www.canada.ca/en/health-canada/services/food-nutrition/food-safety/food-additives/caffeine-foods.html). Full text.
