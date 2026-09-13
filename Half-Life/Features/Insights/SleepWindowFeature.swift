//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life SleepWindowFeature
//

import ComposableArchitecture
import Foundation

/// The Insights tab's "Best time to sleep tonight" card: when the caffeine already logged falls to the sleep threshold
/// tonight, and the 90 minutes to fall asleep in.
///
/// It observes the window, and reduces each value into `State`. Its only command is ``Action/task``, which starts the
/// observation. The night is in the calendar dependency, so it follows the user's time zone. See the Insights article.
@Reducer nonisolated struct SleepWindowFeature {
    /// What the card shows.
    @ObservableState
    struct State: Equatable {
        /// Tonight's window, or `nil` until the first one arrives.
        var window: SleepWindow?
    }

    /// What can happen to the card.
    enum Action {
        /// Subscribes to the window, for as long as the view is on screen.
        case task
        /// The decay repository published a window.
        case windowUpdated(SleepWindow)
    }

    @Dependency(\.calendar) private var calendar
    @Dependency(\.observeSleepWindow) private var observeSleepWindow

    /// Starts the observation, and reduces each window it emits into `State`.
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                return .run { [observeSleepWindow, calendar] send in
                    for await window in observeSleepWindow.execute(calendar) {
                        await send(.windowUpdated(window))
                    }
                }
            case let .windowUpdated(window):
                state.window = window
                return .none
            }
        }
    }
}
