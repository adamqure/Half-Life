//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FakeWidgetSnapshotDataSource
//

@testable import Half_Life

/// An in-memory widget snapshot data source. Each successful store adds "store" to the shared event log, so a test can
/// check it against the widgets' reloads.
actor FakeWidgetSnapshotDataSource: WidgetSnapshotDataSource {
    /// The snapshot it holds.
    private(set) var stored: WidgetSnapshot?
    private let events: Recorded<[String]>
    private let readError: (any Error)?
    private let storeError: (any Error)?

    init(
        stored: WidgetSnapshot? = nil, events: Recorded<[String]> = Recorded([]), readError: (any Error)? = nil,
        storeError: (any Error)? = nil
    ) {
        self.stored = stored
        self.events = events
        self.readError = readError
        self.storeError = storeError
    }

    func storedSnapshot() throws -> WidgetSnapshot? {
        if let readError { throw readError }
        return stored
    }

    func store(_ snapshot: WidgetSnapshot) throws {
        if let storeError { throw storeError }
        stored = snapshot
        events.update { $0.append("store") }
    }
}

/// A widget reload data source that adds "reload" to the shared event log each time it's asked to reload.
struct FakeWidgetReloadDataSource: WidgetReloadDataSource {
    let events: Recorded<[String]>

    func reloadAllTimelines() {
        events.update { $0.append("reload") }
    }
}
