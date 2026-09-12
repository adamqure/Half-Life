//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life UserProfileDataSource
//

/// Reads and stores the user's profile.
///
/// An implementation is the only code that touches the profile's storage (constitution Article I.14). It signals every
/// subscriber after each successful store, so every repository that reads the profile can re-read it. See the
/// Onboarding article.
protocol UserProfileDataSource: Sendable {
    /// Returns the stored profile, or `nil` if nothing has been stored.
    ///
    /// - Throws: An error if a stored profile couldn't be read.
    func storedProfile() async throws -> UserProfile?

    /// Stores `profile` in place of whatever was stored, then signals every subscriber.
    ///
    /// - Parameter profile: The profile to store.
    /// - Throws: An error if the profile couldn't be stored. Nothing is signalled.
    func store(_ profile: UserProfile) async throws

    /// Returns a stream that yields once after each successful store.
    func changes() async -> AsyncStream<Void>
}

/// The profile data source both repositories share: one type that stores the profile, and serves the bedtime and
/// the half-life from it to ``CaffeineDecayRepository``.
typealias ProfileDataSource = BedtimeDataSource & HalfLifeDataSource & UserProfileDataSource
