//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life Spacing
//

import CoreGraphics

/// Spacing between and inside elements, in points. Every value sits on a 4 pt grid.
///
/// See the Design System article for where each value comes from.
nonisolated enum Spacing {
    /// The inset between the screen's leading and trailing edges and its content.
    static let screenMargin: CGFloat = 20
    /// The inset inside large cards.
    static let cardPadding: CGFloat = 20
    /// The inset inside tiles and other small cards.
    static let cardPaddingCompact: CGFloat = 16
    /// The space between stacked cards.
    static let cardGap: CGFloat = 16
    /// The space between chips, tiles, and options in a group.
    static let itemGap: CGFloat = 12
    /// The space between sections of a screen.
    static let sectionGap: CGFloat = 28
    /// The space between a section's label and its content.
    static let sectionHeaderGap: CGFloat = 12
}
