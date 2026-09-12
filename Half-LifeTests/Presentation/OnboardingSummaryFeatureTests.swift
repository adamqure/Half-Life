//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests OnboardingSummaryFeatureTests
//

import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// Checks the summary, onboarding's last step.
@MainActor
struct OnboardingSummaryFeatureTests {

    static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()

    static func store(
        profiles: FakeUserProfileRepository, permissions: FakePermissionsRepository = FakePermissionsRepository()
    ) -> TestStoreOf<OnboardingSummaryFeature> {
        TestStore(initialState: OnboardingSummaryFeature.State()) {
            OnboardingSummaryFeature()
        } withDependencies: {
            $0.calendar = utc
            $0.observeUserProfile = ObserveUserProfileUseCase(repository: profiles)
            $0.observeRecommendedSleep = ObserveRecommendedSleepUseCase(repository: profiles)
            $0.observePermissions = ObservePermissionsUseCase(repository: permissions)
        }
    }

    @Test func taskReducesTheProfileIntoState() async {
        let profile = UserProfile(name: "Alex", halfLifeFactors: [.smokes])
        let store = Self.store(profiles: FakeUserProfileRepository(profiles: [profile]))

        await store.send(.task)
        await store.receive(\.profileUpdated) {
            $0.profile = profile
        }
        await store.finish()
    }

    @Test func taskReducesTheRecommendedSleepInTheUsersCalendar() async {
        let store = Self.store(
            profiles: FakeUserProfileRepository(recommendedSleeps: [.olderAdult], sleepCalendar: Self.utc))

        await store.send(.task)
        await store.receive(\.recommendedSleepUpdated) {
            $0.recommendedSleep = .olderAdult
        }
        await store.finish()
    }

    @Test func taskReducesThePermissionsIntoState() async {
        let permissions = Permissions(health: .requested, notifications: .denied, biometrics: .unavailable)
        let store = Self.store(
            profiles: FakeUserProfileRepository(), permissions: FakePermissionsRepository(streamed: [permissions]))

        await store.send(.task)
        await store.receive(\.permissionsUpdated) {
            $0.permissions = permissions
        }
        await store.finish()
    }

    @Test func logMyFirstCupFinishesOnboardingAndAsksForTheComposer() async {
        let store = Self.store(profiles: FakeUserProfileRepository())

        await store.send(.logFirstCupTapped)
        await store.receive(\.delegate.finished, true)
    }

    @Test func takeMeToTodayFinishesOnboarding() async {
        let store = Self.store(profiles: FakeUserProfileRepository())

        await store.send(.takeMeToTodayTapped)
        await store.receive(\.delegate.finished, false)
    }
}
