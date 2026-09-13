//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life LanguageModelFormat
//

import Foundation

/// Formats the amounts, times, days, and drinks that tools give the language model (LMTOOL-8).
///
/// The model copies what the tools give it, so it never formats or rounds a number itself. Amounts and times follow
/// the calendar's locale and time zone (constitution Article VII.3). Drink names are prompt text for the model, not
/// text the user sees, so they're in English, like the rest of the prompt.
struct LanguageModelFormat: Sendable {
    /// The calendar whose locale and time zone everything is formatted in.
    let calendar: Calendar

    private var locale: Locale {
        calendar.locale ?? .autoupdatingCurrent
    }

    /// A whole number of milligrams, such as "85 mg".
    func milligrams(_ value: Double) -> String {
        Measurement(value: value.rounded(), unit: UnitMass.milligrams)
            .formatted(
                Measurement<UnitMass>.FormatStyle(
                    width: .abbreviated, locale: locale, usage: .asProvided,
                    numberFormatStyle: .number.precision(.fractionLength(0))))
    }

    /// A time of day, such as "3:05 PM".
    func time(_ date: Date) -> String {
        date.formatted(
            Date.FormatStyle(
                date: .omitted, time: .shortened, locale: locale, calendar: calendar, timeZone: calendar.timeZone))
    }

    /// A day, such as "Monday, September 7".
    func day(_ date: Date) -> String {
        date.formatted(
            Date.FormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone)
                .weekday(.wide).month(.wide).day())
    }

    /// A day without its weekday, such as "Aug 14".
    func shortDay(_ date: Date) -> String {
        date.formatted(
            Date.FormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone)
                .month(.abbreviated).day())
    }

    /// A count, such as "17".
    func count(_ value: Int) -> String {
        value.formatted(.number.locale(locale))
    }

    /// A drink and its quantity, such as "latte, 2 shots".
    func drink(_ type: DrinkType, quantity: Int) -> String {
        let count = quantity.formatted(.number.locale(locale))
        return "\(type.promptName), \(count) \(Self.unit(type.unit, quantity: quantity))"
    }

    private static func unit(_ unit: ServingUnit, quantity: Int) -> String {
        switch unit {
        case .shot: quantity == 1 ? "shot" : "shots"
        case .cup: quantity == 1 ? "cup" : "cups"
        case .can: quantity == 1 ? "can" : "cans"
        }
    }
}

extension DrinkType {
    /// The drink's name in a prompt for the language model.
    fileprivate var promptName: String {
        switch self {
        case .espresso: "espresso"
        case .americano: "americano"
        case .latte: "latte"
        case .cappuccino: "cappuccino"
        case .flatWhite: "flat white"
        case .dripCoffee: "drip coffee"
        case .coldBrew: "cold brew"
        case .instantCoffee: "instant coffee"
        case .blackTea: "black tea"
        case .greenTea: "green tea"
        case .matcha: "matcha"
        case .cola: "cola"
        case .energyDrink: "energy drink"
        }
    }
}
