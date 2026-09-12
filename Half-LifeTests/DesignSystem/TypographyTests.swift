//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests TypographyTests
//

import SwiftUI
import Testing

@testable import Half_Life

/// Checks the type styles from the Design System article's Typography table that code defines so far.
struct TypographyTests {

    /// Eyebrow: 12 semibold, uppercase, with no tracking, scaling with `caption`. `caption2` fails the accessibility
    /// audit's Dynamic Type check, and tracked text fails its "Text clipped" check once it wraps.
    @Test func eyebrowIsSemiboldCaption() {
        #expect(Font.eyebrow == Font.caption.weight(.semibold))
    }

    /// Title large: 34 bold, scaling with `largeTitle`.
    @Test func titleLargeIsBoldLargeTitle() {
        #expect(Font.titleLarge == Font.largeTitle.bold())
    }

    /// Metric hero: 80 pt at the default size. Views scale it with `@ScaledMetric(relativeTo: .largeTitle)`.
    @Test func metricHeroIsEightyPoints() {
        #expect(Typography.metricHeroSize == 80)
    }

    /// A unit beside a metric is set at about 45% of the metric's size.
    @Test func metricUnitIsFortyFivePercentOfTheMetric() {
        #expect(Typography.metricUnitScale == 0.45)
    }
}
