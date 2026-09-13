//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life ObserveAppLockUseCase
//

/// Streams the app lock: whether it's on, and whether the app is locked now.
///
/// See the App Lock article.
nonisolated struct ObserveAppLockUseCase: UseCase {
    /// The repository that owns the lock.
    let repository: any AppLockRepository

    /// Returns a stream of the lock: the current one, then each change.
    ///
    /// - Parameter input: Nothing. Observing the lock takes no input.
    func execute(_ input: Void) -> AsyncStream<AppLock> {
        repository.appLock()
    }
}
