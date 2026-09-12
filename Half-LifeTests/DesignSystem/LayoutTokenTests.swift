//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests LayoutTokenTests
//

import CoreGraphics
import Testing

@testable import Half_Life

/// Checks the spacing, corner radius, sizing, and elevation constants against the Design System article.
struct LayoutTokenTests {

    /// The 4 pt grid every spacing and radius value sits on.
    static let grid: CGFloat = 4

    static let spacing: [CGFloat] = [
        Spacing.screenMargin, Spacing.cardPadding, Spacing.cardPaddingCompact, Spacing.cardGap, Spacing.itemGap,
        Spacing.sectionGap, Spacing.sectionHeaderGap,
    ]

    static let radii: [CGFloat] = [
        CornerRadius.large, CornerRadius.medium, CornerRadius.small, CornerRadius.extraSmall,
    ]

    @Test func spacingHasDocumentedValues() {
        #expect(Self.spacing == [20, 20, 16, 16, 12, 28, 12])
    }

    @Test func cornerRadiiHaveDocumentedValues() {
        #expect(Self.radii == [20, 16, 12, 8])
    }

    @Test(arguments: spacing + radii)
    func valueSitsOnTheGrid(_ value: CGFloat) {
        #expect(value.truncatingRemainder(dividingBy: Self.grid) == 0)
    }

    @Test func sizingHasDocumentedValues() {
        #expect(Sizing.buttonHeight == 52)
        #expect(Sizing.chipHeight == 44)
        #expect(Sizing.fabDiameter == 64)
        #expect(Sizing.iconTile == 34)
        #expect(Sizing.iconTileCompact == 26)
        #expect(Sizing.curveHeight == 160)
    }

    /// Apple's minimum, which `performAccessibilityAudit()` checks (constitution Article VI).
    @Test func minimumHitTargetIsFortyFourPoints() {
        #expect(Sizing.minimumHitTarget == 44)
    }

    @Test(arguments: [Sizing.buttonHeight, Sizing.chipHeight, Sizing.fabDiameter])
    func tappableSizeMeetsMinimumHitTarget(_ size: CGFloat) {
        #expect(size >= Sizing.minimumHitTarget)
    }

    @Test func elevationHasDocumentedValues() {
        #expect(Elevation.floating == Elevation(opacity: 0.18, radius: 12, yOffset: 8))
        #expect(Elevation.card == Elevation(opacity: 0.05, radius: 6, yOffset: 2))
    }
}
