//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life LiveHealthDataRepository+SleepHistory
//

import Foundation

/// A sleep history subscriber of ``LiveHealthDataRepository``: how many days it follows, its calendar, its stream, the
/// last history it was sent, and when that was read.
struct SleepHistorySubscriber {
    /// How many days the subscriber follows, today included.
    let days: Int
    /// The calendar, and so the time zone, whose days and noons define its nights.
    let calendar: Calendar
    /// The subscriber's stream.
    let continuation: AsyncStream<SleepHistory>.Continuation
    /// The last history it was sent, or `nil` before the first.
    var lastSent: SleepHistory?
    /// When the last history was read, which tells when its day has turned.
    var readAt: Date?
}

/// The sleep history for the Insights tab's last 7 days card: the night that followed each day.
///
/// It reads the data sources the summary reads, on the same events, and sends each subscriber a history only when it
/// has changed. While Health access hasn't been requested, every night is empty. See the Insights article, SHREPO-1 to
/// SHREPO-6.
extension LiveHealthDataRepository {
    /// Streams the sleep that followed each of the last `days` days, today last.
    ///
    /// A new subscriber immediately receives the current history. After that, it receives a new history whenever the
    /// chosen data, the switch, Health access, or a new day changes it.
    ///
    /// - Parameters:
    ///   - days: How many days, today included.
    ///   - calendar: The calendar, and so the time zone, whose days and noons define the nights.
    nonisolated func sleepHistory(days: Int, in calendar: Calendar) -> AsyncStream<SleepHistory> {
        let (stream, continuation) = AsyncStream.makeStream(of: SleepHistory.self)
        let id = UUID()
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeSleepHistorySubscriber(id) }
        }
        let subscriber = SleepHistorySubscriber(days: days, calendar: calendar, continuation: continuation)
        Task { await addSleepHistorySubscriber(id, subscriber) }
        return stream
    }

    /// Reads the history at `moment`, or now, for each of the sleep history subscribers `ids`, or for every one, for
    /// its own days in its own calendar, and sends it to each it differs for.
    ///
    /// - Parameters:
    ///   - ids: The subscribers to publish to, or `nil` for every one.
    ///   - moment: The time to read the history at, or `nil` for the clock's current time.
    func publishSleepHistory(to ids: [UUID]?, at moment: Date? = nil) async {
        let now = moment ?? clock.now()
        for id in ids ?? Array(sleepHistorySubscribers.keys) {
            guard let subscriber = sleepHistorySubscribers[id] else { continue }
            let history = await readSleepHistory(days: subscriber.days, at: now, calendar: subscriber.calendar)
            guard var current = sleepHistorySubscribers[id] else { continue }
            current.readAt = now
            if history != current.lastSent {
                current.lastSent = history
                current.continuation.yield(history)
            }
            sleepHistorySubscribers[id] = current
        }
    }

    /// Publishes a new history to each sleep history subscriber whose day has turned by `minute`.
    ///
    /// - Parameter minute: The minute the clock streamed.
    func publishSleepHistoryToTurned(at minute: Date) async {
        let turned = sleepHistorySubscribers.filter { _, subscriber in
            guard let readAt = subscriber.readAt else { return false }
            return !subscriber.calendar.isDate(minute, inSameDayAs: readAt)
        }
        if !turned.isEmpty {
            await publishSleepHistory(to: Array(turned.keys), at: minute)
        }
    }

    private func addSleepHistorySubscriber(_ id: UUID, _ subscriber: SleepHistorySubscriber) async {
        await start()
        sleepHistorySubscribers[id] = subscriber
        await publishSleepHistory(to: [id])
    }

    private func removeSleepHistorySubscriber(_ id: UUID) {
        sleepHistorySubscribers[id] = nil
    }

    /// Reads the sleep for every night in one query, from the chosen data sources, and executes ``SleepHistoryRule``.
    /// With nothing chosen, or sleep that can't be read, every night is empty; the data source has logged any error.
    private func readSleepHistory(days: Int, at now: Date, calendar: Calendar) async -> SleepHistory {
        let rule = SleepHistoryRule()
        let chosen = chosenSources
        var intervals: [SleepStageInterval] = []
        if let sleep = chosen?.sources.sleep, let range = rule.range(endingAt: now, days: days, calendar: calendar),
            let read = try? await sleep.sleepIntervals(in: range)
        {
            intervals = read
        }
        return SleepHistory(
            nights: rule.nights(from: intervals, endingAt: now, days: days, calendar: calendar),
            isDemo: chosen?.isDemo ?? false)
    }
}
