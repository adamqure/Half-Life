//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life OnboardingSummaryFeature
//

import ComposableArchitecture
import Foundation

/// Onboarding's last step: what the user told the app, the recommended sleep, and each permission's status, with two
/// ways out.
///
/// "Log my first cup" and "Take me to Today" both finish onboarding. ``AppFeature`` completes it, and opens the drink
/// composer afterwards for the first. See the Onboarding article.
@Reducer nonisolated struct OnboardingSummaryFeature {
    /// The step's state.
    @ObservableState
    struct State: Equatable {
        /// The profile the repository last published, or `nil` until it arrives.
        var profile: UserProfile?
        /// The recommended sleep for the user's age, or `nil` until it arrives.
        var recommendedSleep: RecommendedSleep?
        /// The permissions, or `nil` until they arrive.
        var permissions: Permissions?
    }

    /// What can happen in the step.
    enum Action {
        /// The step appeared, so it starts observing what it summarizes.
        case task
        /// The repository published the profile.
        case profileUpdated(UserProfile)
        /// The repository published the recommended sleep.
        case recommendedSleepUpdated(RecommendedSleep)
        /// The repository published the permissions.
        case permissionsUpdated(Permissions)
        /// The user tapped "Log my first cup".
        case logFirstCupTapped
        /// The user tapped "Take me to Today".
        case takeMeToTodayTapped
        /// What the step tells onboarding.
        case delegate(Delegate)
    }

    /// What the step tells ``OnboardingFeature``.
    @CasePathable
    enum Delegate {
        /// The user left the summary. `logFirstCup` is whether they asked to log their first cup.
        case finished(logFirstCup: Bool)
    }

    @Dependency(\.calendar) var calendar
    @Dependency(\.observeUserProfile) var observeUserProfile
    @Dependency(\.observeRecommendedSleep) var observeRecommendedSleep
    @Dependency(\.observePermissions) var observePermissions

    /// Reduces what it observes into `State`, and finishes onboarding from either button.
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
                    .run { [observeRecommendedSleep, calendar] send in
                        for await range in observeRecommendedSleep.execute(calendar) {
                            await send(.recommendedSleepUpdated(range))
                        }
                    },
                    .run { [observePermissions] send in
                        for await permissions in observePermissions.execute(()) {
                            await send(.permissionsUpdated(permissions))
                        }
                    }
                )
            case let .profileUpdated(profile):
                state.profile = profile
                return .none
            case let .recommendedSleepUpdated(range):
                state.recommendedSleep = range
                return .none
            case let .permissionsUpdated(permissions):
                state.permissions = permissions
                return .none
            case .logFirstCupTapped:
                return .send(.delegate(.finished(logFirstCup: true)))
            case .takeMeToTodayTapped:
                return .send(.delegate(.finished(logFirstCup: false)))
            case .delegate:
                return .none
            }
        }
    }
}
