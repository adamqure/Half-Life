//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life SiriShortcutsFeature
//

import ComposableArchitecture

/// Onboarding's "Use Siri and Shortcuts" step: phrases to try with Siri, and a way to the Shortcuts app.
///
/// Half-Life's App Shortcuts work as soon as the app is installed, and App Intents need no permission, so the step
/// asks for nothing. It only moves on. See ONB-SIRI-1 in the Onboarding article, and the App Intents article.
@Reducer nonisolated struct SiriShortcutsFeature {
    /// The step holds no state: its phrases and button are fixed.
    @ObservableState
    struct State: Equatable {}

    /// What the user can do on the step.
    enum Action {
        /// The user tapped Continue.
        case continueTapped
        /// Tells onboarding what happened.
        case delegate(Delegate)
    }

    /// What onboarding hears from the step.
    @CasePathable
    enum Delegate: Equatable {
        /// The user moved on.
        case continued
    }

    /// Moves on when the user taps Continue.
    var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .continueTapped:
                return .send(.delegate(.continued))
            case .delegate:
                return .none
            }
        }
    }
}
