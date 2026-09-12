//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life CornerRadius
//

import CoreGraphics

/// Corner radii for rounded shapes, in points.
///
/// Draw them with the continuous corner style, for example
/// `RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)`. Toggles, segmented controls,
/// chart bars, and the log button are capsules or circles instead.
nonisolated enum CornerRadius {
    /// The radius of large cards.
    static let large: CGFloat = 20
    /// The radius of buttons, tiles, and option cards.
    static let medium: CGFloat = 16
    /// The radius of chips.
    static let small: CGFloat = 12
    /// The radius of icon tiles.
    static let extraSmall: CGFloat = 8
}
