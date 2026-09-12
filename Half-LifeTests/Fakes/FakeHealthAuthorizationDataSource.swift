//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FakeHealthAuthorizationDataSource
//

@testable import Half_Life

/// A Health authorization data source for repository tests. It reports a status, and changes it after a request.
actor FakeHealthAuthorizationDataSource: HealthAuthorizationDataSource {
    /// The status `status()` reports now.
    private(set) var current: HealthAccessStatus
    /// The status after a successful request.
    private let afterRequest: HealthAccessStatus
    /// The error a request throws instead of succeeding, if any.
    private let requestError: (any Error)?
    /// How many times access was requested.
    private(set) var requestCount = 0

    init(
        status: HealthAccessStatus = .notRequested, afterRequest: HealthAccessStatus = .requested,
        requestError: (any Error)? = nil
    ) {
        current = status
        self.afterRequest = afterRequest
        self.requestError = requestError
    }

    func status() -> HealthAccessStatus {
        current
    }

    func requestAccess() throws {
        requestCount += 1
        if let requestError { throw requestError }
        current = afterRequest
    }
}
