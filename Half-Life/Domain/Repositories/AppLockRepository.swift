//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life AppLockRepository
//

/// The source of truth for the app lock: whether it's on, and whether the app is locked now.
///
/// It's app-scoped. Whether the lock is on is stored on the device. Whether the app is locked lives only in memory,
/// and starts locked when the lock is on, so every launch asks. The App Lock article lists its requirements,
/// LOCKREPO-1 to LOCKREPO-5.
protocol AppLockRepository: Sendable {
    /// Streams the lock: the current one as soon as it's subscribed to, then each change. It never finishes.
    func appLock() -> AsyncStream<AppLock>

    /// Turns the lock on, leaving the app unlocked until it next locks.
    ///
    /// - Throws: An error if the setting couldn't be stored. The lock stays off.
    func turnOn() async throws

    /// Turns the lock off, and unlocks the app.
    ///
    /// - Throws: An error if the setting couldn't be stored. The lock stays on.
    func turnOff() async throws

    /// Locks the app, if the lock is on. The app calls it when it goes to the background.
    func lock() async

    /// Asks the user to pass Face ID, Touch ID, or the passcode, and unlocks the app if they do.
    ///
    /// If they cancel or fail, the app stays locked. A device with no passcode can't ask, so the app unlocks.
    ///
    /// - Throws: An error if the prompt couldn't be shown. The app stays locked.
    func unlock() async throws
}
