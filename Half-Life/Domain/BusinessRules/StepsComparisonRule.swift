//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life StepsComparisonRule
//

import Foundation

/// The business rule behind the Insights tab's steps screen: the steps on days after a caffeine night, against the
/// others.
///
/// A day follows a caffeine night when the night that began on the day before it was one, because a caffeine night's
/// cost lands on the next day. Which nights were caffeine nights is decided elsewhere, by the definition every Insights
/// comparison shares, and given to the rule. A day without steps counts on neither side.
///
/// The verdict names a difference only when each side has at least 5 days with steps, and the difference is larger
/// than twice its standard error, from each side's own spread. Otherwise the difference is within the user's
/// day-to-day swing, and could be chance. It never says caffeine caused a difference. It holds no state and reads no
/// clock. ``ObserveStepsComparisonUseCase`` executes it, with the owner's approval. See the Insights article,
/// STEPSRULE-1 to STEPSRULE-6.
struct StepsComparisonRule: Sendable {
    /// How many whole days before today the comparison covers.
    static let dayCount = 30
    /// The fewest days with steps each side needs before the comparison names a difference.
    static let minimumDaysPerGroup = 5
    /// How many standard errors a difference must exceed to be named.
    static let standardErrors: Double = 2

    /// Returns the steps on days after a caffeine night, against the steps on the other days.
    ///
    /// - Parameters:
    ///   - caffeineNightDays: The midnights of the days whose night was a caffeine night.
    ///   - threshold: The sleep threshold the nights were judged against, which the comparison carries.
    ///   - steps: The steps of each day to compare.
    ///   - calendar: The calendar, and so the time zone, whose days the nights and steps follow.
    func comparison(
        caffeineNightDays: Set<Date>, threshold: SleepThreshold, steps: StepHistory, calendar: Calendar
    ) -> StepsComparison {
        let nights = Set(caffeineNightDays.map { calendar.startOfDay(for: $0) })
        let days = steps.days.map { day in
            let dayBefore = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: day.day))
            return StepsComparison.Day(
                day: day.day, steps: day.steps, followsCaffeineNight: dayBefore.map(nights.contains) ?? false)
        }
        let after = days.filter(\.followsCaffeineNight).compactMap(\.steps).map(Double.init)
        let other = days.filter { !$0.followsCaffeineNight }.compactMap(\.steps).map(Double.init)
        return StepsComparison(
            days: days, afterCaffeineNight: Self.group(after), otherDays: Self.group(other),
            verdict: Self.verdict(after: after, other: other), threshold: threshold, isDemo: steps.isDemo)
    }

    /// The group for `steps`, or `nil` when there are none.
    private static func group(_ steps: [Double]) -> StepsComparison.Group? {
        steps.isEmpty ? nil : StepsComparison.Group(averageSteps: mean(steps), dayCount: steps.count)
    }

    /// Names the difference only with enough days, and only beyond twice its standard error.
    private static func verdict(after: [Double], other: [Double]) -> StepsComparison.Verdict {
        guard after.count >= minimumDaysPerGroup, other.count >= minimumDaysPerGroup else { return .tooFewDays }
        let difference = mean(after) - mean(other)
        let standardError = (variance(after) / Double(after.count) + variance(other) / Double(other.count))
            .squareRoot()
        guard abs(difference) > standardErrors * standardError else { return .noClearDifference }
        return difference < 0
            ? .fewerAfterCaffeineNight(steps: -difference) : .moreAfterCaffeineNight(steps: difference)
    }

    private static func mean(_ values: [Double]) -> Double {
        values.reduce(0, +) / Double(values.count)
    }

    /// The sample variance, which needs at least two values.
    private static func variance(_ values: [Double]) -> Double {
        let average = mean(values)
        return values.map { ($0 - average) * ($0 - average) }.reduce(0, +) / Double(values.count - 1)
    }
}
