//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life UnlockAppUseCase
//

/// Asks the user to pass Face ID, Touch ID, or the passcode, and unlocks the app if they do.
///
/// The lock screen runs it. See the App Lock article.
nonisolated struct UnlockAppUseCase: UseCase {
    /// The repository that owns the lock.
    let repository: any AppLockRepository

    /// Asks the user to unlock the app. The repository publishes the unlocked app if they pass.
    ///
    /// - Parameter input: Nothing.
    /// - Throws: The repository's error if the prompt couldn't be shown.
    func execute(_ input: Void) async throws {
        try await repository.unlock()
    }
}
