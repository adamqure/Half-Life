//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests WidgetDependencyTests
//

import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// Checks the widgets' dependency registrations: requirements WDEP-1 to WDEP-3 in the Widgets article.
///
/// These tests use only the test values, and a UI test's snapshot file. The preview values open an in-memory SwiftData
/// store, so the tests that read them run inside the serialized `SwiftDataStoreTests` below.
struct WidgetDependencyTests {

    /// WDEP-1: a test that keeps the widgets current without overriding `\.keepWidgetsCurrent` fails.
    @Test func keepingTheWidgetsCurrentWithoutOverridingItReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.keepWidgetsCurrent) var keepWidgetsCurrent
            await keepWidgetsCurrent.execute(())
        }
    }

    /// WDEP-1: a test that uses the snapshot repository without overriding `\.widgetSnapshotRepository` fails.
    @Test func usingTheRepositoryWithoutOverridingItReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.widgetSnapshotRepository) var repository
            for await _ in repository.snapshots() {}
        }
    }

    /// WDEP-3: a UI test's snapshot goes to a temporary file, so UI tests never change what the simulator's widgets
    /// show.
    @Test(arguments: [LaunchEnvironmentKey.completed, LaunchEnvironmentKey.fresh])
    func aUITestLaunchWritesItsSnapshotToATemporaryFile(profile: String) {
        let configuration = UITestLaunchConfiguration(environment: [LaunchEnvironmentKey.profile: profile])

        let source = WidgetSnapshotDataSourceKey.makeLiveValue(configuration: configuration)

        #expect(source.fileURL.path().hasPrefix(FileManager.default.temporaryDirectory.path()))
    }

    /// WDEP-3: outside UI tests, the snapshot goes to the App Group file the widget extension reads.
    @Test func anOrdinaryLaunchWritesItsSnapshotToTheAppGroupFile() {
        let configuration = UITestLaunchConfiguration(environment: [:])

        let source = WidgetSnapshotDataSourceKey.makeLiveValue(configuration: configuration)

        #expect(source.fileURL == FileWidgetSnapshotDataSource.appGroupFileURL())
    }
}

extension SwiftDataStoreTests {

    /// Checks the widgets' preview registrations, which open an empty in-memory store. They run inside the serialized
    /// `SwiftDataStoreTests`, because they open a store.
    @Suite(.timeLimit(.minutes(1)))
    struct WidgetPreviewDependencyTests {

        /// WDEP-2: the repository is the app's live repository.
        @Test func previewRepositoryIsTheLiveRepository() {
            withDependencies {
                $0.context = .preview
            } operation: {
                @Dependency(\.widgetSnapshotRepository) var repository
                #expect(repository is LiveWidgetSnapshotRepository)
            }
        }

        /// WDEP-2: keeping the widgets current uses the one app-scoped snapshot repository.
        @Test func previewKeepWidgetsCurrentUsesTheAppScopedRepository() {
            withDependencies {
                $0.context = .preview
            } operation: {
                @Dependency(\.widgetSnapshotRepository) var repository
                @Dependency(\.keepWidgetsCurrent) var keepWidgetsCurrent
                #expect((keepWidgetsCurrent.repository as AnyObject) === (repository as AnyObject))
            }
        }
    }
}
