//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests ObserveUserProfileUseCaseTests
//

import Testing

@testable import Half_Life

/// Checks that observing the user's profile streams exactly what the repository publishes.
struct ObserveUserProfileUseCaseTests {

    @Test func streamsEveryProfileTheRepositoryPublishesInOrder() async throws {
        let profiles = [UserProfile(name: nil), UserProfile(name: "Alex")]
        let observe = ObserveUserProfileUseCase(repository: FakeUserProfileRepository(profiles: profiles))

        var received: [UserProfile] = []
        for await profile in try await executeThroughProtocol(observe, ()) {
            received.append(profile)
        }

        #expect(received == profiles)
    }
}
