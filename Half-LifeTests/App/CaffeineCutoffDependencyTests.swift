//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests CaffeineCutoffDependencyTests
//

import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// Checks the cutoff's test registrations (constitution Article I.15, DEP-CUTOFF in the Caffeine Cutoff article).
/// None of these tests opens a store.
struct CaffeineCutoffDependencyTests {

    /// A test that observes the cutoff without overriding the repository fails.
    @Test func testCaffeineDecayRepositoryCutoffReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.caffeineDecayRepository) var repository
            for await _ in repository.cutoff(in: Calendar(identifier: .gregorian)) {}
        }
    }

    /// A test that observes the cutoff without overriding the use case fails.
    @Test func testObserveCaffeineCutoffReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.observeCaffeineCutoff) var observeCaffeineCutoff
            for await _ in observeCaffeineCutoff.execute(Calendar(identifier: .gregorian)) {}
        }
    }
}

extension SwiftDataStoreTests {

    /// Checks the cutoff's preview registration, which opens an empty in-memory store. It runs inside the serialized
    /// `SwiftDataStoreTests`, because it opens a store.
    @Suite(.timeLimit(.minutes(1)))
    struct CaffeineCutoffPreviewDependencyTests {

        /// DEP-CUTOFF: observing the cutoff uses the one app-scoped decay repository.
        @Test func previewObserveCaffeineCutoffUsesTheAppScopedRepository() {
            withDependencies {
                $0.context = .preview
            } operation: {
                @Dependency(\.caffeineDecayRepository) var repository
                @Dependency(\.observeCaffeineCutoff) var observeCaffeineCutoff
                #expect((observeCaffeineCutoff.repository as AnyObject) === (repository as AnyObject))
            }
        }
    }
}
