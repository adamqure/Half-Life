//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life PermissionsRepository
//

/// The source of truth for the statuses of the Health, notification, and biometric permissions.
///
/// The permissions are system state. The repository reads them through data sources, asks for them when a feature
/// requests them, and publishes each change (constitution Article I.12). The Onboarding article lists its
/// requirements, PERM-1 to PERM-4.
protocol PermissionsRepository: Sendable {
    /// Streams the permissions: the current ones as soon as it's subscribed to, then each change. It never finishes.
    func permissions() -> AsyncStream<Permissions>

    /// Asks, in Health's sheet, to read the Health types Half-Life's features read.
    ///
    /// - Throws: An error if the request couldn't be made.
    func requestHealthAccess() async throws

    /// Asks, in the system's alert, to send notifications.
    ///
    /// - Throws: An error if the request couldn't be made.
    func requestNotifications() async throws

    /// Asks, in the system's prompt, to use Face ID or Touch ID.
    ///
    /// - Throws: An error if the prompt couldn't be shown, or its answer couldn't be recorded.
    func requestBiometrics() async throws

    /// Reads the permissions again, and publishes them if they changed, for example in the Settings app.
    func refresh() async

    /// Opens Half-Life's page in the Settings app, where a denied permission can be turned on.
    func openSettings() async
}
