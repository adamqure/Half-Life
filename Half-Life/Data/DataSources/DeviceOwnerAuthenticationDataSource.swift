//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life DeviceOwnerAuthenticationDataSource
//

/// How a prompt to unlock the app ended.
///
/// See the App Lock article, LOCKSRC-2.
nonisolated enum DeviceOwnerAuthenticationOutcome: Sendable, Equatable {
    /// The user passed Face ID, Touch ID, or the passcode.
    case passed
    /// The user cancelled or failed, or the system dismissed the prompt, so the app stays locked.
    case declined
    /// The device has no passcode, so there's nothing to ask for.
    case unavailable
}

/// Asks the device's owner to prove it's them: Face ID or Touch ID first, then the device passcode.
///
/// An implementation is the only code that touches Local Authentication for the lock (constitution Article I.14). The
/// system presents the prompt itself (Article I.6). See the App Lock article.
protocol DeviceOwnerAuthenticationDataSource: Sendable {
    /// Shows the system's prompt and returns how it ended.
    ///
    /// - Throws: An error if the prompt couldn't be shown or ended for another reason.
    func authenticate() async throws -> DeviceOwnerAuthenticationOutcome
}
