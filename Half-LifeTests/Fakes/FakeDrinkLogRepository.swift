//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FakeDrinkLogRepository
//

import Foundation

@testable import Half_Life

/// An in-memory drink log repository for use case tests.
///
/// It streams the sets of drinks, the intakes, the days, the recent days, and the demo history answers it was given,
/// then finishes, and it records every drink logged to it, every drink deleted from it, and every demo history added
/// or removed. It's an actor, like the live repositories.
actor FakeDrinkLogRepository: DrinkLogRepository {
    /// The sets of drinks that `loggedDrinks()` streams, in order.
    let drinks: [[LoggedDrink]]
    /// The intakes that `intakeToday(in:)` streams for a calendar, in order.
    let intakes: @Sendable (Calendar) -> [DailyCaffeineIntake]
    /// The days that `day(containing:in:)` streams for a date and a calendar, in order.
    let days: @Sendable (Date, Calendar) -> [DrinkLogDay]
    /// The sets of days that `recentDays(_:in:)` streams for a count and a calendar, in order.
    let recentDaySets: @Sendable (Int, Calendar) -> [[DrinkLogDay]]
    /// The answers that `hasDemoHistory()` streams, in order.
    let hasDemoHistoryAnswers: [Bool]
    /// The error `log(_:)` throws instead of recording the drink, if any.
    let logError: (any Error)?
    /// The error `delete(_:)` throws instead of recording the deletion, if any.
    let deleteError: (any Error)?
    /// The error `addDemoHistory(in:)` and `removeDemoHistory()` throw instead of recording, if any.
    let demoHistoryError: (any Error)?
    /// Every drink logged so far, in order.
    private(set) var logged: [LoggedDrink] = []
    /// The identifier of every drink deleted so far, in order.
    private(set) var deleted: [LoggedDrink.ID] = []
    /// The calendar of every demo history added so far, in order.
    private(set) var demoHistoryAdded: [Calendar] = []
    /// How many times the demo history was removed.
    private(set) var demoHistoryRemovedCount = 0

    init(
        drinks: [[LoggedDrink]] = [],
        intakes: @escaping @Sendable (Calendar) -> [DailyCaffeineIntake] = { _ in [] },
        days: @escaping @Sendable (Date, Calendar) -> [DrinkLogDay] = { _, _ in [] },
        recentDays: @escaping @Sendable (Int, Calendar) -> [[DrinkLogDay]] = { _, _ in [] },
        hasDemoHistory: [Bool] = [],
        logError: (any Error)? = nil,
        deleteError: (any Error)? = nil,
        demoHistoryError: (any Error)? = nil
    ) {
        self.drinks = drinks
        self.intakes = intakes
        self.days = days
        self.recentDaySets = recentDays
        self.hasDemoHistoryAnswers = hasDemoHistory
        self.logError = logError
        self.deleteError = deleteError
        self.demoHistoryError = demoHistoryError
    }

    nonisolated func day(containing date: Date, in calendar: Calendar) -> AsyncStream<DrinkLogDay> {
        Self.stream(days(date, calendar))
    }

    nonisolated func recentDays(_ count: Int, in calendar: Calendar) -> AsyncStream<[DrinkLogDay]> {
        Self.stream(recentDaySets(count, calendar))
    }

    func delete(_ id: LoggedDrink.ID) async throws {
        if let deleteError {
            throw deleteError
        }
        deleted.append(id)
    }

    nonisolated func intakeToday(in calendar: Calendar) -> AsyncStream<DailyCaffeineIntake> {
        Self.stream(intakes(calendar))
    }

    nonisolated func loggedDrinks() -> AsyncStream<[LoggedDrink]> {
        Self.stream(drinks)
    }

    func log(_ drink: LoggedDrink) async throws {
        if let logError {
            throw logError
        }
        logged.append(drink)
    }

    nonisolated func hasDemoHistory() -> AsyncStream<Bool> {
        Self.stream(hasDemoHistoryAnswers)
    }

    func addDemoHistory(in calendar: Calendar) async throws {
        if let demoHistoryError {
            throw demoHistoryError
        }
        demoHistoryAdded.append(calendar)
    }

    func removeDemoHistory() async throws {
        if let demoHistoryError {
            throw demoHistoryError
        }
        demoHistoryRemovedCount += 1
    }

    /// A stream of `values`, in order, that then finishes.
    private static func stream<Value: Sendable>(_ values: [Value]) -> AsyncStream<Value> {
        AsyncStream { continuation in
            for value in values {
                continuation.yield(value)
            }
            continuation.finish()
        }
    }
}
