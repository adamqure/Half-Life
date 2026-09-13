//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life SplashViewAccessibilityID
//

import Foundation

/// Accessibility identifiers for the splash screen, shared with the UI test target.
enum SplashViewAccessibilityID {
    /// The splash screen's root element, which robots use to detect the screen.
    static let screen = "splashView.screen"
    /// The app's name, which appears once the launch has taken long enough to need it.
    static let wordmark = "splashView.wordmark"
    /// The loading indicator beneath the app's name.
    static let progress = "splashView.progress"
}
