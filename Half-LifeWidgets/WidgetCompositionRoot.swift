//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeWidgets WidgetCompositionRoot
//

import Foundation
import OSLog

/// Builds the widget extension's one use case, its repository, and its data sources.
///
/// The extension links no TCA, SwiftData, HealthKit, or swift-dependencies, so it builds them here rather than
/// through `DependencyKey`s, and its repository lives for one timeline (constitution Article I.19).
enum WidgetCompositionRoot {
    private static let logger = Logger(for: WidgetCompositionRoot.self)

    /// Returns the use case that streams the widgets' timeline, over the snapshot the app stored in the App Group
    /// container.
    ///
    /// If the container isn't available, which happens only without the App Group entitlement, it reads a file that
    /// doesn't exist, so the widgets ask the user to finish setting up, and the failure is logged.
    static func observeWidgetTimeline() -> ObserveWidgetTimelineUseCase {
        let fileURL: URL
        if let url = FileWidgetSnapshotDataSource.appGroupFileURL() {
            fileURL = url
        } else {
            logger.error("The App Group container isn't available, so the widgets can't read the snapshot.")
            fileURL = FileManager.default.temporaryDirectory.appending(path: FileWidgetSnapshotDataSource.fileName)
        }
        return ObserveWidgetTimelineUseCase(
            repository: LiveWidgetTimelineRepository(
                snapshots: FileWidgetSnapshotDataSource(fileURL: fileURL), clock: SystemClockDataSource()))
    }
}
