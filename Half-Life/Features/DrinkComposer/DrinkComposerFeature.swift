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
/// and stays open with an error if the drink couldn't be saved. Above the drink tiles, a ``OneTapLogFeature`` row logs
/// a favourite in one tap, which closes the composer too. For each choice of drink, quantity, and time, it observes
/// the cutoff warning, which never stops the drink being logged. See the Drink Composer, One-Tap Log, and Caffeine
/// Cutoff articles.
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
        /// Why the chosen drink, at the time chosen, breaks the caffeine cutoff, or `nil` when it fits or until the
        /// first warning arrives. It never stops the drink being logged.
        var cutoffWarning: CutoffWarning?
        /// The one-tap row above the drink tiles.
        var oneTapLog = OneTapLogFeature.State()

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
        /// An action for the one-tap row.
        case oneTapLog(OneTapLogFeature.Action)
        /// The decay repository published the warning for the chosen drink, or `nil` when it fits.
        case cutoffWarningUpdated(CutoffWarning?)
    }

    private static let logger = Logger(for: DrinkComposerFeature.self)

    private enum CancelID {
        case cutoffWarning
    }

    @Dependency(\.observeLoggedDrinks) private var observeLoggedDrinks
    @Dependency(\.logDrink) private var logDrink
    @Dependency(\.dismiss) private var dismiss
    @Dependency(\.calendar) private var calendar
    @Dependency(\.observeCutoffWarning) private var observeCutoffWarning

    /// Reduces each action. It observes the drink log to open on the last drink logged, and logs the drink through
    /// ``LogDrinkUseCase`` when the user taps Add. It runs the one-tap row, and closes once the row logs a favourite.
    var body: some ReducerOf<Self> {
        Scope(state: \.oneTapLog, action: \.oneTapLog) {
            OneTapLogFeature()
        }
        Reduce { state, action in
            switch action {
            case .task:
                return .merge(
                    .run { [observeLoggedDrinks] send in
                        for await drinks in observeLoggedDrinks.execute(()) {
                            await send(.loggedDrinksUpdated(drinks))
                        }
                    },
                    observeWarning(for: state)
                )
            case let .loggedDrinksUpdated(drinks):
                guard !state.hasChosen, let latest = drinks.last else { return .none }
                state.selectedDrink = latest.type
                state.quantity = latest.quantity
                return observeWarning(for: state)
            case let .drinkSelected(drink):
                state.selectedDrink = drink
                state.quantity = drink.defaultQuantity
                state.hasChosen = true
                state.saveFailed = false
                return observeWarning(for: state)
            case .quantityIncremented:
                state.quantity += 1
                state.hasChosen = true
                return observeWarning(for: state)
            case .quantityDecremented:
                let before = state.quantity
                state.quantity = max(1, state.quantity - 1)
                state.hasChosen = true
                return state.quantity == before ? .none : observeWarning(for: state)
            case let .consumedWhenSelected(when):
                state.consumedWhen = when
                return observeWarning(for: state)
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
            case let .cutoffWarningUpdated(warning):
                state.cutoffWarning = warning
                return .none
            case .oneTapLog(.delegate(.drinkLogged)):
                return .run { [dismiss] _ in await dismiss() }
            case .oneTapLog:
                return .none
            }
        }
    }

    /// Observes the cutoff warning for the chosen drink, quantity, and time, in place of the last choice's.
    private func observeWarning(for state: State) -> Effect<Action> {
        let input = ObserveCutoffWarningUseCase.Input(
            drink: FavouriteDrink(type: state.selectedDrink, quantity: state.quantity),
            secondsAgo: state.consumedWhen.secondsAgo, calendar: calendar)
        return .run { [observeCutoffWarning] send in
            for await warning in observeCutoffWarning.execute(input) {
                await send(.cutoffWarningUpdated(warning))
            }
        }
        .cancellable(id: CancelID.cutoffWarning, cancelInFlight: true)
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
