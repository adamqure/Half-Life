//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests OnboardingDependencyTests
//

import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// Checks onboarding's registrations and the UI tests' starting profiles (DEP-2, DEP-3, and LAUNCH-2).
struct OnboardingDependencyTests {

    /// DEP-3: each onboarding use case holds the one app-scoped profile repository.
    @Test func previewOnboardingUseCasesUseTheAppScopedRepositories() {
        withDependencies {
            $0.context = .preview
        } operation: {
            @Dependency(\.userProfileRepository) var repository
            @Dependency(\.currentTimeRepository) var currentTime
            @Dependency(\.saveAboutYou) var saveAboutYou
            @Dependency(\.saveHalfLifeFactors) var saveHalfLifeFactors
            @Dependency(\.saveBedtime) var saveBedtime
            @Dependency(\.completeOnboarding) var completeOnboarding
            @Dependency(\.observeRecommendedSleep) var observeRecommendedSleep

            #expect((saveAboutYou.profile as AnyObject) === (repository as AnyObject))
            #expect((saveAboutYou.currentTime as AnyObject) === (currentTime as AnyObject))
            #expect((saveHalfLifeFactors.repository as AnyObject) === (repository as AnyObject))
            #expect((saveBedtime.repository as AnyObject) === (repository as AnyObject))
            #expect((completeOnboarding.repository as AnyObject) === (repository as AnyObject))
            #expect((observeRecommendedSleep.repository as AnyObject) === (repository as AnyObject))
        }
    }

    /// DEP-2: saving through the profile repository in a test that hasn't overridden it reports an issue.
    @Test func testSavesReportAnIssue() async {
        await withKnownIssue {
            @Dependency(\.saveBedtime) var saveBedtime
            try await saveBedtime.execute(.standard)
        }
        await withKnownIssue {
            @Dependency(\.completeOnboarding) var completeOnboarding
            try await completeOnboarding.execute(())
        }
        await withKnownIssue {
            @Dependency(\.observeRecommendedSleep) var observeRecommendedSleep
            for await _ in observeRecommendedSleep.execute(Calendar(identifier: .gregorian)) {}
        }
    }

    /// DEP-2: the profile data source reports an issue when a test reaches it.
    @Test func testProfileDataSourceReportsAnIssue() async {
        await withKnownIssue {
            _ = try await ProfileDataSourceKey.testValue.storedProfile()
        }
    }

    // MARK: - LAUNCH-2: a UI test's starting profile

    @Test func aUITestWithACompletedProfileStartsPastOnboarding() async throws {
        let source = ProfileDataSourceKey.makeLiveValue(
            configuration: UITestLaunchConfiguration(
                environment: [LaunchEnvironmentKey.profile: LaunchEnvironmentKey.completed]))

        #expect(try await source.storedProfile() == UserProfile(hasCompletedOnboarding: true))
    }

    @Test func aUITestWithAFreshProfileStartsWithNothingSaved() async throws {
        let source = ProfileDataSourceKey.makeLiveValue(
            configuration: UITestLaunchConfiguration(environment: [
                LaunchEnvironmentKey.profile: LaunchEnvironmentKey.fresh
            ]))

        #expect(try await source.storedProfile() == nil)
    }

    @Test func previewsStartPastOnboarding() async throws {
        #expect(try await ProfileDataSourceKey.previewValue.storedProfile()?.hasCompletedOnboarding == true)
    }
}
