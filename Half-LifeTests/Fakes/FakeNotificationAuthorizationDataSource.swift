//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FakeNotificationAuthorizationDataSource
//

@testable import Half_Life

/// A notification authorization data source for repository tests. A test can change its status as the Settings app
/// would, with `set(_:)`.
actor FakeNotificationAuthorizationDataSource: NotificationAuthorizationDataSource {
    /// The permission `status()` reports now.
    private(set) var current: NotificationPermission
    /// The permission after a successful request: what the user chose.
    private let afterRequest: NotificationPermission
    /// The error a request throws instead of succeeding, if any.
    private let requestError: (any Error)?
    /// How many times permission was requested.
    private(set) var requestCount = 0

    init(
        status: NotificationPermission = .notRequested, afterRequest: NotificationPermission = .allowed,
        requestError: (any Error)? = nil
    ) {
        current = status
        self.afterRequest = afterRequest
        self.requestError = requestError
    }

    /// Changes the permission without a request, as the Settings app can.
    func set(_ permission: NotificationPermission) {
        current = permission
    }

    func status() -> NotificationPermission {
        current
    }

    func requestAuthorization() throws {
        requestCount += 1
        if let requestError { throw requestError }
        current = afterRequest
    }
}
