//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life DemoHealthScript
//

import Foundation

/// The script behind the demo Health data: 30 nights of sleep, and 30 days of steps and resting heart rate, before
/// today, plus today, to go with the demo drinks.
///
/// Everything is fixed local clock times and values, keyed by how many days before today a day is, so the same day
/// always gives the same data, at the same local times in any time zone. The nights after the drink script's late-cup
/// days start later and have less deep sleep, so the demo has a timing effect to find. The script reads the drinks
/// from ``DemoHistoryRule``, so the two can't drift apart. The night 10 nights ago has time in bed and no sleep.
///
/// It holds no state and reads no clock: the demo data sources pass it the time. It's Data code standing in for Apple
/// Health, never written to Health. The Apple Health Card article lists its requirements, DEMOHEALTH-1 to
/// DEMOHEALTH-6.
struct DemoHealthScript: Sendable {
    /// How many days before today the demo reaches back: 30, the same as the demo drinks.
    static let dayCount = 30
    /// The night that has time in bed and no sleep: the one that ended 10 mornings ago.
    static let inBedOnlyNight = 10
    /// The least caffeine a cup from 3pm on needs to count as a late cup.
    static let lateCupMilligrams: Double = 90
    /// The hour from which a cup counts as a late cup: 3pm.
    static let lateCupHour = 15

    /// Each day's step total, by how many days before today it is, repeating every 10 days.
    private static let stepTotals = [8_420, 6_150, 11_780, 4_310, 9_660, 7_540, 10_420, 5_880, 9_120, 12_030]
    /// Each day's resting heart rate, in beats per minute, by how many days before today it is, repeating weekly.
    private static let restingHeartRates: [Double] = [58, 57, 60, 56, 59, 61, 57]
    /// How much higher the resting heart rate is on the day after a late cup, after its shorter night.
    private static let restingHeartRateAfterLateCup: Double = 3
    /// Each night's bedtime, in minutes after 10:45pm, by how many nights ago it was, repeating weekly.
    private static let bedtimeOffsets = [0, 10, -5, 20, 5, -10, 15]
    /// Each night's wake time, in minutes after 6:40am, by how many nights ago it was, repeating weekly.
    private static let wakeOffsets = [0, 5, -5, 10, 0, 15, -10]

    /// Returns every demo sleep interval that overlaps `range`, in order of start.
    ///
    /// Like HealthKit's predicate, it counts an interval that ends at or after the range's start and starts before its
    /// end.
    ///
    /// - Parameters:
    ///   - range: The time to return sleep for.
    ///   - now: The current time, which fixes which day is today.
    ///   - calendar: The calendar, and so the time zone, whose clock times the script follows.
    func sleepIntervals(in range: DateInterval, now: Date, calendar: Calendar) -> [SleepStageInterval] {
        let today = calendar.startOfDay(for: now)
        let lateDays = lateCupDays(now: now, calendar: calendar)
        var intervals: [SleepStageInterval] = []
        for nightsAgo in 0...Self.dayCount {
            guard let morning = calendar.date(byAdding: .day, value: -nightsAgo, to: today),
                let evening = calendar.date(byAdding: .day, value: -1, to: morning)
            else { continue }
            intervals += night(
                nightsAgo: nightsAgo, evening: evening, morning: morning, afterALateCup: lateDays.contains(evening),
                calendar: calendar)
        }
        return intervals.filter { $0.end >= range.start && $0.start < range.end }.sorted { $0.start < $1.start }
    }

