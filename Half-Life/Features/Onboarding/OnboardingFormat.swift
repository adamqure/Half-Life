//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life OnboardingFormat
//

import Foundation

/// Formats onboarding's values for display, with locale-aware APIs (constitution Article VII.3).
nonisolated enum OnboardingFormat {
    /// The fixed day a bedtime's date falls on, so turning a time of day into a date never reads the clock.
    private static let referenceDay = Date(timeIntervalSinceReferenceDate: 0)

    /// A bedtime as a time of day: "11:05 PM" in the United States, "23:05" in the United Kingdom.
    ///
    /// - Parameters:
    ///   - bedtime: The bedtime.
    ///   - calendar: The calendar, and so the time zone, the bedtime is a time of day in.
    ///   - locale: The locale to format in. Defaults to the user's.
    /// - Returns: The formatted time.
    static func time(_ bedtime: Bedtime, in calendar: Calendar, locale: Locale = .autoupdatingCurrent) -> String {
        var style = Date.FormatStyle(date: .omitted, time: .shortened, locale: locale, calendar: calendar)
        style.timeZone = calendar.timeZone
        return date(for: bedtime, in: calendar).formatted(style)
    }

    /// The bedtime's hour and minute on a fixed day, in `calendar`, for a time picker that works with dates.
    ///
    /// - Parameters:
    ///   - bedtime: The bedtime.
    ///   - calendar: The calendar, and so the time zone, the bedtime is a time of day in.
    /// - Returns: A date whose hour and minute in `calendar` are the bedtime's.
    static func date(for bedtime: Bedtime, in calendar: Calendar) -> Date {
        calendar.date(bySettingHour: bedtime.hour, minute: bedtime.minute, second: 0, of: referenceDay)
            ?? referenceDay
    }

    /// The bedtime a time picker's date chose: the date's hour and minute in `calendar`, with the seconds dropped.
    ///
    /// - Parameters:
    ///   - date: The date the time picker chose.
    ///   - calendar: The calendar, and so the time zone, the bedtime is a time of day in.
    /// - Returns: The bedtime, or `nil` if the calendar's hour and minute aren't a time of day.
    static func bedtime(at date: Date, in calendar: Calendar) -> Bedtime? {
        Bedtime(hour: calendar.component(.hour, from: date), minute: calendar.component(.minute, from: date))
    }

    /// A recommended range in whole hours, for text such as "7–9 hours".
    ///
    /// - Parameter range: The recommended sleep.
    /// - Returns: The least and the most recommended, in whole hours.
    static func hourRange(_ range: RecommendedSleep) -> (minimum: Int, maximum: Int) {
        (Int((range.minimumSeconds / 3_600).rounded()), Int((range.maximumSeconds / 3_600).rounded()))
    }
}
