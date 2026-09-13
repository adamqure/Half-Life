//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests AppFeatureSplashTests
//

import ComposableArchitecture
import Testing

@testable import Half_Life

/// Checks the root feature's launch against SPLASH-1 in the Splash Screen article.
@MainActor
struct AppFeatureSplashTests {

    static let unlocked = AppLock(isEnabled: false, isLocked: false)

    // MARK: - SPLASH-1: the root is launching until the first profile and the app lock have both arrived

    @Test func theRootIsLaunchingUntilTheProfileThenTheAppLockArrive() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }
        #expect(store.state.isLaunching)

        await store.send(.profileUpdated(UserProfile(hasCompletedOnboarding: true))) {
            $0.hasLoadedProfile = true
        }
        #expect(store.state.isLaunching)

        await store.send(.appLockUpdated(Self.unlocked)) {
            $0.appLock = Self.unlocked
        }
        #expect(!store.state.isLaunching)
    }

    @Test func theRootIsLaunchingUntilTheAppLockThenTheProfileArrive() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }

        await store.send(.appLockUpdated(Self.unlocked)) {
            $0.appLock = Self.unlocked
        }
        #expect(store.state.isLaunching)

        await store.send(.profileUpdated(UserProfile())) {
            $0.hasLoadedProfile = true
            $0.onboarding = OnboardingFeature.State()
        }
        #expect(!store.state.isLaunching)
    }
}
