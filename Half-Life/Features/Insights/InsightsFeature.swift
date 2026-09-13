//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life InsightsFeature
//

import ComposableArchitecture

/// The Insights tab. It composes one child feature per card, and pushes the Health data screens onto its navigation
/// stack.
///
/// The cards are "What we noticed", tonight's sleep window, the last 7 days, and the Health data buttons. Tapping a
/// Health data button pushes that kind's screen onto the `StackState` path (constitution Article I.6). See the Insights
/// article.
@Reducer nonisolated struct InsightsFeature {
    /// A screen pushed onto the Insights tab's navigation stack.
    @Reducer nonisolated enum Path {
        /// The Sleep screen, which the sleep button on the Health data card opens.
        case sleep(SleepDetailFeature)
        /// The steps screen, which the steps button on the Health data card opens.
        case steps(StepsDetailFeature)
        /// The resting heart rate screen, which its button on the Health data card opens.
        case restingHeartRate(HeartRateDetailFeature)
    }

    /// The state of every card on the tab.
    @ObservableState
    struct State: Equatable {
        /// The "What we noticed" card's state.
        var whatWeNoticed = WhatWeNoticedFeature.State()
        /// The sleep window card's state.
        var sleepWindow = SleepWindowFeature.State()
        /// The last 7 days card's state.
        var lastSevenDays = LastSevenDaysFeature.State()
        /// The Health data card's state.
        var healthData = HealthDataListFeature.State()
        /// The screens pushed after the tab's root, in order.
        var path = StackState<Path.State>()
    }

    /// The actions of every card on the tab.
    enum Action {
        /// An action for the "What we noticed" card.
        case whatWeNoticed(WhatWeNoticedFeature.Action)
        /// An action for the sleep window card.
        case sleepWindow(SleepWindowFeature.Action)
        /// An action for the last 7 days card.
        case lastSevenDays(LastSevenDaysFeature.Action)
        /// An action for the Health data card.
        case healthData(HealthDataListFeature.Action)
        /// An action for a pushed screen, or a change to the stack.
        case path(StackActionOf<Path>)
    }

    /// Runs each card's feature on its part of the state, pushes a Health data button's screen, and runs the pushed
    /// screens.
    var body: some ReducerOf<Self> {
        Scope(state: \.whatWeNoticed, action: \.whatWeNoticed) {
            WhatWeNoticedFeature()
        }
        Scope(state: \.sleepWindow, action: \.sleepWindow) {
            SleepWindowFeature()
        }
        Scope(state: \.lastSevenDays, action: \.lastSevenDays) {
            LastSevenDaysFeature()
        }
        Scope(state: \.healthData, action: \.healthData) {
            HealthDataListFeature()
        }
        Reduce { state, action in
            switch action {
            case .healthData(.kindTapped(.sleep)):
                state.path.append(.sleep(SleepDetailFeature.State()))
                return .none
            case .healthData(.kindTapped(.steps)):
                state.path.append(.steps(StepsDetailFeature.State()))
                return .none
            case .healthData(.kindTapped(.restingHeartRate)):
                state.path.append(.restingHeartRate(HeartRateDetailFeature.State()))
                return .none
            case .whatWeNoticed, .sleepWindow, .lastSevenDays, .healthData, .path:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}

/// Lets the Insights tab's `State`, which holds the pushed screens, be `Equatable`.
extension InsightsFeature.Path.State: Equatable {}
