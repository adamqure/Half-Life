//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FakePermissionsRepository
//

@testable import Half_Life

/// A permissions repository for use case tests. It streams the permissions it's given, and counts each command.
actor FakePermissionsRepository: PermissionsRepository {
    /// The permissions that `permissions()` streams, in order.
    let streamed: [Permissions]
    /// The error each request throws, if any.
    let requestError: (any Error)?
    /// How many times Health access was requested.
    private(set) var healthRequestCount = 0
    /// How many times notification permission was requested.
    private(set) var notificationRequestCount = 0
    /// How many times biometric permission was requested.
    private(set) var biometricRequestCount = 0
    /// How many times the permissions were refreshed.
    private(set) var refreshCount = 0
    /// How many times the Settings app was opened.
    private(set) var openSettingsCount = 0

    init(streamed: [Permissions] = [], requestError: (any Error)? = nil) {
        self.streamed = streamed
        self.requestError = requestError
    }

    nonisolated func permissions() -> AsyncStream<Permissions> {
        AsyncStream { continuation in
            for permissions in streamed {
                continuation.yield(permissions)
            }
            continuation.finish()
        }
    }

    func requestHealthAccess() async throws {
        healthRequestCount += 1
        if let requestError { throw requestError }
    }

    func requestNotifications() async throws {
        notificationRequestCount += 1
        if let requestError { throw requestError }
    }

    func requestBiometrics() async throws {
        biometricRequestCount += 1
        if let requestError { throw requestError }
    }

    func refresh() async {
        refreshCount += 1
    }

    func openSettings() async {
        openSettingsCount += 1
    }
}
