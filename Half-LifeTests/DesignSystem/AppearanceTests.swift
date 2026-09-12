//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests AppearanceTests
//

import Foundation
import Testing

/// Dark mode is deferred (see the Design System article), so the app stays in the light appearance its color
/// sets are designed for. The lock was the AI's decision and the owner disagrees with it. Remove this test,
/// with the build setting, when the dark-mode backlog item is built.
struct AppearanceTests {

    @Test func appIsLockedToLightAppearance() {
        #expect(Bundle.main.object(forInfoDictionaryKey: "UIUserInterfaceStyle") as? String == "Light")
    }
}
