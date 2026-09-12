//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life LiveUserProfileRepository
//

/// The app's user profile repository. It publishes the profile its data source has stored.
///
/// Nothing can change the profile yet, so each stream finishes after the current profile. Onboarding adds change
/// signals from the data source. The Today Screen article lists its requirements, PROF-1 and PROF-2.
actor LiveUserProfileRepository: UserProfileRepository {
    /// The data source the profile is read from.
    private let dataSource: any UserProfileDataSource

    /// Creates a repository that reads the profile from `dataSource`.
    ///
    /// - Parameter dataSource: The data source the profile is read from.
    init(dataSource: any UserProfileDataSource) {
        self.dataSource = dataSource
    }

    /// Streams the stored profile, or a profile with no name if nothing is stored, then finishes.
    nonisolated func profile() -> AsyncStream<UserProfile> {
        let profile = dataSource.storedProfile() ?? UserProfile(name: nil)
        return AsyncStream { continuation in
            continuation.yield(profile)
            continuation.finish()
        }
    }
}
