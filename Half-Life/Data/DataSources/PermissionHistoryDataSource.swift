//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life PermissionHistoryDataSource
//

/// Remembers which permissions Half-Life has asked for, where the system can't say.
///
/// iOS reports Face ID as available both before the app asks and after the user allows it, so the app records that it
/// asked. See the Onboarding article, PERM-4.
protocol PermissionHistoryDataSource: Sendable {
    /// Returns whether Half-Life has asked to use biometrics.
    ///
    /// - Throws: An error if the history couldn't be read.
    func hasRequestedBiometrics() async throws -> Bool

    /// Records that Half-Life has asked to use biometrics.
    ///
    /// - Throws: An error if the history couldn't be written.
    func recordBiometricsRequested() async throws
}
