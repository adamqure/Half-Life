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
/// It streams the sets of drinks, the intakes, and the days it was given, then finishes, and it records every drink
/// logged to it and every drink deleted from it. It's an actor, like the live repositories.
actor FakeDrinkLogRepository: DrinkLogRepository {
    /// The sets of drinks that `loggedDrinks()` streams, in order.
    let drinks: [[LoggedDrink]]
    /// The intakes that `intakeToday(in:)` streams for a calendar, in order.
    let intakes: @Sendable (Calendar) -> [DailyCaffeineIntake]
    /// The days that `day(containing:in:)` streams for a date and a calendar, in order.
    let days: @Sendable (Date, Calendar) -> [DrinkLogDay]
    /// The error `log(_:)` throws instead of recording the drink, if any.
    let logError: (any Error)?
    /// The error `delete(_:)` throws instead of recording the deletion, if any.
    let deleteError: (any Error)?
    /// Every drink logged so far, in order.
    private(set) var logged: [LoggedDrink] = []
    /// The identifier of every drink deleted so far, in order.
    private(set) var deleted: [LoggedDrink.ID] = []

    init(
        drinks: [[LoggedDrink]] = [],
        intakes: @escaping @Sendable (Calendar) -> [DailyCaffeineIntake] = { _ in [] },
        days: @escaping @Sendable (Date, Calendar) -> [DrinkLogDay] = { _, _ in [] },
        logError: (any Error)? = nil,
        deleteError: (any Error)? = nil
    ) {
        self.drinks = drinks
        self.intakes = intakes
        self.days = days
        self.logError = logError
        self.deleteError = deleteError
    }

    nonisolated func day(containing date: Date, in calendar: Calendar) -> AsyncStream<DrinkLogDay> {
        let published = days(date, calendar)
        return AsyncStream { continuation in
            for day in published {
                continuation.yield(day)
            }
            continuation.finish()
        }
    }

    func delete(_ id: LoggedDrink.ID) async throws {
        if let deleteError {
            throw deleteError
        }
        deleted.append(id)
    }

    nonisolated func intakeToday(in calendar: Calendar) -> AsyncStream<DailyCaffeineIntake> {
        let published = intakes(calendar)
        return AsyncStream { continuation in
            for intake in published {
                continuation.yield(intake)
            }
            continuation.finish()
        }
    }

    nonisolated func loggedDrinks() -> AsyncStream<[LoggedDrink]> {
        AsyncStream { continuation in
            for set in drinks {
                continuation.yield(set)
            }
            continuation.finish()
        }
    }

    func log(_ drink: LoggedDrink) async throws {
        if let logError {
            throw logError
        }
        logged.append(drink)
    }
}
