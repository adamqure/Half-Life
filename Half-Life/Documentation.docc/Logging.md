# Logging

How Half-Life writes to Apple's unified log, what it's allowed to record, and how a user sends the log with a bug report.

## Overview

Half-Life logs with `Logger`, from the `os` framework. Developers read the log live in Console.app or Xcode. Users send it to the developer from Settings, attached to a bug report email. Constitution Article XI sets the rules. This article is the reference for applying them.

| Part | Status |
|------|--------|
| The logging convention (subsystem, categories, levels, privacy) | In effect for all new code. No code logs yet. |
| `Logger(for:)`, the helper that applies the convention | Built, in `Half-Life/Logging/Logger+HalfLife.swift`, and tested by `LoggerHalfLifeTests`. ``DrinkComposerFeature`` logs failed saves through it. |
| SwiftLint rules that enforce the convention | In effect (see Enforcement). |
| The log export in Settings, with unsent crash reports attached | Designed, not built. It ships with Settings (roadmap rank 21). |
| The crash-report prompt on the launch after a crash | In the roadmap's Backlog, designed under Crash reports. |

## Subsystem and categories

Every logger uses one subsystem, the app's bundle identifier `com.quillanq.Half-Life`. Its category is the name of the type that owns it. A developer can filter to the whole app by subsystem, or to one type by category, and the category shows where a message came from without searching the source.

Types don't call `Logger(subsystem:category:)` themselves. A single extension applies the convention (a sketch until it's built):

```swift
import OSLog

extension Logger {
    /// Creates a logger in Half-Life's subsystem, categorized by the type that owns it.
    init<Owner>(for owner: Owner.Type) {
        self.init(subsystem: "com.quillanq.Half-Life", category: String(describing: owner))
    }
}
```

Each type that logs keeps one private logger, named `logger`. The SwiftLint rules look for calls on `logger`:

```swift
actor LiveCaffeineDecayRepository: CaffeineDecayRepository {
    private static let logger = Logger(for: LiveCaffeineDecayRepository.self)
}
```

## Where logging happens

| Layer | Logs? | What it logs |
|-------|-------|--------------|
| Presentation: reducers | Yes | Failures that use cases throw, caught in a `.run` effect's `catch:`, plus feature transitions a bug report needs |
| Presentation: views | No | Views send actions, and the reducer logs |
| Domain | No | Domain imports only Swift and Foundation (Article I), and `Foundation` doesn't provide `Logger`. Domain reports failures by throwing, and the code that catches the error logs it. |
| Data: repositories | Yes | State transitions and failures reported by data sources |
| Data: data sources | Yes | Framework failures, with the error's domain and code |

Importing only `Foundation` and calling `Logger` fails with "cannot find 'Logger' in scope". This was checked against the iOS 26.5 SDK on 2026-09-11.

TCA's `._printChanges()` is for local debugging only and is never committed. It prints every `State` change, health values included, through `print` rather than `Logger`.

## Choosing a level

Use the method named for the level. Don't use `log(level:)` or the aliases `trace` (debug), `warning` (error), and `critical` (fault). Five names keep every level easy to search for.

| Level | Use it for | Persisted to disk | In a log export | Half-Life examples |
|-------|------------|-------------------|-----------------|--------------------|
| `debug` | Detail while actively developing a feature | No | No | An observation effect started or finished. The curve was recomputed. |
| `info` | Context that's helpful but not essential | Only when collected with the `log` tool | Only if it's still in memory | A screen appeared. A Health query started. |
| `notice` | Information essential for troubleshooting | Yes, up to a storage limit | Yes | The app launched (version and build). Health access was requested, and the outcome. The intake store opened. A log export started. |
| `error` | A failure the app handled or recovered from | Yes, up to a storage limit | Yes | An intake failed to save. A Health query failed. The store failed to open. |
| `fault` | A bug in Half-Life's own code: a state that should be impossible | Yes, up to a storage limit | Yes | The decay rule returned a curve out of time order. A dose of zero or less reached the repository despite validation. |

