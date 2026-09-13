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

/// The app's root feature: onboarding until the user's profile says it's complete, then the Today, Insights, and
/// Settings tabs, with the log button that presents the drink composer as a sheet, and the lock screen in their place
/// while the app lock has locked the app.
///
/// Onboarding is presented and dismissed by the profile the root observes, not by the button that finishes it
/// (constitution Article I.5). The lock screen comes and goes the same way, from the app lock the root observes, and
/// only once onboarding is complete. See the Onboarding, Drink Composer, Today Screen, Settings, and App Lock articles.
@Reducer nonisolated struct AppFeature {
    private static let logger = Logger(for: AppFeature.self)

    /// The root screen's state.
    @ObservableState
    struct State: Equatable {
        /// The Today screen.
        var today = TodayFeature.State()
        /// The Insights tab.
        var insights = InsightsFeature.State()
        /// The Settings tab.
        var settings = SettingsFeature.State()
        /// The drink composer, while it's presented.
        @Presents var composer: DrinkComposerFeature.State?
        /// Onboarding, while it's presented.
        @Presents var onboarding: OnboardingFeature.State?
        /// Whether the first profile has arrived. Until it has, the root shows the splash screen, so the Today screen
        /// never flashes up behind onboarding.
        var hasLoadedProfile = false
        /// Whether the user asked to log their first cup, so the composer opens once onboarding is dismissed.
        var opensComposerAfterOnboarding = false
        /// The app lock the repository last published, or `nil` until it arrives. Until it has, the root shows the
        /// splash screen, so the Today screen never flashes up before the lock screen.
        var appLock: AppLock?
        /// The lock screen, while the app is locked and onboarding is complete.
        var lock: AppLockFeature.State?
        /// The cutoff reminder, which has no screen.
        var cutoffReminder = CutoffReminderFeature.State()

        /// Whether the app is still launching: the first profile or the app lock hasn't arrived yet. Until both have,
        /// the root shows the splash screen, so the Today screen never flashes up behind onboarding or before the lock
        /// screen (see the Splash Screen article).
        var isLaunching: Bool {
            !hasLoadedProfile || appLock == nil
        }
    }

    /// What can happen on the root screen.
    enum Action {
        /// An action for the Today screen.
        case today(TodayFeature.Action)
        /// An action for the Insights tab.
        case insights(InsightsFeature.Action)
        /// An action for the Settings tab.
        case settings(SettingsFeature.Action)
        /// An action for the presented drink composer, or its dismissal.
        case composer(PresentationAction<DrinkComposerFeature.Action>)
        /// An action for presented onboarding, or its dismissal.
        case onboarding(PresentationAction<OnboardingFeature.Action>)
        /// An action for the lock screen.
        case lock(AppLockFeature.Action)
        /// An action for the cutoff reminder.
        case cutoffReminder(CutoffReminderFeature.Action)
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
        /// The root screen appeared, so it starts observing the app lock.
        case appLockTask
        /// The repository published the app lock.
        case appLockUpdated(AppLock)
        /// The app went to the background, so it locks, if the lock is on.
        case enteredBackground
        /// The app launched, so it keeps the Home Screen widgets current for as long as it runs, even when the system
        /// launched it in the background to log a drink from a widget (WAPP-1 in the Widgets article). It also keeps
        /// the caffeine tolerance current, which the cutoff reads as the sleep threshold (TOLAPP-1 in the Insights
        /// article).
        case launched
    }

    @Dependency(\.observeUserProfile) var observeUserProfile
    @Dependency(\.completeOnboarding) var completeOnboarding
    @Dependency(\.observeAppLock) var observeAppLock
    @Dependency(\.lockApp) var lockApp
    @Dependency(\.keepWidgetsCurrent) var keepWidgetsCurrent
    @Dependency(\.keepSleepToleranceCurrent) var keepSleepToleranceCurrent

    /// Runs the Today screen, onboarding, the composer, the lock screen, and the cutoff reminder, and presents
    /// onboarding while the profile isn't complete.
    var body: some ReducerOf<Self> {
        Scope(state: \.today, action: \.today) {
            TodayFeature()
        }
        Scope(state: \.insights, action: \.insights) {
            InsightsFeature()
        }
        Scope(state: \.settings, action: \.settings) {
            SettingsFeature()
        }
        Scope(state: \.cutoffReminder, action: \.cutoffReminder) {
            CutoffReminderFeature()
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
                Self.showLockScreenWhileLocked(&state)
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
            case .appLockTask:
                return .run { [observeAppLock] send in
                    for await lock in observeAppLock.execute(()) {
                        await send(.appLockUpdated(lock))
                    }
                }
            case let .appLockUpdated(lock):
                state.appLock = lock
                Self.showLockScreenWhileLocked(&state)
                return .none
            case .enteredBackground:
                return .run { [lockApp] _ in
                    await lockApp.execute(())
                }
            case .launched:
                return .merge(
                    .run { [keepWidgetsCurrent] _ in
                        await keepWidgetsCurrent.execute(())
                    },
                    .run { [keepSleepToleranceCurrent] _ in
                        await keepSleepToleranceCurrent.execute(())
                    }
                )
            case .today, .insights, .settings, .composer, .onboarding, .lock, .cutoffReminder:
                return .none
            }
        }
        .ifLet(\.$composer, action: \.composer) {
            DrinkComposerFeature()
        }
        .ifLet(\.$onboarding, action: \.onboarding) {
            OnboardingFeature()
        }
        .ifLet(\.lock, action: \.lock) {
            AppLockFeature()
        }
    }

    /// Shows the lock screen while the app is locked, once the profile has arrived and onboarding is complete, and
    /// removes it once the app unlocks. Showing it dismisses the composer, whose sheet would otherwise sit above it.
    private static func showLockScreenWhileLocked(_ state: inout State) {
        let showsLockScreen = state.appLock?.isLocked == true && state.hasLoadedProfile && state.onboarding == nil
        if !showsLockScreen {
            state.lock = nil
        } else if state.lock == nil {
            state.lock = AppLockFeature.State()
            state.composer = nil
        }
    }
}
