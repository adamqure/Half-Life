//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life DemoDataFeature
//

import ComposableArchitecture

/// Settings' Demo data screen: the demo drinks, and the demo Health data switch.
///
/// It's the screen Settings pushes for its Demo data row. It runs ``DemoHistoryFeature`` and ``DemoHealthDataFeature``
/// side by side, each on its own data, so the two demos stay independent. See the Settings and Apple Health Card
/// articles.
@Reducer nonisolated struct DemoDataFeature {
    /// The screen's state.
    @ObservableState
    struct State: Equatable {
        /// The demo drinks.
        var history = DemoHistoryFeature.State()
        /// The demo Health data switch.
        var health = DemoHealthDataFeature.State()
    }

    /// What can happen on the screen.
    enum Action {
        /// An action for the demo drinks.
        case history(DemoHistoryFeature.Action)
        /// An action for the demo Health data switch.
        case health(DemoHealthDataFeature.Action)
    }

    /// Runs the demo drinks and the demo Health data switch, each on its part of the state.
    var body: some ReducerOf<Self> {
        Scope(state: \.history, action: \.history) {
            DemoHistoryFeature()
        }
        Scope(state: \.health, action: \.health) {
            DemoHealthDataFeature()
        }
    }
}
