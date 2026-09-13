//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life HealthDataListView
//

import ComposableArchitecture
import SwiftUI

/// The Insights tab's Health data card: a button for each kind of Health data with any data, which opens its screen.
///
/// Each button shows the kind's symbol, in its data color, its name, and a chevron. The name says what the button is,
/// so the color is never the only signal (constitution Article VI.3), and the symbols are hidden from VoiceOver. With
/// no kind available, the card and its heading aren't in the layout at all. ``InsightsView`` starts its observation,
/// because a view that isn't on screen can't. See the Insights article.
@MainActor
struct HealthDataListView: View {
    /// The card's store.
    let store: StoreOf<HealthDataListFeature>

    /// The heading and a button for each available kind, or nothing.
    var body: some View {
        if store.isShown {
            VStack(alignment: .leading, spacing: Spacing.sectionHeaderGap) {
                Text("Against your caffeine")
                    .font(.eyebrow)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                VStack(spacing: 0) {
                    ForEach(store.kinds, id: \.self) { kind in
                        if kind != store.kinds.first {
                            Divider()
                                .padding(.leading, Spacing.cardPaddingCompact)
                        }
                        button(for: kind)
                    }
                }
                .background {
                    RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                        .fill(Color.surfaceCard)
                        .shadow(
                            color: Color.textPrimary.opacity(Elevation.card.opacity),
                            radius: Elevation.card.radius,
                            y: Elevation.card.yOffset
                        )
                }
                .overlay {
                    RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                        .strokeBorder(Color.borderCard, lineWidth: 1)
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(InsightsViewAccessibilityID.healthDataCard)
        }
    }

    /// The button for `kind`: its symbol on a light tile, its name, and a chevron.
    private func button(for kind: HealthDataKind) -> some View {
        Button {
            store.send(.kindTapped(kind))
        } label: {
            HStack(spacing: Spacing.itemGap) {
                Image(systemName: kind.symbolName)
                    .font(.body)
                    .foregroundStyle(kind.color)
                    .frame(width: Sizing.iconTile, height: Sizing.iconTile)
                    .background(kind.subtleColor, in: RoundedRectangle(cornerRadius: CornerRadius.extraSmall))
                    .accessibilityHidden(true)
                Text(kind.title)
                    .font(.body)
                    .foregroundStyle(Color.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.textSecondary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, Spacing.cardPaddingCompact)
            .padding(.vertical, Spacing.itemGap)
            .frame(minHeight: Sizing.minimumHitTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(kind.buttonIdentifier)
    }
}
