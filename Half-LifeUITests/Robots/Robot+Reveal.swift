//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeUITests Robot+Reveal
//

import XCTest

extension Robot {
    /// Scrolls `screen` until `element` sits below the top bars and above the log button, waiting for it to appear.
    ///
    /// Settings' screens scroll under the status bar and navigation bar at the top, and under the log button and the
    /// tab bar at the bottom, where a tap would land on something else. It swipes slowly, and gives up after 12
    /// swipes, failing at the test's call site if the element never appears.
    ///
    /// - Parameters:
    ///   - element: The element to bring into view.
    ///   - screen: The screen's element, its scroll view, which is swiped.
    ///   - description: What the element is, for the failure message.
    func reveal(
        _ element: XCUIElement, on screen: XCUIElement, _ description: String, file: StaticString, line: UInt
    ) {
        require(screen, "The screen", file: file, line: line)
        let logButton = app.buttons[AppViewAccessibilityID.logButton]
        let top = app.frame.height * 0.18
        for _ in 0..<12 {
            let bottom = logButton.exists ? logButton.frame.minY - 16 : app.frame.height * 0.8
            if element.exists, element.frame.minY >= top, element.frame.maxY <= bottom { return }
            if element.exists, element.frame.minY < top {
                screen.swipeDown(velocity: .slow)
            } else {
                screen.swipeUp(velocity: .slow)
            }
        }
        require(element, description, file: file, line: line)
    }
}
