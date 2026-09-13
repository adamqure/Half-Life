//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests OnboardingFeatureTests
//

import ComposableArchitecture
import Testing

@testable import Half_Life

/// Checks the order of onboarding's steps (ONB-4 in the Onboarding article).
@MainActor
struct OnboardingFeatureTests {

    @Test func getStartedShowsAboutYou() async {
        let store = TestStore(initialState: OnboardingFeature.State()) {
            OnboardingFeature()
        }

        await store.send(.getStartedTapped) {
            $0.path[id: 0] = .aboutYou(AboutYouFeature.State())
        }
    }

    @Test func aboutYouContinuesToTheHalfLifeFactors() async {
        let store = TestStore(
            initialState: OnboardingFeature.State(path: StackState([.aboutYou(AboutYouFeature.State())]))
        ) {
            OnboardingFeature()
        }

        await store.send(.path(.element(id: 0, action: .aboutYou(.delegate(.continued))))) {
            $0.path[id: 1] = .halfLifeFactors(HalfLifeFactorsFeature.State())
        }
    }

    @Test func theHalfLifeFactorsContinueToTheBedtime() async {
        let store = TestStore(
            initialState: OnboardingFeature.State(
                path: StackState([.aboutYou(AboutYouFeature.State()), .halfLifeFactors(HalfLifeFactorsFeature.State())])
            )
        ) {
            OnboardingFeature()
        }

        await store.send(.path(.element(id: 1, action: .halfLifeFactors(.delegate(.continued))))) {
            $0.path[id: 2] = .bedtime(BedtimeFeature.State())
        }
    }

    @Test func theBedtimeContinuesToThePermissions() async {
        let store = TestStore(
            initialState: OnboardingFeature.State(path: StackState([.bedtime(BedtimeFeature.State())]))
        ) {
            OnboardingFeature()
        }

        // Onboarding's step turns the app lock on when Face ID is allowed (the App Lock article's ONB-LOCK).
        await store.send(.path(.element(id: 0, action: .bedtime(.delegate(.continued))))) {
            $0.path[id: 1] = .permissions(PermissionsFeature.State(turnsOnAppLock: true))
        }
    }

    @Test func thePermissionsContinueToSiriAndShortcuts() async {
        let store = TestStore(
            initialState: OnboardingFeature.State(path: StackState([.permissions(PermissionsFeature.State())]))
        ) {
            OnboardingFeature()
        }

        await store.send(.path(.element(id: 0, action: .permissions(.delegate(.continued))))) {
            $0.path[id: 1] = .siriShortcuts(SiriShortcutsFeature.State())
        }
    }

    @Test func siriAndShortcutsContinueToTheSummary() async {
        let store = TestStore(
            initialState: OnboardingFeature.State(path: StackState([.siriShortcuts(SiriShortcutsFeature.State())]))
        ) {
            OnboardingFeature()
        }

        await store.send(.path(.element(id: 0, action: .siriShortcuts(.delegate(.continued))))) {
            $0.path[id: 1] = .summary(OnboardingSummaryFeature.State())
        }
    }

    @Test func theSummaryFinishesOnboardingWithTheComposer() async {
        let store = TestStore(
            initialState: OnboardingFeature.State(path: StackState([.summary(OnboardingSummaryFeature.State())]))
        ) {
            OnboardingFeature()
        }

        await store.send(.path(.element(id: 0, action: .summary(.delegate(.finished(logFirstCup: true))))))
        await store.receive(\.delegate.finished, true)
    }

    @Test func theSummaryFinishesOnboardingWithoutTheComposer() async {
        let store = TestStore(
            initialState: OnboardingFeature.State(path: StackState([.summary(OnboardingSummaryFeature.State())]))
        ) {
            OnboardingFeature()
        }

        await store.send(.path(.element(id: 0, action: .summary(.delegate(.finished(logFirstCup: false))))))
        await store.receive(\.delegate.finished, false)
    }
}
