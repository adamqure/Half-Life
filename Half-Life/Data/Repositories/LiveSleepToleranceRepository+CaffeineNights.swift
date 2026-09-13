//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life LiveSleepToleranceRepository+CaffeineNights
//

import Foundation

/// A caffeine nights subscriber of ``LiveSleepToleranceRepository``: how many nights it follows, its calendar, its
/// stream, and the history it was last sent.
struct SleepToleranceNightSubscriber {
    /// How many nights it follows, the one that followed yesterday last.
    let days: Int
    /// The calendar, and so the time zone, its days, noons, and bedtime are in.
    let calendar: Calendar
    /// Its stream.
    let continuation: AsyncStream<CaffeineNightHistory>.Continuation
    /// The history it was last sent, or `nil` before the first.
    var lastSent: CaffeineNightHistory?
}

/// The caffeine in the user when each night began: the one stream every comparison on the Insights tab reads.
///
/// It's calculated from the same read as the analysis, so the two always agree. See the Insights article, TOLREPO-8 to
/// TOLREPO-11.
extension LiveSleepToleranceRepository {
    /// Streams the caffeine in the user when each of the last `days` nights began.
    ///
    /// A new subscriber immediately receives the current history. After that, it receives a new one whenever the
    /// drinks, the half-life, the bedtime, the chosen sleep, the tolerance, Health access, or a new day changes it.
    ///
    /// - Parameters:
    ///   - days: How many nights, the one that followed yesterday last.
    ///   - calendar: The calendar, and so the time zone, the days, the noons, and the bedtime are in.
    nonisolated func caffeineNights(days: Int, in calendar: Calendar) -> AsyncStream<CaffeineNightHistory> {
        let (stream, continuation) = AsyncStream.makeStream(of: CaffeineNightHistory.self)
        let id = UUID()
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeNightSubscriber(id) }
        }
        let subscriber = SleepToleranceNightSubscriber(days: days, calendar: calendar, continuation: continuation)
        Task { await addNightSubscriber(id, subscriber) }
        return stream
    }

    private func addNightSubscriber(_ id: UUID, _ subscriber: SleepToleranceNightSubscriber) async {
        await start()
        nightSubscribers[id] = subscriber
        await recalculate()
    }

    private func removeNightSubscriber(_ id: UUID) {
        nightSubscribers[id] = nil
    }

    /// Sends each caffeine nights subscriber its history, calculated for its own days in its own calendar, if it
    /// changed.
    func publishNights(from inputs: CaffeineNightRule.Inputs, now: Date) {
        for (id, var subscriber) in nightSubscribers {
            let history = nightRule.history(inputs, days: subscriber.days, now: now, calendar: subscriber.calendar)
            guard history != subscriber.lastSent else { continue }
            subscriber.lastSent = history
            subscriber.continuation.yield(history)
            nightSubscribers[id] = subscriber
        }
    }

    /// The sleep to read: the analysis's range, reaching back far enough for the subscriber that follows the most
    /// nights, so a night before the period still gets its recorded onset.
    func readRange(at now: Date) -> DateInterval? {
        guard let range = rule.range(endingAt: now, calendar: calendar) else { return nil }
        let mostNights = nightSubscribers.values.map(\.days).max() ?? 0
        guard let earliest = calendar.date(byAdding: .day, value: -(mostNights + 1), to: calendar.startOfDay(for: now))
        else { return range }
        return DateInterval(start: min(range.start, earliest), end: range.end)
    }
}