The "Persisted to disk" column is Apple's, from *Generating log messages from your code*.

Two rules of thumb:

- If you'd need a message to understand a bug report, log it at `notice` or above. Nothing below `notice` is sure to reach the developer.
- If something happens on every emission, every frame, or every sample, it's `debug`.

An expected condition outside the app, such as denied Health access, no network, or a full disk, is never a `fault`. Log it as `notice` if it's normal, and as `error` if it made an operation fail.

## Privacy and redaction

### Why the defaults aren't enough

By default, `Logger` doesn't redact integers, floating-point numbers, or Booleans, but it does redact dynamic strings and objects. A caffeine amount is a `Double`, so it would be logged unredacted. That's why every interpolated value states its privacy explicitly (Article XI.5).

### What each kind of data gets

| Data | Examples | How it's logged |
|------|----------|-----------------|
| Health values | Caffeine amounts and intake times, sleep, steps, heart rate, and anything derived from them: levels, curves, cutoffs, half-lives, correlations, counts of records | Never, at any level, not even as `.private` (Article V.5, XI.6) |
| Personal data | The user's name, bedtime, and goals, and any text they type | Only when a diagnosis needs it: `.private`, or `.private(mask: .hash)` to match messages about the same value |
| Record identifiers | An intake's `id` | `.private(mask: .hash)` |
| Errors | Any `Error` | Domain and code `.public`, description `.private`, because descriptions can contain user data |
| Diagnostic state | App version and build, OS version, non-health enum states (which screen, the Health authorization outcome, the export result) | `.public` |

The Health authorization outcome is logged `.public`. It says whether the user granted access, not anything about their health, and it's the first thing a "my Health data is missing" report needs.

### Timing is health data too

Every log entry has a timestamp. A message about a routine health event reveals when the event happened, even with no value in it: "Intake saved" at 4:02pm records that the user had caffeine at 4:02pm. So successful routine health events, such as an intake saved or Health samples read, are logged at `debug` at most. `debug` is never stored or exported. Failures are still logged at `error`, without values, because a bug report can't be diagnosed without them.

### Examples

```swift
// ✗ The amount is a health value, and a Double is unredacted by default.
logger.notice("Saved an intake of \(intake.milligrams) mg")

// ✗ No value, but the entry's timestamp records when the user drank.
logger.notice("Saved intake \(intake.id, privacy: .private(mask: .hash))")

// ✓ A failure, with no health value, and explicit privacy on every value.
let nsError = error as NSError
logger.error(
    """
    Saving an intake failed: \(nsError.domain, privacy: .public) \(nsError.code, privacy: .public), \
    \(nsError.localizedDescription, privacy: .private)
    """
)
```

### When redaction happens, and when it doesn't

The system redacts private values, and they appear as `<private>`. There's one exception. When Xcode launches the app, the system shows that process's own log unredacted, because the developer could attach a debugger to it. That applies to Xcode's console, Console.app, and the app's own log export. So:

- Seeing private values in Xcode's console doesn't mean redaction is broken, and seeing them there doesn't show that redaction works either.
- A log export from a build launched by Xcode contains private values in the clear. TestFlight and App Store builds are redacted. Apple DTS confirmed this on the developer forums, and a TestFlight export must be checked by hand once (see Manual checks).

## Enforcement

SwiftLint custom rules in `.swiftlint.yml` enforce the parts of Article XI that can be checked mechanically. They apply to the app target only, skip comments, and fail `swiftlint lint --strict`.

| Rule | Rejects | Article |
|------|---------|---------|
| `logging_forbidden_call` | `print`, `debugPrint`, `dump`, `NSLog`, and `os_log` | XI.1 |
| `logging_print_changes` | `._printChanges()` | XI.1 |
| `logging_level_alias` | `logger.log`, `logger.trace`, `logger.warning`, and `logger.critical` | XI.4 |
| `logging_explicit_privacy` | An interpolated value in a `logger.debug`/`info`/`notice`/`error`/`fault` message with no `privacy:` | XI.5 |

