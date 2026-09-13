# App Lock

Face ID, Touch ID, or the device passcode before the app shows any caffeine or health data.

## Overview

The app lock is roadmap rank 27, "Biometric lock", the last item on the roadmap. The owner asked for it on 2026-09-12, ahead of the roadmap's order.

When the lock is on, Half-Life locks every time it launches and every time it goes to the background. While it's locked, a lock screen takes the place of the tab bar, and it asks for Face ID or Touch ID, with the device passcode as a fallback. While the app isn't active, for example in the app switcher, a cover hides the screen. The lock is off until the user turns it on, in onboarding or in Settings.

### The owner's decisions

The owner answered four questions on 2026-09-12 at 23:10.

| Question | Decision | Rejected |
|----------|----------|----------|
| How the lock is turned on | A control in Settings, and allowing Face ID in onboarding turns it on too | The Settings control alone, which the AI recommended. Allowing Face ID as the only way, with no control. |
| When the app locks | At every launch, and whenever it goes to the background. While the app isn't active, a cover hides the data. | Locking after a grace period in the background. Locking only at launch. |
| What happens when Face ID fails | The device passcode is the fallback, through Local Authentication's device owner policy | Face ID or Touch ID only, which locks the user out after a biometric lockout |
| What the lock hides | Everything after onboarding: every tab, the log button, and the composer | Only the Today tab |

The owner was asked about "a switch in Settings". The control became a selectable option instead, because the owner rebuilt Settings in the app's own style the same evening, after the accessibility audit failed every native switch row in the tab (<doc:Settings>).

### What the brief asks for

- **"On device" and "No accounts infrastructure."** The lock needs neither. Whether it's on is stored on the device and never syncs, so each device has its own lock.
- **"Don't build … settings screens for their own sake."** The lock adds one option to the Settings tab that already exists.
- **Honesty.** The Face ID purpose string, "Half-Life uses Face ID to unlock the app", promised a lock that didn't exist until now (<doc:Onboarding>, "Risks the owner accepted"). Onboarding's Face ID row now says what allowing it does: it locks the app, and the lock can be turned off in Settings.

## Behavior

### Turning the lock on and off

- **The lock turns on only once Face ID is allowed.** Turning it on asks for Face ID first, in the system's prompt, if Half-Life hasn't asked yet. If the user says no, the lock stays off, so no one finds the app locked after declining Face ID (``TurnOnAppLockUseCase``). If Face ID is already allowed, it doesn't ask again.
- **Onboarding's Face ID row turns it on.** Its Allow button runs ``TurnOnAppLockUseCase`` instead of the plain permission request, so there's one prompt, not two. The app stays unlocked for the rest of onboarding.
- **Settings' App lock option turns it on or off.** It's selected while the lock is on. It shows what the repository last published, so it changes once the change is stored (constitution Article I.5). While a change is under way, another tap does nothing. A failed change says so until the next try.
- **Turning it off asks nothing.** Settings is behind the lock, so whoever reaches the option has already unlocked the app.
- **Settings' Face ID permission row stays a permission.** Allowing Face ID there doesn't turn the lock on, because Settings has the lock's own option.

### Locking and unlocking

- **The app starts locked** when the lock is on, so every launch asks.
- **Going to the background locks it.** The root sends the lock when the scene reaches the background. It doesn't lock when the app is only inactive, because the unlock prompt itself makes the app inactive.
- **The lock screen asks by itself** once when the app becomes active while it's showing, and again from its Unlock button. Dismissing the prompt makes the app active again, so it asks by itself only once, until the app has been in the background.
- **Only a passed prompt unlocks.** A cancelled or failed prompt, or one the system dismissed, leaves the app locked.
- **The passcode is the fallback.** After failed scans or a biometric lockout, iOS asks for the device passcode, so the user is never locked out of their own data.
- **A device with no passcode unlocks without asking.** It can't ask for anything, and its data isn't protected by a passcode anyway. This happens only if the passcode was removed after the lock was turned on, because Face ID and Touch ID need a passcode.
- **A setting that can't be read counts as on.** A damaged file never leaves the data unprotected, and the user can still unlock with the passcode and turn the lock off.

### What the lock hides

- **Everything after onboarding.** The lock screen replaces the tab bar, so every tab and the log button are gone while the app is locked. Locking dismisses the drink composer, because its sheet would sit above the lock screen. A drink being composed is discarded.
- **Not onboarding.** The lock screen waits until onboarding is complete. If the lock was turned on at onboarding's permissions step and the app then went to the background, the lock screen shows as soon as onboarding finishes.
- **The app switcher.** While the lock is on and the app isn't active, ``PrivacyCover`` covers the screen and the composer with the app's name, and hides them from VoiceOver. iOS takes the app switcher's snapshot on the way to the background, before the lock screen could replace the content, so the cover follows the scene's phase directly. It's purely visual (constitution Article I.2).
- **Nothing is ever shown before the lock.** The root shows only the splash screen until both the profile and the lock have arrived (<doc:SplashScreen>).

