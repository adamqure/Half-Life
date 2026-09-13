//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life BundleAppVersionDataSource
//

import Foundation

/// The live app version data source. It reads `CFBundleShortVersionString` and `CFBundleVersion` from the app
/// bundle's Info.plist, which the build settings `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` fill in.
///
/// It's the only code that reads them (constitution Article I.14). The lookup is injected so tests can give it any
/// Info.plist; the default is the app's own bundle.
struct BundleAppVersionDataSource: AppVersionDataSource {
    /// Returns an Info.plist key's string value, or `nil` if it has none.
    let infoValue: @Sendable (String) -> String?

    /// Creates an app version data source.
    ///
    /// - Parameter infoValue: Returns an Info.plist key's string value. Defaults to the app bundle's.
    init(
        infoValue: @escaping @Sendable (String) -> String? = {
            Bundle.main.object(forInfoDictionaryKey: $0) as? String
        }
    ) {
        self.infoValue = infoValue
    }

    /// Returns the Info.plist's version and build, or `nil` if either is missing.
    func appVersion() -> AppVersion? {
        guard let version = infoValue("CFBundleShortVersionString"), let build = infoValue("CFBundleVersion") else {
            return nil
        }
        return AppVersion(version: version, build: build)
    }
}
