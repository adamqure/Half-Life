//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests AvailableHealthDataDependencyTests
//

import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// Checks the available Health data's registrations (constitution Article I.15, DEP-AVAIL in the Insights article).
/// None of these tests opens a store.
struct AvailableHealthDataDependencyTests {

    /// A test that observes the available kinds without overriding the repository fails.
    @Test func testHealthDataRepositoryAvailableKindsReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.healthDataRepository) var repository
            for await _ in repository.availableKinds(days: 30, in: Calendar(identifier: .gregorian)) {}
        }
    }

    /// A test that observes the available Health data without overriding the use case fails.
    @Test func testObserveAvailableHealthDataReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.observeAvailableHealthData) var observeAvailableHealthData
            for await _ in observeAvailableHealthData.execute(Calendar(identifier: .gregorian)) {}
        }
    }

    /// DEP-AVAIL: in previews, observing the available Health data uses the one app-scoped Health data repository.
    @Test func previewObserveAvailableHealthDataUsesTheAppScopedRepository() {
        withDependencies {
            $0.context = .preview
        } operation: {
            @Dependency(\.healthDataRepository) var repository
            @Dependency(\.observeAvailableHealthData) var observeAvailableHealthData
            #expect((observeAvailableHealthData.repository as AnyObject) === (repository as AnyObject))
        }
    }
}
