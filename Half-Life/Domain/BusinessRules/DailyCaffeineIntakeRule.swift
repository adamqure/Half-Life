//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life DailyCaffeineIntakeRule
//

import Foundation

/// The business rule behind the "Today" tile: it totals the caffeine in the drinks consumed on one calendar day.
///
/// A day runs from its midnight, included, to the next midnight, excluded, in the given calendar, so it follows the
/// user's time zone and lasts 23 or 25 hours when the clocks change. Each drink counts with the milligrams it was
/// logged with. Like ``DayPeriodRule``, the rule holds no state and reads no clock, so the current time is an input.
/// ``DrinkLogRepository`` executes it. See the Today Screen article, INTAKE-1 to INTAKE-4.
struct DailyCaffeineIntakeRule: Sendable {
    /// Returns the caffeine in the drinks consumed on the calendar day that `date` falls in.
    ///
    /// - Parameters:
    ///   - drinks: The drinks to total. Drinks consumed on other days add nothing.
    ///   - date: A moment in the day to total, usually the current time.
    ///   - calendar: The calendar, and so the time zone, that defines the day.
    func intake(from drinks: [LoggedDrink], on date: Date, calendar: Calendar) -> DailyCaffeineIntake {
        let milligrams = drinks.reduce(0.0) { total, drink in
            calendar.isDate(drink.consumedAt, inSameDayAs: date) ? total + drink.milligrams : total
        }
        return DailyCaffeineIntake(day: calendar.startOfDay(for: date), milligrams: milligrams)
    }
}
