//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life UserProfileRepository
//

/// The source of truth for what the user has told the app about themselves.
///
/// An implementation reads the stored profile from a user profile data source. The Today Screen article lists its
/// requirements, PROF-1 and PROF-2.
protocol UserProfileRepository: Sendable {
    /// Streams the user's profile, starting with the current one.
    ///
    /// Each new subscriber immediately receives the current profile. When nothing has been stored, that's a profile
    /// with no name.
    func profile() -> AsyncStream<UserProfile>
}
