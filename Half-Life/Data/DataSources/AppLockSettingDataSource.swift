//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life AppLockSettingDataSource
//

/// Stores whether the user turned the app lock on.
///
/// See the App Lock article.
protocol AppLockSettingDataSource: Sendable {
    /// Returns whether the lock is on. With nothing stored, it's off.
    ///
    /// - Throws: An error if the setting couldn't be read.
    func isEnabled() async throws -> Bool

    /// Stores whether the lock is on.
    ///
    /// - Parameter isEnabled: Whether the lock is on.
    /// - Throws: An error if the setting couldn't be written.
    func setEnabled(_ isEnabled: Bool) async throws
}
