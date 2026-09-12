//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life DayPeriodRule
//

import Foundation

/// The business rule that finds the part of the day a moment falls in.
///
/// It reads the hour in the given calendar, so the period follows the user's time zone. Like ``CaffeineDecayRule``,
/// it reads no clock and holds no state. See the Today Screen article, PERIOD-1 and PERIOD-2.
nonisolated struct DayPeriodRule: Sendable {
    /// Returns the part of the day that `date` falls in.
    ///
    /// - Parameters:
    ///   - date: The moment to classify.
    ///   - calendar: The calendar, and so the time zone, to read the hour in.
    func period(at date: Date, calendar: Calendar) -> DayPeriod {
        switch calendar.component(.hour, from: date) {
        case 5..<12: .morning
        case 12..<17: .afternoon
        default: .evening
        }
    }
}
