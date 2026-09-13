//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests StepsComparisonDependencyTests
//

import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// Checks the steps comparison's registrations (constitution Article I.15, DEP-STEPS in the Insights article). None
/// of these tests opens a store.
struct StepsComparisonDependencyTests {

    /// A test that observes the step history without overriding the repository fails.
    @Test func testHealthDataRepositoryStepHistoryReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.healthDataRepository) var repository
            for await _ in repository.stepHistory(days: 30, in: Calendar(identifier: .gregorian)) {}
        }
    }

    /// A test that observes the steps comparison without overriding the use case fails.
    @Test func testObserveStepsComparisonReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.observeStepsComparison) var observeStepsComparison
            for await _ in observeStepsComparison.execute(Calendar(identifier: .gregorian)) {}
        }
    }

    /// DEP-STEPS: in previews, observing the steps comparison uses the one app-scoped sleep tolerance repository and
    /// the one app-scoped Health data repository.
    @Test func previewObserveStepsComparisonUsesTheAppScopedRepositories() {
        withDependencies {
            $0.context = .preview
        } operation: {
            @Dependency(\.sleepToleranceRepository) var sleepTolerance
            @Dependency(\.healthDataRepository) var healthData
            @Dependency(\.observeStepsComparison) var observeStepsComparison
            #expect((observeStepsComparison.sleepTolerance as AnyObject) === (sleepTolerance as AnyObject))
            #expect((observeStepsComparison.healthData as AnyObject) === (healthData as AnyObject))
        }
    }
}
