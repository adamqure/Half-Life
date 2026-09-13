//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests AppFeatureAppLockTests
//

import ComposableArchitecture
import Testing

@testable import Half_Life

/// Checks the root feature's app lock against ROOT-LOCK-1 to ROOT-LOCK-3 in the App Lock article.
@MainActor
struct AppFeatureAppLockTests {

    static let locked = AppLock(isEnabled: true, isLocked: true)
    static let unlocked = AppLock(isEnabled: true, isLocked: false)

    // MARK: - ROOT-LOCK-1: after onboarding, the lock screen shows while the app is locked

    @Test func theLockScreenShowsWhileTheAppIsLocked() async {
        let store = TestStore(initialState: AppFeature.State(hasLoadedProfile: true)) {
            AppFeature()
        } withDependencies: {
            $0.observeAppLock = ObserveAppLockUseCase(
                repository: FakeAppLockRepository(streamed: [Self.locked, Self.unlocked]))
        }

        await store.send(.appLockTask)
        await store.receive(\.appLockUpdated) {
            $0.appLock = Self.locked
            $0.lock = AppLockFeature.State()
        }
        await store.receive(\.appLockUpdated) {
            $0.appLock = Self.unlocked
            $0.lock = nil
        }
        await store.finish()
    }

    @Test func lockingDismissesTheComposer() async {
        let store = TestStore(
            initialState: AppFeature.State(composer: DrinkComposerFeature.State(), hasLoadedProfile: true)
        ) {
            AppFeature()
        }

        await store.send(.appLockUpdated(Self.locked)) {
            $0.appLock = Self.locked
            $0.lock = AppLockFeature.State()
            $0.composer = nil
        }
    }

    @Test func theLockScreenRunsInsideTheRoot() async {
        let repository = FakeAppLockRepository()
        let store = TestStore(
            initialState: AppFeature.State(
                hasLoadedProfile: true, appLock: Self.locked, lock: AppLockFeature.State(hasPrompted: true))
        ) {
            AppFeature()
        } withDependencies: {
            $0.unlockApp = UnlockAppUseCase(repository: repository)
        }

        await store.send(\.lock.unlockTapped) {
            $0.lock?.isUnlocking = true
        }
        await store.receive(\.lock.unlockFinished) {
            $0.lock?.isUnlocking = false
        }

        #expect(await repository.unlockCount == 1)
    }

    // MARK: - ROOT-LOCK-2: the lock screen waits for the profile and for onboarding to finish

    @Test func beforeTheProfileArrivesTheLockScreenWaits() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }

        await store.send(.appLockUpdated(Self.locked)) {
            $0.appLock = Self.locked
        }
        await store.send(.profileUpdated(UserProfile(hasCompletedOnboarding: true))) {
            $0.hasLoadedProfile = true
            $0.lock = AppLockFeature.State()
        }
    }

    @Test func duringOnboardingTheLockScreenWaits() async {
        let store = TestStore(
            initialState: AppFeature.State(onboarding: OnboardingFeature.State(), hasLoadedProfile: true)
        ) {
            AppFeature()
        }

        await store.send(.appLockUpdated(Self.locked)) {
            $0.appLock = Self.locked
        }
        await store.send(.profileUpdated(UserProfile(hasCompletedOnboarding: true))) {
            $0.onboarding = nil
            $0.lock = AppLockFeature.State()
        }
    }

    // MARK: - ROOT-LOCK-3: going to the background locks the app

    @Test func goingToTheBackgroundLocksTheApp() async {
        let repository = FakeAppLockRepository()
        let store = TestStore(initialState: AppFeature.State(hasLoadedProfile: true)) {
            AppFeature()
        } withDependencies: {
            $0.lockApp = LockAppUseCase(repository: repository)
        }

        await store.send(.enteredBackground)
        await store.finish()

        #expect(await repository.lockCount == 1)
    }
}