The rules are regular expressions, not a parser, so they have limits:

- They only see calls on a property named `logger`.
- `logging_explicit_privacy` checks a message written as a string literal, on the call's line or the next one, or as a `"""` multi-line literal. It allows one level of parentheses inside an interpolation, as in `String(describing:)`.
- No rule can tell a health value from any other value. Code review enforces Article XI.6–7.

## Reading logs during development

- **Console.app:** select the device or simulator, start streaming, and search `subsystem:com.quillanq.Half-Life`. Add a `category:` term to narrow to one type. The Action menu includes info and debug messages, which are hidden by default.
- **Xcode's console** filters the same fields and shows each entry's level.
- **Terminal, for the simulator:**

```sh
xcrun simctl spawn booted log stream --level debug \
  --predicate 'subsystem == "com.quillanq.Half-Life"'
```

## Sending logs with a bug report

Designed, not built. This section is the requirement for the Settings feature (roadmap rank 21).

### What the user sees

1. In Settings, the user taps **Send logs**. If the device has no Mail account, the button is disabled, and text next to it explains that sending logs needs an email account set up in the Mail app. The explanation is visible text, not only a dimmed button (Article VI.3).
2. The app gathers this launch's log into a file and opens a Mail draft addressed to the developer, `adamqure@icloud.com`, with the file attached, along with any crash reports that haven't been sent yet (see Crash reports). The subject names the app. The body has the app version and build, the iOS version, and the device model, followed by a prompt asking the user to describe what went wrong. All of this text is localized (Article VII).
3. The user writes the report and taps Send, or cancels. They can see the attachment in the draft, and can remove it.
4. When the draft closes, crash reports are deleted only if it was sent. If it was saved or cancelled, they go with the next send. The log is built in memory for the draft, and the app never writes it to disk.

Nothing leaves the device unless the user taps Send in Mail. The app makes no network request (Article V.1).

### What iOS allows

- **Only the current launch.** An iOS app can open only `OSLogStore(scope: .currentProcessIdentifier)`. It returns this process's entries, and never those from earlier launches. If the app crashed, the log from that launch is gone. The flow's copy asks the user to reproduce the problem and send the log before closing the app. MetricKit crash reports cover crashes (see Crash reports).
- **Info and debug may be missing.** Debug messages aren't stored, and info messages are only in memory. The export can include only what the store still holds, which is why anything a bug report needs is logged at `notice` or above.
- **A text file, not a `.logarchive`.** iOS has no API that writes a log archive. `OSLogStore(url:)` only opens an existing archive, and `OSLogStore.local()` and the `.system` scope are macOS-only. This was checked in the iOS 26.5 SDK's `OSLog` headers. The export is a plain-text `.log` file that Console.app opens (File ▸ Open) and any text editor can read.

### File format

A header, then one line per entry in time order, tab-separated:

```
# Half-Life log export
# App: 1.0 (42)
# OS: iOS 26.5
# Device: iPhone18,1
# Exported: 2026-09-18T15:04:05.120-04:00
2026-09-18T14:58:10.004-04:00	notice	Half_LifeApp	Launched
2026-09-18T15:01:22.731-04:00	error	LiveCaffeineDecayRepository	Saving an intake failed: NSCocoaErrorDomain 640, <private>
```

Timestamps are ISO 8601, with milliseconds and the device's UTC offset, so they line up with the local time in the user's report. The file is named `Half-Life-log-<export time>.log`.

### Components

The bug report follows Article I like any other feature. The Mail composer is MessageUI, a system framework, so only a data source touches it (Article I.14). The composer is also system UI, so that data source presents it over the app's frontmost view controller, rather than through Settings' `@Presents` state (Article I.6).

