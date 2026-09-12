//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life BiometricPermission
//

/// Whether Half-Life may use the device's Face ID or Touch ID.
///
/// iOS reports biometrics as available both before an app asks and after the user allows it, so the app remembers
/// that it asked. See the Onboarding article, PERM-4.
nonisolated enum BiometricPermission: Sendable, Equatable {
    /// Half-Life hasn't asked yet, so asking shows the system's prompt.
    case notRequested(Biometry)
    /// The user allowed Half-Life to use biometrics.
    case allowed(Biometry)
    /// The user didn't allow it. Only the Settings app can change that.
    case denied(Biometry)
    /// The device has biometrics, but none are set up.
    case notEnrolled(Biometry)
    /// The device has no biometrics.
    case unavailable
}
