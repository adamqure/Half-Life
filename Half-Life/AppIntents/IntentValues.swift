//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life IntentValues
//

import AppIntents
import Foundation

/// The caffeine status as a value a shortcut can use: what ``GetCaffeineStatusIntent`` returns.
///
/// Amounts are whole milligrams. See INTENT-VALUE-1 in the App Intents article.
struct CaffeineStatusEntity: TransientAppEntity {
    /// What Shortcuts calls the value.
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Caffeine Level"

    /// The caffeine in the body now, in whole milligrams.
    @Property(title: "Caffeine now (mg)") var milligramsNow: Int
    /// The caffeine at the next bedtime, in whole milligrams, if there's a next bedtime.
    @Property(title: "Caffeine at bedtime (mg)") var milligramsAtBedtime: Int?
    /// The next bedtime, if there is one.
    @Property(title: "Bedtime") var bedtime: Date?

    /// How Shortcuts shows the value: the caffeine now.
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(CaffeineFormat.milligrams(Double(milligramsNow))) now")
    }

    /// Creates an empty value, as App Intents requires.
    init() {}

    /// Creates the value of a status.
    ///
    /// - Parameter status: The caffeine status.
    init(_ status: CaffeineStatus) {
        self.init()
        milligramsNow = Int(status.level.milligrams.rounded())
        milligramsAtBedtime = status.levelAtBedtime.map { Int($0.milligrams.rounded()) }
        bedtime = status.levelAtBedtime?.date
    }
}

/// The last cup as a value a shortcut can use: what ``GetLastCupIntent`` returns.
///
/// See INTENT-VALUE-2 in the App Intents article.
struct CaffeineCutoffEntity: TransientAppEntity {
    /// What Shortcuts calls the value.
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Last Cup"

    /// The usual drink's name.
    @Property(title: "Usual drink") var drink: String
    /// How many shots, cups, or cans the usual drink is.
    @Property(title: "Quantity") var quantity: Int
    /// The latest time to have the usual drink, or `nil` when there's no more today.
    @Property(title: "Latest cup") var latestCup: Date?
    /// The bedtime the cutoff is for.
    @Property(title: "Bedtime") var bedtime: Date
    /// The most caffeine the cutoff allows at bedtime, in whole milligrams.
    @Property(title: "Most caffeine at bedtime (mg)") var thresholdMilligrams: Int

    /// How Shortcuts shows the value, in the "Last cup" tile's words: "By 2:30 PM", or "No more today".
    var displayRepresentation: DisplayRepresentation {
        guard let latestCup else {
            return DisplayRepresentation(title: "No more today")
        }
        return DisplayRepresentation(title: "By \(latestCup.formatted(date: .omitted, time: .shortened))")
    }

    /// Creates an empty value, as App Intents requires.
    init() {}

    /// Creates the value of a cutoff.
    ///
    /// - Parameter cutoff: The cutoff.
    init(_ cutoff: CaffeineCutoff) {
        self.init()
        drink = String(localized: cutoff.drink.type.displayName)
        quantity = cutoff.drink.quantity
        latestCup = cutoff.latestCup
        bedtime = cutoff.bedtime
        thresholdMilligrams = Int(cutoff.threshold.milligrams.rounded())
    }
}

/// A day's caffeine as a value a shortcut can use: what ``GetCaffeineIntakeIntent`` returns.
///
/// See INTENT-VALUE-3 in the App Intents article.
struct CaffeineIntakeEntity: TransientAppEntity {
    /// What Shortcuts calls the value.
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Caffeine Intake"

    /// The day's midnight.
    @Property(title: "Day") var day: Date
    /// The caffeine in the day's drinks, in whole milligrams.
    @Property(title: "Caffeine (mg)") var milligrams: Int
    /// How many drinks were logged that day.
    @Property(title: "Drinks") var drinkCount: Int

    /// How Shortcuts shows the value: the day's caffeine.
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(CaffeineFormat.milligrams(Double(milligrams))) logged")
    }

    /// Creates an empty value, as App Intents requires.
    init() {}

    /// Creates the value of a day of the log.
    ///
    /// - Parameter logDay: The day of the log.
    init(_ logDay: DrinkLogDay) {
        self.init()
        day = logDay.intake.day
        milligrams = Int(logDay.intake.milligrams.rounded())
        drinkCount = logDay.drinks.count
    }
}

/// Tonight's sleep time as a value a shortcut can use: what ``GetSleepTimeIntent`` returns.
///
/// See INTENT-VALUE-4 in the App Intents article.
struct SleepTimeEntity: TransientAppEntity {
    /// What Shortcuts calls the value.
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Sleep Time"

    /// When the window to fall asleep in starts, or `nil` when caffeine doesn't clear.
    @Property(title: "Window start") var windowStart: Date?
    /// When the window ends, or `nil` when caffeine doesn't clear.
    @Property(title: "Window end") var windowEnd: Date?
    /// When caffeine falls under the sleep threshold for good, or `nil` when it doesn't by noon.
    @Property(title: "Caffeine clears") var clearsAt: Date?
    /// Tonight's bedtime.
    @Property(title: "Bedtime") var bedtime: Date

    /// How Shortcuts shows the value, in the Insights card's words: the window's times, or "Not tonight".
    var displayRepresentation: DisplayRepresentation {
        guard let start = windowStart, let end = windowEnd else {
            return DisplayRepresentation(title: "Not tonight")
        }
        let startTime = start.formatted(date: .omitted, time: .shortened)
        let endTime = end.formatted(date: .omitted, time: .shortened)
        return DisplayRepresentation(title: "\(startTime) – \(endTime)")
    }

    /// Creates an empty value, as App Intents requires.
    init() {}

    /// Creates the value of tonight's window.
    ///
    /// - Parameter window: Tonight's window.
    init(_ window: SleepWindow) {
        self.init()
        windowStart = window.window?.start
        windowEnd = window.window?.end
        clearsAt = window.clearsAt
        bedtime = window.bedtime
    }
}
