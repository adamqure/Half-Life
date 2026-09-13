# Splash Screen

What the app shows from the moment it's opened until it knows what to show next.

## Overview

The owner asked for "a reasonable splash screen for this application as everything loads" on 2026-09-13. Before it, a launch showed iOS's blank generated launch screen, then an empty root view. The root waits for two things before it shows anything: the first profile, which decides whether onboarding shows, and the app lock, which decides whether the lock screen shows (<doc:Onboarding>, <doc:AppLock>).

The splash fills that wait in two parts that look the same:

1. **iOS's launch screen**, which iOS draws before any of the app's code runs. It's the page color, `backgroundCanvasTop`, with the brand mark in the middle, declared in `Info.plist` under `UILaunchScreen` (`UIColorName` and `UIImageName`).
2. **``SplashView``**, which ``AppView`` shows over the root while ``AppFeature/State/isLaunching`` is true. It draws the same color, and the same mark at the same size in the same place, so the launch screen hands over to it with no visible change.

When the profile and the app lock have both arrived, the splash fades into the app, onboarding, or the lock screen over 0.25 seconds.

### The AI's decisions

The owner didn't specify the design. The AI made these decisions, and the owner hasn't reviewed them yet.

| Decision | Choice | Rejected |
|----------|--------|----------|
| How long the splash shows | Only as long as the launch takes | A minimum time on screen. The brief judges whether "one-tap logging actually take[s] one tap", and a splash held for show delays every tap. |
| What a quick launch shows | The mark alone. The app's name and a loading indicator fade in only if the launch is still running after 0.6 seconds (``SplashView/detailDelay``). | Showing them at once. On a quick launch, they'd flash up and vanish. |
| What iOS's launch screen shows | The color and the mark, no text | The app's name. A launch screen can't be localized in code, and Apple's guidelines advise against text on it. |
| The mark | One cup's decay curve: a flat line before the drink, the rise, the peak marked with a dot, and the long fall. It's drawn from the one-compartment absorption and elimination curve, the shape the decay model uses (<doc:CaffeineDecayModel>), and echoes the prototype's welcome logo. | An SF Symbol, which the launch screen can't draw. A third-party illustration, which constitution Article III.2 and the owner's preference for first-party work rule out. |

## The brand mark

The mark is `Assets.xcassets/Images/brandMark.imageset/brandMark.svg`, 120 × 60 pt. Onboarding's Welcome screen (<doc:Onboarding>) and the lock screen (<doc:AppLock>) draw it too, at the same size, so a change to the file changes every one of them. The AI wrote it by script: 280 points along the curve for one cup, with an absorption rate of 1.1 per hour and an elimination rate of 0.27 per hour, from two hours before the drink to twelve after. It's decorative, not data: its rates only give it the right shape.

- **Colors.** The curve is `AccentColor`, #B87333, in a 5 pt round stroke. The peak's dot is `textPrimary`, #2E271F, 6 pt in radius, with a 2.5 pt ring in the page color. An SVG can't read color sets, so the values are written into the file. A change to either token must change the file too.
- **Contrast.** The curve measures 3.4:1 against `backgroundCanvasTop`, above the 3:1 that graphics need. The Design System article keeps `AccentColor` to card surfaces because it drops below 3:1 on `backgroundCanvasBottom`, and the splash uses only the top color.
- **Dark mode.** The app is locked to the light appearance (<doc:DesignSystem#Dark-mode>). When dark mode is built, the mark needs a dark variant in its image set, and the launch screen's color set already follows the color token.

## Presentation

``SplashView`` has no store, because it shows nothing that changes. It's not a feature, so it has no reducer (constitution Article I.1). Its one piece of state, whether the name and the indicator have appeared yet, is purely visual (Article I.2).

- **``AppFeature/State/isLaunching``** is true until both the first profile and the app lock have arrived. ``AppView`` shows the splash while it's true, and the tabs or the lock screen once it isn't.
- **The splash sits over the root's container, not in it.** As the only child of the `appView.screen` container, SwiftUI merged the splash into the container, and its own `screen` identifier was lost. The lock screen hit the same problem (<doc:AppLock>). UI-SPLASH-1 caught it.
- **Centering.** A flexible region above the mark and another below share the height equally, so the mark sits in the middle of the whole screen, where iOS's launch screen centers its image, whatever the size of the text below it.
- **Onboarding** is presented over the root as before. On a first launch, onboarding's cover slides up over the splash as it fades.

## Accessibility and localization

- The mark is hidden from VoiceOver, because it's decorative (constitution Article VI.1).
- The name is the existing `Half-Life` key in `Localizable.xcstrings`, marked as a header. The loading indicator is the system's `ProgressView`, which VoiceOver announces as in progress. The splash adds no new strings.
- The name uses `titleLarge`, so it scales with Dynamic Type. At the largest accessibility size it still fits below the mark (UI-SPLASH-2).
- The fades are opacity changes, which suit Reduce Motion.

## UI tests

A normal launch passes the splash too quickly to test. So the launch environment key `HALF_LIFE_UI_TEST_LAUNCH`, set to `held`, holds it: the simulated app lock's setting becomes ``HeldAppLockSettingDataSource``, which never answers, so the app lock never arrives. The profile still arrives, so the root holds on the splash with onboarding complete. `launchHoldingTheSplash()`, in `Robot.swift`, sets the key and launches past onboarding.

`SplashRobot` drives the screen through `SplashViewAccessibilityID` (`screen`, `wordmark`, `progress`). Its `verifyShowsLoading()` waits for the name and the indicator, then waits until three pictures of the name in a row are identical, so the audit that follows reads the name's final color, not a frame of its fade. It watches the name alone, because the indicator never stops turning.

## Testable requirements

### Features

| ID | Requirement |
|----|-------------|
| SPLASH-1 | ``AppFeature`` is launching until both the first profile and the app lock have arrived, in either order. |

### UI test configuration

| ID | Requirement |
|----|-------------|
| LAUNCH-SPLASH | The launch key's `held` value holds the app on its splash screen, and any other value is ignored. Without it, the launch isn't held. |
| LOCKSIM-2 | The held app lock setting never answers. It throws only when its caller is cancelled. |

### UI

| ID | Requirement |
|----|-------------|
| UI-SPLASH-1 | While the app launches, the splash screen names the app and shows that it's loading, and passes the system accessibility audit (Article VI.4). |
| UI-SPLASH-2 | At the largest accessibility text size, the splash screen still names the app, and passes the audit. |

`AppFeatureSplashTests` covers SPLASH-1, `UITestLaunchConfigurationTests` covers LAUNCH-SPLASH, `AppLockDependencyTests` covers LOCKSIM-2, and `SplashUITests` covers UI-SPLASH-1 and UI-SPLASH-2.

## Not tested automatically

- **iOS's launch screen.** No test can see it, because it's gone before a UI test can query anything. That it matches the splash is a manual check: launch the app on a device and watch for a jump or a change of color as the launch screen hands over. iOS caches launch screens, so after changing it, delete the app first.
