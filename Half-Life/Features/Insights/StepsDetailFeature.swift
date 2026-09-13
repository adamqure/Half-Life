//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life StepsDetailFeature
//

import ComposableArchitecture
import Foundation

/// The steps screen the Insights tab's steps button opens: the steps on days after a caffeine night, against the
/// other days, over the last 30 days.
///
/// It observes the comparison, and reduces each one into `State`. ``Action/task`` starts the observation, for as long
/// as the screen is on screen. See the Insights article.
@Reducer nonisolated struct StepsDetailFeature {
    /// What the screen shows.
    @ObservableState
    struct State: Equatable {
        /// The comparison, or `nil` until the first one arrives.
        var comparison: StepsComparison?
    }

    /// What can happen on the screen.
    enum Action {
        /// Subscribes to the comparison, for as long as the screen is on screen.
        case task
        /// The comparison changed.
        case comparisonUpdated(StepsComparison)
    }

    @Dependency(\.calendar) private var calendar
    @Dependency(\.observeStepsComparison) private var observeStepsComparison

    /// Starts the observation, and reduces each comparison it emits into `State`.
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                return .run { [observeStepsComparison, calendar] send in
                    for await comparison in observeStepsComparison.execute(calendar) {
                        await send(.comparisonUpdated(comparison))
                    }
                }
            case .comparisonUpdated(let comparison):
                state.comparison = comparison
                return .none
            }
        }
    }
}
