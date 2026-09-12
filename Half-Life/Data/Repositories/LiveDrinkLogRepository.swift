//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life LiveDrinkLogRepository
//

import Foundation
import OSLog

/// The live drink log repository: the source of truth for every drink the user has logged.
///
/// It stores drinks through its ``DrinkLogDataSource``, which it shares with ``LiveCaffeineDecayRepository``. Before
/// storing, it executes ``DrinkLogRule`` with the current time from its ``ClockDataSource``. It publishes what the
/// data source holds: a new subscriber gets every drink, and every subscriber gets the updated set after each change
/// the data source signals.
///
/// It also publishes the caffeine logged today, by executing ``DailyCaffeineIntakeRule`` in each subscriber's
/// calendar. It recalculates after each change the data source signals, and follows the clock's minutes so the total
/// starts again at midnight. Each intake subscriber gets a value only when its intake has changed.
///
/// It publishes any one day of the log too, by executing ``DrinkLogDayRule`` for the day each subscriber asked for.
/// It recalculates after each change the data source signals, and never follows the clock, because the day is fixed.
/// It deletes drinks through the data source, whose change signal updates every stream here and the decay
/// repository's. It's an actor, off the main actor (constitution Article I.13). The Drink Composer article lists its
/// requirements, DLOG-1 to DLOG-4, and the Today Screen article lists DLOG-5 to DLOG-9, DAYLOG-1 to DAYLOG-3, and
/// DELETE-1 to DELETE-3.
actor LiveDrinkLogRepository: DrinkLogRepository {
    private static let logger = Logger(for: LiveDrinkLogRepository.self)

    /// An intake subscriber: its stream, the calendar its day is in, and the last intake it was sent.
    private struct IntakeSubscriber {
        let calendar: Calendar
        let continuation: AsyncStream<DailyCaffeineIntake>.Continuation
        var lastSent: DailyCaffeineIntake?
    }

    /// A day subscriber: its stream, a moment in its day, the calendar its day is in, and the last day it was sent.
    private struct DaySubscriber {
        let date: Date
        let calendar: Calendar
        let continuation: AsyncStream<DrinkLogDay>.Continuation
        var lastSent: DrinkLogDay?
    }

    private let dataSource: any DrinkLogDataSource
    private let clock: any ClockDataSource
    private let rule = DrinkLogRule()
    private let intakeRule = DailyCaffeineIntakeRule()
    private let dayRule = DrinkLogDayRule()
    private var subscribers: [UUID: AsyncStream<[LoggedDrink]>.Continuation] = [:]
    private var intakeSubscribers: [UUID: IntakeSubscriber] = [:]
    private var daySubscribers: [UUID: DaySubscriber] = [:]
    private var isListening = false
    private var changeListener: Task<Void, Never>?
    private var minuteListener: Task<Void, Never>?

    /// Creates the repository.
    ///
    /// - Parameters:
    ///   - dataSource: Where drinks are stored, shared with the caffeine decay repository.
    ///   - clock: The current time, for ``DrinkLogRule`` and ``DailyCaffeineIntakeRule``, and the minutes the day's
    ///     intake follows.
    init(dataSource: any DrinkLogDataSource, clock: any ClockDataSource) {
        self.dataSource = dataSource
        self.clock = clock
    }

    deinit {
        changeListener?.cancel()
        minuteListener?.cancel()
    }

    /// Streams every logged drink, oldest first.
    ///
    /// A new subscriber immediately receives every drink. After that, every subscriber receives the updated set
    /// whenever the data source signals a change.
    nonisolated func loggedDrinks() -> AsyncStream<[LoggedDrink]> {
        let (stream, continuation) = AsyncStream.makeStream(of: [LoggedDrink].self)
        let id = UUID()
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeSubscriber(id) }
        }
        Task { await addSubscriber(id, continuation) }
        return stream
    }

    /// Streams the caffeine logged on the current calendar day.
    ///
    /// A new subscriber immediately receives the current day's intake. After that, it receives a new intake when a
    /// change the data source signals alters the day's total, and at the first minute the clock streams on each new
    /// day.
    ///
    /// - Parameter calendar: The calendar, and so the time zone, that defines the day.
    nonisolated func intakeToday(in calendar: Calendar) -> AsyncStream<DailyCaffeineIntake> {
        let (stream, continuation) = AsyncStream.makeStream(of: DailyCaffeineIntake.self)
        let id = UUID()
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeIntakeSubscriber(id) }
        }
        Task { await addIntakeSubscriber(id, IntakeSubscriber(calendar: calendar, continuation: continuation)) }
        return stream
    }

    /// Checks `drink` with ``DrinkLogRule``, then stores it. Subscribers get the updated set when the data source
    /// signals the change.
    ///
    /// - Parameter drink: The drink to store.
    /// - Throws: A ``DrinkLogRule/Violation`` if the drink can't be logged, or the data source's error if it couldn't
    ///   be stored. Nothing is stored or published then.
    func log(_ drink: LoggedDrink) async throws {
        try rule.validate(drink, now: clock.now())
        try await dataSource.store(drink)
    }

    /// Streams the calendar day that `date` falls in.
    ///
    /// A new subscriber immediately receives the day. After that, it receives a new day when a change the data source
    /// signals alters it.
    ///
    /// - Parameters:
    ///   - date: A moment in the day.
    ///   - calendar: The calendar, and so the time zone, that defines the day.
    nonisolated func day(containing date: Date, in calendar: Calendar) -> AsyncStream<DrinkLogDay> {
        let (stream, continuation) = AsyncStream.makeStream(of: DrinkLogDay.self)
        let id = UUID()
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeDaySubscriber(id) }
        }
        let subscriber = DaySubscriber(date: date, calendar: calendar, continuation: continuation)
        Task { await addDaySubscriber(id, subscriber) }
        return stream
    }

    /// Has the data source delete the drink. Subscribers get the updated values when the data source signals the
    /// change.
    ///
    /// - Parameter id: The identifier of the drink to delete.
    /// - Throws: The data source's error if the deletion couldn't be stored. Nothing is published then.
    func delete(_ id: LoggedDrink.ID) async throws {
        try await dataSource.delete(id)
    }

    /// Starts listening to the data source before the first set goes out, so no change after it is missed.
    private func addSubscriber(_ id: UUID, _ continuation: AsyncStream<[LoggedDrink]>.Continuation) async {
        await listenForChanges()
        subscribers[id] = continuation
        if let drinks = await readDrinks() {
            continuation.yield(drinks)
        }
    }

    private func removeSubscriber(_ id: UUID) {
        subscribers[id] = nil
    }

    /// Starts listening to the data source before the first intake goes out, and follows the clock's minutes after
    /// it, so the first intake is always the current day's.
    private func addIntakeSubscriber(_ id: UUID, _ subscriber: IntakeSubscriber) async {
        await listenForChanges()
        intakeSubscribers[id] = subscriber
        if let drinks = await readDrinks() {
            publishIntake(from: drinks, at: clock.now(), to: [id])
        }
        listenForMinutes()
    }

    private func removeIntakeSubscriber(_ id: UUID) {
        intakeSubscribers[id] = nil
    }

    /// Starts listening to the data source before the first day goes out, so no change after it is missed.
    private func addDaySubscriber(_ id: UUID, _ subscriber: DaySubscriber) async {
        await listenForChanges()
        daySubscribers[id] = subscriber
        if let drinks = await readDrinks() {
            publishDays(from: drinks, to: [id])
        }
    }

    private func removeDaySubscriber(_ id: UUID) {
        daySubscribers[id] = nil
    }

    /// Subscribes to the data source's changes once, for the life of the repository.
    private func listenForChanges() async {
        guard !isListening else { return }
        isListening = true
        let changes = await dataSource.changes()
        changeListener = Task { [weak self] in
            for await _ in changes {
                await self?.publishChange()
            }
        }
    }

    /// Follows the clock's minutes once, from the first intake subscriber on. Only the intake follows them.
    private func listenForMinutes() {
        guard minuteListener == nil else { return }
        let minutes = clock.minutes()
        minuteListener = Task { [weak self] in
            for await minute in minutes {
                await self?.publishNewDay(at: minute)
            }
        }
    }

    /// After the data source signals a change, publishes every drink to every subscriber, the day's intake to each
    /// intake subscriber whose total changed, and each day subscriber's day if it changed.
    private func publishChange() async {
        guard !subscribers.isEmpty || !intakeSubscribers.isEmpty || !daySubscribers.isEmpty,
            let drinks = await readDrinks()
        else { return }
        for subscriber in subscribers.values {
            subscriber.yield(drinks)
        }
        publishIntake(from: drinks, at: clock.now(), to: Array(intakeSubscribers.keys))
        publishDays(from: drinks, to: Array(daySubscribers.keys))
    }

    /// Calculates the day for each of the day subscribers `ids`, in its own calendar, and sends it to those it
    /// differs for.
    private func publishDays(from drinks: [LoggedDrink], to ids: [UUID]) {
        for id in ids {
            guard var subscriber = daySubscribers[id] else { continue }
            let day = dayRule.day(containing: subscriber.date, from: drinks, calendar: subscriber.calendar)
            guard day != subscriber.lastSent else { continue }
            subscriber.lastSent = day
            daySubscribers[id] = subscriber
            subscriber.continuation.yield(day)
        }
    }

    /// Publishes the new day's intake to each intake subscriber whose day has turned by `minute`, or that hasn't been
    /// sent an intake yet. The drinks are read only then, so the other minutes cost nothing.
    private func publishNewDay(at minute: Date) async {
        let turned = intakeSubscribers.filter { _, subscriber in
            guard let lastSent = subscriber.lastSent else { return true }
            return !subscriber.calendar.isDate(minute, inSameDayAs: lastSent.day)
        }
        guard !turned.isEmpty, let drinks = await readDrinks() else { return }
        publishIntake(from: drinks, at: minute, to: Array(turned.keys))
    }

    /// Calculates the intake at `now` for each of the intake subscribers `ids`, in its own calendar, and sends it to
    /// those it differs for.
    private func publishIntake(from drinks: [LoggedDrink], at now: Date, to ids: [UUID]) {
        for id in ids {
            guard var subscriber = intakeSubscribers[id] else { continue }
            let intake = intakeRule.intake(from: drinks, on: now, calendar: subscriber.calendar)
            guard intake != subscriber.lastSent else { continue }
            subscriber.lastSent = intake
            intakeSubscribers[id] = subscriber
            subscriber.continuation.yield(intake)
        }
    }

    /// Reads every drink. Returns `nil`, after logging the error without any drink data, if they couldn't be read.
    private func readDrinks() async -> [LoggedDrink]? {
        do {
            return try await dataSource.drinks()
        } catch {
            let error = error as NSError
            Self.logger.error(
                "Couldn't read the drink log: \(error.domain, privacy: .public) \(error.code, privacy: .public)")
            return nil
        }
    }
}
