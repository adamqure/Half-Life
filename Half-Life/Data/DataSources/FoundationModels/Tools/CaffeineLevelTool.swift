//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life CaffeineLevelTool
//

import Foundation
import FoundationModels

/// `getCaffeineLevelAt`: the caffeine in the body the next time the clock shows a given time.
///
/// It reads the level from the curve ``CaffeineDecayRepository`` publishes, which covers the 12 hours either side of
/// now. A time further ahead is reported as out of reach (LMTOOL-3, LMTOOL-7).
struct CaffeineLevelTool: Tool {
    /// The time of day to report the level at.
    @Generable
    struct Arguments {
        /// The hour, on a 24-hour clock.
        @Guide(description: "The hour, on a 24-hour clock, from 0 to 23.", .range(0...23))
        let hour: Int
        /// The minute.
        @Guide(description: "The minute, from 0 to 59.", .range(0...59))
        let minute: Int
    }

    /// The repository the curve comes from.
    let caffeineDecay: any CaffeineDecayRepository
    /// The repository that gives the current time.
    let currentTime: any CurrentTimeRepository
    /// Formats the amounts and times, and finds the next time the clock shows the given time.
    let format: LanguageModelFormat

    /// The name the model calls the tool by.
    let name = "getCaffeineLevelAt"
    /// What the tool tells the model it does.
    let description = """
        Gets how much caffeine will be in the user's body the next time the clock shows a given time, up to 12 hours \
        ahead.
        """

    /// Reports the level at the next time the clock shows the given time.
    @concurrent func call(arguments: Arguments) async throws -> String {
        let calendar = format.calendar
        let time = DateComponents(hour: arguments.hour, minute: arguments.minute, second: 0)
        // The current minute counts, so the search starts just before it.
        guard let currentMinute = calendar.dateInterval(of: .minute, for: currentTime.now())?.start,
            let target = calendar.nextDate(
                after: currentMinute.addingTimeInterval(-1), matching: time, matchingPolicy: .nextTime),
            let curve = await caffeineDecay.curve().firstValue(), let last = curve.last
        else {
            return "The caffeine level isn't available."
        }
        guard target <= last.date, let level = curve.last(where: { $0.date <= target }) else {
            return "The caffeine curve only reaches 12 hours ahead, so the level at \(format.time(target)) isn't "
                + "available."
        }
        return "Caffeine in the body at \(format.time(target)): \(format.milligrams(level.milligrams))."
    }
}
