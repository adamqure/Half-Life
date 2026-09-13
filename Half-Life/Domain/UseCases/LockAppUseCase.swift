//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life LockAppUseCase
//

/// Locks the app, if the app lock is on. The root runs it when the app goes to the background.
///
/// See the App Lock article.
nonisolated struct LockAppUseCase: UseCase {
    /// The repository that owns the lock.
    let repository: any AppLockRepository

    /// Locks the app. With the lock off, nothing changes.
    ///
    /// - Parameter input: Nothing.
    func execute(_ input: Void) async {
        await repository.lock()
    }
}
