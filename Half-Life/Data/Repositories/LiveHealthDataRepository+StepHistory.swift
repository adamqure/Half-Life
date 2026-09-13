//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life LiveHealthDataRepository+StepHistory
//

import Foundation

/// A step history subscriber of ``LiveHealthDataRepository``: how many days it follows, its calendar, its stream, the
/// last history it was sent, and when that was read.
struct StepHistorySubscriber {
    /// How many whole days before today the subscriber follows.
    let days: Int
    /// The calendar, and so the time zone, whose days are read.
    let calendar: Calendar
    /// The subscriber's stream.
    let continuation: AsyncStream<StepHistory>.Continuation
    /// The last history it was sent, or `nil` before the first.
    var lastSent: StepHistory?
    /// When the last history was read, which tells when its day has turned.
    var readAt: Date?
}

/// The step history for the Insights tab's steps screen: the steps of each whole day before today.
///
/// It reads the data sources the summary reads, on the same events, and sends each subscriber a history only when it
/// has changed. While Health access hasn't been requested, no day has steps. Steps are health data, so none are
/// logged (constitution Article XI.6). See the Insights article, STEPSREPO-1 to STEPSREPO-6.
extension LiveHealthDataRepository {
    /// Streams the steps of each of the `days` whole days before today, oldest first.
    ///
    /// A new subscriber immediately receives the current history. After that, it receives a new history whenever the
    /// chosen data, the switch, Health access, or a new day changes it.
    ///
    /// - Parameters:
    ///   - days: How many whole days before today.
    ///   - calendar: The calendar, and so the time zone, whose days are read.
    nonisolated func stepHistory(days: Int, in calendar: Calendar) -> AsyncStream<StepHistory> {
        let (stream, continuation) = AsyncStream.makeStream(of: StepHistory.self)
        let id = UUID()
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeStepHistorySubscriber(id) }
        }
        let subscriber = StepHistorySubscriber(days: days, calendar: calendar, continuation: continuation)
        Task { await addStepHistorySubscriber(id, subscriber) }
        return stream
    }

    /// Reads the history at `moment`, or now, for each of the step history subscribers `ids`, or for every one, for its
    /// own days in its own calendar, and sends it to each it differs for.
    ///
    /// - Parameters:
    ///   - ids: The subscribers to publish to, or `nil` for every one.
    ///   - moment: The time to read the history at, or `nil` for the clock's current time.
    func publishStepHistory(to ids: [UUID]?, at moment: Date? = nil) async {
        let now = moment ?? clock.now()
        for id in ids ?? Array(stepHistorySubscribers.keys) {
            guard let subscriber = stepHistorySubscribers[id] else { continue }
            let history = await readStepHistory(days: subscriber.days, at: now, calendar: subscriber.calendar)
            guard var current = stepHistorySubscribers[id] else { continue }
            current.readAt = now
            if history != current.lastSent {
                current.lastSent = history
                current.continuation.yield(history)
            }
            stepHistorySubscribers[id] = current
        }
    }

    /// Publishes a new history to each step history subscriber whose day has turned by `minute`.
    ///
    /// - Parameter minute: The minute the clock streamed.
    func publishStepHistoryToTurned(at minute: Date) async {
        let turned = stepHistorySubscribers.filter { _, subscriber in
            guard let readAt = subscriber.readAt else { return false }
            return !subscriber.calendar.isDate(minute, inSameDayAs: readAt)
        }
        if !turned.isEmpty {
            await publishStepHistory(to: Array(turned.keys), at: minute)
        }
    }

    private func addStepHistorySubscriber(_ id: UUID, _ subscriber: StepHistorySubscriber) async {
        await start()
        stepHistorySubscribers[id] = subscriber
        await publishStepHistory(to: [id])
    }

    private func removeStepHistorySubscriber(_ id: UUID) {
        stepHistorySubscribers[id] = nil
    }

    /// Reads each day's steps from the chosen data sources. With nothing chosen, every day is empty. A day whose steps
    /// can't be read is empty too; its data source has logged the error.
    private func readStepHistory(days: Int, at now: Date, calendar: Calendar) async -> StepHistory {
        let chosen = chosenSources
        let today = calendar.startOfDay(for: now)
        let dates =
            days > 0 ? (1...days).reversed().compactMap { calendar.date(byAdding: .day, value: -$0, to: today) } : []
        var history: [DailySteps] = []
        for date in dates {
            var steps: Int?
            if let source = chosen?.sources.steps {
                // `try?` flattens the data source's optional, so a failed read and a missing value are both `nil`.
                steps = try? await source.stepCount(on: date)
            }
            history.append(DailySteps(day: date, steps: steps))
        }
        return StepHistory(days: history, isDemo: chosen?.isDemo ?? false)
    }
}
