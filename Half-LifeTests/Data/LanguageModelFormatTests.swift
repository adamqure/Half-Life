//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests LanguageModelFormatTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks how tools format what they give the language model (LMTOOL-8 in the Language Model article).
struct LanguageModelFormatTests {

    /// A Gregorian calendar in the given time zone and the `en_US` locale.
    static func calendar(_ timeZone: String) throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: timeZone))
        calendar.locale = Locale(identifier: "en_US")
        return calendar
    }

    /// 3:05pm on Monday, 2026-09-07, in New York.
    static func afternoon() throws -> Date {
        let newYork = try calendar("America/New_York")
        return try #require(newYork.date(from: DateComponents(year: 2026, month: 9, day: 7, hour: 15, minute: 5)))
    }

    @Test(arguments: [(84.6, "85 mg"), (0.4, "0 mg"), (1_234.2, "1,234 mg")])
    func amountsAreWholeMilligrams(milligrams: Double, expected: String) throws {
        let format = LanguageModelFormat(calendar: try Self.calendar("America/New_York"))

        #expect(format.milligrams(milligrams) == expected)
    }

    @Test func timesAreInTheCalendarsTimeZone() throws {
        let newYork = LanguageModelFormat(calendar: try Self.calendar("America/New_York"))
        let tokyo = LanguageModelFormat(calendar: try Self.calendar("Asia/Tokyo"))
        let afternoon = try Self.afternoon()

        #expect(newYork.time(afternoon).contains("3:05"))
        #expect(newYork.time(afternoon).contains("PM"))
        #expect(tokyo.time(afternoon).contains("4:05"))
        #expect(tokyo.time(afternoon).contains("AM"))
    }

    @Test func daysNameTheWeekdayMonthAndDay() throws {
        let format = LanguageModelFormat(calendar: try Self.calendar("America/New_York"))

        #expect(format.day(try Self.afternoon()) == "Monday, September 7")
    }

    @Test(arguments: [
        (DrinkType.latte, 2, "latte, 2 shots"), (.flatWhite, 1, "flat white, 1 shot"),
        (.coldBrew, 1, "cold brew, 1 cup"), (.dripCoffee, 3, "drip coffee, 3 cups"), (.cola, 1, "cola, 1 can"),
        (.energyDrink, 2, "energy drink, 2 cans"),
    ])
    func drinksNameTheDrinkAndItsQuantity(type: DrinkType, quantity: Int, expected: String) throws {
        let format = LanguageModelFormat(calendar: try Self.calendar("America/New_York"))

        #expect(format.drink(type, quantity: quantity) == expected)
    }

    @Test func everyDrinkHasAName() throws {
        let format = LanguageModelFormat(calendar: try Self.calendar("America/New_York"))

        for type in DrinkType.allCases {
            #expect(!format.drink(type, quantity: 1).hasPrefix(","))
        }
    }
}
