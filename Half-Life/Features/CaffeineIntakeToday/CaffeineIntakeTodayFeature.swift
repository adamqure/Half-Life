//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life CaffeineIntakeTodayFeature
//

import ComposableArchitecture
import Foundation

/// The Today screen's "Today" tile: the caffeine logged so far today.
///
/// It observes today's intake, and reduces each value into `State`. Its only command is ``Action/task``, which starts
/// the observation. The day is the one in the calendar dependency, so it follows the user's time zone. See the Today
/// Screen article.
@Reducer nonisolated struct CaffeineIntakeTodayFeature {
    /// What the tile shows.
    @ObservableState
    struct State: Equatable {
        /// The caffeine logged today, or `nil` until the first intake arrives.
        var intake: DailyCaffeineIntake?
    }

    /// What can happen to the tile.
    enum Action {
        /// Subscribes to today's intake, for as long as the view is on screen.
        case task
        /// The drink log repository published today's intake.
        case intakeUpdated(DailyCaffeineIntake)
    }

    @Dependency(\.calendar) private var calendar
    @Dependency(\.observeCaffeineIntakeToday) private var observeCaffeineIntakeToday

    /// Starts the observation, and reduces each intake it emits into `State`.
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                return .run { [observeCaffeineIntakeToday, calendar] send in
                    for await intake in observeCaffeineIntakeToday.execute(calendar) {
                        await send(.intakeUpdated(intake))
                    }
                }
            case let .intakeUpdated(intake):
                state.intake = intake
                return .none
            }
        }
    }
}
