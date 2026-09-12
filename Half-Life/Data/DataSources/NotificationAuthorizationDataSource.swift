//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life NotificationAuthorizationDataSource
//

/// Reads and requests permission to send notifications.
///
/// An implementation is the only code that touches the system's notification permission (constitution Article
/// I.14). See the Onboarding article.
protocol NotificationAuthorizationDataSource: Sendable {
    /// Returns whether Half-Life may send notifications.
    func status() async -> NotificationPermission

    /// Asks to send notifications, showing the system's alert if it hasn't been shown before.
    ///
    /// - Throws: An error if the request couldn't be made. The user turning notifications off isn't an error.
    func requestAuthorization() async throws
}
