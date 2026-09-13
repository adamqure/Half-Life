//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life WhatWeNoticedView
//

import ComposableArchitecture
import SwiftUI

/// The Insights tab's first card, "What we noticed": one finding about the user's own nights, in the on-device model's
/// words, with "Feel right?".
///
/// It shows only once the finding is written, so it's hidden while the model is unavailable, without enough nights,
/// after a "Not really", and while the model writes. The finding is the model's own text, so it's shown verbatim, and
/// the card says who wrote it, and when its nights are the demo's. It sits on the dark emphasis surface, like the
/// half-life factors card. The parent starts its feature's observation, because a hidden view can't start its own
/// task. See the Insights article.
@MainActor
struct WhatWeNoticedView: View {
    /// The card's store.
    let store: StoreOf<WhatWeNoticedFeature>

    /// The finding, where it came from, and "Feel right?" while the card asks, or nothing while it's hidden.
    var body: some View {
        if let card = store.card, let insight = store.insight {
            VStack(alignment: .leading, spacing: Spacing.itemGap) {
                Text("What we noticed")
                    .font(.eyebrow)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.textOnEmphasisSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Text(verbatim: insight.headline)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.textOnEmphasis)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier(InsightsViewAccessibilityID.noticedHeadline)
                Text(verbatim: insight.sentence)
                    .font(.body)
                    .foregroundStyle(Color.textOnEmphasis)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier(InsightsViewAccessibilityID.noticedSentence)
                source(isDemo: card.isDemo)
                if card.asksForFeedback {
                    feelRight
                }
            }
            .padding(Spacing.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Color.surfaceEmphasis, in: RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
            )
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(InsightsViewAccessibilityID.noticedCard)
        }
    }

    /// Who wrote the finding, and whether its nights are the demo's, since the brief asks the app to say what's seeded.
    private func source(isDemo: Bool) -> some View {
        VStack(alignment: .leading) {
            Text("Written on your iPhone by Apple Intelligence")
            if isDemo {
                Text("Demo Health data")
                    .accessibilityIdentifier(InsightsViewAccessibilityID.noticedDemo)
            }
        }
        .font(.footnote)
        .foregroundStyle(Color.textOnEmphasisSecondary)
        .fixedSize(horizontal: false, vertical: true)
    }

    /// "Feel right?" on its own line, then its two answers, each half the card's width. Their titles wrap within it at
    /// large text sizes rather than being cut off (constitution Article VI.2).
    private var feelRight: some View {
        VStack(alignment: .leading, spacing: Spacing.itemGap) {
            Text("Feel right?")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.textOnEmphasis)
                .fixedSize(horizontal: false, vertical: true)
            HStack(alignment: .top, spacing: Spacing.itemGap) {
                answer(
                    "Yes", hint: "Keeps the finding, and stops asking.",
                    identifier: InsightsViewAccessibilityID.feelRightYes
                ) {
                    store.send(.answered(.agree))
                }
                answer(
                    "Not really", hint: "Hides this finding until it changes.",
                    identifier: InsightsViewAccessibilityID.feelRightNotReally
                ) {
                    store.send(.answered(.disagree))
                }
            }
        }
    }

    /// An answer, outlined on the emphasis surface, as wide as it's offered. Its title wraps rather than being cut off,
    /// so it keeps up with Dynamic Type, which the system's bordered style didn't.
    private func answer(
        _ title: LocalizedStringResource, hint: LocalizedStringResource, identifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.textOnEmphasis)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Spacing.cardPaddingCompact)
                .frame(maxWidth: .infinity, minHeight: Sizing.minimumHitTarget)
                .overlay {
                    RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                        .strokeBorder(Color.borderOnEmphasis, lineWidth: 1)
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text(hint))
        .accessibilityIdentifier(identifier)
    }
}
