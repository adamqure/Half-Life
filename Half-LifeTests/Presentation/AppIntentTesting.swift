//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests AppIntentTesting
//

import Foundation
import Testing

@testable import Half_Life

/// What the App Intents tests share: New York's time zone, the `en_US` locale, and moments in September 2026.
enum AppIntentTesting {
    /// An error a fake repository throws when a store fails for a reason other than a rule.
    struct StoreFailed: Error {}

    /// A Gregorian calendar in New York's time zone, with the `en_US` locale.
    static func newYork() throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/New_York"))
        calendar.locale = Locale(identifier: "en_US")
        return calendar
    }

    /// A moment in September 2026, in New York. 2026-09-07 is a Monday.
    static func date(day: Int, hour: Int, minute: Int) throws -> Date {
        try #require(
            newYork().date(from: DateComponents(year: 2026, month: 9, day: day, hour: hour, minute: minute)))
    }

    /// The format the intents use, in New York's calendar.
    static func format() throws -> IntentDialogFormat {
        IntentDialogFormat(calendar: try newYork())
    }

    /// 3:05pm on Monday, 2026-09-07: the tests' current time.
    static func now() throws -> Date {
        try date(day: 7, hour: 15, minute: 5)
    }

    /// A caffeine status at ``now()``, with one intake still counting and the level at a 10:30pm bedtime.
    static func status() throws -> CaffeineStatus {
        let now = try now()
        return CaffeineStatus(
            level: CaffeineLevel(date: now, milligrams: 84.6),
            activeIntakes: [CaffeineIntake(id: UUID(), milligrams: 125.4, consumedAt: now)],
            lastIntakeHalfGoneAt: nil,
            levelAtBedtime: CaffeineLevel(date: try date(day: 7, hour: 22, minute: 30), milligrams: 34.2))
    }

    /// The cutoff for a usual latte of 2 shots, by 2:30pm, for a 10:30pm bedtime.
    static func cutoff(latestCup: Bool = true) throws -> CaffeineCutoff {
        CaffeineCutoff(
            drink: FavouriteDrink(type: .latte, quantity: 2),
            latestCup: latestCup ? try date(day: 7, hour: 14, minute: 30) : nil,
            bedtime: try date(day: 7, hour: 22, minute: 30),
            threshold: .standard)
    }

    /// A day with a latte of 2 shots at 8:10am, and a demo espresso at 1:05pm.
    static func day(_ day: Int) throws -> DrinkLogDay {
        DrinkLogDay(
            intake: DailyCaffeineIntake(day: try date(day: day, hour: 0, minute: 0), milligrams: 188.1),
            drinks: [
                LoggedDrink(
                    type: .latte, quantity: 2, milligrams: 125.4, consumedAt: try date(day: day, hour: 8, minute: 10)),
                LoggedDrink(
                    type: .espresso, quantity: 1, milligrams: 62.7,
                    consumedAt: try date(day: day, hour: 13, minute: 5), isDemo: true),
            ])
    }

    /// Tonight's window, for a 10:30pm bedtime, when caffeine clears at `clearHour`:`clearMinute`, or never.
    static func sleepWindow(clearHour: Int?, clearMinute: Int = 0) throws -> SleepWindow {
        let evening = try date(day: 7, hour: 18, minute: 0)
        let bedtime = try date(day: 7, hour: 22, minute: 30)
        let clearsAt = try clearHour.map { try date(day: 7, hour: $0, minute: clearMinute) }
        let start = clearsAt.map { max($0, bedtime) }
        return SleepWindow(
            evening: evening,
            bedtime: bedtime,
            clearsAt: clearsAt,
            window: start.map { DateInterval(start: $0, duration: 90 * 60) },
            chartEnd: try date(day: 8, hour: 4, minute: 0),
            threshold: .standard,
            levels: [])
    }
}
