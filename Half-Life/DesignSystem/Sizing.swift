//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life Sizing
//

import CoreGraphics

/// Fixed sizes of controls, icons, and charts, in points.
nonisolated enum Sizing {
    /// The height of the decay curve on the Today screen.
    static let curveHeight: CGFloat = 160
    /// The smallest tappable area, in both directions. `performAccessibilityAudit()` checks hit regions
    /// against it, so every control must be at least this large.
    static let minimumHitTarget: CGFloat = 44
    /// The height of primary and secondary buttons.
    static let buttonHeight: CGFloat = 52
    /// The height of chips.
    static let chipHeight: CGFloat = 44
    /// The diameter of the log button in the tab bar.
    static let fabDiameter: CGFloat = 64
    /// The side of an icon tile in a settings-style row.
    static let iconTile: CGFloat = 34
    /// The side of an icon tile on a drink favourite.
    static let iconTileCompact: CGFloat = 26
}
