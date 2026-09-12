//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests UserProfileTests
//

import Testing

@testable import Half_Life

struct UserProfileTests {

    /// PROF-2: a profile with nothing given has no name or age, no factors, the standard bedtime and half-life, and
    /// hasn't completed onboarding.
    @Test func aNewProfileHoldsOnlyDefaults() {
        let profile = UserProfile()

        #expect(profile.name == nil)
        #expect(profile.birthYear == nil)
        #expect(profile.halfLifeFactors.isEmpty)
        #expect(profile.bedtime == .standard)
        #expect(profile.halfLife == .standard)
        #expect(!profile.hasCompletedOnboarding)
    }

    @Test func aProfileKeepsWhatItsGiven() throws {
        let bedtime = try #require(Bedtime(hour: 23, minute: 15))
        let halfLife = try #require(CaffeineHalfLife(seconds: 29_700))
        let profile = UserProfile(
            name: "Alex", birthYear: 1990, halfLifeFactors: [.estrogen], bedtime: bedtime, halfLife: halfLife,
            hasCompletedOnboarding: true)

        #expect(profile.name == "Alex")
        #expect(profile.birthYear == 1990)
        #expect(profile.halfLifeFactors == [.estrogen])
        #expect(profile.bedtime == bedtime)
        #expect(profile.halfLife == halfLife)
        #expect(profile.hasCompletedOnboarding)
    }
}
