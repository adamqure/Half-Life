//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FakeUserProfileRepository
//

@testable import Half_Life

/// An in-memory user profile repository for use case and reducer tests.
///
/// It streams the profiles it was given, then finishes. It's an actor, like the live repositories.
actor FakeUserProfileRepository: UserProfileRepository {
    /// The profiles that `profile()` streams, in order.
    let profiles: [UserProfile]

    init(profiles: [UserProfile] = []) {
        self.profiles = profiles
    }

    nonisolated func profile() -> AsyncStream<UserProfile> {
        AsyncStream { continuation in
            for profile in profiles {
                continuation.yield(profile)
            }
            continuation.finish()
        }
    }
}
