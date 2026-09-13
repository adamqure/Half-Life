//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life DemoHistoryRule
//

import Foundation

/// The business rule behind the demo history: 30 days of plausible drinks, ending now.
///
/// The history is a fixed script of local clock times, drinks, and quantities: one list for each of the 30 days before
/// today, and one for today, cut off at the current time. Mornings start with coffee. 11 of the 30 days end with a cup
/// of 90 mg or more from 3pm on, 17 stop before 3pm, and 2 end with a small cola, so the timing varies from day to day.
/// Two heavy days have four drinks each. Only the identifiers change between calls, so a later feature can generate
/// matching sleep from the same drinks. It holds no state and reads no clock. ``DrinkLogRepository`` executes it. See
/// the Settings article, DEMO-1 to DEMO-6.
struct DemoHistoryRule: Sendable {
    /// One drink in the script: when on its day, which drink, and how many units.
    private struct Serving: Sendable {
        let hour: Int
        let minute: Int
        let type: DrinkType
        let quantity: Int

        init(_ hour: Int, _ minute: Int, _ type: DrinkType, quantity: Int = 1) {
            self.hour = hour
            self.minute = minute
            self.type = type
            self.quantity = quantity
        }

        /// The demo drink this serving is on the day that starts at `day`, or `nil` if the calendar has no such time.
        func drink(on day: Date, calendar: Calendar) -> LoggedDrink? {
            guard let consumedAt = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) else {
                return nil
            }
            return LoggedDrink(
                type: type, quantity: quantity, milligrams: type.estimatedMilligrams(quantity: quantity),
                consumedAt: consumedAt, isDemo: true)
        }
    }

    /// The script for each of the 30 days before today, from the earliest to yesterday. Each serving is its hour and
    /// minute on the 24-hour clock, the drink, and its quantity when it's more than one. The last 14 days are the
    /// first build's 14-day script.
    private static let earlierDays: [[Serving]] = [
        [Serving(7, 45, .latte, quantity: 2), Serving(10, 30, .dripCoffee)],
        [Serving(7, 40, .latte, quantity: 2), Serving(15, 45, .coldBrew, quantity: 2)],
        [Serving(8, 0, .latte, quantity: 2), Serving(11, 0, .americano, quantity: 2)],
        [Serving(7, 50, .latte, quantity: 2), Serving(13, 30, .blackTea)],
        [Serving(9, 30, .cappuccino, quantity: 2), Serving(14, 0, .matcha)],
        [Serving(10, 0, .cappuccino, quantity: 2), Serving(16, 0, .dripCoffee)],
        [Serving(7, 45, .latte, quantity: 2), Serving(10, 45, .dripCoffee), Serving(16, 30, .cola)],
        [Serving(7, 40, .latte, quantity: 2), Serving(12, 30, .greenTea)],
        [Serving(7, 55, .latte, quantity: 2), Serving(15, 30, .coldBrew, quantity: 2)],
        [
            Serving(6, 50, .dripCoffee), Serving(9, 30, .latte, quantity: 2), Serving(14, 15, .energyDrink),
            Serving(17, 0, .espresso, quantity: 2),
        ],
        [Serving(9, 45, .cappuccino, quantity: 2)],
        [Serving(10, 15, .flatWhite, quantity: 2), Serving(15, 30, .dripCoffee)],
        [Serving(7, 45, .latte, quantity: 2), Serving(11, 0, .dripCoffee)],
        [Serving(7, 40, .latte, quantity: 2), Serving(16, 15, .coldBrew)],
        [Serving(7, 50, .latte, quantity: 2), Serving(15, 0, .latte, quantity: 2)],
        [Serving(8, 5, .latte, quantity: 2), Serving(11, 30, .greenTea)],
        // The first build's 14 days.
        [Serving(7, 45, .latte, quantity: 2), Serving(10, 30, .dripCoffee)],
        [Serving(7, 40, .latte, quantity: 2), Serving(15, 45, .coldBrew, quantity: 2)],
        [Serving(8, 0, .latte, quantity: 2), Serving(11, 0, .americano, quantity: 2)],
        [Serving(7, 50, .latte, quantity: 2), Serving(13, 30, .blackTea)],
        [Serving(9, 30, .cappuccino, quantity: 2), Serving(14, 0, .matcha)],
        [Serving(10, 0, .cappuccino, quantity: 2)],
        [Serving(7, 45, .latte, quantity: 2), Serving(10, 45, .dripCoffee), Serving(16, 30, .cola)],
        [Serving(7, 40, .latte, quantity: 2), Serving(12, 30, .greenTea)],
        [Serving(7, 55, .latte, quantity: 2), Serving(15, 30, .coldBrew, quantity: 2)],
        [
            Serving(6, 50, .dripCoffee), Serving(9, 30, .latte, quantity: 2), Serving(14, 15, .energyDrink),
            Serving(17, 0, .espresso, quantity: 2),
        ],
        [Serving(9, 45, .cappuccino, quantity: 2)],
        [Serving(10, 15, .flatWhite, quantity: 2), Serving(13, 30, .blackTea)],
        [Serving(7, 45, .latte, quantity: 2), Serving(11, 0, .dripCoffee)],
        [Serving(7, 40, .latte, quantity: 2), Serving(16, 15, .coldBrew)],
    ]

    /// The script for today. Only the servings up to the current time are drunk.
    private static let today: [Serving] = [
        Serving(7, 45, .latte, quantity: 2), Serving(10, 30, .dripCoffee), Serving(14, 30, .greenTea),
    ]

    /// Returns the demo drinks for the 30 days before the day `now` falls in, and that day's drinks up to `now`.
    ///
    /// Every drink is marked demo, has a new identifier, and carries the caffeine its type and quantity give.
    ///
    /// - Parameters:
    ///   - now: The current time. No drink is later than it.
    ///   - calendar: The calendar, and so the time zone, whose days and clock times the script follows.
    /// - Returns: The demo drinks, oldest first.
    func drinks(now: Date, calendar: Calendar) -> [LoggedDrink] {
        let startOfToday = calendar.startOfDay(for: now)
        var drinks: [LoggedDrink] = []
        for (index, servings) in Self.earlierDays.enumerated() {
            let daysAgo = Self.earlierDays.count - index
            guard let day = calendar.date(byAdding: .day, value: -daysAgo, to: startOfToday) else { continue }
            drinks += servings.compactMap { $0.drink(on: day, calendar: calendar) }
        }
        drinks += Self.today
            .compactMap { $0.drink(on: startOfToday, calendar: calendar) }
            .filter { $0.consumedAt <= now }
        return drinks
    }
}
