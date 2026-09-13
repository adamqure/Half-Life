//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests HeartRateComparisonDependencyTests
//

import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// Checks the resting heart rate comparison's registrations (constitution Article I.15, DEP-RHRCOMP in the Insights
/// article). None of these tests opens a store.
struct HeartRateComparisonDependencyTests {

    /// A test that observes the resting heart rates without overriding the Health data repository fails.
    @Test func testHealthDataRepositoryRestingHeartRatesReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.healthDataRepository) var repository
            for await _ in repository.restingHeartRates(days: 30, in: Calendar(identifier: .gregorian)) {}
        }
    }

    /// A test that observes the comparison without overriding the use case fails.
    @Test func testObserveRestingHeartRateComparisonReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.observeRestingHeartRateComparison) var observe
            for await _ in observe.execute(Calendar(identifier: .gregorian)) {}
        }
    }

    /// DEP-RHRCOMP: in previews, observing the comparison uses the one app-scoped sleep tolerance repository and the
    /// one app-scoped Health data repository.
    @Test func previewObserveRestingHeartRateComparisonUsesTheAppScopedRepositories() {
        withDependencies {
            $0.context = .preview
        } operation: {
            @Dependency(\.sleepToleranceRepository) var sleepTolerance
            @Dependency(\.healthDataRepository) var healthData
            @Dependency(\.observeRestingHeartRateComparison) var observe
            #expect((observe.sleepTolerance as AnyObject) === (sleepTolerance as AnyObject))
            #expect((observe.healthData as AnyObject) === (healthData as AnyObject))
        }
    }
}
