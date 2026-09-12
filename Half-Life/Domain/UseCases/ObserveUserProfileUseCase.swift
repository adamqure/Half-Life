//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life ObserveUserProfileUseCase
//

/// Streams the user's profile, starting with the current one.
nonisolated struct ObserveUserProfileUseCase: UseCase {
    /// The repository that owns the profile.
    let repository: any UserProfileRepository

    /// Returns a stream of the user's profile: the current one, then each change.
    ///
    /// - Parameter input: Nothing. Observing the profile takes no input.
    func execute(_ input: Void) -> AsyncStream<UserProfile> {
        repository.profile()
    }
}
