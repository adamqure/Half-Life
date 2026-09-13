//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FakeAppLockSettingDataSource
//

@testable import Half_Life

/// An in-memory app lock setting for repository tests, which can fail its reads or writes.
actor FakeAppLockSettingDataSource: AppLockSettingDataSource {
    /// Whether the lock is on.
    private(set) var enabled: Bool
    private let readError: (any Error)?
    private let writeError: (any Error)?
    /// Every value written, in order, including writes that failed.
    private(set) var writes: [Bool] = []

    init(enabled: Bool = false, readError: (any Error)? = nil, writeError: (any Error)? = nil) {
        self.enabled = enabled
        self.readError = readError
        self.writeError = writeError
    }

    func isEnabled() throws -> Bool {
        if let readError { throw readError }
        return enabled
    }

    func setEnabled(_ isEnabled: Bool) throws {
        writes.append(isEnabled)
        if let writeError { throw writeError }
        enabled = isEnabled
    }
}
