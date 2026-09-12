//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests LiveUserProfileRepositoryTests
//

import Testing

@testable import Half_Life

/// Checks the live user profile repository against a fake data source (PROF-1 and PROF-2 in the Today Screen
/// article).
struct LiveUserProfileRepositoryTests {

    /// PROF-1: a new subscriber immediately gets the stored profile.
    @Test func publishesTheStoredProfile() async {
        let repository = LiveUserProfileRepository(
            dataSource: FakeUserProfileDataSource(stored: UserProfile(name: "Alex")))

        var received: [UserProfile] = []
        for await profile in repository.profile() {
            received.append(profile)
        }

        #expect(received == [UserProfile(name: "Alex")])
    }

    /// PROF-2: with nothing stored, it publishes a profile with no name.
    @Test func publishesAProfileWithNoNameWhenNothingIsStored() async {
        let repository = LiveUserProfileRepository(dataSource: FakeUserProfileDataSource(stored: nil))

        var received: [UserProfile] = []
        for await profile in repository.profile() {
            received.append(profile)
        }

        #expect(received == [UserProfile(name: nil)])
    }
}
