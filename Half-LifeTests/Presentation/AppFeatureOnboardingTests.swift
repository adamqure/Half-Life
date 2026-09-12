//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests AppFeatureOnboardingTests
//

import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// Checks how the root presents and dismisses onboarding (ONB-1 to ONB-3 in the Onboarding article).
@MainActor
struct AppFeatureOnboardingTests {

    // MARK: - ONB-2: nothing shows until the first profile arrives

    @Test func theRootStartsWithoutAProfile() {
        let state = AppFeature.State()

        #expect(!state.hasLoadedProfile)
        #expect(state.onboarding == nil)
    }

    // MARK: - ONB-1: onboarding shows while the profile isn't complete

    @Test func anIncompleteProfilePresentsOnboarding() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.observeUserProfile = ObserveUserProfileUseCase(
                repository: FakeUserProfileRepository(profiles: [UserProfile()]))
        }

        await store.send(.task)
        await store.receive(\.profileUpdated) {
            $0.hasLoadedProfile = true
            $0.onboarding = OnboardingFeature.State()
        }
        await store.finish()
    }

    @Test func aCompleteProfileShowsTheAppWithoutOnboarding() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.observeUserProfile = ObserveUserProfileUseCase(
                repository: FakeUserProfileRepository(profiles: [UserProfile(hasCompletedOnboarding: true)]))
        }

        await store.send(.task)
        await store.receive(\.profileUpdated) {
            $0.hasLoadedProfile = true
        }
        await store.finish()
    }

    @Test func completingTheProfileDismissesOnboarding() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.observeUserProfile = ObserveUserProfileUseCase(
                repository: FakeUserProfileRepository(profiles: [
                    UserProfile(), UserProfile(hasCompletedOnboarding: true),
                ]))
        }

        await store.send(.task)
        await store.receive(\.profileUpdated) {
            $0.hasLoadedProfile = true
            $0.onboarding = OnboardingFeature.State()
        }
        await store.receive(\.profileUpdated) {
            $0.onboarding = nil
        }
        await store.finish()
    }

    @Test func anotherIncompleteProfileLeavesOnboardingWhereItIs() async {
        let inProgress = OnboardingFeature.State(path: StackState([.aboutYou(AboutYouFeature.State())]))
        let store = TestStore(initialState: AppFeature.State(onboarding: inProgress, hasLoadedProfile: true)) {
            AppFeature()
        }

        await store.send(.profileUpdated(UserProfile(name: "Alex")))
    }

    // MARK: - ONB-3: finishing onboarding completes it, and "Log my first cup" opens the composer afterwards

    @Test func logMyFirstCupCompletesOnboardingThenOpensTheComposer() async {
        let repository = FakeUserProfileRepository()
        let store = TestStore(
            initialState: AppFeature.State(onboarding: OnboardingFeature.State(), hasLoadedProfile: true)
        ) {
            AppFeature()
        } withDependencies: {
            $0.completeOnboarding = CompleteOnboardingUseCase(repository: repository)
        }

        await store.send(.onboarding(.presented(.delegate(.finished(logFirstCup: true))))) {
            $0.opensComposerAfterOnboarding = true
        }
        await store.finish()
        #expect(await repository.completeCount == 1)

        await store.send(.profileUpdated(UserProfile(hasCompletedOnboarding: true))) {
            $0.onboarding = nil
        }
        await store.send(.onboardingDismissed) {
            $0.opensComposerAfterOnboarding = false
            $0.composer = DrinkComposerFeature.State()
        }
    }

    @Test func takeMeToTodayCompletesOnboardingWithoutTheComposer() async {
        let repository = FakeUserProfileRepository()
        let store = TestStore(
            initialState: AppFeature.State(onboarding: OnboardingFeature.State(), hasLoadedProfile: true)
        ) {
            AppFeature()
        } withDependencies: {
            $0.completeOnboarding = CompleteOnboardingUseCase(repository: repository)
        }

        await store.send(.onboarding(.presented(.delegate(.finished(logFirstCup: false)))))
        await store.finish()
        #expect(await repository.completeCount == 1)

        await store.send(.profileUpdated(UserProfile(hasCompletedOnboarding: true))) {
            $0.onboarding = nil
        }
        await store.send(.onboardingDismissed)
    }

    @Test func aFailedCompletionKeepsOnboardingAndForgetsTheComposer() async {
        let store = TestStore(
            initialState: AppFeature.State(onboarding: OnboardingFeature.State(), hasLoadedProfile: true)
        ) {
            AppFeature()
        } withDependencies: {
            $0.completeOnboarding = CompleteOnboardingUseCase(
                repository: FakeUserProfileRepository(error: FakeDataSourceError()))
        }

        await store.send(.onboarding(.presented(.delegate(.finished(logFirstCup: true))))) {
            $0.opensComposerAfterOnboarding = true
        }
        await store.receive(\.completeOnboardingFailed) {
            $0.opensComposerAfterOnboarding = false
        }
    }
}
