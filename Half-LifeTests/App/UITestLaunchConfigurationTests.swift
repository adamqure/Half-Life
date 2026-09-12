//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests UITestLaunchConfigurationTests
//

import Testing

@testable import Half_Life

struct UITestLaunchConfigurationTests {

    /// LAUNCH-1: with no launch environment key, the app isn't under a UI test.
    @Test func withoutTheKeyTheAppIsNotUnderAUITest() {
        let configuration = UITestLaunchConfiguration(environment: [:])

        #expect(configuration.profile == nil)
        #expect(!configuration.isUITest)
    }

    /// LAUNCH-1: the key's two values choose a fresh or a completed profile.
    @Test func theKeyChoosesAFreshOrACompletedProfile() {
        let fresh = UITestLaunchConfiguration(
            environment: [LaunchEnvironmentKey.profile: LaunchEnvironmentKey.fresh])
        let completed = UITestLaunchConfiguration(
            environment: [LaunchEnvironmentKey.profile: LaunchEnvironmentKey.completed])

        #expect(fresh.profile == .fresh)
        #expect(fresh.isUITest)
        #expect(completed.profile == .completed)
        #expect(completed.isUITest)
    }

    /// LAUNCH-1: an unknown value is ignored.
    @Test func anUnknownValueIsIgnored() {
        let configuration = UITestLaunchConfiguration(environment: [LaunchEnvironmentKey.profile: "sometimes"])

        #expect(configuration.profile == nil)
    }
}
