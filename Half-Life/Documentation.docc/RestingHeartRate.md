# Resting Heart Rate

How Half-Life reads the user's resting heart rate from Apple Health.

## Overview

The brief asks Half-Life to show how caffeine habits might be affecting sleep and heart rate. Resting heart rate is the heart-rate signal the app reads: one number per day, the average of the resting heart rate samples Health recorded during that day. Apple Watch usually records one resting heart rate a day. Averaging also gives one number for a day with several samples, for example from a second device or app.

``HealthKitRestingHeartRateDataSource``, implementing ``RestingHeartRateDataSource``, is the only code that reads resting heart rate from HealthKit (constitution Articles I.14 and V.3.5). No repository reads it yet.

## What's read

| | |
|---|---|
| Health type | `HKQuantityType(.restingHeartRate)` |
| Statistic | `.discreteAverage`, from one `HKStatisticsQueryDescriptor` per day |
| Unit | Beats per minute, whatever unit HealthKit returns the average in |
| Day | The calendar day that contains the requested date, in the user's current calendar |

### The day

- **The calendar follows the user.** The default calendar is `Calendar.autoupdatingCurrent`, so a change of time zone moves the day boundaries with it.
- **The whole day counts.** The day runs from its start to the start of the next day, so a 23-hour or 25-hour day at a daylight saving change is covered whole.
- **A sample counts on the day it starts.** The query uses `.strictStartDate`. A sample that spans midnight is counted on the day it started, and never on both days.

## Requirements

| ID | Requirement |
|----|-------------|
| RHR-1 | `averageRestingHeartRate(on:)` covers the calendar day that contains the date, from its start to the start of the next day, and counts each sample on the day it starts. |
| RHR-2 | It asks HealthKit for the discrete average of resting heart rate samples, in one query. |
| RHR-3 | It returns the average in beats per minute. |
| RHR-4 | It returns `nil` when Health has no resting heart rate for that day. |
| RHR-5 | A failed query throws HealthKit's error, logged with the error's domain and code only. |

`HealthKitRestingHeartRateDataSourceTests` covers RHR-1 to RHR-5. Each test replaces the HealthKit query with a stand-in that records the query it's given and answers it, so no test reads real Health data. The query against the real health store isn't unit-tested, because a test can't grant the test host access to Health. RHR-5's logging isn't tested.

## Access and missing data

The data source only reads, and never requests authorization. The owner decided on 2026-09-11 that no data source for one kind of Health data asks for access. The shared ``HealthKitAuthorizationDataSource``, built with onboarding (<doc:Onboarding>), presents one sheet for every type a feature needs, when the feature needs them (constitution Articles I.6 and V.3.1). The existing `NSHealthShareUsageDescription` purpose string already mentions heart rate.

- **Denied access looks like no data.** HealthKit doesn't reveal whether read access was denied. The query returns no samples, so the data source returns `nil`, just as it does for a day without a reading.
- **HealthKit's other errors are thrown.** For example, HealthKit refuses to read while the device is locked, and on a device without Health. The repository that reads this data source decides how to show the missing value. The app works fully without it (Article V.3.3).

## Privacy

- **Read, never stored.** Resting heart rate is read from Health when it's needed and held only in memory. It isn't written to the app's store, and it's never synced to iCloud (Article V.3.4).
- **No values in logs.** A failed query logs "Couldn't read resting heart rate" at `error`, with the error's domain and code as `.public`. Nothing logs the value, the day, or a successful read (Articles XI.6 and XI.7).

## Topics

### Data source

- ``RestingHeartRateDataSource``
- ``HealthKitRestingHeartRateDataSource``
