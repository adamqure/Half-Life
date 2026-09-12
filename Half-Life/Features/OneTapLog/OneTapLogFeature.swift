//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life OneTapLogFeature
//

import ComposableArchitecture
import Foundation
import OSLog

/// The one-tap row: the user's three favourite drinks, each logged as consumed now in one tap.
///
/// It observes the favourites through ``ObserveFavouriteDrinksUseCase``, and logs a tapped favourite through
/// ``LogDrinkUseCase``. There's no confirmation step, so the tapped favourite shows as logged for
/// ``confirmationDuration``. ``TodayFeature`` and ``DrinkComposerFeature`` each compose one, and the composer closes
/// when its row tells it a drink was logged. See the One-Tap Log article.
@Reducer nonisolated struct OneTapLogFeature {
    /// What the row shows.
    @ObservableState
    struct State: Equatable {
        /// The favourites, most logged first, as the repository last published them.
        var favourites: [FavouriteDrink] = []
        /// The favourite being logged, so no tap logs a second drink until it's saved.
        var logging: FavouriteDrink?
        /// The favourite that was just logged, while its confirmation shows.
        var justLogged: FavouriteDrink?
        /// Whether the last attempt to log a favourite failed.
        var saveFailed = false
    }

    /// What can happen in the row.
    enum Action {
        /// Subscribes to the favourites, for as long as the view is on screen.
        case task
        /// The repository published the favourites, most logged first.
        case favouritesUpdated([FavouriteDrink])
        /// The user tapped a favourite.
        case favouriteTapped(FavouriteDrink)
        /// The favourite was logged.
        case logSucceeded(FavouriteDrink)
        /// The favourite couldn't be logged.
        case logFailed
        /// The confirmation's time is up.
        case confirmationEnded
        /// What the row tells the feature that composes it.
        case delegate(Delegate)
    }

    /// What the row tells the feature that composes it.
    @CasePathable
    enum Delegate {
        /// A favourite was logged.
        case drinkLogged
    }

    /// How long a logged favourite shows as logged.
    static let confirmationDuration = Duration.seconds(2)

    private enum CancelID {
        case confirmation
    }

    private static let logger = Logger(for: OneTapLogFeature.self)

    @Dependency(\.observeFavouriteDrinks) private var observeFavouriteDrinks
    @Dependency(\.logDrink) private var logDrink
    @Dependency(\.continuousClock) private var clock

    /// Reduces each action. It observes the favourites, and logs a tapped one as consumed now.
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                return .run { [observeFavouriteDrinks] send in
                    for await favourites in observeFavouriteDrinks.execute(()) {
                        await send(.favouritesUpdated(favourites))
                    }
                }
            case let .favouritesUpdated(favourites):
                state.favourites = favourites
                return .none
            case let .favouriteTapped(favourite):
                guard state.logging == nil else { return .none }
                state.logging = favourite
                state.saveFailed = false
                let input = LogDrinkUseCase.Input(type: favourite.type, quantity: favourite.quantity, secondsAgo: 0)
                return .run { [logDrink] send in
                    try await logDrink.execute(input)
                    await send(.logSucceeded(favourite))
                } catch: { error, send in
                    Self.logFailure(error)
                    await send(.logFailed)
                }
            case let .logSucceeded(favourite):
                state.logging = nil
                state.justLogged = favourite
                return .merge(
                    .send(.delegate(.drinkLogged)),
                    .run { [clock] send in
                        try await clock.sleep(for: Self.confirmationDuration)
                        await send(.confirmationEnded)
                    }
                    .cancellable(id: CancelID.confirmation, cancelInFlight: true)
                )
            case .logFailed:
                state.logging = nil
                state.saveFailed = true
                return .none
            case .confirmationEnded:
                state.justLogged = nil
                return .none
            case .delegate:
                return .none
            }
        }
    }

    /// Logs a failed save with the error's domain and code, and never the drink (constitution Article XI.6–7).
    private static func logFailure(_ error: any Error) {
        let nsError = error as NSError
        logger.error(
            """
            Logging a favourite failed: \(nsError.domain, privacy: .public) \(nsError.code, privacy: .public), \
            \(nsError.localizedDescription, privacy: .private)
            """
        )
    }
}
