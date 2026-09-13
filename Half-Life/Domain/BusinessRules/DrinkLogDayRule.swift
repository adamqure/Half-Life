//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life DrinkLogDayRule
//

import Foundation

/// The business rule behind the history card: it picks out one calendar day of the drink log.
///
/// The day is the one ``DailyCaffeineIntakeRule`` totals: from its midnight, included, to the next midnight, excluded,
/// in the given calendar. The rule asks that rule for the day's intake, so the history card's total and the "Today"
/// tile always agree. It holds no state and reads no clock. ``DrinkLogRepository`` executes it. See the Today Screen
/// article, HISTRULE-1 to HISTRULE-4.
struct DrinkLogDayRule: Sendable {
    private let intakeRule = DailyCaffeineIntakeRule()

    /// Returns the calendar day that `date` falls in: its drinks, in the order given, and its intake.
    ///
    /// - Parameters:
    ///   - date: A moment in the day.
    ///   - drinks: The drinks to choose from, oldest first. Drinks consumed on other days are left out.
    ///   - calendar: The calendar, and so the time zone, that defines the day.
    func day(containing date: Date, from drinks: [LoggedDrink], calendar: Calendar) -> DrinkLogDay {
        DrinkLogDay(
            intake: intakeRule.intake(from: drinks, on: date, calendar: calendar),
            drinks: drinks.filter { calendar.isDate($0.consumedAt, inSameDayAs: date) })
    }

    /// Returns the `count` calendar days that end with the one `date` falls in, oldest first, each as
    /// ``day(containing:from:calendar:)`` gives it. See the Insights article, RECENTRULE-1 to RECENTRULE-3.
    ///
    /// - Parameters:
    ///   - date: A moment in the last day, usually the current time.
    ///   - count: How many days to return.
    ///   - drinks: The drinks to choose from, oldest first.
    ///   - calendar: The calendar, and so the time zone, that defines the days.
    func days(endingOn date: Date, count: Int, from drinks: [LoggedDrink], calendar: Calendar) -> [DrinkLogDay] {
        (0..<max(count, 0)).reversed().compactMap { daysAgo in
            calendar.date(byAdding: .day, value: -daysAgo, to: date).map {
                day(containing: $0, from: drinks, calendar: calendar)
            }
        }
    }
}
