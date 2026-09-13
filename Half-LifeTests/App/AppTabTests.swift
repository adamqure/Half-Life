//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests AppTabTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks that each tab's title comes from the String Catalog (TAB-1 in the Settings article, constitution Article
/// II.6). A key the catalog doesn't have would come back as the key itself, and show in the tab bar.
struct AppTabTests {

    /// The app's catalog in the development language, English.
    static let english: Bundle =
        Bundle.main.path(forResource: "en", ofType: "lproj").flatMap(Bundle.init(path:))
        ?? Bundle.main

    @Test(arguments: AppTab.allCases)
    func everyTabsTitleComesFromTheCatalog(_ tab: AppTab) {
        #expect(tab.title(in: Self.english) != tab.rawValue)
    }

    @Test func theTitlesAreTodayAndSettingsInEnglish() {
        #expect(AppTab.today.title(in: Self.english) == "Today")
        #expect(AppTab.settings.title(in: Self.english) == "Settings")
    }
}