    /// Returns the steps recorded on the day that contains `day`, or `nil` outside the demo's days.
    ///
    /// Today's steps grow with the time of day: none before 7am, then the day's total scaled by how much of the day
    /// from 7am to 10pm has passed.
    ///
    /// - Parameters:
    ///   - day: Any moment in the day to total.
    ///   - now: The current time.
    ///   - calendar: The calendar, and so the time zone, whose days the script follows.
    func stepCount(on day: Date, now: Date, calendar: Calendar) -> Int? {
        guard let daysAgo = daysBeforeToday(day, now: now, calendar: calendar) else { return nil }
        let total = Self.stepTotals[daysAgo % Self.stepTotals.count]
        guard daysAgo == 0 else { return total }
        guard let start = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: now),
            let end = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: now),
            now >= start
        else { return nil }
        let fraction = min(1, now.timeIntervalSince(start) / end.timeIntervalSince(start))
        return Int((Double(total) * fraction).rounded())
    }

    /// Returns the average resting heart rate on the day that contains `day`, or `nil` outside the demo's days.
    ///
    /// Today's appears only from 9am. Each day's is a few beats higher after a late cup the day before.
    ///
    /// - Parameters:
    ///   - day: Any moment in the day to average.
    ///   - now: The current time.
    ///   - calendar: The calendar, and so the time zone, whose days the script follows.
    func restingHeartRate(on day: Date, now: Date, calendar: Calendar) -> Double? {
        guard let daysAgo = daysBeforeToday(day, now: now, calendar: calendar) else { return nil }
        if daysAgo == 0, let nine = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now), now < nine {
            return nil
        }
        let average = Self.restingHeartRates[daysAgo % Self.restingHeartRates.count]
        guard let dayBefore = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: day)) else {
            return average
        }
        let afterALateCup = lateCupDays(now: now, calendar: calendar).contains(dayBefore)
        return afterALateCup ? average + Self.restingHeartRateAfterLateCup : average
    }

    /// Returns the midnights of the days whose demo drinks include a late cup: 90 mg or more, from 3pm on.
    ///
    /// - Parameters:
    ///   - now: The current time, which ``DemoHistoryRule`` ends its drinks at.
    ///   - calendar: The calendar, and so the time zone, whose days and clock times the drinks follow.
    func lateCupDays(now: Date, calendar: Calendar) -> Set<Date> {
        Set(
            DemoHistoryRule().drinks(now: now, calendar: calendar)
                .filter {
                    $0.milligrams >= Self.lateCupMilligrams
                        && calendar.component(.hour, from: $0.consumedAt) >= Self.lateCupHour
                }
                .map { calendar.startOfDay(for: $0.consumedAt) })
    }

    /// How many days before today the day containing `day` is, or `nil` if it's in the future or before the demo.
    private func daysBeforeToday(_ day: Date, now: Date, calendar: Calendar) -> Int? {
        let daysAgo = calendar.dateComponents(
            [.day], from: calendar.startOfDay(for: day), to: calendar.startOfDay(for: now)
        ).day
        guard let daysAgo, (0...Self.dayCount).contains(daysAgo) else { return nil }
        return daysAgo
    }

    /// One night, from the evening before `morning`: time in bed, and sleep stages inside it, except on the in-bed
    /// night. After a late cup, the user goes to bed later and takes longer to fall asleep.
    private func night(
        nightsAgo: Int, evening: Date, morning: Date, afterALateCup: Bool, calendar: Calendar
    ) -> [SleepStageInterval] {
        let bedtimeOffset = Self.bedtimeOffsets[nightsAgo % Self.bedtimeOffsets.count] + (afterALateCup ? 30 : 0)
        let wakeOffset = Self.wakeOffsets[nightsAgo % Self.wakeOffsets.count]
        guard let tenFortyFive = calendar.date(bySettingHour: 22, minute: 45, second: 0, of: evening),
            let sixForty = calendar.date(bySettingHour: 6, minute: 40, second: 0, of: morning)
        else { return [] }
        let bedtime = tenFortyFive.addingTimeInterval(TimeInterval(bedtimeOffset * 60))
        let wake = sixForty.addingTimeInterval(TimeInterval(wakeOffset * 60))
        let inBed = SleepStageInterval(stage: .inBed, start: bedtime, end: wake.addingTimeInterval(10 * 60))
        guard nightsAgo != Self.inBedOnlyNight else { return [inBed] }
        let minutesToFallAsleep = (afterALateCup ? 40 : 12) + (nightsAgo % 3) * 3
        let onset = bedtime.addingTimeInterval(TimeInterval(minutesToFallAsleep * 60))
        return [inBed] + stages(from: onset, to: wake, afterALateCup: afterALateCup)
    }

    /// Sleep stages from `onset` to `wake`, in 90-minute cycles of core, deep, core, and REM sleep. Deep sleep is
    /// longest in the first cycle and fades after it, REM grows through the night, and a short awakening follows the
    /// second cycle. After a late cup, every cycle has less deep sleep.
    private func stages(from onset: Date, to wake: Date, afterALateCup: Bool) -> [SleepStageInterval] {
        var stages: [SleepStageInterval] = []
        var cursor = onset
        func add(_ stage: SleepStageInterval.Stage, minutes: Int) {
            guard minutes > 0, cursor < wake else { return }
            let end = min(cursor.addingTimeInterval(TimeInterval(minutes * 60)), wake)
            stages.append(SleepStageInterval(stage: stage, start: cursor, end: end))
            cursor = end
        }
        var cycle = 0
        while cursor < wake {
            let deep = max(0, (afterALateCup ? 18 : 32) - 9 * cycle)
            let rem = min(10 + 7 * cycle, 40)
            let core = 90 - deep - rem
            add(.core, minutes: core / 2)
            add(.deep, minutes: deep)
            add(.core, minutes: core - core / 2)
            add(.rem, minutes: rem)
            if cycle == 1 {
                add(.awake, minutes: 5)
            }
            cycle += 1
        }
        return stages
    }
}
