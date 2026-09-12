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
import Foundation
import OSLog

/// The app's root feature: onboarding until the user's profile says it's complete, then the Today screen, with the
/// log button that presents the drink composer as a sheet.
///
/// Onboarding is presented and dismissed by the profile the root observes, not by the button that finishes it
/// (constitution Article I.5). See the Onboarding, Drink Composer, and Today Screen articles.
@Reducer nonisolated struct AppFeature {
    private static let logger = Logger(for: AppFeature.self)

    /// The root screen's state.
    @ObservableState
    struct State: Equatable {
        /// The Today screen.
        var today = TodayFeature.State()
        /// The drink composer, while it's presented.
        @Presents var composer: DrinkComposerFeature.State?
        /// Onboarding, while it's presented.
        @Presents var onboarding: OnboardingFeature.State?
        /// Whether the first profile has arrived. Until it has, the root shows only its background, so the Today screen
        /// never flashes up behind onboarding.
        var hasLoadedProfile = false
        /// Whether the user asked to log their first cup, so the composer opens once onboarding is dismissed.
        var opensComposerAfterOnboarding = false
    }

    /// What can happen on the root screen.
    enum Action {
        /// An action for the Today screen.
        case today(TodayFeature.Action)
        /// An action for the presented drink composer, or its dismissal.
        case composer(PresentationAction<DrinkComposerFeature.Action>)
        /// An action for presented onboarding, or its dismissal.
        case onboarding(PresentationAction<OnboardingFeature.Action>)
        /// The user tapped the log button.
        case logButtonTapped
        /// The root screen appeared, so it starts observing the profile.
        case task
        /// The repository published the profile.
        case profileUpdated(UserProfile)
        /// Onboarding's full-screen cover finished animating away.
        case onboardingDismissed
        /// Onboarding couldn't be recorded as complete, so it stays.
        case completeOnboardingFailed
    }

    @Dependency(\.observeUserProfile) var observeUserProfile
    @Dependency(\.completeOnboarding) var completeOnboarding

    /// Runs the Today screen, onboarding, and the composer, and presents onboarding while the profile isn't complete.
    var body: some ReducerOf<Self> {
        Scope(state: \.today, action: \.today) {
            TodayFeature()
        }
        Reduce { state, action in
            switch action {
            case .logButtonTapped:
                state.composer = DrinkComposerFeature.State()
                return .none
            case .task:
                return .run { [observeUserProfile] send in
                    for await profile in observeUserProfile.execute(()) {
                        await send(.profileUpdated(profile))
                    }
                }
            case let .profileUpdated(profile):
                state.hasLoadedProfile = true
                if profile.hasCompletedOnboarding {
                    state.onboarding = nil
                } else if state.onboarding == nil {
                    state.onboarding = OnboardingFeature.State()
                }
                return .none
            case let .onboarding(.presented(.delegate(.finished(logFirstCup)))):
                state.opensComposerAfterOnboarding = logFirstCup
                return .run { [completeOnboarding] _ in
                    try await completeOnboarding.execute(())
                } catch: { error, send in
                    let domain = (error as NSError).domain
                    let code = (error as NSError).code
                    Self.logger.error(
                        "Couldn't complete onboarding: \(domain, privacy: .public) \(code, privacy: .public)"
                    )
                    await send(.completeOnboardingFailed)
                }
            case .onboardingDismissed:
                guard state.opensComposerAfterOnboarding else { return .none }
                state.opensComposerAfterOnboarding = false
                state.composer = DrinkComposerFeature.State()
                return .none
            case .completeOnboardingFailed:
                state.opensComposerAfterOnboarding = false
                return .none
            case .today, .composer, .onboarding:
                return .none
            }
        }
        .ifLet(\.$composer, action: \.composer) {
            DrinkComposerFeature()
        }
        .ifLet(\.$onboarding, action: \.onboarding) {
            OnboardingFeature()
        }
    }
}
