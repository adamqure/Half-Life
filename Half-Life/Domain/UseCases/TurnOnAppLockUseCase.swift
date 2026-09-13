//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life TurnOnAppLockUseCase
//

/// Turns the app lock on, once Half-Life may use Face ID or Touch ID.
///
/// If Half-Life hasn't asked for biometrics yet, it asks first, in the system's prompt. The lock turns on only if
/// biometrics are then allowed, so a user who says no to Face ID doesn't find the app locked. Settings' switch and
/// onboarding's Face ID row both run it. See the App Lock article, LOCKUSE-2 and LOCKUSE-3.
nonisolated struct TurnOnAppLockUseCase: UseCase {
    /// The repository that owns the biometric permission.
    let permissions: any PermissionsRepository
    /// The repository that owns the lock.
    let appLock: any AppLockRepository

    /// Asks for biometrics if they haven't been asked for, then turns the lock on if they're allowed.
    ///
    /// - Parameter input: Nothing.
    /// - Throws: The permissions repository's error if the prompt couldn't be shown, or the lock repository's if the
    ///   setting couldn't be stored.
    func execute(_ input: Void) async throws {
        if case .notRequested? = await biometrics() {
            try await permissions.requestBiometrics()
        }
        guard case .allowed? = await biometrics() else { return }
        try await appLock.turnOn()
    }

    /// The biometric permission now: the first value the permissions stream sends.
    private func biometrics() async -> BiometricPermission? {
        for await current in permissions.permissions() {
            return current.biometrics
        }
        return nil
    }
}
