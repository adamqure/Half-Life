//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life WidgetSnapshotDataSource
//

/// Where the widgets' snapshot is stored: written by the app, and read by the widget extension.
///
/// ``FileWidgetSnapshotDataSource`` implements it over a file in the App Group container. See the Widgets article.
protocol WidgetSnapshotDataSource: Sendable {
    /// Returns the stored snapshot, or `nil` if none has been stored.
    ///
    /// - Throws: An error if the snapshot couldn't be read.
    func storedSnapshot() async throws -> WidgetSnapshot?

    /// Stores `snapshot` in place of the one stored before.
    ///
    /// - Parameter snapshot: The snapshot to store.
    /// - Throws: An error if the snapshot couldn't be stored.
    func store(_ snapshot: WidgetSnapshot) async throws
}
