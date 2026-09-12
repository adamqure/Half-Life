//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life LastCupView
//

import ComposableArchitecture
import SwiftUI

/// The Today screen's "Last cup" tile: the latest time the user's usual drink still leaves little enough caffeine in
/// them at bedtime, such as "By 1:06 PM", or "No more today".
///
/// It runs its feature's observation for as long as it's on screen. The time is formatted for the locale
/// (constitution Article VII.3). VoiceOver reads the heading, the answer, and the usual drink as one element. See the
/// Caffeine Cutoff article.
@MainActor
struct LastCupView: View {
    /// The tile's store.
    let store: StoreOf<LastCupFeature>

    private static let clockTime = Date.FormatStyle.dateTime.hour().minute()

    /// The tile's heading and, once the first cutoff arrives, its answer and the usual drink.
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.itemGap) {
            Text("Last cup")
                .font(.eyebrow)
                .textCase(.uppercase)
                .foregroundStyle(Color.textSecondary)
            if let cutoff = store.cutoff {
                // The Design System's `metric` style: 22 pt regular, scaling with `title2`. The answer and the caption
                // wrap rather than truncating in the half-width tile at large Dynamic Type sizes.
                Text(answer(for: cutoff))
                    .font(.title2)
                    .monospacedDigit()
                    .foregroundStyle(Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                usual(cutoff.drink)
                    .font(.footnote)
                    .foregroundStyle(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
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
        .accessibilityIdentifier(LastCupViewAccessibilityID.tile)
        .task { await store.send(.task).finish() }
    }

    /// "By 1:06 PM", or "No more today" when there's no cutoff.
    private func answer(for cutoff: CaffeineCutoff) -> LocalizedStringResource {
        guard let latestCup = cutoff.latestCup else { return "No more today" }
        return "By \(latestCup.formatted(Self.clockTime))"
    }

    /// The drink the cutoff is sized for, such as "Your usual: Latte, 2 shots".
    private func usual(_ drink: FavouriteDrink) -> Text {
        let name = Text(drink.type.displayName)
        let quantity = Text(drink.type.unit.quantityText(drink.quantity))
        return Text("Your usual: \(name), \(quantity)")
    }
}
