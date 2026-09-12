//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests CaffeineStatusDependencyTests
//

import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// Checks the caffeine status's test registrations (constitution Article I.15). None of these tests opens a store.
struct CaffeineStatusDependencyTests {

    /// A test that observes the status without overriding the repository fails.
    @Test func testCaffeineDecayRepositoryStatusReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.caffeineDecayRepository) var repository
            for await _ in repository.status(in: Calendar(identifier: .gregorian)) {}
        }
    }

    /// A test that observes the status without overriding the use case fails.
    @Test func testObserveCaffeineStatusReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.observeCaffeineStatus) var observeCaffeineStatus
            for await _ in observeCaffeineStatus.execute(Calendar(identifier: .gregorian)) {}
        }
    }
}

extension SwiftDataStoreTests {

    /// Checks the status's preview registration, which opens an empty in-memory store. It runs inside the serialized
    /// `SwiftDataStoreTests`, because it opens a store.
    @Suite(.timeLimit(.minutes(1)))
    struct CaffeineStatusPreviewDependencyTests {

        @Test func previewObserveCaffeineStatusUsesTheAppScopedRepository() {
            withDependencies {
                $0.context = .preview
            } operation: {
                @Dependency(\.caffeineDecayRepository) var repository
                @Dependency(\.observeCaffeineStatus) var observeCaffeineStatus
                #expect((observeCaffeineStatus.repository as AnyObject) === (repository as AnyObject))
            }
        }
    }
}
