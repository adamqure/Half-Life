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

    /// A half-life in hours, to one decimal place at most, rounding halves up: "5.5 hours", "8.3 hours", "33 hours".
    ///
    /// - Parameters:
    ///   - halfLife: The half-life.
    ///   - locale: The locale to format in. Defaults to the user's.
    /// - Returns: The formatted duration.
    static func hours(_ halfLife: CaffeineHalfLife, locale: Locale = .autoupdatingCurrent) -> String {
        Measurement(value: halfLife.seconds / 3_600, unit: UnitDuration.hours)
            .formatted(
                .measurement(
                    width: .wide, usage: .asProvided,
                    numberFormatStyle: .number.precision(.fractionLength(0...1))
                        .rounded(rule: .toNearestOrAwayFromZero)
                )
                .locale(locale))
    }

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

    /// An hour of the day, for the bedtime's hour wheel: "10 PM" in the United States, "22" in the United Kingdom.
    ///
    /// - Parameters:
    ///   - hour: The hour, from 0 to 23.
    ///   - calendar: The calendar the hour is in.
    ///   - locale: The locale to format in. Defaults to the user's.
    /// - Returns: The formatted hour.
    static func hour(_ hour: Int, in calendar: Calendar, locale: Locale = .autoupdatingCurrent) -> String {
        var style = Date.FormatStyle(locale: locale, calendar: calendar).hour()
        style.timeZone = calendar.timeZone
        let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: referenceDay) ?? referenceDay
        return date.formatted(style)
    }

    /// A minute of the hour, for the bedtime's minute wheel, always with two digits: "05".
    ///
    /// - Parameters:
    ///   - minute: The minute, from 0 to 59.
    ///   - locale: The locale to format in. Defaults to the user's.
    /// - Returns: The formatted minute.
    static func minute(_ minute: Int, locale: Locale = .autoupdatingCurrent) -> String {
        minute.formatted(.number.precision(.integerLength(2)).grouping(.never).locale(locale))
    }

    /// A recommended range in whole hours, for text such as "7–9 hours".
    ///
    /// - Parameter range: The recommended sleep.
    /// - Returns: The least and the most recommended, in whole hours.
    static func hourRange(_ range: RecommendedSleep) -> (minimum: Int, maximum: Int) {
        (Int((range.minimumSeconds / 3_600).rounded()), Int((range.maximumSeconds / 3_600).rounded()))
    }
}
