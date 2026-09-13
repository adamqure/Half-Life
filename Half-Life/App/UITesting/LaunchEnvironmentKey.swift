//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life LaunchEnvironmentKey
//

/// The launch environment that UI tests use to set the app's starting state, shared with the UI test target.
///
/// Like a view's accessibility identifiers, this file belongs to both targets, so the app and its tests share one
/// definition (constitution Article II.7). See the Onboarding article.
enum LaunchEnvironmentKey {
    /// The key that starts the app with its profile in a new temporary file, an empty in-memory drink log, and
    /// simulated permissions. Its value is ``fresh`` or ``completed``.
    static let profile = "HALF_LIFE_UI_TEST_PROFILE"
    /// A profile with nothing saved, so onboarding shows.
    static let fresh = "fresh"
    /// A profile that has finished onboarding, so the Today screen shows.
    static let completed = "completed"
    /// The key that chooses the Health data a UI test's app holds: a comma-separated list of ``healthSleep``,
    /// ``healthInBed``, ``healthSteps``, and ``healthHeartRate``. Without it, the app holds none. See the Apple Health
    /// Card article.
    static let healthData = "HALF_LIFE_UI_TEST_HEALTH_DATA"
    /// Last night's sleep, with stages, and time in bed around it.
    static let healthSleep = "sleep"
    /// Last night's time in bed, with no sleep.
    static let healthInBed = "inBed"
    /// Today's steps.
    static let healthSteps = "steps"
    /// Today's resting heart rate.
    static let healthHeartRate = "heartRate"
    /// The key that gives a UI test's app the simulated language model. Its value is ``simulatedLanguageModel``.
    /// Without it, the language model is unavailable under a UI test, so a test doesn't depend on the Mac that runs
    /// it. See the Language Model article.
    static let languageModel = "HALF_LIFE_UI_TEST_LANGUAGE_MODEL"
    /// The simulated language model, which is available and writes its insight from the tool's facts.
    static let simulatedLanguageModel = "simulated"
    /// The key that holds a UI test's app on its splash screen, so the test can check and audit it. Its value is
    /// ``heldLaunch``. Without it, the app finishes launching. See the Splash Screen article.
    static let launch = "HALF_LIFE_UI_TEST_LAUNCH"
    /// A launch that never finishes: the app lock's setting never answers, so the app stays on its splash screen.
    static let heldLaunch = "held"
}
