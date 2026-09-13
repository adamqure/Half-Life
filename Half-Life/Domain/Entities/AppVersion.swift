//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life AppVersion
//

/// The app's version and build, as Settings' root shows them on its last line.
///
/// Both are identifiers, not quantities, so they're kept as the Info.plist writes them. See the Settings article.
struct AppVersion: Sendable, Equatable {
    /// The version users see, such as "1.0": the Info.plist's `CFBundleShortVersionString`.
    let version: String
    /// The build number, such as "1": the Info.plist's `CFBundleVersion`.
    let build: String
}
