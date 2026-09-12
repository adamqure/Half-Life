# Step Count

How Half-Life reads the user's daily step count from Apple Health.

## Overview

The brief asks Half-Life to pull sleep, steps, and other data from Apple Health, and to build a profile of how the user's caffeine habits might be affecting them. Step count is one number per day: the total number of steps Health recorded during that day.

``HealthKitStepCountDataSource``, implementing ``StepCountDataSource``, is the only code that reads step count from HealthKit (constitution Articles I.14 and V.3.5). No repository reads it yet.

## What's read

| | |
|---|---|
| Health type | `HKQuantityType(.stepCount)` |
| Statistic | `.cumulativeSum`, from one `HKStatisticsQueryDescriptor` per day |
| Unit | Steps (`HKUnit.count()`), rounded to the nearest whole step |
| Day | The calendar day that contains the requested date, in the user's current calendar |

### HealthKit's sum, not the samples added up

An iPhone and an Apple Watch both count steps, so the same walk can be recorded twice. HealthKit's statistics queries merge overlapping samples from different sources before summing, so each step counts once. Adding up the raw samples would count those steps twice.

Health can hold a fractional sum, for example from an app that writes partial steps. The data source rounds it to the nearest whole step, as the Health app shows it.

### The day

- **The calendar follows the user.** The default calendar is `Calendar.autoupdatingCurrent`, so a change of time zone moves the day boundaries with it.
- **The whole day counts.** The day runs from its start to the start of the next day, so a 23-hour or 25-hour day at a daylight saving change is covered whole.
- **A sample counts on the day it starts.** The query uses `.strictStartDate`. A sample that spans midnight is counted on the day it started, and never on both days.

### No data isn't zero steps

A day with no step samples in Health returns `nil`, and a sum of zero returns `0`. Reporting `0` for a day with no data would claim the user didn't move when the app only knows it has nothing. The brief grades the app on not overstating what it knows.

## Requirements

| ID | Requirement |
|----|-------------|
| STEPS-1 | `stepCount(on:)` covers the calendar day that contains the date, from its start to the start of the next day, and counts each sample on the day it starts. |
| STEPS-2 | It asks HealthKit for the cumulative sum of step count samples, in one query. |
| STEPS-3 | It returns the sum in steps, rounded to the nearest whole step. A sum of zero is `0`. |
| STEPS-4 | It returns `nil` when Health has no step count for that day. |
| STEPS-5 | A failed query throws HealthKit's error, logged with the error's domain and code only. |

`HealthKitStepCountDataSourceTests` covers STEPS-1 to STEPS-5. Each test replaces the HealthKit query with a stand-in that records the query it's given and answers it, so no test reads real Health data. The query against the real health store isn't unit-tested, because a test can't grant the test host access to Health. STEPS-5's logging isn't tested.

## Access and missing data

The data source only reads, and never requests authorization. The owner decided on 2026-09-11 that no data source for one kind of Health data asks for access. A shared HealthKit authorization data source, built with onboarding, will present one sheet for every type a feature needs, when the feature needs them (constitution Articles I.6 and V.3.1). The existing `NSHealthShareUsageDescription` purpose string already mentions steps.

- **Denied access looks like no data.** HealthKit doesn't reveal whether read access was denied. The query returns no samples, so the data source returns `nil`, just as it does for a day without steps.
- **HealthKit's other errors are thrown.** For example, HealthKit refuses to read while the device is locked, and on a device without Health. The repository that reads this data source decides how to show the missing value. The app works fully without it (Article V.3.3).

## Privacy

- **Read, never stored.** Step count is read from Health when it's needed and held only in memory. It isn't written to the app's store, and it's never synced to iCloud (Article V.3.4).
- **No values in logs.** A failed query logs "Couldn't read step count" at `error`, with the error's domain and code as `.public`. Nothing logs the count, the day, or a successful read (Articles XI.6 and XI.7).

## Manual check

Once the authorization data source exists, compare `stepCount(on:)` for a past day with that day's total in the Health app, on a device that has an iPhone's and an Apple Watch's steps. They should match. A small difference would most likely come from a sample that spans midnight, which this data source counts on the day it starts.

## Topics

### Data source

- ``StepCountDataSource``
- ``HealthKitStepCountDataSource``
