//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests DependencyRegistrationTests
//

import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// Checks the Today screen's dependency registrations (DEP-1 to DEP-3 in the Today Screen article, constitution
/// Article I.15).
///
/// Tests never read the `.live` context. These keys' preview values are their live values, so the `.preview` context
/// checks the same objects. None of these keys opens a store.
struct DependencyRegistrationTests {

    /// DEP-1: the profile repository is the app's live repository.
    @Test func previewUserProfileRepositoryIsTheLiveRepository() {
        withDependencies {
            $0.context = .preview
        } operation: {
            @Dependency(\.userProfileRepository) var repository
            #expect(repository is LiveUserProfileRepository)
        }
    }

    /// DEP-1: the current time repository is the app's live repository.
    @Test func previewCurrentTimeRepositoryIsTheLiveRepository() {
        withDependencies {
            $0.context = .preview
        } operation: {
            @Dependency(\.currentTimeRepository) var repository
            #expect(repository is LiveCurrentTimeRepository)
        }
    }

    /// DEP-2: a test that uses the current time repository without overriding it fails.
    @Test func testCurrentTimeRepositoryReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.currentTimeRepository) var repository
            for await _ in repository.currentTime() {}
        }
    }

    /// DEP-3: the use case observes the one app-scoped current time repository.
    @Test func previewObserveTimeOfDayUsesTheAppScopedRepository() {
        withDependencies {
            $0.context = .preview
        } operation: {
            @Dependency(\.currentTimeRepository) var repository
            @Dependency(\.observeTimeOfDay) var observeTimeOfDay
            #expect((observeTimeOfDay.currentTime as AnyObject) === (repository as AnyObject))
        }
    }

    /// DEP-2: a test that uses the profile repository without overriding it fails.
    @Test func testUserProfileRepositoryReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.userProfileRepository) var repository
            for await _ in repository.profile() {}
        }
    }

    /// DEP-2: a test that observes the time of day without overriding it fails.
    @Test func testObserveTimeOfDayReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.observeTimeOfDay) var observeTimeOfDay
            for await _ in observeTimeOfDay.execute(Calendar(identifier: .gregorian)) {}
        }
    }

    /// DEP-3: the use case observes the one app-scoped profile repository.
    @Test func previewObserveUserProfileUsesTheAppScopedRepository() {
        withDependencies {
            $0.context = .preview
        } operation: {
            @Dependency(\.userProfileRepository) var repository
            @Dependency(\.observeUserProfile) var observeUserProfile
            #expect((observeUserProfile.repository as AnyObject) === (repository as AnyObject))
        }
    }
}
