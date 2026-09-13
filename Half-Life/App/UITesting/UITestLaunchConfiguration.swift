//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life UITestLaunchConfiguration
//

import Foundation

/// How a UI test asked the app to start, read from the launch environment.
///
/// Outside UI tests the environment has no ``LaunchEnvironmentKey/profile`` key, and the app uses its real storage
/// and permissions. The Onboarding article lists its requirement, LAUNCH-1.
nonisolated struct UITestLaunchConfiguration: Sendable, Equatable {
    /// The profile a UI test starts with.
    enum Profile: Sendable, Equatable {
        /// Nothing saved, so onboarding shows.
        case fresh
        /// Onboarding finished, so the Today screen shows.
        case completed
    }

    /// The launch environment of this process.
    static let current = UITestLaunchConfiguration(environment: ProcessInfo.processInfo.environment)

    /// The profile the UI test asked for, or `nil` outside UI tests.
    let profile: Profile?

    /// The Health data the UI test's app holds, chosen by ``LaunchEnvironmentKey/healthData``. It's empty outside UI
    /// tests, and when the test chose none (LAUNCH-HEALTH in the Apple Health Card article).
    let healthData: Set<SimulatedHealthData>

    /// Whether the UI test asked for the simulated language model with ``LaunchEnvironmentKey/languageModel``. It's
    /// `false` outside UI tests (LAUNCH-LM in the Language Model article).
    let usesSimulatedLanguageModel: Bool

    /// Whether the UI test asked, with ``LaunchEnvironmentKey/launch``, for the app to stay on its splash screen. It's
    /// `false` outside UI tests (LAUNCH-SPLASH in the Splash Screen article).
    let holdsLaunch: Bool

    /// Whether a UI test launched the app.
    var isUITest: Bool {
        profile != nil
    }

    /// Reads the configuration from a launch environment.
    ///
    /// - Parameter environment: The process's environment variables.
    init(environment: [String: String]) {
        switch environment[LaunchEnvironmentKey.profile] {
        case LaunchEnvironmentKey.fresh: profile = .fresh
        case LaunchEnvironmentKey.completed: profile = .completed
        default: profile = nil
        }
        healthData = Set(
            (environment[LaunchEnvironmentKey.healthData] ?? "")
                .split(separator: ",")
                .compactMap { SimulatedHealthData(launchValue: String($0)) })
        usesSimulatedLanguageModel =
            environment[LaunchEnvironmentKey.languageModel] == LaunchEnvironmentKey.simulatedLanguageModel
        holdsLaunch = environment[LaunchEnvironmentKey.launch] == LaunchEnvironmentKey.heldLaunch
    }
}
