//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests SleepToleranceDependencyTests
//

import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// Checks the sleep tolerance's registrations (constitution Article I.15, DEP-TOL in the Insights article). None of
/// these tests opens a store.
struct SleepToleranceDependencyTests {

    /// A test that observes the analysis without overriding the repository fails.
    @Test func testSleepToleranceRepositoryReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.sleepToleranceRepository) var repository
            for await _ in repository.analysis() {}
        }
    }

    /// A test that observes the analysis without overriding the use case fails.
    @Test func testObserveSleepCaffeineAnalysisReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.observeSleepCaffeineAnalysis) var observeSleepCaffeineAnalysis
            for await _ in observeSleepCaffeineAnalysis.execute(()) {}
        }
    }

    /// A test that observes the caffeine nights without overriding the repository fails.
    @Test func testSleepToleranceRepositoryCaffeineNightsReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.sleepToleranceRepository) var repository
            for await _ in repository.caffeineNights(days: 31, in: Calendar(identifier: .gregorian)) {}
        }
    }

    /// A test that observes the caffeine nights without overriding the use case fails.
    @Test func testObserveCaffeineNightsReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.observeCaffeineNights) var observeCaffeineNights
            for await _ in observeCaffeineNights.execute(Calendar(identifier: .gregorian)) {}
        }
    }

    /// A test that keeps the tolerance current without overriding the use case fails.
    @Test func testKeepSleepToleranceCurrentReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.keepSleepToleranceCurrent) var keepSleepToleranceCurrent
            await keepSleepToleranceCurrent.execute(())
        }
    }

    /// DEP-TOL: in previews, both use cases use the one app-scoped sleep tolerance repository.
    @Test func previewUseCasesUseTheAppScopedRepository() {
        withDependencies {
            $0.context = .preview
        } operation: {
            @Dependency(\.sleepToleranceRepository) var repository
            @Dependency(\.observeSleepCaffeineAnalysis) var observeSleepCaffeineAnalysis
            @Dependency(\.keepSleepToleranceCurrent) var keepSleepToleranceCurrent
            @Dependency(\.observeCaffeineNights) var observeCaffeineNights
            #expect((observeCaffeineNights.repository as AnyObject) === (repository as AnyObject))
            #expect((observeSleepCaffeineAnalysis.repository as AnyObject) === (repository as AnyObject))
            #expect((keepSleepToleranceCurrent.repository as AnyObject) === (repository as AnyObject))
        }
    }
}
