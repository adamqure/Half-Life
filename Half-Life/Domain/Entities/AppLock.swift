//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life AppLock
//

/// Whether the app lock is on, and whether it's hiding the app now.
///
/// The user turns the lock on in onboarding or in Settings. While it's on, the app locks each time it launches or
/// goes to the background, and stays locked until the user passes Face ID, Touch ID, or the device passcode. See the
/// App Lock article.
nonisolated struct AppLock: Sendable, Equatable {
    /// Whether the user turned the lock on.
    let isEnabled: Bool
    /// Whether the app is locked now, so its content stays hidden until the user unlocks it.
    let isLocked: Bool
}
