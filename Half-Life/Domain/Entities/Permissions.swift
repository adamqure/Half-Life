//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life Permissions
//

/// The status of each permission that onboarding's permissions step shows.
///
/// All three are system state, read through their data sources. See the Onboarding article.
nonisolated struct Permissions: Sendable, Equatable {
    /// Whether Half-Life has asked to read Apple Health.
    let health: HealthAccessStatus
    /// Whether Half-Life may send notifications.
    let notifications: NotificationPermission
    /// Whether Half-Life may use Face ID or Touch ID.
    let biometrics: BiometricPermission
}
