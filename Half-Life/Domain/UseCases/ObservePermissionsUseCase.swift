//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life ObservePermissionsUseCase
//

/// Streams the statuses of the Health, notification, and biometric permissions.
///
/// See the Onboarding article.
nonisolated struct ObservePermissionsUseCase: UseCase {
    /// The repository that owns the permissions.
    let repository: any PermissionsRepository

    /// Returns a stream of the permissions: the current ones, then each change.
    ///
    /// - Parameter input: Nothing. Observing the permissions takes no input.
    func execute(_ input: Void) -> AsyncStream<Permissions> {
        repository.permissions()
    }
}
