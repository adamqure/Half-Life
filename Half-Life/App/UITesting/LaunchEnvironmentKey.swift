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
}