## Presentation

### Features

| Feature | Responsibility | Use cases |
|---------|----------------|-----------|
| ``AppLockFeature`` | The lock screen: asks to unlock by itself once per return, and from its button | ``UnlockAppUseCase`` |
| ``AppFeature`` | Observes the lock, shows the lock screen while the app is locked after onboarding, dismisses the composer, and locks the app when it goes to the background | ``ObserveAppLockUseCase``, ``LockAppUseCase`` |
| ``AppLockSettingsFeature`` | Settings' App lock section: the option that turns the lock on or off, named for the device's Face ID or Touch ID | ``ObserveAppLockUseCase``, ``ObservePermissionsUseCase``, ``TurnOnAppLockUseCase``, ``TurnOffAppLockUseCase`` |
| ``PermissionsFeature`` | Onboarding's Face ID row turns the lock on, through its `turnsOnAppLock` flag, which onboarding sets and Settings doesn't | ``TurnOnAppLockUseCase`` |

### The lock screen

``AppLockView`` is laid out like the Welcome screen: the brand mark, "Half-Life is locked", "Unlock it to see your caffeine and health data.", and an Unlock button at the bottom. It shows no caffeine or health data. It scrolls, so nothing is lost at the largest Dynamic Type sizes (constitution Article VI.2). The mark is decorative and hidden from VoiceOver, and the title is a heading.

The mark is the same image as Welcome's and the splash screen's (<doc:SplashScreen>). It replaced an SF Symbol of a padlock on 2026-09-13, at the owner's request. The title says the app is locked, so the screen doesn't need the padlock to say it.

### Settings' App lock section

``AppLockSettingsSection`` sits between Permissions and Demo data, in Settings' own style: a ``SettingsSection`` with one ``SettingsOption``. The option reads "Lock with Face ID", or Touch ID or Optic ID for the device. It shows that it's on with a check and the selected trait, never by color alone (constitution Article VI.3), and its hint says what tapping it does. The note under it says what the lock does. When Face ID is denied or not set up, the option is disabled while the lock is off, and the note says what to change in the Settings app. On a device with no biometrics, the section is hidden unless the lock is already on, so it can always be turned off.

## Domain

| Type | Kind | Responsibility |
|------|------|----------------|
| ``AppLock`` | Entity | Whether the lock is on, and whether the app is locked now |
| ``AppLockRepository`` | Repository protocol | The source of truth for the lock |
| ``ObserveAppLockUseCase`` | Use case | Streams the lock |
| ``TurnOnAppLockUseCase`` | Use case | Asks for Face ID if it hasn't been asked for, then turns the lock on if it's allowed. It acts on ``PermissionsRepository`` and ``AppLockRepository``. |
| ``TurnOffAppLockUseCase`` | Use case | Turns the lock off |
| ``LockAppUseCase`` | Use case | Locks the app, if the lock is on |
| ``UnlockAppUseCase`` | Use case | Asks the user to unlock the app |

## Data

| Type | Kind | Responsibility |
|------|------|----------------|
| ``LiveAppLockRepository`` | Repository, an actor | Reads the setting once, starts the app locked if the lock is on, and publishes each change |
| ``FileAppLockSettingDataSource``, implementing ``AppLockSettingDataSource`` | Data source | `AppLock.json` in Application Support, written atomically with `NSFileProtectionComplete` |
| ``LocalAuthenticationDeviceOwnerDataSource``, implementing ``DeviceOwnerAuthenticationDataSource`` | Data source | `LAContext`'s device owner policy: Face ID or Touch ID, then the passcode. It classifies each outcome as ``DeviceOwnerAuthenticationOutcome/passed``, ``DeviceOwnerAuthenticationOutcome/declined``, or ``DeviceOwnerAuthenticationOutcome/unavailable``. |

The existing ``LocalAuthenticationDataSource`` still asks for the Face ID permission, through ``PermissionsRepository``. The lock's data source is separate because it needs the passcode fallback and has to tell a passed prompt from a cancelled one, which the permission request treats alike.

## Privacy and logging

- **One new value is stored:** whether the lock is on, in `AppLock.json` in Application Support, with `NSFileProtectionComplete`. It never syncs. Whether the app is locked lives only in memory.
- **No health data is involved.** The lock reads nothing from Health, and the prompt's outcome isn't stored.
- **Logging (constitution Article XI).** ``LiveAppLockRepository`` logs turning the lock on and off at `notice`, and locking and unlocking at `debug`, because they happen every time the app is used. Failed reads, writes, and prompts are logged at `error` with the error's domain and code only. A device with no passcode is logged at `notice`.

## Accessibility and localization

- The Unlock button has a visible title, and the lock screen's title is a heading.
- Settings' option is a button with a visible title, the selected trait while the lock is on, and a hint.
- The privacy cover hides the covered content from VoiceOver.
- All copy is in `Localizable.xcstrings`. The unlock prompt's reason, "Unlock Half-Life to see your caffeine and health data.", is shown by iOS for Touch ID and when asking for the passcode. Face ID shows the purpose string `NSFaceIDUsageDescription` the first time it's used.

