//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests DemoHistoryRuleTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the demo history's rule against DEMO-1 to DEMO-6 in the Settings article. The rule is pure, so its tests
/// need no fakes.
struct DemoHistoryRuleTests {

    let rule = DemoHistoryRule()

    static func calendar(_ identifier: String) throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: identifier))
        return calendar
    }

    /// A moment on September `day`, 2026, at `hour`:`minute` in `calendar`.
    static func date(day: Int, hour: Int, minute: Int = 0, in calendar: Calendar) throws -> Date {
        try #require(calendar.date(from: DateComponents(year: 2026, month: 9, day: day, hour: hour, minute: minute)))
    }

    /// The drinks consumed before the day `now` falls in, grouped by the start of their day.
    static func earlierDays(_ drinks: [LoggedDrink], now: Date, calendar: Calendar) -> [Date: [LoggedDrink]] {
        Dictionary(grouping: drinks.filter { !calendar.isDate($0.consumedAt, inSameDayAs: now) }) {
            calendar.startOfDay(for: $0.consumedAt)
        }
    }

    // MARK: - DEMO-1: every one of the 30 days before today has drinks, and nothing comes before them

    @Test func coversEachOfTheThirtyDaysBeforeToday() throws {
        let utc = try Self.calendar("UTC")
        let now = try Self.date(day: 12, hour: 20, in: utc)

        let days = Self.earlierDays(rule.drinks(now: now, calendar: utc), now: now, calendar: utc)

        let today = utc.startOfDay(for: now)
        let expected = try (1...30).map { try #require(utc.date(byAdding: .day, value: -$0, to: today)) }
        #expect(Set(days.keys) == Set(expected))
    }

    // MARK: - DEMO-2: today holds only the drinks consumed by now

    @Test func todayHoldsOnlyTheDrinksConsumedByNow() throws {
        let utc = try Self.calendar("UTC")
        let morning = try Self.date(day: 12, hour: 9, in: utc)
        let night = try Self.date(day: 12, hour: 23, minute: 30, in: utc)

        let byMorning = rule.drinks(now: morning, calendar: utc)
            .filter { utc.isDate($0.consumedAt, inSameDayAs: morning) }
        let byNight = rule.drinks(now: night, calendar: utc)
            .filter { utc.isDate($0.consumedAt, inSameDayAs: night) }

        #expect(!byMorning.isEmpty)
        #expect(byMorning.allSatisfy { $0.consumedAt <= morning })
        #expect(byNight.count > byMorning.count)
        #expect(Array(byNight.prefix(byMorning.count)).map(\.type) == byMorning.map(\.type))
    }

    @Test func justAfterMidnightTodayHasNoDrinksButTheThirtyDaysStay() throws {
        let utc = try Self.calendar("UTC")
        let now = try Self.date(day: 12, hour: 0, minute: 30, in: utc)

        let drinks = rule.drinks(now: now, calendar: utc)

        #expect(!drinks.contains { utc.isDate($0.consumedAt, inSameDayAs: now) })
        #expect(Self.earlierDays(drinks, now: now, calendar: utc).count == 30)
    }

    // MARK: - DEMO-3: every drink is a demo drink that could have been logged

    @Test func everyDrinkIsADemoDrinkThatCouldHaveBeenLogged() throws {
        let utc = try Self.calendar("UTC")
        let now = try Self.date(day: 12, hour: 23, minute: 59, in: utc)

        let drinks = rule.drinks(now: now, calendar: utc)

        #expect(!drinks.isEmpty)
        for drink in drinks {
            #expect(drink.isDemo)
            #expect(throws: Never.self) { try DrinkLogRule().validate(drink, now: now) }
            #expect(drink.milligrams == drink.type.estimatedMilligrams(quantity: drink.quantity))
        }
    }

    @Test func drinksAreOldestFirstEachWithItsOwnID() throws {
        let utc = try Self.calendar("UTC")
        let now = try Self.date(day: 12, hour: 20, in: utc)

        let drinks = rule.drinks(now: now, calendar: utc)

        #expect(drinks.map(\.consumedAt) == drinks.map(\.consumedAt).sorted())
        #expect(Set(drinks.map(\.id)).count == drinks.count)
    }

    // MARK: - DEMO-4: at least 10 days end with a strong cup from 3pm on, and at least 10 stop before 3pm

    @Test func tenDaysEndWithAStrongLateCupAndTenStopBeforeThree() throws {
        let utc = try Self.calendar("UTC")
        let now = try Self.date(day: 12, hour: 20, in: utc)

        let days = Self.earlierDays(rule.drinks(now: now, calendar: utc), now: now, calendar: utc)
        let lateDays = days.values.filter { drinks in
            drinks.contains { utc.component(.hour, from: $0.consumedAt) >= 15 && $0.milligrams >= 90 }
        }
        let earlyDays = days.values.filter { drinks in
            !drinks.contains { utc.component(.hour, from: $0.consumedAt) >= 15 }
        }

        #expect(lateDays.count >= 10)
        #expect(earlyDays.count >= 10)
    }

    // MARK: - DEMO-5: the drinks fall at the same local clock times in any time zone

    @Test func drinksFallAtTheSameLocalTimesInAnyTimeZone() throws {
        let utc = try Self.calendar("UTC")
        let tokyo = try Self.calendar("Asia/Tokyo")

        func localTimes(in calendar: Calendar) throws -> [String] {
            let now = try Self.date(day: 12, hour: 20, in: calendar)
            return rule.drinks(now: now, calendar: calendar).map { drink in
                let parts = calendar.dateComponents([.day, .hour, .minute], from: drink.consumedAt)
                return "\(parts.day ?? 0) \(parts.hour ?? 0):\(parts.minute ?? 0) \(drink.type) ×\(drink.quantity)"
            }
        }

        #expect(try localTimes(in: utc) == localTimes(in: tokyo))
    }

    // MARK: - DEMO-6: the same moment always gives the same drinks

    @Test func theSameMomentGivesTheSameDrinks() throws {
        let utc = try Self.calendar("UTC")
        let now = try Self.date(day: 12, hour: 20, in: utc)

        let first = rule.drinks(now: now, calendar: utc)
        let second = rule.drinks(now: now, calendar: utc)

        #expect(first.map(\.consumedAt) == second.map(\.consumedAt))
        #expect(first.map(\.type) == second.map(\.type))
        #expect(first.map(\.quantity) == second.map(\.quantity))
    }
}
