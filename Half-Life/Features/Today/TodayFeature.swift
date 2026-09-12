//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life TodayFeature
//

import ComposableArchitecture

/// The Today screen, the app's root feature. It composes one child feature per card.
///
/// The greeting and the decay card are built so far. The drink-log cards join them as they're built. See the Today
/// Screen article.
@Reducer nonisolated struct TodayFeature {
    /// The state of every card on the screen.
    @ObservableState
    struct State: Equatable {
        /// The greeting's state.
        var greeting = DailyGreetingFeature.State()
        /// The decay card's state.
        var caffeineDecay = CaffeineDecayFeature.State()
    }

    /// The actions of every card on the screen.
    enum Action {
        /// An action for the greeting.
        case greeting(DailyGreetingFeature.Action)
        /// An action for the decay card.
        case caffeineDecay(CaffeineDecayFeature.Action)
    }

    /// Runs each card's feature on its part of the state.
    var body: some ReducerOf<Self> {
        Scope(state: \.greeting, action: \.greeting) {
            DailyGreetingFeature()
        }
        Scope(state: \.caffeineDecay, action: \.caffeineDecay) {
            CaffeineDecayFeature()
        }
    }
}
