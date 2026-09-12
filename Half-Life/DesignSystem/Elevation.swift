//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life Elevation
//

import CoreGraphics

/// A shadow that lifts an element off the surface beneath it.
///
/// Draw the shadow in the `textPrimary` color, a warm near-black, at the elevation's opacity:
/// `.shadow(color: .textPrimary.opacity(e.opacity), radius: e.radius, y: e.yOffset)`.
nonisolated struct Elevation: Equatable, Sendable {
    /// The opacity of the shadow color.
    let opacity: Double
    /// The shadow's blur radius, as SwiftUI's `shadow(color:radius:x:y:)` takes it.
    let radius: CGFloat
    /// How far the shadow falls below the element, in points.
    let yOffset: CGFloat

    /// The elevation of buttons, the log button, and the tab bar.
    static let floating = Elevation(opacity: 0.18, radius: 12, yOffset: 8)
    /// The elevation of cards, which pair it with the `borderCard` hairline.
    static let card = Elevation(opacity: 0.05, radius: 6, yOffset: 2)
}