```
 Status:   BugReportRepository ─▶ ObserveBugReportStatusUseCase ─▶ .statusUpdated ─▶ SettingsFeature
             (whether Mail can send, and whether a report is being sent)
 Command:  SettingsView ─▶ .sendLogsTapped ─▶ SettingsFeature ─▶ SendBugReportUseCase
             ─▶ CrashReportRepository (reads the unsent crash reports)
             ─▶ BugReportRepository ─▶ OSLogEntryDataSource (reads OSLogStore)
                                    ─▶ MessageUIMailDataSource (presents the composer, waits for it to close)
             ─▶ if the draft was sent: CrashReportRepository deletes the reports it carried
 Crash:    MetricKit, on a later launch ─▶ MetricKitCrashReportDataSource ─▶ CrashReportRepository
             ─▶ FileCrashReportDataSource (keeps the report until it's sent)
```

`SendBugReportUseCase` performs one operation: sending a bug report.

1. It reads the unsent crash reports, and asks `BugReportRepository` to send them with this launch's log.
2. The repository formats the log in memory, and builds the draft: the recipient, the localized subject and body, and the attachments.
3. `MessageUIMailDataSource` presents the draft, and returns how it closed. Attachments go to the composer as data (`addAttachmentData(_:mimeType:fileName:)`), so the app writes no temporary file.
4. The repository returns the outcome to the use case.
5. If the outcome is sent, the use case has `CrashReportRepository` delete the reports it passed.

Settings learns everything it shows from `BugReportStatus`, which the repository publishes: whether Mail can send, and whether a report is being sent. `SendBugReportUseCase` returns nothing to the feature (Article I.5). The repository checks whether Mail can send whenever Settings subscribes, which happens each time Settings appears, and again after every send.

| Component | Layer | Responsibility |
|-----------|-------|----------------|
| `DiagnosticLogEntry`, `DiagnosticLogLevel` | Domain entities | One log entry: date, level, category, and message. Domain can't use `OSLog`'s types. |
| `CrashReport` | Domain entity | One unsent crash report: an identifier, when it was received, and MetricKit's JSON |
| `BugReportStatus` | Domain entity | Whether Mail can send, and whether a report is being sent |
| `BugReportOutcome` | Domain entity | How the draft closed: sent, saved, cancelled, or failed |
| `SendBugReportUseCase` | Domain use case | Send a bug report with this launch's log and the unsent crash reports, then delete those reports if the draft was sent |
| `ObserveBugReportStatusUseCase` | Domain use case | Stream `BugReportStatus` |
| `BugReportRepository` | Domain protocol, Data implementation | Owns `BugReportStatus` and publishes it on an `AsyncStream`. Formats the log, builds the draft, and returns the outcome. |
| `CrashReportRepository` | Domain protocol, Data implementation | Owns the unsent crash reports and publishes them on an `AsyncStream`. Deletes the reports it's given. |
| `OSLogEntryDataSource` | Data | The only code that touches `OSLogStore`. Returns this launch's entries in Half-Life's subsystem, plus the device details for the header. |
| `MessageUIMailDataSource` | Data | The only code that touches MessageUI. Reports `MFMailComposeViewController.canSendMail()`, presents the composer with the draft over the app's frontmost view controller, and returns how it closed. |
| `MetricKitCrashReportDataSource` | Data | The only code that touches MetricKit. Subscribes to `MXMetricManager` at launch and passes on each `MXCrashDiagnostic` as JSON. |
| `FileCrashReportDataSource` | Data | Stores unsent crash reports in Application Support with complete file protection, and deletes them |

The names are working names.

### Privacy of the export

