//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeUITests Robot+TabBarAudit
//

import XCTest

/// How far above the log button the tab bar's soft edge fades the content under it, in points. The audit read text up
/// to about 40 pt above the button as low contrast on 2026-09-12, while it sat in that fade.
private let tabBarFadeHeight: CGFloat = 44

extension Robot {
    /// Runs the system accessibility audit on a screen shown in the root tab bar, twice: once as it opens, and once
    /// scrolled to its end.
    ///
    /// The bottom bar is the log button and the tab bar below it. The screen scrolls under the bar, so as it opens,
    /// its lowest cards sit behind the bar's glass, or in the fade just above it, and the audit reads their contrast
    /// against the bar. So the first audit ignores contrast issues for elements that reach into the fade, within
    /// `tabBarFadeHeight` above the log button's top edge, or below it, and for issues the audit can't tie to an
    /// element, such as a decorative icon that VoiceOver doesn't see. It never ignores one for the log button itself.
    /// Then the screen scrolls to its end, where nothing sits under the bar, and the second audit ignores nothing, so
    /// every card that was behind the bar is checked in full. The owner approved the exception, the second audit, and
    /// the fade on 2026-09-12 (constitution Article VI.4).
    func auditAccessibilityAboveTheTabBar() throws {
        let fadeTop = app.buttons[AppViewAccessibilityID.logButton].frame.minY - tabBarFadeHeight
        waitForAStillScreen()
        try app.performAccessibilityAudit { issue in
            guard issue.auditType == .contrast else { return false }
            guard let element = issue.element else { return true }
            guard element.identifier != AppViewAccessibilityID.logButton else { return false }
            return element.frame.maxY > fadeTop
        }
        scrollToTheEnd()
        waitForAStillScreen()
        try app.performAccessibilityAudit()
    }

    /// Swipes up until the screen's content stops moving. It watches the screen's first text, which rises with each
    /// swipe until the end is reached.
    private func scrollToTheEnd() {
        let marker = app.descendants(matching: .any)[Self.screenIdentifier].staticTexts.firstMatch
        var position = settledFrame(of: marker)
        for _ in 0..<10 {
            app.swipeUp(velocity: .slow)
            let next = settledFrame(of: marker)
            if next == position { return }
            position = next
        }
    }

    /// Reads `element`'s frame until two readings in a row agree, so a scroll that's still decelerating is waited out.
    private func settledFrame(of element: XCUIElement) -> CGRect {
        var previous = element.frame
        for _ in 0..<50 {
            let current = element.frame
            if current == previous { return current }
            previous = current
        }
        return previous
    }

    /// Waits until the screen stops changing: until two screenshots taken one after the other are identical, or 20
    /// have been taken. After a launch or a scroll, the bar's glass and the scroll edge effect keep animating after the
    /// content stops, and the audit reads contrast from the pixels on screen. It waits for that condition, not for a
    /// fixed time (constitution Article II.9).
    private func waitForAStillScreen() {
        var previous = app.screenshot().pngRepresentation
        for _ in 0..<20 {
            let current = app.screenshot().pngRepresentation
            if current == previous { return }
            previous = current
        }
    }

}
