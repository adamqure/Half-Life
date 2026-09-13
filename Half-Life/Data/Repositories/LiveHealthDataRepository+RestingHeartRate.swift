//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life LiveHealthDataRepository+RestingHeartRate
//

import Foundation

/// A resting heart rate history subscriber of ``LiveHealthDataRepository``: how many days it follows, its calendar,
/// its stream, the last history it was sent, and when that was read.
struct RestingHeartRateSubscriber {
    /// How many days the subscriber follows, today included.
    let days: Int
    /// The calendar, and so the time zone, whose days are read.
    let calendar: Calendar
    /// The subscriber's stream.
    let continuation: AsyncStream<RestingHeartRateHistory>.Continuation
    /// The last history it was sent, or `nil` before the first.
    var lastSent: RestingHeartRateHistory?
    /// When the last history was read, which tells when its day has turned.
    var readAt: Date?
}

/// The resting heart rate history for the Insights tab's resting heart rate screen: each day's reading.
///
/// It reads the data sources the summary reads, on the same events, and sends each subscriber a history only when it
/// has changed. While Health access hasn't been requested, no day has a reading. See the Insights article, RHRREPO-1 to
/// RHRREPO-6.
extension LiveHealthDataRepository {
    /// Streams the resting heart rate of each of the last `days` days, oldest first, today last.
    ///
    /// A new subscriber immediately receives the current history. After that, it receives a new history whenever the
    /// chosen data, the switch, Health access, or a new day changes it.
    ///
    /// - Parameters:
    ///   - days: How many days, today included.
    ///   - calendar: The calendar, and so the time zone, whose days are read.
    nonisolated func restingHeartRates(days: Int, in calendar: Calendar) -> AsyncStream<RestingHeartRateHistory> {
        let (stream, continuation) = AsyncStream.makeStream(of: RestingHeartRateHistory.self)
        let id = UUID()
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeRestingHeartRateSubscriber(id) }
        }
        let subscriber = RestingHeartRateSubscriber(days: days, calendar: calendar, continuation: continuation)
        Task { await addRestingHeartRateSubscriber(id, subscriber) }
        return stream
    }

    /// Reads the history at `moment`, or now, for each of the subscribers `ids`, or for every one, for its own days in
    /// its own calendar, and sends it to each it differs for.
    ///
    /// - Parameters:
    ///   - ids: The subscribers to publish to, or `nil` for every one.
    ///   - moment: The time to read at, or `nil` for the clock's current time.
    func publishRestingHeartRates(to ids: [UUID]?, at moment: Date? = nil) async {
        let now = moment ?? clock.now()
        for id in ids ?? Array(restingHeartRateSubscribers.keys) {
            guard let subscriber = restingHeartRateSubscribers[id] else { continue }
            let history = await readRestingHeartRates(days: subscriber.days, at: now, calendar: subscriber.calendar)
            guard var current = restingHeartRateSubscribers[id] else { continue }
            current.readAt = now
            if history != current.lastSent {
                current.lastSent = history
                current.continuation.yield(history)
            }
            restingHeartRateSubscribers[id] = current
        }
    }

    /// Publishes a new history to each subscriber whose day has turned by `minute`.
    ///
    /// - Parameter minute: The minute the clock streamed.
    func publishRestingHeartRatesToTurned(at minute: Date) async {
        let turned = restingHeartRateSubscribers.filter { _, subscriber in
            guard let readAt = subscriber.readAt else { return false }
            return !subscriber.calendar.isDate(minute, inSameDayAs: readAt)
        }
        if !turned.isEmpty {
            await publishRestingHeartRates(to: Array(turned.keys), at: minute)
        }
    }

    private func addRestingHeartRateSubscriber(_ id: UUID, _ subscriber: RestingHeartRateSubscriber) async {
        await start()
        restingHeartRateSubscribers[id] = subscriber
        await publishRestingHeartRates(to: [id])
    }

    private func removeRestingHeartRateSubscriber(_ id: UUID) {
        restingHeartRateSubscribers[id] = nil
    }

    /// Reads each day's resting heart rate from the chosen data sources, oldest first. With nothing chosen, no day has
    /// a reading. A read that fails counts as no reading; its data source has logged the error.
    private func readRestingHeartRates(days: Int, at now: Date, calendar: Calendar) async -> RestingHeartRateHistory {
        let chosen = chosenSources
        var readings: [RestingHeartRateDay] = []
        for daysAgo in stride(from: days - 1, through: 0, by: -1) {
            guard let moment = calendar.date(byAdding: .day, value: -daysAgo, to: now) else { continue }
            var beatsPerMinute: Double?
            if let source = chosen?.sources.restingHeartRate {
                // `try?` flattens the data source's optional, so a failed read and a missing value are both `nil`.
                beatsPerMinute = try? await source.averageRestingHeartRate(on: moment)
            }
            readings.append(RestingHeartRateDay(day: calendar.startOfDay(for: moment), beatsPerMinute: beatsPerMinute))
        }
        return RestingHeartRateHistory(days: readings, isDemo: chosen?.isDemo ?? false)
    }
}