- The data source reads only entries whose subsystem is `com.quillanq.Half-Life`. Messages that system frameworks log from inside the app's process are left out.
- Private values arrive as `<private>` in TestFlight and App Store builds. Given Article XI.6–7, the file contains no health values, and no timestamps of routine health events.
- The log attachment exists only in memory until it's handed to the composer. Once the user sends or saves the draft, Mail keeps its own copy, under Mail's protection.
- **Privacy label and manifest (Article V.7).** The owner defines what a bug report sends as diagnostic data, collected for diagnostic purposes only. The change that builds the export adds these to `PrivacyInfo.xcprivacy` and the App Store privacy label:
  - Data types: Crash Data (`NSPrivacyCollectedDataTypeCrashData`) for the MetricKit crash reports, and Other Diagnostic Data (`NSPrivacyCollectedDataTypeOtherDiagnosticData`) for the log.
  - Purpose: App Functionality (`NSPrivacyCollectedDataTypePurposeAppFunctionality`). This is Apple's purpose for data used to "minimize app crashes … or perform customer support". It isn't Analytics, which Apple defines as evaluating user behavior.
  - Tracking: no (`NSPrivacyCollectedDataTypeTracking` is false).
  - Linked to the user: yes (`NSPrivacyCollectedDataTypeLinked` is true). The report arrives from the user's own email address, and Apple treats data as linked unless direct identifiers are stripped before collection.

### Crash reports

The log can't explain a crash, because the log from the launch that crashed is gone. MetricKit fills that gap, and Article V.6 allows it. On iOS 15 and later, the system usually delivers a crash's diagnostic on the app's next launch, as an `MXCrashDiagnostic` inside an `MXDiagnosticPayload`. Delivery isn't guaranteed: developers have reported next-launch crash diagnostics missing on some iOS 17 releases.

- **Captured.** At every launch, `MetricKitCrashReportDataSource` subscribes to `MXMetricManager`. For each `MXCrashDiagnostic` it receives, `CrashReportRepository` stores the diagnostic's `jsonRepresentation()` until it's sent. Other diagnostics, such as hangs and CPU or disk-write exceptions, are ignored. `pastDiagnosticPayloads` isn't used, because the subscriber registers on every launch.
- **Attached.** Every send attaches each unsent crash report as its own attachment, `Half-Life-crash-<received time>.json`, next to the log attachment.
- **Deleted only once sent.** When the draft closes with Mail's `sent` result, the reports it carried are deleted. If the user cancels or saves the draft, or sending fails, the reports stay and go with the next send. `sent` means Mail accepted the message into its outbox, not that it was delivered.
- **Offered after a crash.** This is the roadmap's Backlog item. When a new crash report arrives, the app offers to send it, and one tap opens the same draft. It never sends on its own (Article XI.8).
- **If the device is locked** when MetricKit delivers, the complete-protection write fails and that report is lost. This is accepted rather than weakening the file protection (Article V.4).

A crash report contains:

- the call stack tree: binary names and UUIDs, with unsymbolicated addresses;
- the exception type, code, and signal, and the termination reason;
- virtual-memory details for a bad memory access;
- metadata: app version and build, OS version, device type, architecture, region format, and, on iOS 17 and later, Low Power Mode, TestFlight, and the process ID.

On iOS 17 and later, it can also include an Objective-C exception's composed message, which is why crash messages follow the logging rules (Article XI.6.5). The developer symbolicates the stacks with the build's dSYM.

### Testable requirements

