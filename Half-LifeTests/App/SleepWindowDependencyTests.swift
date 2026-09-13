//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests SleepWindowDependencyTests
//

import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// Checks the sleep window's test registrations (constitution Article I.15, DEP-SLEEPWIN in the Insights article).
/// None of these tests opens a store.
struct SleepWindowDependencyTests {

    /// A test that observes the sleep window without overriding the repository fails.
    @Test func testCaffeineDecayRepositorySleepWindowReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.caffeineDecayRepository) var repository
            for await _ in repository.sleepWindow(in: Calendar(identifier: .gregorian)) {}
        }
    }

    /// A test that observes the sleep window without overriding the use case fails.
    @Test func testObserveSleepWindowReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.observeSleepWindow) var observeSleepWindow
            for await _ in observeSleepWindow.execute(Calendar(identifier: .gregorian)) {}
        }
    }
}

extension SwiftDataStoreTests {

    /// Checks the sleep window's preview registration, which opens an empty in-memory store. It runs inside the
    /// serialized `SwiftDataStoreTests`, because it opens a store.
    @Suite(.timeLimit(.minutes(1)))
    struct SleepWindowPreviewDependencyTests {

        /// DEP-SLEEPWIN: observing the sleep window uses the one app-scoped decay repository.
        @Test func previewObserveSleepWindowUsesTheAppScopedRepository() {
            withDependencies {
                $0.context = .preview
            } operation: {
                @Dependency(\.caffeineDecayRepository) var repository
                @Dependency(\.observeSleepWindow) var observeSleepWindow
                #expect((observeSleepWindow.repository as AnyObject) === (repository as AnyObject))
            }
        }
    }
}
