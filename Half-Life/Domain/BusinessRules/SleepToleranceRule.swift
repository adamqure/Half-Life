//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life SleepToleranceRule
//

import Foundation

/// The business rule behind the Insights tab's Sleep screen: each night's sleep against the caffeine at sleep onset,
/// and the user's caffeine tolerance.
///
/// 1. **Nights.** Sleep, and time awake recorded during it, is grouped into sessions as ``SleepNightRule`` groups it.
///    A session with at least 3 hours of sleep, recorded with or without stages, is a night. It runs from its first
///    sleep to its last, and its time asleep counts overlapping trackers once. A night counts when it ended in the
///    period, today and the 29 days before it in the user's calendar, before the current time, and began once drinks
///    had been logged for 2 days, so drinks from before the user started logging don't go missing from its caffeine.
/// 2. **The caffeine at sleep onset** is ``CaffeineDecayRule``'s level at the onset, from the drinks of the week
///    before it.
/// 3. **The time to fall asleep** runs from the start of the time in bed that holds the onset to the onset. Without
///    time in bed around the onset, it's unknown.
/// 4. **The tolerance** is where time asleep starts to drop: a "hockey-stick" fit, in which time asleep holds level up
///    to a caffeine level, then falls in a straight line. Each whole 5 mg from 20 to 80 mg with at least 5 nights on
///    each side is a candidate. The candidate whose fit leaves the least squared error, among those whose line falls,
///    is the tolerance. Caffeine is only allowed to shorten sleep, so with no falling fit, there's no tolerance.
/// 5. **The comparisons** set time asleep, and the time to fall asleep, on the nights at or under the threshold in use
///    against the nights over it, once each side has 5 nights.
///
/// It also gives every recorded night's onset, before the period too, for ``CaffeineNightRule``, so the Sleep screen's
/// night is the only one on the tab. It holds no state and reads no clock. ``SleepToleranceRepository`` executes it.
/// The Insights article lists its requirements, TOL-1 to TOL-11.
struct SleepToleranceRule {
    /// What an analysis is made from.
    struct Inputs: Sendable, Equatable {
        /// The sleep Health or the demo recorded, from any trackers, in any order.
        let intervals: [SleepStageInterval]
        /// Every intake that counts for the sleep, in any order.
        let intakes: [CaffeineIntake]
        /// The half-life and absorption rate the decay model uses.
        let kinetics: CaffeineKinetics
        /// Whether the sleep came from the demo data sources.
        let isDemo: Bool
    }

    /// How many days the period covers, today included: 30.
    static let days = 30
    /// The fewest nights on each side of a threshold for a tolerance or a comparison: 5.
    static let minimumNightsEachSide = 5
    /// The lowest tolerance: 20 mg.
    static let lowestTolerance = 20.0
    /// The highest tolerance: 80 mg.
    static let highestTolerance = 80.0
    /// The distance between candidate tolerances: 5 mg.
    static let toleranceStep = 5.0
    /// How far before the period sleep is read, so a night that started before the period is read whole.
    private static let lookBack: TimeInterval = 24 * 3_600

    private let decayRule = CaffeineDecayRule()

    /// Returns the period the nights must end in: from midnight 29 days before the day `now` falls in, to the midnight
    /// after it. It ends at a midnight, so it's the same all day.
    ///
    /// - Parameters:
    ///   - now: The current time.
    ///   - calendar: The calendar, and so the time zone, whose days the period covers.
    /// - Returns: The period, or `nil` if the calendar can't find its days.
    func period(endingAt now: Date, calendar: Calendar) -> DateInterval? {
        let today = calendar.startOfDay(for: now)
        guard let start = calendar.date(byAdding: .day, value: -(Self.days - 1), to: today),
            let end = calendar.date(byAdding: .day, value: 1, to: today)
        else { return nil }
        return DateInterval(start: start, end: end)
    }

    /// Returns the time to read sleep for: from a day before the period to the current time.
    ///
    /// - Parameters:
    ///   - now: The current time.
    ///   - calendar: The calendar, and so the time zone, whose days the period covers.
    /// - Returns: The range, or `nil` if the calendar can't find the period.
    func range(endingAt now: Date, calendar: Calendar) -> DateInterval? {
        guard let period = period(endingAt: now, calendar: calendar) else { return nil }
        return DateInterval(start: period.start.addingTimeInterval(-Self.lookBack), end: max(now, period.start))
    }

