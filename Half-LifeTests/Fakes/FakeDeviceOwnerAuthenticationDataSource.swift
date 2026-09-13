//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FakeDeviceOwnerAuthenticationDataSource
//

@testable import Half_Life

/// A device owner authentication stand-in for repository tests. Every prompt has the same outcome, or throws.
actor FakeDeviceOwnerAuthenticationDataSource: DeviceOwnerAuthenticationDataSource {
    private let outcome: DeviceOwnerAuthenticationOutcome
    private let error: (any Error)?
    /// How many times the user was asked.
    private(set) var promptCount = 0

    init(outcome: DeviceOwnerAuthenticationOutcome = .passed, error: (any Error)? = nil) {
        self.outcome = outcome
        self.error = error
    }

    func authenticate() throws -> DeviceOwnerAuthenticationOutcome {
        promptCount += 1
        if let error { throw error }
        return outcome
    }
}
