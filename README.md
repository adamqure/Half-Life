# Half-Life

An iOS app that tracks caffeine by *when* you drink it, not just *how much*. It draws your caffeine decay curve, shows where your bedtime falls on it, and compares your drinking with sleep, steps, and resting heart rate from Apple Health. It's femmli's case study (`spec.md`, from `spec/brief.pdf`).

It's built with SwiftUI and The Composable Architecture (TCA), in Clean Architecture layers. The rules every change follows are in `constitution.md` and `CLAUDE.md`, and the architecture is documented in the DocC catalog, `Half-Life/Documentation.docc/`.

The app's privacy policy is [`PRIVACY.md`](PRIVACY.md).

## Requirements

| Tool | Version | Notes |
|------|---------|-------|
| macOS | One that runs Xcode 26 | |
| Xcode | 26.5 or later (developed on 26.6) | Includes `swift-format`. The app targets iOS 26.5. |
| iOS 26.5 simulator runtime | | Install it from Xcode ▸ Settings ▸ Components if it's missing. |
| SwiftLint | 0.63 or later | Only for linting. The build doesn't run it. Install it with `brew install swiftlint`. |
| Python 3.9 | `/usr/bin/python3` | Only for `scripts/`. It ships with Xcode's command-line tools. |

Swift packages resolve automatically on the first build. The versions are pinned in `Half-Life.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`. The only direct dependency is `swift-composable-architecture` 1.26.2, and the rest are its Point-Free dependencies.

## Build and run

```sh
git clone https://github.com/adamqure/Half-Life.git
cd Half-Life
open Half-Life.xcodeproj
```

In Xcode, choose the **Half-Life** scheme and an iPhone simulator, then press ⌘R. The first time, Xcode asks you to trust the macros that TCA and its dependencies use. Choose **Trust & Enable** for each.

From the command line:

```sh
xcodebuild build -project Half-Life.xcodeproj -scheme Half-Life -skipMacroValidation \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5'
```

`-skipMacroValidation` does from the command line what **Trust & Enable** does in Xcode. If you don't have an iPhone 17 Pro simulator on iOS 26.5, list the ones you have with `xcrun simctl list devices available` and change the destination to match.

Use the **Half-Life** scheme, the only shared one. It builds the app with its widget extension, and runs both test targets.

### Trying it in the simulator

- **Demo data.** The simulator has no Health data. In the app, open **Settings ▸ Demo data**. There you can add 30 days of demo drinks and turn on demo Health data for sleep, steps, and resting heart rate. Demo drinks are marked "Demo" wherever they appear, and Settings removes them.
- **Apple Intelligence.** The "What we noticed" insight and Siri's "Ask Half-Life" use Apple's on-device language model. They're hidden while it's unavailable. In the simulator, the model is available only if Apple Intelligence is on in the Mac's System Settings.
- **App lock.** To try the Face ID lock, choose Features ▸ Face ID ▸ Enrolled in the Simulator app. Then use Matching Face or Non-matching Face from the same menu when the app asks.
- **Widgets.** Buttons on the widgets don't reliably respond to taps in the simulator. Check widget behavior on a device.

## Signing with a different Apple account

The project is set up for the owner's team (`422Y4K9N6G`), with bundle identifiers under `com.quillanq`.

- **Simulator builds need no changes.** The simulator doesn't need a team or a provisioning profile.
- **A device or TestFlight build needs your own team, and new identifiers.** Bundle identifiers and App Group identifiers are unique across all of Apple's developer accounts. You can't register the `com.quillanq` identifiers in another team, so choose your own prefix, such as `com.example`.

Change the identifiers in every place below. Change them together, because each of them has to match the others.

### 1. The team and bundle identifiers (Xcode project)

In Xcode, select the project, then each target, then **Signing & Capabilities**. Choose your team and enter the bundle identifier. Each target has Debug and Release configurations, and the tab sets both. These build settings live in `Half-Life.xcodeproj/project.pbxproj`.

