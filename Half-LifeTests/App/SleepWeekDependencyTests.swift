//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests SleepWeekDependencyTests
//

import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// Checks the sleep week's registrations (constitution Article I.15, DEP-SLEEPWEEK in the Insights article). None of
/// these tests opens a store.
struct SleepWeekDependencyTests {

    /// A test that observes the sleep history without overriding the repository fails.
    @Test func testHealthDataRepositorySleepHistoryReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.healthDataRepository) var repository
            for await _ in repository.sleepHistory(days: 7, in: Calendar(identifier: .gregorian)) {}
        }
    }

    /// A test that observes the sleep week without overriding the use case fails.
    @Test func testObserveSleepWeekReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.observeSleepWeek) var observeSleepWeek
            for await _ in observeSleepWeek.execute(Calendar(identifier: .gregorian)) {}
        }
    }

    /// DEP-SLEEPWEEK: in previews, observing the sleep week uses the one app-scoped Health data repository.
    @Test func previewObserveSleepWeekUsesTheAppScopedRepository() {
        withDependencies {
            $0.context = .preview
        } operation: {
            @Dependency(\.healthDataRepository) var repository
            @Dependency(\.observeSleepWeek) var observeSleepWeek
            #expect((observeSleepWeek.repository as AnyObject) === (repository as AnyObject))
        }
    }
}