## UI tests

- **Simulated data sources.** A UI test can't answer the Face ID or passcode prompt, so when a UI test launches the app, the repository uses ``InMemoryAppLockSettingDataSource``, which starts off, and ``SimulatedDeviceOwnerDataSource``. The simulated user dismisses the first prompt and passes every one after it. The lock screen's own first prompt is declined, so the test can check the screen and audit it, then unlock it with the button. The real prompts are a manual check on a device.
- **One robot for the lock screen.** `AppLockRobot` drives ``AppLockView``, through `AppLockViewAccessibilityID`. It's listed in `Robots.all`, and every test of it runs its accessibility audit (constitution Article VI.4).
- **The screen's identifier is on its scroll view.** The lock screen is the only child of the root's `appView.screen` container, and with its identifier on the whole screen, SwiftUI merged the two into one element and the lock screen's identifier was lost. UI-LOCK-1 caught it. The Settings screen had the same problem on 2026-09-12 (<doc:Settings>).
- **Settings' option** is driven by `SettingsRobot`'s `switchAppLock()` and `verifyAppLockOn(_:)`, and the app leaves and returns through `leaveAndComeBack()`, beside the launch helpers in `Robot.swift`.

## Risks and limits

- **A quick return may briefly show the app.** The lock is sent when the scene reaches the background, through the repository. If iOS suspends the app before that finishes, it finishes on the way back, and a frame of the Today screen can show before the lock screen. The privacy cover hides the screen until the app is active again.
- **A drink being composed is lost** when the app locks.
- **The lock is per device.** A user with two devices turns it on on each.

## Testable requirements

Each requirement is written so that one test can prove it.

### Domain

| ID | Requirement |
|----|-------------|
| LOCKUSE-1 | ``ObserveAppLockUseCase`` streams the repository's lock. |
| LOCKUSE-2 | Turning the lock on asks for Face ID first when it hasn't been asked for, and turns the lock on only if Face ID is then allowed. Without usable biometrics, it does neither. A failed request throws, and the lock stays off. |
| LOCKUSE-3 | Turning the lock on when Face ID is already allowed doesn't ask again. |
| LOCKUSE-4 | Turning off, locking, and unlocking go to the repository, and its errors pass through. |

### Data

| ID | Requirement |
|----|-------------|
| LOCKSRC-1 | With no file, the lock is off. The setting persists across instances, written atomically with complete protection. An unreadable file or a failed write throws. |
| LOCKSRC-2 | A passed prompt passes. A cancelled or failed prompt, or one the system or the app dismissed, is declined. No passcode is unavailable, and skips the prompt. Other errors throw. |
| LOCKREPO-1 | The stream sends the current lock first, then each change, to every subscriber. The app starts locked when the lock is on. |
| LOCKREPO-2 | A setting that can't be read counts as on. |
| LOCKREPO-3 | Turning the lock on stores it and leaves the app unlocked. Turning it off stores it and unlocks. A failed write throws and changes nothing. |
| LOCKREPO-4 | Locking locks the app only while the lock is on. |
| LOCKREPO-5 | Unlocking asks only while the app is locked. A passed prompt, or no passcode, unlocks. A declined prompt stays locked. A failed prompt throws and stays locked. |
| DEP-LOCK | Each app lock use case holds the one app-scoped app lock repository, and turning on also holds the permissions repository. Each reports an issue in a test that doesn't override it. |
| LOCKSIM-1 | The simulated setting starts off. The simulated user declines the first prompt, then passes. |

### Features

Each is tested with an exhaustive `TestStore`, with its use cases overridden.

| ID | Requirement |
|----|-------------|
| LOCKSCREEN-1 | The lock screen asks by itself once when the app becomes active, and again only after the app has been in the background. |
| LOCKSCREEN-2 | The Unlock button asks. While a prompt is showing, nothing asks again. A failed prompt lets the button ask again. |
| ROOT-LOCK-1 | After onboarding, the lock screen shows while the app is locked, and goes once it unlocks. Showing it dismisses the composer. The lock screen runs inside the root. |
| ROOT-LOCK-2 | The lock screen waits for the profile, and for onboarding to be complete. |
| ROOT-LOCK-3 | Going to the background locks the app. |
| SETLOCK-1 | Settings runs the App lock section, which shows the lock and the biometric permission from their repositories. |
| SETLOCK-2 | The option turns the lock on or off through its use cases, and waits for the repository. |
| SETLOCK-3 | A failed change says so until the next try. A tap while a change is under way does nothing. |
| ONB-LOCK | In onboarding, allowing Face ID turns the lock on. In Settings' Permissions section, it only asks for the permission. |

### UI

| ID | Requirement |
|----|-------------|
| UI-LOCK-1 | Turning the lock on in Settings, leaving the app, and coming back shows the lock screen, which passes the system accessibility audit. Unlocking shows the app again, with the lock still on. |
