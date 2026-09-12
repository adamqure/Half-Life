//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FakeBiometricAuthenticationDataSource
//

import Synchronization

@testable import Half_Life

/// A biometric authentication data source for repository tests.
///
/// It's a class guarded by a mutex rather than an actor, because `availability()` is synchronous.
final class FakeBiometricAuthenticationDataSource: BiometricAuthenticationDataSource, Sendable {
    private struct State {
        var availability: BiometricAvailability
        var authenticateCount = 0
    }

    private let state: Mutex<State>
    /// The availability after the user answers the prompt, or `nil` to leave it unchanged.
    private let availabilityAfterAuthenticating: BiometricAvailability?
    /// The error `authenticate()` throws, if any.
    private let authenticateError: (any Error)?

    init(
        availability: BiometricAvailability = .available(.faceID),
        availabilityAfterAuthenticating: BiometricAvailability? = nil, authenticateError: (any Error)? = nil
    ) {
        state = Mutex(State(availability: availability))
        self.availabilityAfterAuthenticating = availabilityAfterAuthenticating
        self.authenticateError = authenticateError
    }

    /// How many times `authenticate()` was called.
    var authenticateCount: Int {
        state.withLock { $0.authenticateCount }
    }

    func availability() -> BiometricAvailability {
        state.withLock { $0.availability }
    }

    func authenticate() async throws {
        state.withLock { $0.authenticateCount += 1 }
        if let authenticateError { throw authenticateError }
        if let availabilityAfterAuthenticating {
            state.withLock { $0.availability = availabilityAfterAuthenticating }
        }
    }
}
