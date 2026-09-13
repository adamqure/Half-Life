//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life IntentDialogFormat
//

import Foundation

/// Builds the sentences the App Intents say, from Domain values.
///
/// Amounts are whole milligrams, and times are clock times, in its calendar's time zone and locale (constitution
/// Article VII.3). Each sentence is one String Catalog key, so a translator sees it whole (VII.2), and its words match
/// the screen that shows the same figure. The intents are thin, so this is where their words are tested. See
/// INTENT-FORMAT-1 to INTENT-FORMAT-6 in the App Intents article.
nonisolated struct IntentDialogFormat: Sendable {
    /// The calendar whose time zone and locale the sentences use.
    let calendar: Calendar

    /// Creates a format for a calendar.
    ///
    /// - Parameter calendar: The calendar whose time zone and locale the sentences use.
    init(calendar: Calendar) {
        self.calendar = calendar
    }

    private var locale: Locale {
        calendar.locale ?? .autoupdatingCurrent
    }

    /// The prompt to open the app, when Ask Half-Life can't answer without Apple Intelligence.
    var needsApp: LocalizedStringResource {
        localized("Answers need Apple Intelligence. Open Half-Life to see your caffeine?")
    }

    /// What Ask Half-Life says as the app opens.
    var openingApp: LocalizedStringResource {
        localized("Opening Half-Life.")
    }

    /// An amount in whole milligrams, such as "85 mg".
    ///
    /// - Parameter milligrams: The amount, in milligrams.
    func amount(_ milligrams: Double) -> String {
        CaffeineFormat.milligrams(milligrams, locale: locale)
    }

    /// A clock time in the calendar's time zone, such as "10:30 PM".
    ///
    /// - Parameter date: The moment.
    func time(_ date: Date) -> String {
        var style = Date.FormatStyle.dateTime.hour().minute()
        style.locale = locale
        style.calendar = calendar
        style.timeZone = calendar.timeZone
        return date.formatted(style)
    }

    /// What was logged: "Logged Latte, 2 shots: about 125 mg."
    ///
    /// - Parameters:
    ///   - type: The drink.
    ///   - quantity: How many units of the drink.
    func logged(_ type: DrinkType, quantity: Int) -> LocalizedStringResource {
        let name = text(type.displayName)
        let units = text(type.unit.quantityText(quantity))
        let caffeine = amount(type.estimatedMilligrams(quantity: quantity))
        return localized("Logged \(name), \(units): about \(caffeine).")
    }

    /// The level now, and at the next bedtime, in the decay card's words: "About 85 mg in your system now. Down to
    /// about 34 mg by 10:30 PM." With no intake still counting, it's "Nothing in your system right now.", as the card
    /// says.
    ///
    /// - Parameter status: The caffeine status.
    func status(_ status: CaffeineStatus) -> LocalizedStringResource {
        guard !status.activeIntakes.isEmpty else {
            return localized("Nothing in your system right now.")
        }
        let now = amount(status.level.milligrams)
        guard let atBedtime = status.levelAtBedtime else {
            return localized("About \(now) in your system now.")
        }
        let later = amount(atBedtime.milligrams)
        let bedtime = time(atBedtime.date)
        return localized("About \(now) in your system now. Down to about \(later) by \(bedtime).")
    }

    /// The latest time for the usual drink, or that there's no more today.
    ///
    /// - Parameter cutoff: The cutoff.
    func cutoff(_ cutoff: CaffeineCutoff) -> LocalizedStringResource {
        let most = amount(cutoff.threshold.milligrams)
        let bedtime = time(cutoff.bedtime)
        guard let latestCup = cutoff.latestCup else {
            return localized("No more caffeine today if you want to be at \(most) or less by your \(bedtime) bedtime.")
        }
        let name = text(cutoff.drink.type.displayName)
        let units = text(cutoff.drink.type.unit.quantityText(cutoff.drink.quantity))
        let cup = time(latestCup)
        return localized(
            """
            Have your usual \(name), \(units), by \(cup) to be at \(most) or less by your \(bedtime) bedtime.
            """)
    }

    /// One day of the log: its total, and each drink with its time, marked when it's demo data. The day is "today",
    /// "yesterday", or its name.
    ///
    /// - Parameters:
    ///   - day: The day of the log.
    ///   - today: A moment in the current day.
    func day(_ day: DrinkLogDay, today: Date) -> LocalizedStringResource {
        let date = day.intake.day
        let isToday = calendar.isDate(date, inSameDayAs: today)
        let isYesterday =
            calendar.date(byAdding: .day, value: -1, to: today).map { calendar.isDate(date, inSameDayAs: $0) } ?? false
        guard !day.drinks.isEmpty else {
            if isToday {
                return localized("No drinks logged today.")
            }
            if isYesterday {
                return localized("No drinks logged yesterday.")
            }
            return localized("No drinks logged on \(dayName(date)).")
        }
        let total = amount(day.intake.milligrams)
        let drinks = day.drinks.map(item).formatted(.list(type: .and).locale(locale))
        if isToday {
            return localized("Today you've logged about \(total): \(drinks).")
        }
        if isYesterday {
            return localized("Yesterday you logged about \(total): \(drinks).")
        }
        return localized("On \(dayName(date)), you logged about \(total): \(drinks).")
    }

    /// Tonight's window to fall asleep in, and why it's there, in the Insights card's words.
    ///
    /// - Parameter window: Tonight's window.
    func sleepWindow(_ window: SleepWindow) -> LocalizedStringResource {
        let most = amount(window.threshold.milligrams)
        let bedtime = time(window.bedtime)
        guard let interval = window.window, let clearsAt = window.clearsAt else {
            return localized(
                """
                Caffeine should stay over \(most) until after noon tomorrow, so there's no good time to fall asleep \
                tonight.
                """)
        }
        let start = time(interval.start)
        let end = time(interval.end)
        if window.clearsBeforeBedtime {
            return localized(
                """
                Your best time to fall asleep is \(start) to \(end). Caffeine should be under \(most) by your \
                \(bedtime) bedtime.
                """)
        }
        let clears = time(clearsAt)
        return localized(
            """
            Your best time to fall asleep is \(start) to \(end). Caffeine should drop under \(most) at about \
            \(clears), after your \(bedtime) bedtime.
            """)
    }

    /// A drink in a day's list: "Latte (2 shots) at 8:10 AM", with ", from the demo data" when it's demo data.
    private func item(_ drink: LoggedDrink) -> String {
        let name = text(drink.type.displayName)
        let units = text(drink.type.unit.quantityText(drink.quantity))
        let clock = time(drink.consumedAt)
        guard drink.isDemo else {
            return text("\(name) (\(units)) at \(clock)")
        }
        return text("\(name) (\(units)) at \(clock), from the demo data")
    }

    /// A day's name, such as "Tuesday, September 1".
    private func dayName(_ date: Date) -> String {
        var style = Date.FormatStyle.dateTime.weekday(.wide).month(.wide).day()
        style.locale = locale
        style.calendar = calendar
        style.timeZone = calendar.timeZone
        return date.formatted(style)
    }

    /// The resource, looked up in the calendar's locale.
    private func localized(_ resource: LocalizedStringResource) -> LocalizedStringResource {
        var resource = resource
        resource.locale = locale
        return resource
    }

    /// The resource's text in the calendar's locale.
    private func text(_ resource: LocalizedStringResource) -> String {
        String(localized: localized(resource))
    }
}
