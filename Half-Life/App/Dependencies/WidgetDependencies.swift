//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life WidgetDependencies
//

import ComposableArchitecture
import Foundation
import OSLog

extension DependencyValues {
    /// The app's widget snapshot repository (constitution Article I.15).
    ///
    /// Live, it's one app-scoped ``LiveWidgetSnapshotRepository`` over the shared drink log and profile data sources,
    /// storing its snapshot in the App Group file the widget extension reads. In previews, it's the same repository
    /// over empty stores and a temporary file. In tests, using it without overriding it reports an issue.
    var widgetSnapshotRepository: any WidgetSnapshotRepository {
        get { self[WidgetSnapshotRepositoryKey.self] }
        set { self[WidgetSnapshotRepositoryKey.self] = newValue }
    }

    /// Keeps the widgets' snapshot current through the app-scoped ``widgetSnapshotRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var keepWidgetsCurrent: KeepWidgetsCurrentUseCase {
        get { self[KeepWidgetsCurrentUseCaseKey.self] }
        set { self[KeepWidgetsCurrentUseCaseKey.self] = newValue }
    }
}

/// Where the app stores the widgets' snapshot. Only ``LiveWidgetSnapshotRepository`` uses it, so it has no
/// `DependencyValues` property.
enum WidgetSnapshotDataSourceKey {
    private static let logger = Logger(for: WidgetSnapshotDataSourceKey.self)

    /// The App Group file the widget extension reads. Under a UI test, a temporary file (WDEP-3).
    static let liveValue: any WidgetSnapshotDataSource = makeLiveValue(configuration: .current)

    /// A temporary file, so previews never change what the widgets show.
    static let previewValue: any WidgetSnapshotDataSource = FileWidgetSnapshotDataSource(fileURL: temporaryFileURL())

    /// The live data source for a launch with `configuration`.
    ///
    /// A UI test gets a temporary file, so UI tests never change what the simulator's widgets show. Outside UI tests,
    /// it's the App Group file. If the App Group container isn't available, which happens only without the
    /// entitlement, it's a temporary file too, and the failure is logged.
    ///
    /// - Parameter configuration: How a UI test asked the app to start, if one did.
    /// - Returns: The data source.
    static func makeLiveValue(configuration: UITestLaunchConfiguration) -> FileWidgetSnapshotDataSource {
        if !configuration.isUITest {
            if let url = FileWidgetSnapshotDataSource.appGroupFileURL() {
                return FileWidgetSnapshotDataSource(fileURL: url)
            }
            logger.error("The App Group container isn't available, so the widgets won't update.")
        }
        return FileWidgetSnapshotDataSource(fileURL: temporaryFileURL())
    }

    private static func temporaryFileURL() -> URL {
        FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
            .appending(path: FileWidgetSnapshotDataSource.fileName)
    }
}

private enum WidgetSnapshotRepositoryKey: DependencyKey {
    static let liveValue: any WidgetSnapshotRepository = LiveWidgetSnapshotRepository(
        drinkLog: DrinkLogDataSourceKey.liveValue, profile: ProfileDataSourceKey.liveValue,
        halfLife: EstimatedHalfLifeDataSource(
            estimates: HalfLifeEstimateDataSourceKey.liveValue, prior: ProfileDataSourceKey.liveValue),
        absorption: StandardAbsorptionRateDataSource(), clock: SystemClockDataSource(),
        snapshots: WidgetSnapshotDataSourceKey.liveValue, widgets: WidgetKitReloadDataSource())
    static let previewValue: any WidgetSnapshotRepository = LiveWidgetSnapshotRepository(
        drinkLog: DrinkLogDataSourceKey.previewValue, profile: ProfileDataSourceKey.previewValue,
        halfLife: EstimatedHalfLifeDataSource(
            estimates: HalfLifeEstimateDataSourceKey.previewValue, prior: ProfileDataSourceKey.previewValue),
        absorption: StandardAbsorptionRateDataSource(), clock: SystemClockDataSource(),
        snapshots: WidgetSnapshotDataSourceKey.previewValue, widgets: WidgetKitReloadDataSource())
    static let testValue: any WidgetSnapshotRepository = UnimplementedWidgetSnapshotRepository()
}

// Built from the repository key's values directly, not through `@Dependency`, following the Architecture article's
// "Registering a repository and its use cases".
private enum KeepWidgetsCurrentUseCaseKey: DependencyKey {
    static let liveValue = KeepWidgetsCurrentUseCase(repository: WidgetSnapshotRepositoryKey.liveValue)
    static let previewValue = KeepWidgetsCurrentUseCase(repository: WidgetSnapshotRepositoryKey.previewValue)
    static let testValue = KeepWidgetsCurrentUseCase(repository: WidgetSnapshotRepositoryKey.testValue)
}

private struct UnimplementedWidgetSnapshotRepository: WidgetSnapshotRepository {
    func snapshots() -> AsyncStream<WidgetSnapshot> {
        reportIssue(
            "A test kept the widgets current without overriding \\.widgetSnapshotRepository or \\.keepWidgetsCurrent.")
        return AsyncStream { $0.finish() }
    }
}
