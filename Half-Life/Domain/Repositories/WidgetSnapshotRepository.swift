//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life WidgetSnapshotRepository
//

/// The source of truth for what the Home Screen widgets show: the app's ``WidgetSnapshot``, kept stored for the widget
/// extension.
///
/// ``LiveWidgetSnapshotRepository`` implements it. See the Widgets article.
protocol WidgetSnapshotRepository: Sendable {
    /// Streams the snapshot.
    ///
    /// Each new subscriber immediately receives a snapshot calculated for the current data. After that, every
    /// subscriber receives a new one whenever the data it comes from changes. Each snapshot is stored, and the widgets
    /// reloaded, before it's published.
    func snapshots() -> AsyncStream<WidgetSnapshot>
}
