//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FakePermissionHistoryDataSource
//

@testable import Half_Life

/// An in-memory permission history for repository tests, which can fail its reads or writes.
actor FakePermissionHistoryDataSource: PermissionHistoryDataSource {
    /// Whether biometrics have been requested.
    private(set) var requested: Bool
    /// The error a read throws, if any.
    private let readError: (any Error)?
    /// The error a record throws, if any.
    private let recordError: (any Error)?
    /// How many times a request was recorded.
    private(set) var recordCount = 0

    init(requested: Bool = false, readError: (any Error)? = nil, recordError: (any Error)? = nil) {
        self.requested = requested
        self.readError = readError
        self.recordError = recordError
    }

    func hasRequestedBiometrics() throws -> Bool {
        if let readError { throw readError }
        return requested
    }

    func recordBiometricsRequested() throws {
        recordCount += 1
        if let recordError { throw recordError }
        requested = true
    }
}
