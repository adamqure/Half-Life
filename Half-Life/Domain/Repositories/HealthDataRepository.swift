//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life HealthDataRepository
//

import Foundation

/// The source of truth for the Apple Health data the app shows, and for whether it comes from Health or the demo.
///
/// It reads sleep, steps, and resting heart rate through data sources: Apple Health's, or the demo's while the demo
/// switch is on. It publishes each change (constitution Article I.12). The Apple Health Card article lists its
/// requirements, HREPO-1 to HREPO-8, and the Insights article adds the sleep history's, SHREPO-1 to SHREPO-6, the
/// available kinds', AVREPO-1 to AVREPO-4, and the resting heart rate history's, RHRREPO-1 to RHRREPO-6.
protocol HealthDataRepository: Sendable {
    /// Streams today's Health summary: the current one as soon as it's subscribed to, then each change. It never
    /// finishes.
    ///
    /// - Parameter calendar: The calendar, and so the time zone, whose days and noons define today and last night.
    func summary(in calendar: Calendar) -> AsyncStream<HealthSummary>

    /// Streams whether the demo switch is on: the current answer as soon as it's subscribed to, then each change. It
    /// never finishes.
    func usesDemoData() -> AsyncStream<Bool>

    /// Turns the demo switch on or off. Subscribers get the new answer, and the summary from the chosen data, once it's
    /// stored.
    ///
    /// - Parameter isOn: Whether to show demo Health data in place of Apple Health's.
    /// - Throws: An error if the switch couldn't be stored. Nothing changes then.
    func setUsesDemoData(_ isOn: Bool) async throws

    /// Streams the sleep that followed each of the last `days` days, today last: the current history as soon as it's
    /// subscribed to, then each change. It never finishes.
    ///
    /// It reads the same data sources as the summary, on the same events, and executes ``SleepHistoryRule``. While
    /// Health access hasn't been requested, every night is empty. See the Insights article.
    ///
    /// - Parameters:
    ///   - days: How many days, today included.
    ///   - calendar: The calendar, and so the time zone, whose days and noons define the nights.
    func sleepHistory(days: Int, in calendar: Calendar) -> AsyncStream<SleepHistory>

    /// Streams the kinds of Health data that have any data in the last `days` days: the current set as soon as it's
    /// subscribed to, then each change. It never finishes.
    ///
    /// It reads the same data sources as the summary, on the same events, and executes ``HealthDataAvailabilityRule``.
    /// While Health access hasn't been requested, no kind is available. See the Insights article.
    ///
    /// - Parameters:
    ///   - days: How many days to look back over, today included.
    ///   - calendar: The calendar, and so the time zone, whose days are looked back over.
    func availableKinds(days: Int, in calendar: Calendar) -> AsyncStream<Set<HealthDataKind>>

    /// Streams the resting heart rate of each of the last `days` days, oldest first, today last: the current history as
    /// soon as it's subscribed to, then each change. It never finishes.
    ///
    /// It reads the same data sources as the summary, on the same events. A day with no reading, or one that can't be
    /// read, has none. While Health access hasn't been requested, no day has a reading. See the Insights article.
    ///
    /// - Parameters:
    ///   - days: How many days, today included.
    ///   - calendar: The calendar, and so the time zone, whose days are read.
    func restingHeartRates(days: Int, in calendar: Calendar) -> AsyncStream<RestingHeartRateHistory>

    /// Streams the steps of each of the `days` whole days before today, oldest first, yesterday last: the current
    /// history as soon as it's subscribed to, then each change. It never finishes.
    ///
    /// Today is left out, because its steps are still growing. It reads the same data sources as the summary, on the
    /// same events. A day with no steps, or whose steps can't be read, has none. While Health access hasn't been
    /// requested, no day has steps. See the Insights article, STEPSREPO-1 to STEPSREPO-6.
    ///
    /// - Parameters:
    ///   - days: How many whole days before today.
    ///   - calendar: The calendar, and so the time zone, whose days are read.
    func stepHistory(days: Int, in calendar: Calendar) -> AsyncStream<StepHistory>
}
