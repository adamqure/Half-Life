//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life UIKitSystemSettingsDataSource
//

import Foundation
import OSLog
import UIKit

/// Opens Half-Life's page in the Settings app, through UIKit.
///
/// Its one method runs on the main actor, the only main-actor code in the Data layer (constitution Article IV.1.3).
/// See the Onboarding article.
struct UIKitSystemSettingsDataSource: SystemSettingsDataSource {
    private static let logger = Logger(for: UIKitSystemSettingsDataSource.self)

    /// Opens a URL, and returns whether it opened.
    let open: @MainActor @Sendable (URL) async -> Bool

    /// Creates the data source.
    ///
    /// - Parameter open: Opens a URL. Defaults to asking the shared application.
    init(open: @escaping @MainActor @Sendable (URL) async -> Bool = { await UIApplication.shared.open($0) }) {
        self.open = open
    }

    /// Opens Half-Life's page in the Settings app. If it doesn't open, that's logged.
    @MainActor func openSettings() async {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            Self.logger.fault("The Settings app's address isn't a URL.")
            return
        }
        if await !open(url) {
            Self.logger.error("Couldn't open the Settings app.")
        }
    }
}
