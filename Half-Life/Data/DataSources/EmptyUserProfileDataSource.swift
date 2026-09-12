//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life EmptyUserProfileDataSource
//

/// The profile data source until a profile can be stored. It stores nothing, so it never has a profile.
///
/// The onboarding survey (roadmap rank 6) replaces it with a data source backed by real storage.
nonisolated struct EmptyUserProfileDataSource: UserProfileDataSource {
    /// Returns `nil`, because nothing has been stored.
    func storedProfile() -> UserProfile? {
        nil
    }
}
