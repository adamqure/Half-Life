//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life TurnOffAppLockUseCase
//

/// Turns the app lock off.
///
/// Settings is behind the lock, so whoever reaches the switch has already unlocked the app. See the App Lock article.
nonisolated struct TurnOffAppLockUseCase: UseCase {
    /// The repository that owns the lock.
    let repository: any AppLockRepository

    /// Turns the lock off.
    ///
    /// - Parameter input: Nothing.
    /// - Throws: The repository's error if the setting couldn't be stored.
    func execute(_ input: Void) async throws {
        try await repository.turnOff()
    }
}
