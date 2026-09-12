//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life DrinkComposerFeature
//

import ComposableArchitecture
import Foundation
import OSLog

/// The drink composer: choose a drink, set its quantity and when it was consumed, and log it.
///
/// A drink is always chosen. The composer opens on the last drink logged, with its quantity, or on one espresso shot
/// when nothing has been logged. ``AppFeature`` presents it as a sheet. It closes itself once the drink is logged,
/// and stays open with an error if the drink couldn't be saved. See the Drink Composer article.
@Reducer nonisolated struct DrinkComposerFeature {
    /// When the drink was consumed, as the composer offers it.
    enum ConsumedWhen: CaseIterable, Equatable, Sendable {
        /// Just now.
        case now
        /// An hour ago.
        case oneHourAgo
        /// Two hours ago.
        case twoHoursAgo
        /// Four hours ago.
        case fourHoursAgo

        /// How long ago, in seconds. ``LogDrinkUseCase`` subtracts it from the current time.
        var secondsAgo: TimeInterval {
            switch self {
            case .now: 0
            case .oneHourAgo: 3_600
            case .twoHoursAgo: 7_200
            case .fourHoursAgo: 14_400
            }
        }
    }

    /// What the composer shows.
    @ObservableState
    struct State: Equatable {
        /// The chosen drink. It starts as espresso, and becomes the last drink logged once the log arrives.
        var selectedDrink = DrinkType.espresso
        /// How many units of the chosen drink. At least 1.
        var quantity = DrinkType.espresso.defaultQuantity
        /// When the drink was consumed.
        var consumedWhen = ConsumedWhen.now
        /// Whether the user has chosen a drink or changed its quantity, so the last drink logged no longer replaces it.
        var hasChosen = false
        /// Whether the drink is being logged, so Add can't log it twice.
        var isLogging = false
        /// Whether the last attempt to log the drink failed.
        var saveFailed = false

        /// The chosen drink's estimated caffeine, in milligrams.
        var estimatedMilligrams: Double {
            selectedDrink.estimatedMilligrams(quantity: quantity)
        }
    }

    /// What can happen in the composer.
    enum Action {
        /// Subscribes to the drink log, for as long as the view is on screen.
        case task
        /// The drink log published its drinks, oldest first.
        case loggedDrinksUpdated([LoggedDrink])
        /// The user chose a drink.
        case drinkSelected(DrinkType)
        /// The user added one unit.
        case quantityIncremented
        /// The user removed one unit.
        case quantityDecremented
        /// The user said when the drink was consumed.
        case consumedWhenSelected(ConsumedWhen)
        /// The user tapped Add.
        case addTapped
        /// The drink was logged.
        case logSucceeded
        /// The drink couldn't be logged.
        case logFailed
        /// The user closed the composer without logging.
        case closeTapped
    }

    private static let logger = Logger(for: DrinkComposerFeature.self)

    @Dependency(\.observeLoggedDrinks) private var observeLoggedDrinks
    @Dependency(\.logDrink) private var logDrink
    @Dependency(\.dismiss) private var dismiss

    /// Reduces each action. It observes the drink log to open on the last drink logged, and logs the drink through
    /// ``LogDrinkUseCase`` when the user taps Add.
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                return .run { [observeLoggedDrinks] send in
                    for await drinks in observeLoggedDrinks.execute(()) {
                        await send(.loggedDrinksUpdated(drinks))
                    }
                }
            case let .loggedDrinksUpdated(drinks):
                guard !state.hasChosen, let latest = drinks.last else { return .none }
                state.selectedDrink = latest.type
                state.quantity = latest.quantity
                return .none
            case let .drinkSelected(drink):
                state.selectedDrink = drink
                state.quantity = drink.defaultQuantity
                state.hasChosen = true
                state.saveFailed = false
                return .none
            case .quantityIncremented:
                state.quantity += 1
                state.hasChosen = true
                return .none
            case .quantityDecremented:
                state.quantity = max(1, state.quantity - 1)
                state.hasChosen = true
                return .none
            case let .consumedWhenSelected(when):
                state.consumedWhen = when
                return .none
            case .addTapped:
                guard !state.isLogging else { return .none }
                state.isLogging = true
                state.saveFailed = false
                let input = LogDrinkUseCase.Input(
                    type: state.selectedDrink, quantity: state.quantity, secondsAgo: state.consumedWhen.secondsAgo)
                return .run { [logDrink] send in
                    try await logDrink.execute(input)
                    await send(.logSucceeded)
                } catch: { error, send in
                    Self.logFailure(error)
                    await send(.logFailed)
                }
            case .logSucceeded:
                state.isLogging = false
                return .run { [dismiss] _ in await dismiss() }
            case .logFailed:
                state.isLogging = false
                state.saveFailed = true
                return .none
            case .closeTapped:
                return .run { [dismiss] _ in await dismiss() }
            }
        }
    }

    /// Logs a failed save with the error's domain and code, and never the drink (constitution Article XI.6–7).
    private static func logFailure(_ error: any Error) {
        let nsError = error as NSError
        logger.error(
            """
            Logging a drink failed: \(nsError.domain, privacy: .public) \(nsError.code, privacy: .public), \
            \(nsError.localizedDescription, privacy: .private)
            """
        )
    }
}