| Target | Setting | Current value | Example new value |
|--------|---------|---------------|-------------------|
| All four targets, and the project itself | `DEVELOPMENT_TEAM` | `422Y4K9N6G` | Your team ID |
| `Half-Life` (the app) | `PRODUCT_BUNDLE_IDENTIFIER` | `com.quillanq.Half-Life` | `com.example.Half-Life` |
| `Half-LifeWidgets` (the widget extension) | `PRODUCT_BUNDLE_IDENTIFIER` | `com.quillanq.Half-Life.Widgets` | `com.example.Half-Life.Widgets` |
| `Half-LifeTests` (unit tests) | `PRODUCT_BUNDLE_IDENTIFIER` | `com.quillanq.Half-LifeTests` | `com.example.Half-LifeTests` |
| `Half-LifeUITests` (UI tests) | `PRODUCT_BUNDLE_IDENTIFIER` | `com.quillanq.Half-LifeUITests` | `com.example.Half-LifeUITests` |

The widget extension's identifier must start with the app's identifier followed by a dot. Otherwise the app can't embed it.

### 2. The App Group

The app and its widget extension share a file through an App Group, `group.com.quillanq.Half-Life`. The app writes a snapshot of the caffeine forecast there, and the widgets read it. The identifier appears in three places in the app and one in its tests, and all four must match.

| File | What to change |
|------|----------------|
| `Half-Life/Half-Life.entitlements` | The `com.apple.security.application-groups` entry |
| `Half-LifeWidgets/Half-LifeWidgets.entitlements` | The same entry, for the extension |
| `Half-Life/Data/DataSources/FileWidgetSnapshotDataSource.swift` | `appGroupIdentifier`, which the code uses to find the shared container |
| `Half-LifeTests/Data/FileWidgetSnapshotDataSourceTests.swift` | The test that expects that identifier |

You can change the two entitlements in the App Groups section of **Signing & Capabilities**, on both the `Half-Life` and `Half-LifeWidgets` targets. Remove the old group, then add yours. With automatic signing, Xcode registers the new group with your team. Then change the Swift constant and the test to match.

If the entitlements and the Swift constant don't match, the build still succeeds, but the widgets stay empty.

### 3. The capabilities

Automatic signing registers these on your team's App IDs when you choose your team. Nothing in the repository changes.

| Target | Capability | Why |
|--------|------------|-----|
| `Half-Life` | HealthKit, with Background Delivery | Reads sleep, steps, and resting heart rate, and writes caffeine to Apple Health |
| `Half-Life` | App Groups | The widget snapshot |
| `Half-LifeWidgets` | App Groups | The widget snapshot |

A free Personal Team may not support every capability. If Xcode says your team doesn't support one, you'll need a paid Apple Developer Program membership. TestFlight needs one either way.

### 4. The logging subsystem (recommended)

The app logs under the subsystem `com.quillanq.Half-Life`. Constitution Article XI.2 says the subsystem is the app's bundle identifier, so change it to match your new identifier. Signing works without this change, but Console and the in-app log export filter by the subsystem.

| File | What to change |
|------|----------------|
| `Half-Life/Logging/Logger+HalfLife.swift` | The `subsystem:` string |
| `Half-LifeTests/Logging/LoggerHalfLifeTests.swift` | The test that expects it |

### 5. What you can leave alone

- **Widget kinds.** `Half-LifeWidgets/OneTapWidget.swift` and `Half-LifeWidgets/CaffeineLevelWidget.swift` name their widgets `com.quillanq.Half-Life.oneTap` and `com.quillanq.Half-Life.caffeineLevel`. These names only need to be unique within the app, and aren't registered anywhere. Changing one removes that widget from any Home Screen it's on.
- **Documentation.** The DocC articles `Logging`, `Widgets`, and `Architecture` quote the current identifiers. Update them if you keep the new identifiers for good.

### Search for anything missed

This lists every remaining use of the old prefix in the app, the extension, the tests, and the project:

```sh
grep -rn "quillanq\|422Y4K9N6G" Half-Life Half-LifeWidgets Half-LifeTests Half-LifeUITests Half-Life.xcodeproj/project.pbxproj
```

### Running on a device and uploading to TestFlight

