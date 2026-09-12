//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life RequestBiometricPermissionUseCase
//

/// Asks, in the system's prompt, to use Face ID or Touch ID.
///
/// See the Onboarding article.
nonisolated struct RequestBiometricPermissionUseCase: UseCase {
    /// The repository that owns the permissions.
    let repository: any PermissionsRepository

    /// Asks for biometric permission.
    ///
    /// - Parameter input: Nothing.
    /// - Throws: The repository's error if the prompt couldn't be shown, or its answer couldn't be recorded.
    func execute(_ input: Void) async throws {
        try await repository.requestBiometrics()
    }
}
