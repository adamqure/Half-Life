//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests HalfLifeShortcutsTests
//

import AppIntents
import Testing

@testable import Half_Life

/// INTENT-SHORTCUTS-1 in the App Intents article.
struct HalfLifeShortcutsTests {

    /// INTENT-SHORTCUTS-1: one App Shortcut per intent, so every intent works through Siri with no setup.
    @Test func thereIsOneShortcutPerIntent() {
        #expect(HalfLifeShortcuts.appShortcuts.count == 6)
    }
}
