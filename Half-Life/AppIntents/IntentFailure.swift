//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life IntentFailure
//

import Foundation

/// Why an App Intent couldn't do what it was asked. Siri and Shortcuts show its message.
///
/// See INTENT-FAIL-1 in the App Intents article.
nonisolated enum IntentFailure: Error, Equatable, CustomLocalizedStringResourceConvertible {
    /// ``DrinkLogRule`` refused the drink.
    case notLogged(DrinkLogRule.Violation)
    /// The drink couldn't be stored.
    case saveFailed
    /// The figure asked for wasn't published.
    case unavailable
    /// The language model couldn't answer, for a reason other than being unavailable.
    case couldntAnswer

    /// What Siri and Shortcuts say.
    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .notLogged(.quantityBelowOne): "Half-Life can only log a quantity of 1 or more."
        case .notLogged(.consumedInFuture): "Half-Life can't log a drink in the future."
        case .saveFailed: "The drink couldn't be saved. Try again."
        case .unavailable: "That isn't available right now. Open Half-Life to see your caffeine."
        case .couldntAnswer: "Half-Life couldn't answer that. Try again."
        }
    }
}
