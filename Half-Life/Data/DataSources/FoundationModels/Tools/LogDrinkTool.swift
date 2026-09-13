//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life LogDrinkTool
//

import Foundation
import FoundationModels

/// `logDrink`: logs a drink the user says they had. Only an App Intent's session gets it.
///
/// It logs through ``LogDrinkUseCase``, like the composer and one-tap favourites, so ``DrinkLogRule`` checks the
/// drink. The tool is built for one instruction, so its use case lives only that long (LMTOOL-5, LMTOOL-6).
struct LogDrinkTool: Tool {
    /// The drink to log.
    @Generable
    struct Arguments {
        /// Which drink.
        @Guide(description: "The drink the user had.")
        let drink: GeneratedDrinkType
        /// How many servings of the drink's unit.
        @Guide(
            description: "How many servings: shots for espresso drinks, cups for brewed coffee and tea, cans for cola.",
            .range(1...10))
        let quantity: Int
        /// How long ago the user had it.
        @Guide(description: "How many minutes ago the user had it: 0 is now.", .range(0...720))
        let minutesAgo: Int
    }

    /// Logs the drink.
    let logDrink: LogDrinkUseCase
    /// The repository that gives the current time, for the time the tool reports.
    let currentTime: any CurrentTimeRepository
    /// Formats the amount and time it reports.
    let format: LanguageModelFormat

    /// The name the model calls the tool by.
    let name = "logDrink"
    /// What the tool tells the model it does.
    let description = "Logs a drink the user says they had, and reports what was logged."

    /// Logs the drink, and reports what was logged, or why it wasn't.
    @concurrent func call(arguments: Arguments) async throws -> String {
        let type = arguments.drink.drinkType
        let secondsAgo = TimeInterval(arguments.minutesAgo) * 60
        let consumedAt = currentTime.now().addingTimeInterval(-secondsAgo)
        do {
            try await logDrink.execute(
                LogDrinkUseCase.Input(type: type, quantity: arguments.quantity, secondsAgo: secondsAgo))
        } catch let violation as DrinkLogRule.Violation {
            switch violation {
            case .quantityBelowOne: return "Not logged: the quantity has to be at least 1."
            case .consumedInFuture: return "Not logged: a drink can't be logged in the future."
            }
        }
        let caffeine = format.milligrams(type.estimatedMilligrams(quantity: arguments.quantity))
        return "Logged \(format.drink(type, quantity: arguments.quantity)), \(caffeine), at \(format.time(consumedAt))."
    }
}