    /// Returns the analysis of the nights in `inputs`.
    ///
    /// - Parameters:
    ///   - inputs: The sleep, the intakes, the kinetics, and whether the sleep is the demo's.
    ///   - now: The current time.
    ///   - calendar: The calendar, and so the time zone, whose days the period covers.
    /// - Returns: The analysis, or `nil` if the calendar can't find the period.
    func analysis(_ inputs: Inputs, now: Date, calendar: Calendar) -> SleepCaffeineAnalysis? {
        guard let period = period(endingAt: now, calendar: calendar) else { return nil }
        let nights = nights(
            from: inputs.intervals, intakes: inputs.intakes, kinetics: inputs.kinetics, now: now, calendar: calendar)
        return analysis(period: period, of: nights, isDemo: inputs.isDemo)
    }

    /// Returns the analysis of nights already measured: the tolerance, and the two comparisons either side of the
    /// threshold in use.
    ///
    /// - Parameters:
    ///   - period: The period the nights ended in.
    ///   - nights: The nights, in order of onset.
    ///   - isDemo: Whether the sleep came from the demo data sources.
    func analysis(period: DateInterval, of nights: [SleepCaffeineNight], isDemo: Bool) -> SleepCaffeineAnalysis {
        let tolerance = tolerance(of: nights)
        let threshold = tolerance.flatMap { SleepThreshold(milligrams: $0.milligrams) } ?? .standard
        let asleep = nights.map { (caffeine: $0.caffeineAtOnset, seconds: $0.asleepSeconds) }
        let fallingAsleep = nights.compactMap { night in
            night.secondsToFallAsleep.map { (caffeine: night.caffeineAtOnset, seconds: $0) }
        }
        return SleepCaffeineAnalysis(
            nights: nights, tolerance: tolerance,
            timeAsleep: Self.comparison(of: asleep, at: threshold.milligrams),
            timeToFallAsleep: Self.comparison(of: fallingAsleep, at: threshold.milligrams), period: period,
            days: Self.days, isDemo: isDemo)
    }

    /// Returns the nights in `intervals` that count, each with its time asleep, its time to fall asleep, and the
    /// caffeine at its onset.
    ///
    /// - Parameters:
    ///   - intervals: The sleep recorded, from any trackers, in any order.
    ///   - intakes: Every intake that counts for the sleep, in any order.
    ///   - kinetics: The half-life and absorption rate the decay model uses.
    ///   - now: The current time. A night counts when it ended before it, in the period.
    ///   - calendar: The calendar, and so the time zone, whose days the period covers.
    /// - Returns: The nights, in order of onset. With no intakes, there are none.
    func nights(
        from intervals: [SleepStageInterval], intakes: [CaffeineIntake], kinetics: CaffeineKinetics, now: Date,
        calendar: Calendar
    ) -> [SleepCaffeineNight] {
        guard let periodStart = period(endingAt: now, calendar: calendar)?.start else { return [] }
        let inBed = SleepNightRule.sessions(of: intervals.filter { $0.stage == .inBed })
        return recordedNights(in: intervals, intakes: intakes, now: now)
            .filter { $0.wake >= periodStart }
            .map { night in
                let weekBefore = night.onset.addingTimeInterval(-HalfLifeEstimationRule.lookback)
                let drinks = intakes.filter { $0.consumedAt <= night.onset && $0.consumedAt > weekBefore }
                return SleepCaffeineNight(
                    sleepOnset: night.onset, asleepSeconds: night.asleepSeconds,
                    secondsToFallAsleep: Self.secondsToFallAsleep(at: night.onset, inBed: inBed),
                    caffeineAtOnset: decayRule.level(at: night.onset, from: drinks, kinetics: kinetics).milligrams)
            }
    }

    /// Returns the sleep onset of every night in `intervals` that ended before `now` and began once drinks had been
    /// logged for 2 days, in the period or before it: the nights ``CaffeineNightRule`` measures at their onset.
    ///
    /// - Parameters:
    ///   - intervals: The sleep recorded, from any trackers, in any order.
    ///   - intakes: Every intake that counts for the sleep, in any order.
    ///   - now: The current time.
    /// - Returns: The onsets, in order. With no intakes, there are none.
    func onsets(from intervals: [SleepStageInterval], intakes: [CaffeineIntake], now: Date) -> [Date] {
        recordedNights(in: intervals, intakes: intakes, now: now).map(\.onset)
    }

    /// A session that makes a night: when its sleep began and ended, and its time asleep.
    private struct RecordedNight {
        let onset: Date
        let wake: Date
        let asleepSeconds: TimeInterval
    }

