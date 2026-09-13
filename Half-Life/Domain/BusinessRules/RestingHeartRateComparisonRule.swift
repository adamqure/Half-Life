//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life RestingHeartRateComparisonRule
//

import Foundation

/// The business rule behind the Insights tab's resting heart rate screen: the user's resting heart rate on the days
/// after a night that began with caffeine over the sleep threshold, against the other days.
///
/// Each day with a resting heart rate pairs with the night before it, from ``CaffeineNightRule``: its caffeine at the
/// recorded sleep onset, or at the bedtime when Health recorded no sleep, and whether it's a caffeine night. The rule
/// then compares the two groups' averages, and judges the difference
/// against the user's own day-to-day variation, as the owner chose on 2026-09-13:
///
/// - With fewer than ``minimumDays`` days in either group, there aren't enough days to say anything.
/// - The difference is a pattern when it's more than twice its standard error, from each group's sample variance
///   (Welch's), and at least ``minimumDifference``. Otherwise it's no clear difference.
///
/// It never assumes a direction, and never claims a cause. It holds no state and reads no clock.
/// ``ObserveRestingHeartRateComparisonUseCase`` executes it. See the Insights article, RHRCOMP-1 to RHRCOMP-7.
struct RestingHeartRateComparisonRule: Sendable {
    /// The fewest days each group needs before the difference is judged: 5.
    static let minimumDays = 5
    /// The smallest difference that can be a pattern: 1 beat per minute, the precision the screen shows.
    static let minimumDifference: Double = 1
    /// How many standard errors the difference must exceed to be a pattern: 2.
    static let standardErrors: Double = 2

    /// Returns the comparison of `heartRates` against the nights before them.
    ///
    /// - Parameters:
    ///   - heartRates: Each day's resting heart rate.
    ///   - nights: Each night's caffeine, and the threshold.
    ///   - calendar: The calendar, and so the time zone, whose days pair a reading with the night before it.
    /// - Returns: The comparison. Days with no reading, or no night before them, are left out.
    func comparison(
        of heartRates: RestingHeartRateHistory, with nights: CaffeineNightHistory, calendar: Calendar
    ) -> RestingHeartRateComparison {
        let nightsByDay = Dictionary(
            nights.nights.map { (calendar.startOfDay(for: $0.day), $0) },
            uniquingKeysWith: { _, last in last })
        let days = heartRates.days.compactMap { reading -> RestingHeartRateComparison.Day? in
            guard let beatsPerMinute = reading.beatsPerMinute,
                let dayBefore = calendar.date(
                    byAdding: .day, value: -1, to: calendar.startOfDay(for: reading.day)),
                let night = nightsByDay[dayBefore]
            else { return nil }
            return RestingHeartRateComparison.Day(
                day: reading.day, beatsPerMinute: beatsPerMinute,
                followsCaffeine: night.isCaffeineNight, measuredAt: night.measuredAt)
        }
        let after = days.filter(\.followsCaffeine).map(\.beatsPerMinute)
        let other = days.filter { !$0.followsCaffeine }.map(\.beatsPerMinute)
        return RestingHeartRateComparison(
            days: days, threshold: nights.threshold, afterCaffeine: group(after), otherDays: group(other),
            finding: finding(after: after, other: other), isDemo: heartRates.isDemo)
    }

    private func group(_ values: [Double]) -> RestingHeartRateComparison.Group {
        RestingHeartRateComparison.Group(dayCount: values.count, averageBeatsPerMinute: mean(values))
    }

    /// What the two groups show: not enough days, no clear difference, or a pattern.
    private func finding(after: [Double], other: [Double]) -> RestingHeartRateComparison.Finding {
        guard after.count >= Self.minimumDays, other.count >= Self.minimumDays,
            let afterMean = mean(after), let otherMean = mean(other)
        else { return .notEnoughDays }
        let difference = afterMean - otherMean
        let standardError =
            (sampleVariance(after) / Double(after.count)
            + sampleVariance(other) / Double(other.count)).squareRoot()
        guard abs(difference) >= Self.minimumDifference,
            abs(difference) > Self.standardErrors * standardError
        else {
            return .noClearDifference
        }
        return .pattern
    }

    private func mean(_ values: [Double]) -> Double? {
        values.isEmpty ? nil : values.reduce(0, +) / Double(values.count)
    }

    /// The sample variance, dividing by one less than the count. It's 0 for fewer than two values.
    private func sampleVariance(_ values: [Double]) -> Double {
        guard values.count > 1, let mean = mean(values) else { return 0 }
        return values.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(values.count - 1)
    }
}
