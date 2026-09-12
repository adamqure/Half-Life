//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests OnboardingFormatTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks how onboarding formats its values, in fixed locales and time zones (constitution Article VII.3).
struct OnboardingFormatTests {

    static let english = Locale(identifier: "en_US")

    static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()

    @Test func aHalfLifeReadsInHoursToOneDecimalPlace() throws {
        #expect(OnboardingFormat.hours(.standard, locale: Self.english) == "5.5 hours")
        #expect(
            OnboardingFormat.hours(try #require(CaffeineHalfLife(seconds: 29_700)), locale: Self.english) == "8.3 hours"
        )
        #expect(
            OnboardingFormat.hours(try #require(CaffeineHalfLife(seconds: 118_800)), locale: Self.english) == "33 hours"
        )
    }

    @Test func aHalfLifeFollowsTheLocale() {
        #expect(OnboardingFormat.hours(.standard, locale: Locale(identifier: "de_DE")) == "5,5 Stunden")
    }

    @Test func aBedtimeReadsAsATimeOfDay() throws {
        let late = try #require(Bedtime(hour: 23, minute: 5))

        #expect(OnboardingFormat.time(late, in: Self.utc, locale: Self.english) == "11:05\u{202F}PM")
        #expect(OnboardingFormat.time(.standard, in: Self.utc, locale: Locale(identifier: "en_GB")) == "22:30")
    }

    @Test func aBedtimesDateIsItsTimeOfDayInTheCalendar() throws {
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let late = try #require(Bedtime(hour: 23, minute: 45))

        let date = OnboardingFormat.date(for: late, in: tokyo)

        #expect(tokyo.component(.hour, from: date) == 23)
        #expect(tokyo.component(.minute, from: date) == 45)
    }

    @Test func anHourReadsInTheLocalesClock() {
        #expect(OnboardingFormat.hour(22, in: Self.utc, locale: Self.english) == "10\u{202F}PM")
        #expect(OnboardingFormat.hour(0, in: Self.utc, locale: Self.english) == "12\u{202F}AM")
        #expect(OnboardingFormat.hour(22, in: Self.utc, locale: Locale(identifier: "en_GB")) == "22")
    }

    @Test func aMinuteAlwaysHasTwoDigits() {
        #expect(OnboardingFormat.minute(5, locale: Self.english) == "05")
        #expect(OnboardingFormat.minute(30, locale: Self.english) == "30")
        #expect(OnboardingFormat.minute(0, locale: Self.english) == "00")
    }

    @Test func aRecommendedRangeIsInWholeHours() {
        #expect(OnboardingFormat.hourRange(.adult) == (7, 9))
        #expect(OnboardingFormat.hourRange(.teen) == (8, 10))
    }
}
