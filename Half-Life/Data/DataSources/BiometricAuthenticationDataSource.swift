//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life BiometricAuthenticationDataSource
//

/// What the device's biometrics allow, as the system reports them.
///
/// It can't tell whether Half-Life has asked: iOS reports biometrics as available both before an app asks and after
/// the user allows it. ``LivePermissionsRepository`` combines it with the permission history to find the
/// ``BiometricPermission``. See the Onboarding article, PERM-4.
nonisolated enum BiometricAvailability: Sendable, Equatable {
    /// Biometrics can be used, or the user hasn't been asked yet.
    case available(Biometry)
    /// The user didn't allow Half-Life to use biometrics.
    case denied(Biometry)
    /// The device has biometrics, but none are set up.
    case notEnrolled(Biometry)
    /// The device has no biometrics.
    case unavailable
}

/// Reads whether the device's biometrics can be used, and asks to use them.
///
/// An implementation is the only code that touches Local Authentication (constitution Article I.14). See the
/// Onboarding article.
protocol BiometricAuthenticationDataSource: Sendable {
    /// Returns what the device's biometrics allow now.
    func availability() -> BiometricAvailability

    /// Shows the system's biometric prompt, which asks for permission first if the app hasn't asked before.
    ///
    /// It returns normally once the user has answered the prompt, whether they allowed it, cancelled, or failed the
    /// scan.
    ///
    /// - Throws: An error if the prompt couldn't be shown or ended for another reason.
    func authenticate() async throws
}
