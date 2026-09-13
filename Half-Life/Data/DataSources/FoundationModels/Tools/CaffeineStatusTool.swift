//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life CaffeineStatusTool
//

import Foundation
import FoundationModels

/// `getCaffeineStatus`: the caffeine in the body now, the level at bedtime, and when the last drink is half gone.
///
/// It reads the first status ``CaffeineDecayRepository`` publishes, the same one the Today screen's decay card shows
/// (LMTOOL-1, LMTOOL-7).
struct CaffeineStatusTool: Tool {
    /// The tool takes no arguments.
    @Generable
    struct Arguments {}

    /// The repository the status comes from.
    let caffeineDecay: any CaffeineDecayRepository
    /// Formats the amounts and times, in the calendar the status is read in.
    let format: LanguageModelFormat

    /// The name the model calls the tool by.
    let name = "getCaffeineStatus"
    /// What the tool tells the model it does.
    let description = """
        Gets the caffeine in the user's body now, how much will be left at their bedtime, and when their last drink \
        is half gone.
        """

    /// Reports the current status.
    @concurrent func call(arguments: Arguments) async throws -> String {
        guard let status = await caffeineDecay.status(in: format.calendar).firstValue() else {
            return "The caffeine level isn't available."
        }
        var lines = ["Caffeine in the body now: \(format.milligrams(status.level.milligrams))."]
        if let atBedtime = status.levelAtBedtime {
            lines.append("At bedtime, \(format.time(atBedtime.date)): \(format.milligrams(atBedtime.milligrams)).")
        }
        if let halfGone = status.lastIntakeHalfGoneAt {
            lines.append("The last drink is half gone at \(format.time(halfGone)).")
        }
        return lines.joined(separator: "\n")
    }
}
