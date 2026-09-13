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

    /// LAUNCH-HEALTH: the Health data key lists the simulated Health data a UI test's app holds, and ignores anything
    /// else. Without it, the app holds none.
    @Test func theHealthDataKeyListsTheSimulatedHealthData() {
        let without = UITestLaunchConfiguration(
            environment: [LaunchEnvironmentKey.profile: LaunchEnvironmentKey.completed])
        let with = UITestLaunchConfiguration(
            environment: [
                LaunchEnvironmentKey.profile: LaunchEnvironmentKey.completed,
                LaunchEnvironmentKey.healthData:
                    [LaunchEnvironmentKey.healthSleep, LaunchEnvironmentKey.healthSteps, "weight"]
                    .joined(separator: ","),
            ])

        #expect(without.healthData.isEmpty)
        #expect(with.healthData == [.sleep, .steps])
    }

    /// LAUNCH-LM: the language model key asks for the simulated language model, and ignores any other value. Without
    /// it, there's none.
    @Test func theLanguageModelKeyAsksForTheSimulatedModel() {
        let completed = [LaunchEnvironmentKey.profile: LaunchEnvironmentKey.completed]
        let without = UITestLaunchConfiguration(environment: completed)
        let with = UITestLaunchConfiguration(
            environment: completed.merging(
                [LaunchEnvironmentKey.languageModel: LaunchEnvironmentKey.simulatedLanguageModel]) { $1 })
        let unknown = UITestLaunchConfiguration(
            environment: completed.merging([LaunchEnvironmentKey.languageModel: "real"]) { $1 })

        #expect(!without.usesSimulatedLanguageModel)
        #expect(with.usesSimulatedLanguageModel)
        #expect(!unknown.usesSimulatedLanguageModel)
    }

    /// LAUNCH-SPLASH: the launch key holds the app on its splash screen, and ignores any other value. Without it, the
    /// launch isn't held.
    @Test func theLaunchKeyHoldsTheSplashScreen() {
        let completed = [LaunchEnvironmentKey.profile: LaunchEnvironmentKey.completed]
        let without = UITestLaunchConfiguration(environment: completed)
        let with = UITestLaunchConfiguration(
            environment: completed.merging([LaunchEnvironmentKey.launch: LaunchEnvironmentKey.heldLaunch]) { $1 })
        let unknown = UITestLaunchConfiguration(
            environment: completed.merging([LaunchEnvironmentKey.launch: "slow"]) { $1 })

        #expect(!without.holdsLaunch)
        #expect(with.holdsLaunch)
        #expect(!unknown.holdsLaunch)
    }
}
