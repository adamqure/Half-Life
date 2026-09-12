//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life NotificationPermission
//

/// Whether Half-Life may send notifications.
///
/// Provisional and ephemeral permission count as allowed. See the Onboarding article.
nonisolated enum NotificationPermission: Sendable, Equatable {
    /// Half-Life hasn't asked yet, so asking shows the system's alert.
    case notRequested
    /// The user allowed notifications.
    case allowed
    /// The user turned notifications off. Only the Settings app can turn them back on.
    case denied
}
