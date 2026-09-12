//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life SystemSettingsDataSource
//

/// Opens Half-Life's page in the Settings app.
///
/// Opening another app is system UI, so a data source does it, not a view (constitution Article I.6). See the
/// Onboarding article.
protocol SystemSettingsDataSource: Sendable {
    /// Opens Half-Life's page in the Settings app. It runs on the main actor, because UIKit opens apps there.
    @MainActor func openSettings() async
}
