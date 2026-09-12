//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life DailyGreetingFeature
//

import ComposableArchitecture
import Foundation

/// The Today screen's greeting: "Good afternoon, Alex" above today's date.
///
/// It observes the user's profile and the time of day, and reduces each value into `State`. Its only command is
/// ``Action/task``, which starts both observations. See the Today Screen article.
@Reducer nonisolated struct DailyGreetingFeature {
    /// What the greeting shows.
    @ObservableState
    struct State: Equatable {
        /// The user's first name, or `nil` until they've given it.
        var name: String?
        /// The current minute and its day period, or `nil` until the first minute arrives.
        var timeOfDay: TimeOfDay?
    }

    /// What can happen to the greeting.
    enum Action {
        /// Subscribes to the profile and the time of day, for as long as the view is on screen.
        case task
        /// The profile repository published the user's profile.
        case profileUpdated(UserProfile)
        /// A new minute arrived.
        case timeOfDayUpdated(TimeOfDay)
    }

    @Dependency(\.calendar) private var calendar
    @Dependency(\.observeUserProfile) private var observeUserProfile
    @Dependency(\.observeTimeOfDay) private var observeTimeOfDay

    /// Starts the observations, and reduces each value they emit into `State`.
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                return .merge(
                    .run { [observeUserProfile] send in
                        for await profile in observeUserProfile.execute(()) {
                            await send(.profileUpdated(profile))
                        }
                    },
                    .run { [observeTimeOfDay, calendar] send in
                        for await timeOfDay in observeTimeOfDay.execute(calendar) {
                            await send(.timeOfDayUpdated(timeOfDay))
                        }
                    }
                )
            case let .profileUpdated(profile):
                state.name = profile.name
                return .none
            case let .timeOfDayUpdated(timeOfDay):
                state.timeOfDay = timeOfDay
                return .none
            }
        }
    }
}
