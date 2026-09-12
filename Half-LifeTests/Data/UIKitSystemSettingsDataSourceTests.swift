//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests UIKitSystemSettingsDataSourceTests
//

import Foundation
import Testing
import UIKit

@testable import Half_Life

/// Checks that the Settings data source opens Half-Life's page in the Settings app, through a stand-in opener.
@MainActor
struct UIKitSystemSettingsDataSourceTests {

    @Test func opensTheAppsPageInSettings() async throws {
        let opened = Recorded<[URL]>([])
        let source = UIKitSystemSettingsDataSource { url in
            opened.update { $0.append(url) }
            return true
        }

        await source.openSettings()

        let expected = try #require(URL(string: UIApplication.openSettingsURLString))
        #expect(opened.value == [expected])
    }

    @Test func aRefusedOpenIsHandled() async {
        let attempts = Recorded(0)
        let source = UIKitSystemSettingsDataSource { _ in
            attempts.update { $0 += 1 }
            return false
        }

        await source.openSettings()

        #expect(attempts.value == 1)
    }
}
