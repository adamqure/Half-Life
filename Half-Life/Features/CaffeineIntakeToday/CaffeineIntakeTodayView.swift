//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life CaffeineIntakeTodayView
//

import ComposableArchitecture
import SwiftUI

/// The Today screen's "Today" tile: the caffeine logged so far today, such as "192 mg".
///
/// It runs its feature's observation for as long as it's on screen. The amount stays in milligrams and is formatted
/// with a locale-aware API (constitution Article VII.3). VoiceOver reads the heading and the amount as one element,
/// such as "Today, 192 milligrams". See the Today Screen article.
@MainActor
struct CaffeineIntakeTodayView: View {
    /// The tile's store.
    let store: StoreOf<CaffeineIntakeTodayFeature>

    private static let spokenAmount = Measurement<UnitMass>.FormatStyle(
        width: .wide, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(0)))

    /// The tile's heading and, once the first intake arrives, its amount.
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.itemGap) {
            Text("Today")
                .font(.eyebrow)
                .textCase(.uppercase)
                .foregroundStyle(Color.textSecondary)
            if let intake = store.intake {
                // The Design System's `metric` style: 22 pt regular, scaling with `title2`.
                // It wraps rather than truncating in the half-width tile at large Dynamic Type sizes.
                Text(CaffeineFormat.milligrams(intake.milligrams))
                    .font(.title2)
                    .monospacedDigit()
                    .foregroundStyle(Color.textAccent)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(Text(Self.spoken(intake.milligrams)))
            }
        }
        .padding(Spacing.cardPaddingCompact)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                .fill(Color.surfaceCard)
                .shadow(
                    color: Color.textPrimary.opacity(Elevation.card.opacity),
                    radius: Elevation.card.radius,
                    y: Elevation.card.yOffset
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                .strokeBorder(Color.borderCard, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(CaffeineIntakeTodayViewAccessibilityID.total)
        .task { await store.send(.task).finish() }
    }

    /// The amount in full, rounded to whole milligrams, such as "192 milligrams", for VoiceOver.
    private static func spoken(_ milligrams: Double) -> String {
        Measurement(value: milligrams, unit: UnitMass.milligrams).formatted(spokenAmount)
    }
}