    /// The sessions in `intervals` with at least 3 hours of sleep that ended before `now`, and began once drinks had
    /// been logged for 2 days, in order of onset.
    private func recordedNights(
        in intervals: [SleepStageInterval], intakes: [CaffeineIntake], now: Date
    ) -> [RecordedNight] {
        guard let firstDrink = intakes.map(\.consumedAt).min() else { return [] }
        let earliestOnset = firstDrink.addingTimeInterval(HalfLifeEstimationRule.warmUp)
        return SleepNightRule.sessions(of: intervals.filter { $0.stage.isAsleep || $0.stage == .awake })
            .compactMap { session -> RecordedNight? in
                let asleep = session.filter(\.stage.isAsleep)
                guard let onset = asleep.map(\.start).min(), let wake = asleep.map(\.end).max(), wake < now,
                    onset >= earliestOnset
                else { return nil }
                let seconds = SleepNightRule.unionLength(of: asleep, within: DateInterval(start: onset, end: wake))
                guard seconds >= SleepNightRule.minimumAsleepSeconds else { return nil }
                return RecordedNight(onset: onset, wake: wake, asleepSeconds: seconds)
            }
            .sorted { $0.onset < $1.onset }
    }

    /// Returns the tolerance the nights show: the candidate from 20 to 80 mg where time asleep starts to drop, or
    /// `nil` when no candidate has 5 nights on each side and a falling fit.
    ///
    /// - Parameter nights: The nights, in any order.
    func tolerance(of nights: [SleepCaffeineNight]) -> SleepTolerance? {
        var best: (tolerance: SleepTolerance, error: Double)?
        for candidate in stride(from: Self.lowestTolerance, through: Self.highestTolerance, by: Self.toleranceStep) {
            let under = nights.filter { $0.caffeineAtOnset <= candidate }.count
            let over = nights.count - under
            guard under >= Self.minimumNightsEachSide, over >= Self.minimumNightsEachSide,
                let fit = Self.fit(nights, from: candidate), fit.slope < 0
            else { continue }
            if let current = best, current.error <= fit.error { continue }
            best = (SleepTolerance(milligrams: candidate, nightsUnder: under, nightsOver: over), fit.error)
        }
        return best?.tolerance
    }

    /// The least-squares fit of time asleep to a line that's level up to `candidate` and slopes after it: its slope,
    /// in seconds per milligram, and its squared error, or `nil` when no night is over the candidate.
    private static func fit(
        _ nights: [SleepCaffeineNight], from candidate: Double
    ) -> (slope: Double, error: Double)? {
        guard !nights.isEmpty else { return nil }
        let excess = nights.map { max(0, $0.caffeineAtOnset - candidate) }
        let asleep = nights.map(\.asleepSeconds)
        let meanExcess = excess.reduce(0, +) / Double(nights.count)
        let meanAsleep = asleep.reduce(0, +) / Double(nights.count)
        var covariance = 0.0
        var variance = 0.0
        for (milligrams, seconds) in zip(excess, asleep) {
            covariance += (milligrams - meanExcess) * (seconds - meanAsleep)
            variance += (milligrams - meanExcess) * (milligrams - meanExcess)
        }
        guard variance > 0 else { return nil }
        let slope = covariance / variance
        let level = meanAsleep - slope * meanExcess
        let error = zip(excess, asleep).reduce(0.0) { total, pair in
            let residual = pair.1 - level - slope * pair.0
            return total + residual * residual
        }
        return (slope, error)
    }

    /// The averages of `values` at or under `threshold` and over it, or `nil` with fewer than 5 on either side.
    private static func comparison(
        of values: [(caffeine: Double, seconds: TimeInterval)], at threshold: Double
    ) -> SleepComparison? {
        let under = values.filter { $0.caffeine <= threshold }.map(\.seconds)
        let over = values.filter { $0.caffeine > threshold }.map(\.seconds)
        guard under.count >= minimumNightsEachSide, over.count >= minimumNightsEachSide else { return nil }
        return SleepComparison(
            underSeconds: under.reduce(0, +) / Double(under.count), overSeconds: over.reduce(0, +) / Double(over.count),
            nightsUnder: under.count, nightsOver: over.count)
    }

    /// The time from the start of the time in bed that holds `onset` to `onset`, or `nil` when none holds it.
    private static func secondsToFallAsleep(
        at onset: Date, inBed sessions: [[SleepStageInterval]]
    ) -> TimeInterval? {
        sessions.lazy.compactMap { session -> TimeInterval? in
            guard let start = session.map(\.start).min(), let end = session.map(\.end).max(), start <= onset,
                onset <= end
            else { return nil }
            return onset.timeIntervalSince(start)
        }
        .first
    }
}
