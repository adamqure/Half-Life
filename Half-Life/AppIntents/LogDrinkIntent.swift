//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life LogDrinkIntent
//

import AppIntents

#if !WIDGET_EXTENSION
    import ComposableArchitecture
    import OSLog
#endif

/// Logs a drink the user asked Siri, a shortcut, the Action Button, or the one-tap widget to log.
///
/// It logs through ``LogDrinkUseCase``, consumed now, like a one-tap favourite, and replies with what it logged. It
/// conforms to `LiveActivityIntent`, so a widget's button runs it in the app's process, not the widget extension's,
/// and the app stays the only process that writes the drink log (constitution Article I.18). See INTENT-LOG-1 to
/// INTENT-LOG-4 in the App Intents article.
///
/// The widget extension compiles it too, so the One tap widget's buttons can create it. There, under the
/// `WIDGET_EXTENSION` condition, it has no dependencies, and its `perform()` throws rather than logging (see the
/// Widgets article).
struct LogDrinkIntent: AppIntent, LiveActivityIntent {
    /// The intent's name in Shortcuts.
    static let title: LocalizedStringResource = "Log a Drink"
    /// What the intent does, for Shortcuts and Apple Intelligence.
    static let description: IntentDescription? = IntentDescription("Logs a drink in Half-Life, as drunk now.")
    /// It runs in the background, so logging never opens the app.
    static let supportedModes: IntentModes = .background
    /// It runs only on an unlocked phone, because a drink is health data.
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresLocalDeviceAuthentication

    /// The drink. Siri asks for it when the phrase doesn't name one.
    @Parameter(title: "Drink") var drink: DrinkTypeAppEnum
    /// How many shots, cups, or cans. Without one, it's the drink's usual quantity.
    @Parameter(title: "Quantity") var quantity: Int?

    #if !WIDGET_EXTENSION
        // App Intents' `Dependency` typealias shadows swift-dependencies' inside an intent, so the module is named.
        @Dependencies.Dependency(\.calendar) private var calendar
        @Dependencies.Dependency(\.logDrink) private var logDrink

        private static let logger = Logger(for: LogDrinkIntent.self)
    #endif

    /// Creates an intent with no drink, as App Intents requires.
    init() {}

    /// Creates an intent for a drink and quantity, for the one-tap widget's button.
    ///
    /// - Parameters:
    ///   - drink: The drink.
    ///   - quantity: How many units of the drink.
    init(drink: DrinkTypeAppEnum, quantity: Int) {
        self.drink = drink
        self.quantity = quantity
    }

    #if WIDGET_EXTENSION
        /// The widget extension never performs this intent: `LiveActivityIntent` makes the system perform it in the
        /// app's process, even from a widget's button. If it ever ran here, it throws rather than losing the drink.
        ///
        /// - Returns: Nothing. It always throws.
        /// - Throws: An error saying only the app logs drinks.
        func perform() async throws -> some IntentResult {
            guard Self.logsInThisProcess else { throw OnlyTheAppLogsDrinks() }
            return .result()
        }

        /// Whether this process logs drinks. The widget extension doesn't.
        private static var logsInThisProcess: Bool { false }

        /// The error the widget extension throws if the system ever performs the intent there.
        private struct OnlyTheAppLogsDrinks: Error {}
    #else
        /// Logs the drink, consumed now.
        ///
        /// - Returns: What was logged, as a dialog.
        /// - Throws: ``IntentFailure/notLogged(_:)`` when ``DrinkLogRule`` refuses the drink, or
        ///   ``IntentFailure/saveFailed`` when it couldn't be stored.
        func perform() async throws -> some IntentResult & ProvidesDialog {
        let type = drink.drinkType
        let quantity = quantity ?? type.defaultQuantity
        do {
            try await logDrink.execute(LogDrinkUseCase.Input(type: type, quantity: quantity, secondsAgo: 0))
        } catch let violation as DrinkLogRule.Violation {
            throw IntentFailure.notLogged(violation)
        } catch {
            let error = error as NSError
            Self.logger.error(
                """
                Couldn't log a drink: \(error.domain, privacy: .public) \(error.code, privacy: .public) \
                \(error.localizedDescription, privacy: .private)
                """)
            throw IntentFailure.saveFailed
        }
        return .result(dialog: IntentDialog(IntentDialogFormat(calendar: calendar).logged(type, quantity: quantity)))
    }
    #endif
}