1. Connect the iPhone, and turn on Developer Mode in its Settings ▸ Privacy & Security.
2. Choose the device as the run destination in Xcode, and press ⌘R.
3. For TestFlight, create an app in App Store Connect with your new app bundle identifier.
4. Increase the build number, `CURRENT_PROJECT_VERSION` (the **Build** field on the app target's **General** tab), above the last build you uploaded.
5. Choose **Any iOS Device** as the destination, then Product ▸ Archive. In the Organizer, choose **Distribute App ▸ TestFlight & App Store**.

## Tests

The **Half-Life** scheme runs both test targets and measures code coverage for the app target only.

| Target | Framework | What it covers |
|--------|-----------|----------------|
| `Half-LifeTests` | Swift Testing | Reducers (exhaustive `TestStore`), use cases against fake repositories, repositories against fake data sources, business rules, and App Intents |
| `Half-LifeUITests` | XCTest / XCUITest | Every screen, through one robot per screen in `Half-LifeUITests/Robots/`, with an accessibility audit on each |

The tests never touch real Health data, Face ID, or the language model. When a UI test launches the app, it passes launch environment keys (`Half-Life/App/UITesting/LaunchEnvironmentKey.swift`) that swap in a temporary profile, an in-memory drink log, simulated permissions, and simulated Health data. The UI tests run the app in English (`en_US`), whatever the simulator's language.

### In Xcode

Press ⌘U to run all the tests. To run one test or suite, click the diamond beside it in the source, or in the Test navigator (⌘6). To see coverage, open the Report navigator (⌘9), select the test run, and choose **Coverage**.

### From the command line

The full run, with coverage. `xcodebuild` won't write over an existing result bundle, so delete it first.

```sh
rm -rf build/TestResults.xcresult
xcodebuild test -project Half-Life.xcodeproj -scheme Half-Life -skipMacroValidation \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -resultBundlePath build/TestResults.xcresult
```

The coverage report. The `Half-Life` app target must stay at 80% line coverage or more, from a full run of both test targets.

```sh
xcrun xccov view --report --only-targets build/TestResults.xcresult
```

Unit tests only. This is faster, but it doesn't count for the coverage check, because the UI tests cover the views.

```sh
xcodebuild test -project Half-Life.xcodeproj -scheme Half-Life -skipMacroValidation \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -only-testing:Half-LifeTests
```

One UI test class, such as the Today screen's:

```sh
xcodebuild test -project Half-Life.xcodeproj -scheme Half-Life -skipMacroValidation \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -only-testing:Half-LifeUITests/TodayUITests
```

The UI tests run one at a time, and a full run takes a while.

### Tests for the scripts

The scripts in `scripts/` have their own tests, in Python `unittest`:

```sh
/usr/bin/python3 -m unittest discover -s scripts/tests
```

### What the tests can't cover

These need a manual check on a device:

- The widgets, and their buttons. They're covered by unit tests and SwiftUI previews, and checked with Accessibility Inspector (constitution Article I.20).
- Siri's dialogs and snippets.
- The real Face ID and passcode prompts.
- The cutoff reminder notification.
- Reading from and writing to Apple Health.

## Format, lint, and documentation

A change isn't done until all of these are clean.

```sh
# Format, then lint. Both must report nothing.
xcrun swift-format format --in-place --recursive Half-Life Half-LifeTests Half-LifeUITests Half-LifeWidgets
xcrun swift-format lint --strict --recursive Half-Life Half-LifeTests Half-LifeUITests Half-LifeWidgets
swiftlint lint --strict

# Build the DocC documentation. It must produce no warnings.
xcodebuild docbuild -project Half-Life.xcodeproj -scheme Half-Life -skipMacroValidation \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath build/DocBuild
```

To read the documentation in Xcode, choose Product ▸ Build Documentation.

## Repository layout

| Path | Contents |
|------|----------|
| `Half-Life/` | The app: `App/`, `Features/`, `Domain/`, `Data/`, `AppIntents/`, `DesignSystem/`, `Logging/`, the String Catalogs, and the DocC catalog |
| `Half-LifeWidgets/` | The widget extension |
| `Half-LifeTests/` | Unit tests |
| `Half-LifeUITests/` | UI tests and their robots |
| `scripts/` | `export_transcripts.py`, which exports the AI session transcripts, and its tests |
| `spec.md`, `spec/` | The case-study brief and the prototype's screenshots |
| `constitution.md` | The principles every change follows |
| `CLAUDE.md` | Working rules for AI-assisted changes, and the definition of done |
| `roadmap.md` | The order features are built in |
| `ai_log.md`, `ai_transcripts/` | The timestamped log and the full transcripts of every AI interaction |
| `PRIVACY.md` | The app's privacy policy, which App Store Connect and the app's Settings tab link to |
