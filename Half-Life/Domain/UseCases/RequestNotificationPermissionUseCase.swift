//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life RequestNotificationPermissionUseCase
//

/// Asks, in the system's alert, to send notifications.
///
/// See the Onboarding article.
nonisolated struct RequestNotificationPermissionUseCase: UseCase {
    /// The repository that owns the permissions.
    let repository: any PermissionsRepository

    /// Asks for notification permission.
    ///
    /// - Parameter input: Nothing.
    /// - Throws: The repository's error if the request couldn't be made.
    func execute(_ input: Void) async throws {
        try await repository.requestNotifications()
    }
}
