# Sleep Data

How Half-Life reads the user's sleep from Apple Health.

## Overview

The brief's question is when caffeine lands relative to bedtime, and sleep is the other half of that comparison. Apple Health records sleep as sleep analysis samples. Each one is a stretch of time in one stage, written by a tracker such as Apple Watch, the iPhone's sleep schedule, or another app. HealthKit has no sleep-quality or sleep-score type, so quality has to be derived from the stages.

Half-Life reads the samples as they were recorded, as ``SleepStageInterval`` values. A business rule, not yet built, will turn a night's intervals into a summary of that night, for example time asleep, time in each stage, time awake, and how long it took to fall asleep. The owner chose this split on 2026-09-11. It keeps the data source a thin HealthKit wrapper, and the rule that decides what a night is can be tested without HealthKit.

``HealthKitSleepDataSource``, implementing ``SleepDataSource``, is the only code that reads sleep from HealthKit (constitution Articles I.14 and V.3.5). No repository reads it yet. It's part of the HealthKit read (roadmap rank 7), built ahead of its rank at the owner's request.

## What's read

| | |
|---|---|
| Health type | `HKCategoryType(.sleepAnalysis)` |
| Query | One `HKSampleQueryDescriptor` per call, with no limit |
| Range | Every sample that overlaps the requested `DateInterval`. HealthKit's predicate counts a sample that ends at or after the range's start and starts before its end. |
| Changes | One `HKObserverQuery` for each subscriber to `changes()` |
| Store | `HKHealthStore.halfLife`, the app's one health store |

### SleepStageInterval

| Stage | HealthKit value | Meaning |
|-------|-----------------|---------|
| `inBed` | `.inBed` | In bed, asleep or not |
| `awake` | `.awake` | Awake during a sleep session |
| `asleepUnspecified` | `.asleepUnspecified` | Asleep, from a tracker that doesn't record stages |
| `core` | `.asleepCore` | Core, or light, sleep |
| `deep` | `.asleepDeep` | Deep sleep |
| `rem` | `.asleepREM` | REM sleep |

- **Times are as recorded.** An interval keeps its sample's start and end, even when it starts before the range or ends after it. Clipping is the rule's choice.
- **Nothing is merged.** Trackers overlap. The iPhone can record time in bed while Apple Watch records stages inside it, and two apps can both record the same night. The data source returns every sample, and the rule decides how to merge them.
- **An unknown value is skipped.** A later iOS can add a sleep value. A sample with a value this version doesn't recognize is left out, and the skip is logged, rather than failing the whole read. HealthKit won't create a sample with an unknown value, so the tests check the value mapping, `stage(forValue:)`, directly.

### Changes

`changes()` gives each subscriber its own observer query on sleep analysis. The subscriber gets a signal each time HealthKit reports a change. A signal doesn't say what changed, so the subscriber re-reads what it needs. An error HealthKit reports is logged and signals nothing. When the subscriber stops listening, its observer query stops.

Background delivery isn't enabled, so the app hears about changes only while it runs, even though `Half-Life.entitlements` already has the background delivery entitlement.

### The shared health store

`HKHealthStore.halfLife` is the app's one health store. Apple recommends a single long-lived store per app, and every HealthKit data source uses this one. Creating it reads no Health data.

## Requirements

| ID | Requirement |
|----|-------------|
| SLEEP-1 | `sleepIntervals(in:)` asks HealthKit, in one query with no limit, for every sleep analysis sample that overlaps the range. |
| SLEEP-2 | Each sample becomes a ``SleepStageInterval`` with its stage and the start and end Health recorded, unclipped. No samples give no intervals. |
| SLEEP-3 | Intervals come back in order of start. |
| SLEEP-4 | A value this version doesn't recognize has no stage, and its sample is skipped. |
| SLEEP-5 | A failed query throws HealthKit's error, logged with the error's domain and code only. |
| SLEEP-6 | Each subscriber to `changes()` starts its own observer query on sleep analysis, and gets one signal per change HealthKit reports. |
| SLEEP-7 | An error HealthKit reports to the observer signals nothing, and is logged with the error's domain and code only. |
| SLEEP-8 | When a subscriber stops listening, its observer query stops. |
| STORE-1 | `HKHealthStore.halfLife` is one store for the life of the app. |

`HealthKitSleepDataSourceTests` covers SLEEP-1 to SLEEP-8, and `HKHealthStoreHalfLifeTests` covers STORE-1. Each sleep test replaces HealthKit's sample query and observer query with a stand-in that records what it's asked and answers it, so no test reads real Health data. The queries against the real health store aren't unit-tested, because a test can't grant the test host access to Health. SLEEP-4 is tested on the mapping only, not on a read, and the logging isn't tested.

## Access and missing data

The data source only reads, and never requests authorization. The owner decided on 2026-09-11 that the HealthKit authorization data source is the only one that requests Health access. It's built with onboarding (roadmap rank 6), and it asks in one sheet for every type a feature needs, when the feature needs them (constitution Articles I.6 and V.3.1). Sleep needs read access to sleep analysis. The existing `NSHealthShareUsageDescription` purpose string already mentions sleep.

- **Denied access looks like no sleep.** HealthKit doesn't reveal whether read access was denied: the query just returns no samples. So an empty result never means the user slept badly, or not at all. A feature that shows sleep can say only that Health has none to show, which matters for the brief's honesty criterion.
- **Missing nights are normal.** A night without a tracker has no samples. Intervals say what was recorded, not what happened.
- **HealthKit's other errors are thrown.** For example, HealthKit refuses to read while the device is locked, and on a device without Health. The app works fully without sleep (Article V.3.3).

## Privacy

- **Read, never stored.** Sleep is read from Health when it's needed and held only in memory. It isn't written to the app's store, and it's never synced to iCloud (Article V.3.4).
- **No sleep data in logs.** A failed query logs "Couldn't read sleep", and an observer error logs "Couldn't observe sleep", both at `error` with the error's domain and code as `.public`. A skipped sample logs a fixed message at `error`. Nothing logs a stage, a time, a count of samples, a successful read, or a change signal (Articles XI.6 and XI.7).

## Still to decide

- **The night rule.** The business rule that turns intervals into a night's summary. It decides what counts as a night (for example noon to noon, dated by the morning), how overlapping trackers merge, and which figures describe the night's quality.
- **The repository.** Which repository reads the data source, what range it reads, and how it republishes on `changes()` (constitution Article I.12).
- **Background delivery.** Whether sleep that syncs while the app isn't running should wake it.

## Topics

### Entity

- ``SleepStageInterval``

### Data source

- ``SleepDataSource``
- ``HealthKitSleepDataSource``
