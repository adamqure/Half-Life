//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FakeSystemSettingsDataSource
//

import Synchronization

@testable import Half_Life

/// A Settings app opener for repository tests. It counts how many times it was asked to open Settings.
final class FakeSystemSettingsDataSource: SystemSettingsDataSource, Sendable {
    private let count = Mutex(0)

    /// How many times Settings was opened.
    var openCount: Int {
        count.withLock { $0 }
    }

    @MainActor func openSettings() async {
        count.withLock { $0 += 1 }
    }
}
