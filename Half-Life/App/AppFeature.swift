//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life AppFeature
//

import ComposableArchitecture

/// The app's root feature: the Today screen, and the log button that presents the drink composer as a sheet.
///
/// See the Drink Composer and Today Screen articles.
@Reducer nonisolated struct AppFeature {
    /// The root screen's state.
    @ObservableState
    struct State: Equatable {
        /// The Today screen.
        var today = TodayFeature.State()
        /// The drink composer, while it's presented.
        @Presents var composer: DrinkComposerFeature.State?
    }

    /// What can happen on the root screen.
    enum Action {
        /// An action for the Today screen.
        case today(TodayFeature.Action)
        /// An action for the presented drink composer, or its dismissal.
        case composer(PresentationAction<DrinkComposerFeature.Action>)
        /// The user tapped the log button.
        case logButtonTapped
    }

    /// Runs the Today screen, presents the composer from the log button, and runs the composer while it's shown.
    var body: some ReducerOf<Self> {
        Scope(state: \.today, action: \.today) {
            TodayFeature()
        }
        Reduce { state, action in
            switch action {
            case .logButtonTapped:
                state.composer = DrinkComposerFeature.State()
                return .none
            case .today, .composer:
                return .none
            }
        }
        .ifLet(\.$composer, action: \.composer) {
            DrinkComposerFeature()
        }
    }
}
