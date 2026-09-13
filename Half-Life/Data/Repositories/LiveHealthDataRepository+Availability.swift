//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life LiveHealthDataRepository+Availability
//

import Foundation

/// An available kinds subscriber of ``LiveHealthDataRepository``: how many days it looks back over, its calendar, its
/// stream, the last kinds it was sent, and when they were read.
struct HealthDataAvailabilitySubscriber {
    /// How many days the subscriber looks back over, today included.
    let days: Int
    /// The calendar, and so the time zone, whose days are looked back over.
    let calendar: Calendar
    /// The subscriber's stream.
    let continuation: AsyncStream<Set<HealthDataKind>>.Continuation
    /// The last kinds it was sent, or `nil` before the first.
    var lastSent: Set<HealthDataKind>?
    /// When the last kinds were read, which tells when its day has turned.
    var readAt: Date?
}

/// The kinds of Health data with any data, for the Insights tab's Health data buttons.
///
/// It reads the data sources the summary reads, on the same events, and sends each subscriber the kinds only when they
/// have changed. While Health access hasn't been requested, no kind is available. See the Insights article, AVREPO-1
/// to AVREPO-4.
extension LiveHealthDataRepository {
    /// Streams the kinds of Health data that have any data in the last `days` days.
    ///
    /// A new subscriber immediately receives the current kinds. After that, it receives new kinds whenever the chosen
    /// data, the switch, Health access, or a new day changes them.
    ///
    /// - Parameters:
    ///   - days: How many days to look back over, today included.
    ///   - calendar: The calendar, and so the time zone, whose days are looked back over.
    nonisolated func availableKinds(days: Int, in calendar: Calendar) -> AsyncStream<Set<HealthDataKind>> {
        let (stream, continuation) = AsyncStream.makeStream(of: Set<HealthDataKind>.self)
        let id = UUID()
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeAvailabilitySubscriber(id) }
        }
        let subscriber = HealthDataAvailabilitySubscriber(days: days, calendar: calendar, continuation: continuation)
        Task { await addAvailabilitySubscriber(id, subscriber) }
        return stream
    }

    /// Reads the available kinds at `moment`, or now, for each of the subscribers `ids`, or for every one, and sends
    /// them to each they differ for.
    ///
    /// - Parameters:
    ///   - ids: The subscribers to publish to, or `nil` for every one.
    ///   - moment: The time to read at, or `nil` for the clock's current time.
    func publishAvailableKinds(to ids: [UUID]?, at moment: Date? = nil) async {
        let now = moment ?? clock.now()
        for id in ids ?? Array(availabilitySubscribers.keys) {
            guard let subscriber = availabilitySubscribers[id] else { continue }
            let kinds = await readAvailableKinds(days: subscriber.days, at: now, calendar: subscriber.calendar)
            guard var current = availabilitySubscribers[id] else { continue }
            current.readAt = now
            if kinds != current.lastSent {
                current.lastSent = kinds
                current.continuation.yield(kinds)
            }
            availabilitySubscribers[id] = current
        }
    }

    /// Publishes the available kinds to each subscriber whose day has turned by `minute`.
    ///
    /// - Parameter minute: The minute the clock streamed.
    func publishAvailableKindsToTurned(at minute: Date) async {
        let turned = availabilitySubscribers.filter { _, subscriber in
            guard let readAt = subscriber.readAt else { return false }
            return !subscriber.calendar.isDate(minute, inSameDayAs: readAt)
        }
        if !turned.isEmpty {
            await publishAvailableKinds(to: Array(turned.keys), at: minute)
        }
    }

    private func addAvailabilitySubscriber(_ id: UUID, _ subscriber: HealthDataAvailabilitySubscriber) async {
        await start()
        availabilitySubscribers[id] = subscriber
        await publishAvailableKinds(to: [id])
    }

    private func removeAvailabilitySubscriber(_ id: UUID) {
        availabilitySubscribers[id] = nil
    }

    /// Reads the sleep since the first day in one query, and each day's steps and resting heart rate from today back,
    /// stopping at the first day with a value, then executes ``HealthDataAvailabilityRule``. With nothing chosen, no
    /// kind is available. A read that fails counts as no data; its data source has logged the error.
    private func readAvailableKinds(days: Int, at now: Date, calendar: Calendar) async -> Set<HealthDataKind> {
        guard let sources = chosenSources?.sources, days > 0,
            let firstDay = calendar.date(byAdding: .day, value: -(days - 1), to: now)
        else { return [] }
        let start = calendar.startOfDay(for: firstDay)
        let sleep =
            (try? await sources.sleep.sleepIntervals(in: DateInterval(start: start, end: max(start, now)))) ?? []
        let dates = (0..<days).compactMap { calendar.date(byAdding: .day, value: -$0, to: now) }
        var steps: [Int?] = []
        for date in dates {
            // `try?` flattens the data source's optional, so a failed read and a missing value are both `nil`.
            steps.append(try? await sources.steps.stepCount(on: date))
            if case .some(.some) = steps.last { break }
        }
        var restingHeartRates: [Double?] = []
        for date in dates {
            restingHeartRates.append(try? await sources.restingHeartRate.averageRestingHeartRate(on: date))
            if case .some(.some) = restingHeartRates.last { break }
        }
        return HealthDataAvailabilityRule().kinds(sleep: sleep, steps: steps, restingHeartRates: restingHeartRates)
    }
}
