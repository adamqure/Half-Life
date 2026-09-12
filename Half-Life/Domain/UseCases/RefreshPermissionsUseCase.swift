//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life RefreshPermissionsUseCase
//

/// Reads the permissions again, for example when the app returns from the Settings app.
///
/// See the Onboarding article.
nonisolated struct RefreshPermissionsUseCase: UseCase {
    /// The repository that owns the permissions.
    let repository: any PermissionsRepository

    /// Refreshes the permissions. The repository publishes them if they changed.
    ///
    /// - Parameter input: Nothing.
    func execute(_ input: Void) async {
        await repository.refresh()
    }
}
