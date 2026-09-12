//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life LastCupFeature
//

import ComposableArchitecture
import Foundation

/// The Today screen's "Last cup" tile: the latest time the user's usual drink still leaves little enough caffeine in
/// them at bedtime.
///
/// It observes the cutoff, and reduces each value into `State`. Its only command is ``Action/task``, which starts the
/// observation. The bedtime is a time of day in the calendar dependency, so it follows the user's time zone. See the
/// Caffeine Cutoff article.
@Reducer nonisolated struct LastCupFeature {
    /// What the tile shows.
    @ObservableState
    struct State: Equatable {
        /// The cutoff, or `nil` until the first one arrives.
        var cutoff: CaffeineCutoff?
    }

    /// What can happen to the tile.
    enum Action {
        /// Subscribes to the cutoff, for as long as the view is on screen.
        case task
        /// The decay repository published a cutoff.
        case cutoffUpdated(CaffeineCutoff)
    }

    @Dependency(\.calendar) private var calendar
    @Dependency(\.observeCaffeineCutoff) private var observeCaffeineCutoff

    /// Starts the observation, and reduces each cutoff it emits into `State`.
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                return .run { [observeCaffeineCutoff, calendar] send in
                    for await cutoff in observeCaffeineCutoff.execute(calendar) {
                        await send(.cutoffUpdated(cutoff))
                    }
                }
            case let .cutoffUpdated(cutoff):
                state.cutoff = cutoff
                return .none
            }
        }
    }
}
