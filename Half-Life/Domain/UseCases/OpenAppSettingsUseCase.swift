//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life OpenAppSettingsUseCase
//

/// Opens Half-Life's page in the Settings app, where a denied permission can be turned on.
///
/// See the Onboarding article.
nonisolated struct OpenAppSettingsUseCase: UseCase {
    /// The repository that owns the permissions.
    let repository: any PermissionsRepository

    /// Opens the Settings app.
    ///
    /// - Parameter input: Nothing.
    func execute(_ input: Void) async {
        await repository.openSettings()
    }
}
