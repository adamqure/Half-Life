//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life DrinksOnDayTool
//

import Foundation
import FoundationModels

/// `getDrinksOnDay`: every drink logged on one day, and the day's total.
///
/// It reads the day from ``DrinkLogRepository``, the same day the history card shows, and marks the drinks the demo
/// history added (LMTOOL-4, LMTOOL-7).
struct DrinksOnDayTool: Tool {
    /// The day to report.
    @Generable
    struct Arguments {
        /// How many days before today the day is.
        @Guide(description: "How many days before today: 0 is today, and 1 is yesterday.", .range(0...90))
        let daysAgo: Int
    }

    /// The repository the day comes from.
    let drinkLog: any DrinkLogRepository
    /// The repository that gives the current time, and so today.
    let currentTime: any CurrentTimeRepository
    /// Formats the amounts, times, and day, in the calendar that defines the day.
    let format: LanguageModelFormat

    /// The name the model calls the tool by.
    let name = "getDrinksOnDay"
    /// What the tool tells the model it does.
    let description = "Gets every drink the user logged on one day, with its time and caffeine, and the day's total."

    /// Reports the day's drinks.
    @concurrent func call(arguments: Arguments) async throws -> String {
        let calendar = format.calendar
        guard let date = calendar.date(byAdding: .day, value: -arguments.daysAgo, to: currentTime.now()) else {
            return "That day isn't available."
        }
        let dayName = format.day(date)
        guard let day = await drinkLog.day(containing: date, in: calendar).firstValue() else {
            return "The drinks logged on \(dayName) aren't available."
        }
        guard !day.drinks.isEmpty else {
            return "No drinks were logged on \(dayName)."
        }
        let drinks = day.drinks.map { drink in
            let demo = drink.isDemo ? " (demo data)" : ""
            return "- \(format.time(drink.consumedAt)): \(format.drink(drink.type, quantity: drink.quantity)), "
                + "\(format.milligrams(drink.milligrams))\(demo)"
        }
        let total = "Total: \(format.milligrams(day.intake.milligrams))."
        return (["Drinks logged on \(dayName):"] + drinks + [total]).joined(separator: "\n")
    }
}
