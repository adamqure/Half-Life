//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life CaffeineCutoffTool
//

import Foundation
import FoundationModels

/// `getCaffeineCutoff`: the latest time to have the usual drink and still be at or under the sleep threshold at
/// bedtime.
///
/// It reads the first cutoff ``CaffeineDecayRepository`` publishes, the same one the Last Cup tile shows (LMTOOL-2,
/// LMTOOL-7).
struct CaffeineCutoffTool: Tool {
    /// The tool takes no arguments.
    @Generable
    struct Arguments {}

    /// The repository the cutoff comes from.
    let caffeineDecay: any CaffeineDecayRepository
    /// Formats the amounts and times, in the calendar the cutoff is read in.
    let format: LanguageModelFormat

    /// The name the model calls the tool by.
    let name = "getCaffeineCutoff"
    /// What the tool tells the model it does.
    let description = """
        Gets the latest time today the user can have their usual drink and still have little enough caffeine left at \
        bedtime to sleep, or says there's no time left today.
        """

    /// Reports the current cutoff.
    @concurrent func call(arguments: Arguments) async throws -> String {
        guard let cutoff = await caffeineDecay.cutoff(in: format.calendar).firstValue() else {
            return "The cutoff isn't available."
        }
        let drink = format.drink(cutoff.drink.type, quantity: cutoff.drink.quantity)
        let limit = "\(format.milligrams(cutoff.threshold.milligrams)) at bedtime, \(format.time(cutoff.bedtime))"
        guard let latestCup = cutoff.latestCup else {
            return "There's no time left today to have the usual drink (\(drink)) and still be at or under \(limit)."
        }
        return "The latest time to have the usual drink (\(drink)) and still be at or under \(limit), is "
            + "\(format.time(latestCup))."
    }
}
