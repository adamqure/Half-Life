//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FakeBiometricPermissionsRepository
//

@testable import Half_Life

/// A permissions repository whose Face ID permission changes when it's requested, for the app lock's tests.
///
/// Each subscriber gets the permissions as they are when it subscribes, then the stream finishes.
actor FakeBiometricPermissionsRepository: PermissionsRepository {
    private var biometrics: BiometricPermission
    private let afterRequest: BiometricPermission
    private let requestError: (any Error)?
    /// How many times biometric permission was requested.
    private(set) var biometricRequestCount = 0

    /// - Parameters:
    ///   - biometrics: The Face ID permission before it's requested.
    ///   - afterRequest: The Face ID permission once it's been requested. Defaults to `biometrics`.
    ///   - requestError: The error a request throws, if any. A failed request changes nothing.
    init(
        biometrics: BiometricPermission, afterRequest: BiometricPermission? = nil, requestError: (any Error)? = nil
    ) {
        self.biometrics = biometrics
        self.afterRequest = afterRequest ?? biometrics
        self.requestError = requestError
    }

    nonisolated func permissions() -> AsyncStream<Permissions> {
        AsyncStream { continuation in
            Task {
                continuation.yield(await self.current())
                continuation.finish()
            }
        }
    }

    private func current() -> Permissions {
        Permissions(health: .notRequested, notifications: .notRequested, biometrics: biometrics)
    }

    func requestBiometrics() throws {
        biometricRequestCount += 1
        if let requestError { throw requestError }
        biometrics = afterRequest
    }

    func requestHealthAccess() {}

    func requestNotifications() {}

    func refresh() {}

    func openSettings() {}
}
