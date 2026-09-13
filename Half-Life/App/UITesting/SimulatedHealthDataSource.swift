//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life SimulatedHealthDataSource
//

// Simulated Apple Health, for UI tests and previews.
//
// A UI test can't grant Health access or add Health data, so when a UI test launches the app, the Health data
// repository reads these instead of HealthKit. The launch environment chooses what they hold. See the Apple Health
// Card article's "UI tests" section.

import Foundation

/// A kind of Health data a UI test's app can hold, chosen by ``LaunchEnvironmentKey/healthData``.
enum SimulatedHealthData: Sendable, CaseIterable {
    /// Last night's sleep, with stages, and time in bed around it.
    case sleep
    /// Last night's time in bed, with no sleep.
    case inBed
    /// Today's steps.
    case steps
    /// Today's resting heart rate.
    case heartRate

    /// The kind a launch environment value names, or `nil` for a value that names none.
    ///
    /// - Parameter launchValue: One of the comma-separated values of ``LaunchEnvironmentKey/healthData``.
    init?(launchValue: String) {
        switch launchValue {
        case LaunchEnvironmentKey.healthSleep: self = .sleep
        case LaunchEnvironmentKey.healthInBed: self = .inBed
        case LaunchEnvironmentKey.healthSteps: self = .steps
        case LaunchEnvironmentKey.healthHeartRate: self = .heartRate
        default: return nil
        }
    }
}

/// Apple Health as a UI test sets it up: fixed values for the kinds of Health data it holds, and nothing else.
///
/// Last night runs from 11pm to 6am, 7 hours asleep, or 10:30pm to 6:30am in bed. Today's steps are 8,420, and today's
/// resting heart rate is 58 bpm. Nothing changes, so its change stream finishes at once. The Apple Health Card article
/// lists its requirement, SIMHEALTH-1.
struct SimulatedHealthDataSource: SleepDataSource, StepCountDataSource, RestingHeartRateDataSource {
    /// The kinds of Health data it holds.
    let data: Set<SimulatedHealthData>
    /// The current time, which fixes which night is last night.
    let clock: any ClockDataSource
    /// The calendar, and so the time zone, whose clock times the night follows.
    let calendar: Calendar

    /// Creates simulated Health data.
    ///
    /// - Parameters:
    ///   - data: The kinds of Health data it holds.
    ///   - clock: The current time.
    ///   - calendar: The calendar whose clock times the night follows. Defaults to the user's current calendar.
    init(
        holding data: Set<SimulatedHealthData>, clock: any ClockDataSource, calendar: Calendar = .autoupdatingCurrent
    ) {
        self.data = data
        self.clock = clock
        self.calendar = calendar
    }

    /// Returns last night's simulated intervals that overlap `range`.
    ///
    /// - Parameter range: The time to read sleep for.
    func sleepIntervals(in range: DateInterval) -> [SleepStageInterval] {
        let morning = calendar.startOfDay(for: clock.now())
        func at(_ hours: Double) -> Date {
            morning.addingTimeInterval(hours * 3_600)
        }
        var intervals: [SleepStageInterval] = []
        if data.contains(.sleep) || data.contains(.inBed) {
            intervals.append(SleepStageInterval(stage: .inBed, start: at(-1.5), end: at(6.5)))
        }
        if data.contains(.sleep) {
            intervals += [
                SleepStageInterval(stage: .core, start: at(-1), end: at(3)),
                SleepStageInterval(stage: .deep, start: at(3), end: at(4)),
                SleepStageInterval(stage: .rem, start: at(4), end: at(6)),
            ]
        }
        return intervals.filter { $0.end >= range.start && $0.start < range.end }
    }

    /// Returns 8,420 steps for any day, if it holds steps.
    ///
    /// - Parameter day: Any moment in the day to total.
    func stepCount(on day: Date) -> Int? {
        data.contains(.steps) ? 8_420 : nil
    }

    /// Returns 58 bpm for any day, if it holds resting heart rate.
    ///
    /// - Parameter day: Any moment in the day to average.
    func averageRestingHeartRate(on day: Date) -> Double? {
        data.contains(.heartRate) ? 58 : nil
    }

    /// Returns a stream that finishes at once, because the simulated data never changes.
    func changes() -> AsyncStream<Void> {
        AsyncStream { $0.finish() }
    }
}

/// Health access that has always been requested, so the Health data repository reads the simulated Health data at
/// once, under a UI test and in previews.
struct RequestedHealthAccessDataSource: HealthAuthorizationDataSource {
    /// Returns `requested`.
    func status() -> HealthAccessStatus {
        .requested
    }

    /// Does nothing, because access has already been requested.
    func requestAccess() {}
}
