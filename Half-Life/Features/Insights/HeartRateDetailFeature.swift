//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life HeartRateDetailFeature
//

import ComposableArchitecture
import Foundation

/// The resting heart rate screen, which its button on the Insights tab's Health data card opens: the user's resting
/// heart rate on the days after a caffeine night, against the other days.
///
/// It observes the comparison, and reduces each value into `State`. Its only command is ``Action/task``, which starts
/// the observation for as long as the screen is on its stack. The days are in the calendar dependency, so they follow
/// the user's time zone. See the Insights article.
@Reducer nonisolated struct HeartRateDetailFeature {
    /// What the screen shows.
    @ObservableState
    struct State: Equatable {
        /// The comparison, or `nil` until the first one arrives.
        var comparison: RestingHeartRateComparison?
    }

    /// What can happen on the screen.
    enum Action {
        /// Subscribes to the comparison, for as long as the view is on screen.
        case task
        /// The use case published a comparison.
        case comparisonUpdated(RestingHeartRateComparison)
    }

    @Dependency(\.calendar) private var calendar
    @Dependency(\.observeRestingHeartRateComparison) private var observeComparison

    /// Starts the observation, and reduces each comparison it emits into `State`.
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                return .run { [observeComparison, calendar] send in
                    for await comparison in observeComparison.execute(calendar) {
                        await send(.comparisonUpdated(comparison))
                    }
                }
            case let .comparisonUpdated(comparison):
                state.comparison = comparison
                return .none
            }
        }
    }
}
