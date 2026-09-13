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

    @Test func aTimePickersDateIsABedtimeAtItsTimeOfDayInTheCalendar() throws {
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        // 2:45:59pm UTC is 11:45:59pm in Tokyo. The seconds are dropped.
        let date = Date(timeIntervalSinceReferenceDate: 14.75 * 3_600 + 59)

        #expect(OnboardingFormat.bedtime(at: date, in: tokyo) == Bedtime(hour: 23, minute: 45))
    }

    @Test func aRecommendedRangeIsInWholeHours() {
        #expect(OnboardingFormat.hourRange(.adult) == (7, 9))
        #expect(OnboardingFormat.hourRange(.teen) == (8, 10))
    }
}
