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
/// The greeting, the decay card, the "Today" and "Last cup" tiles, the one-tap row, and the history card are built so
/// far. The other drink-log cards join them as they're built. See the Today Screen article.
@Reducer nonisolated struct TodayFeature {
    /// The state of every card on the screen.
    @ObservableState
    struct State: Equatable {
        /// The greeting's state.
        var greeting = DailyGreetingFeature.State()
        /// The decay card's state.
        var caffeineDecay = CaffeineDecayFeature.State()
        /// The "Today" tile's state.
        var caffeineIntakeToday = CaffeineIntakeTodayFeature.State()
        /// The "Last cup" tile's state.
        var lastCup = LastCupFeature.State()
        /// The one-tap row's state.
        var oneTapLog = OneTapLogFeature.State()
        /// The history card's state.
        var history = DrinkLogHistoryFeature.State()
    }

    /// The actions of every card on the screen.
    enum Action {
        /// An action for the greeting.
        case greeting(DailyGreetingFeature.Action)
        /// An action for the decay card.
        case caffeineDecay(CaffeineDecayFeature.Action)
        /// An action for the "Today" tile.
        case caffeineIntakeToday(CaffeineIntakeTodayFeature.Action)
        /// An action for the "Last cup" tile.
        case lastCup(LastCupFeature.Action)
        /// An action for the one-tap row.
        case oneTapLog(OneTapLogFeature.Action)
        /// An action for the history card.
        case history(DrinkLogHistoryFeature.Action)
    }

    /// Runs each card's feature on its part of the state.
    var body: some ReducerOf<Self> {
        Scope(state: \.greeting, action: \.greeting) {
            DailyGreetingFeature()
        }
        Scope(state: \.caffeineDecay, action: \.caffeineDecay) {
            CaffeineDecayFeature()
        }
        Scope(state: \.caffeineIntakeToday, action: \.caffeineIntakeToday) {
            CaffeineIntakeTodayFeature()
        }
        Scope(state: \.lastCup, action: \.lastCup) {
            LastCupFeature()
        }
        Scope(state: \.oneTapLog, action: \.oneTapLog) {
            OneTapLogFeature()
        }
        Scope(state: \.history, action: \.history) {
            DrinkLogHistoryFeature()
        }
    }
}