| ID | Component | Requirement |
|----|-----------|-------------|
| EXPORT-1 | `OSLogEntryDataSource` | Returns this process's entries whose subsystem is Half-Life's, and no others. A test logs under Half-Life's subsystem and under another one, then reads both back. |
| EXPORT-2 | `OSLogEntryDataSource` | Maps each `OSLogEntryLog.Level` to a distinct `DiagnosticLogLevel`, and keeps each entry's date, category, and composed message. |
| EXPORT-3 | `BugReportRepository` | Formats the log attachment: the header, then one tab-separated line per entry in time order, in the format above. |
| EXPORT-4 | `BugReportRepository` | Publishes `BugReportStatus` on subscription and after each change: whether Mail can send, and that a report is being sent, from when sending starts until the composer closes (Article I.12). |
| EXPORT-5 | `BugReportRepository` | Hands the Mail data source a draft addressed to `adamqure@icloud.com`, with the localized subject and body, the log attachment, and one `.json` attachment per crash report. |
| EXPORT-6 | `BugReportRepository` | If reading entries or presenting the composer fails, returns failed and logs an `error` with the error's domain and code. |
| EXPORT-7 | `MessageUIMailDataSource` | Reports whether Mail can send from `canSendMail()`, and maps each `MFMailComposeResult` to a `BugReportOutcome`. |
| EXPORT-8 | `SettingsFeature` | Tapping Send logs calls `SendBugReportUseCase` once. While a report is being sent, the button is disabled. |
| EXPORT-9 | `SettingsFeature` | When Mail can't send, the Send logs button is disabled and the explanation is shown. |
| EXPORT-10 | `SettingsRobot` | The Send logs button has an accessibility label and hint, and the Settings screen passes the accessibility audit (Article VI). |
| CRASH-1 | `MetricKitCrashReportDataSource` | Passes on each `MXCrashDiagnostic` in a received payload as JSON, and ignores every other kind of diagnostic. |
| CRASH-2 | `CrashReportRepository` | Stores each crash report it receives, and publishes the unsent reports on subscription and after every change (Article I.12). |
| CRASH-3 | `CrashReportRepository` | Deleting removes exactly the given reports, and publishes the rest. |
| CRASH-4 | `FileCrashReportDataSource` | Writes crash reports with `NSFileProtectionComplete`, keeps them across launches, and deletes them on request. |
| CRASH-5 | `SendBugReportUseCase` | Passes every unsent crash report to `BugReportRepository`. |
| CRASH-6 | `SendBugReportUseCase` | When the outcome is sent, deletes exactly the reports it passed. For any other outcome, deletes none. |

Reducer tests override the use cases, use-case tests use fake repositories, and repository tests use a fake Mail data source. So every path is covered without MessageUI. Presenting the real composer is a manual check. The simulator usually has no Mail account, so UI tests take the unavailable path.

### Manual checks

- With a TestFlight build, send a log export and confirm that private values read `<private>`. This can't be automated, because test runs are launched by Xcode, and Xcode unredacts them.
- On a device with a Mail account, tap Send logs and confirm the draft's recipient, subject, body, and attachments. Cancelling must keep the crash reports, and sending must remove them.

## Open questions

None at the moment.

## Sources

- Apple, [Generating log messages from your code](https://developer.apple.com/documentation/os/generating-log-messages-from-your-code): log levels, persistence, and default redaction.
- Apple Developer Forums, [Using OSLogStore to fetch app logs across restarts](https://developer.apple.com/forums/thread/700321): `.currentProcessIdentifier` returns this process's entries only.
- Apple Developer Forums, [Exporting from OSLogStore doesn't respect privacy](https://developer.apple.com/forums/thread/741284): Xcode unredacts a process it launches, and TestFlight builds are redacted.
- Apple, [MetricKit](https://developer.apple.com/documentation/MetricKit): diagnostic reports arrive immediately (on the next launch) in iOS 15 and later.
- Apple Developer Forums, [Crash and Hang diagnostics not returned on next launch in MetricKit (iOS 17.2 – 17.5)](https://developer.apple.com/forums/thread/806457): next-launch delivery isn't guaranteed.
- Apple, [App privacy details on the App Store](https://developer.apple.com/app-store/app-privacy-details/): the Diagnostics data types, the App Functionality purpose, linked data, and optional disclosure.
- Apple, [NSPrivacyCollectedDataTypes](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacycollecteddatatypes): the privacy-manifest keys.
- The iOS 26.5 SDK's MetricKit headers (`MXMetricManager.h`, `MXCrashDiagnostic.h`, `MXMetaData.h`): what a crash report contains, and when each property became available.
