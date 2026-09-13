//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life AppVersionRepository
//

/// The source of truth for the app's version and build.
///
/// An implementation reads them from an app version data source. See the Settings article.
protocol AppVersionRepository: Sendable {
    /// Streams the app's version and build once, then finishes, because they never change while the app runs.
    ///
    /// Without a version, it finishes without sending one.
    func appVersion() -> AsyncStream<AppVersion>
}
