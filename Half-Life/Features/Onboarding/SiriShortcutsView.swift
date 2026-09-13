//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life SiriShortcutsView
//

import AppIntents
import ComposableArchitecture
import SwiftUI

/// Onboarding's "Use Siri and Shortcuts" step: four phrases to try, and the button to Half-Life's shortcuts in the
/// Shortcuts app.
///
/// The phrases are drawn in the app's own style, not with Apple's `SiriTipView`, which UI tests can't find or audit
/// (the owner's choice, 2026-09-13). Each phrase says one of the App Shortcuts' phrases, so it works as written. The
/// button is Apple's `ShortcutsLink`, which opens the Shortcuts app itself. See the Onboarding article.
@MainActor
struct SiriShortcutsView: View {
    /// The step's store.
    let store: StoreOf<SiriShortcutsFeature>

    private func continueTapped() {
        store.send(.continueTapped)
    }

    /// The step's layout, its phrases, and the Shortcuts button.
    var body: some View {
        OnboardingStepLayout(
            step: 5, title: Text("Use Siri and Shortcuts"),
            lead: Text(
                """
                Half-Life works with Siri and the Shortcuts app as soon as it's installed. There's nothing to turn \
                on. Try saying:
                """),
            screenIdentifier: SiriShortcutsViewAccessibilityID.screen,
            contentIdentifier: SiriShortcutsViewAccessibilityID.content,
            buttonTitle: Text("Continue"), buttonIdentifier: SiriShortcutsViewAccessibilityID.continueButton,
            action: continueTapped
        ) {
            VStack(alignment: .leading, spacing: Spacing.itemGap) {
                phrase(
                    "“Log a latte in Half-Life”", symbol: "cup.and.saucer.fill",
                    identifier: SiriShortcutsViewAccessibilityID.logPhrase)
                phrase(
                    "“How much caffeine is in me in Half-Life?”", symbol: "chart.line.downtrend.xyaxis",
                    identifier: SiriShortcutsViewAccessibilityID.levelPhrase)
                phrase(
                    "“When should I go to sleep in Half-Life?”", symbol: "bed.double.fill",
                    identifier: SiriShortcutsViewAccessibilityID.sleepPhrase)
                phrase(
                    "“Ask Half-Life a question”", symbol: "text.bubble",
                    identifier: SiriShortcutsViewAccessibilityID.askPhrase)
            }
            VStack(alignment: .leading, spacing: Spacing.itemGap) {
                Text("See all of Half-Life's shortcuts in the Shortcuts app.")
                    .font(.body)
                    .foregroundStyle(Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                ShortcutsLink()
                    .accessibilityIdentifier(SiriShortcutsViewAccessibilityID.shortcutsLink)
            }
        }
    }

    /// One phrase to try, in a card, with a decorative symbol. VoiceOver reads the phrase as one element.
    private func phrase(_ text: LocalizedStringResource, symbol: String, identifier: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.itemGap) {
            Image(systemName: symbol)
                .foregroundStyle(Color.textPrimary)
                .accessibilityHidden(true)
            Text(text)
                .font(.body)
                .foregroundStyle(Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.cardPaddingCompact)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surfaceCard, in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                .strokeBorder(Color.borderCard, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(identifier)
    }
}

#Preview {
    NavigationStack {
        SiriShortcutsView(store: Store(initialState: SiriShortcutsFeature.State()) { SiriShortcutsFeature() })
    }
}
