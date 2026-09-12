//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life Typography
//

import SwiftUI

/// Type-style constants that a SwiftUI `Font` can't carry, such as a metric's size before Dynamic Type scales it.
///
/// The styles themselves are `Font` extensions below. See the Design System article's Typography table.
nonisolated enum Typography {
    /// The size of the hero metric, such as the caffeine in your system now, in points at the default text size.
    ///
    /// Scale it with `@ScaledMetric(relativeTo: .largeTitle)` in the view, and set it light, with monospaced digits.
    static let metricHeroSize: CGFloat = 80
    /// The size of a unit beside a metric, such as "mg", as a fraction of the metric's size.
    static let metricUnitScale: CGFloat = 0.45
}

extension Font {
    /// Section labels and the greeting: 12 pt semibold at the default size, scaling with `caption`. Set it uppercase,
    /// with no tracking.
    ///
    /// It doesn't scale with `caption2`, and it has no tracking, because each fails an accessibility audit check:
    /// `caption2` fails the Dynamic Type check, and tracked text fails the "Text clipped" check once it wraps. See the
    /// Design System article.
    static let eyebrow = Font.caption.weight(.semibold)
    /// Screen titles and the Today screen's date: 34 pt bold at the default size, scaling with `largeTitle`.
    static let titleLarge = Font.largeTitle.bold()
}
