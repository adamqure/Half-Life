//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life FactorsSettingsView
//

import ComposableArchitecture
import SwiftUI

/// Settings' Caffeine and your body screen: the factors that change how fast the user clears caffeine.
///
/// Each factor is an option that's chosen or not, with onboarding's copy. Choosing pregnancy shows the trimesters,
/// which save once one is chosen. Like onboarding, the screen never shows the half-life the factors give. See the
/// Settings article.
@MainActor
struct FactorsSettingsView: View {
    /// The screen's store.
    let store: StoreOf<ProfileSettingsFeature>

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// The options, and the note under them.
    var body: some View {
        SettingsScreen(
            title: Text("Caffeine and your body"), screenIdentifier: FactorsSettingsViewAccessibilityID.screen
        ) {
            VStack(alignment: .leading, spacing: Spacing.itemGap) {
                SettingsOption(
                    title: Text("I'm pregnant"), detail: Text("Caffeine clears more slowly as a pregnancy goes on."),
                    isSelected: store.isPregnant, identifier: FactorsSettingsViewAccessibilityID.pregnantOption
                ) {
                    store.send(.pregnancyToggled(!store.isPregnant))
                }
                if store.isPregnant {
                    trimesterChoices
                }
                option(
                    .estrogen, title: Text("I take estrogen"),
                    detail: Text("The combined pill, patch, or ring, or hormone therapy."),
                    identifier: FactorsSettingsViewAccessibilityID.estrogenOption)
                option(
                    .smokes, title: Text("I smoke cigarettes"),
                    detail: Text("Smoke speeds up how fast caffeine clears. Vaping and nicotine patches don't."),
                    identifier: FactorsSettingsViewAccessibilityID.smokesOption)
                option(
                    .cirrhosis, title: Text("I have cirrhosis of the liver"), detail: nil,
                    identifier: FactorsSettingsViewAccessibilityID.cirrhosisOption)
                option(
                    .fluvoxamine, title: Text("I take fluvoxamine (Luvox)"),
                    detail: Text("It slows caffeine down a great deal."),
                    identifier: FactorsSettingsViewAccessibilityID.fluvoxamineOption)
                Text(
                    """
                    Half-Life isn't medical advice. If you're pregnant or have liver disease, ask your doctor how much \
                    caffeine is right for you.
                    """
                )
                .font(.footnote)
                .foregroundStyle(Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, Spacing.itemGap)
            }
        }
        .task { await store.send(.task).finish() }
    }

    private func option(_ factor: HalfLifeFactor, title: Text, detail: Text?, identifier: String) -> some View {
        let isSelected = store.factors.contains(factor)
        return SettingsOption(title: title, detail: detail, isSelected: isSelected, identifier: identifier) {
            store.send(.factorToggled(factor, isOn: !isSelected))
        }
    }

    private var trimesterChoices: some View {
        let layout =
            dynamicTypeSize >= .xxLarge
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.itemGap))
            : AnyLayout(HStackLayout(spacing: Spacing.itemGap))
        return VStack(alignment: .leading, spacing: Spacing.sectionHeaderGap) {
            Text("Which trimester?")
                .font(.footnote)
                .foregroundStyle(Color.textPrimary)
            layout {
                trimesterChoice(
                    .first, title: Text("First"), label: Text("First trimester"),
                    identifier: FactorsSettingsViewAccessibilityID.firstTrimester)
                trimesterChoice(
                    .second, title: Text("Second"), label: Text("Second trimester"),
                    identifier: FactorsSettingsViewAccessibilityID.secondTrimester)
                trimesterChoice(
                    .third, title: Text("Third"), label: Text("Third trimester"),
                    identifier: FactorsSettingsViewAccessibilityID.thirdTrimester)
            }
        }
        .padding(.leading, Spacing.cardPaddingCompact)
    }

    private func trimesterChoice(
        _ trimester: Trimester, title: Text, label: Text, identifier: String
    ) -> some View {
        let isSelected = store.trimester == trimester
        return Button {
            store.send(.trimesterChosen(trimester))
        } label: {
            title
                .font(.callout.weight(.semibold))
                .foregroundStyle(isSelected ? Color.textOnEmphasis : Color.textPrimary)
                .padding(.horizontal, Spacing.cardPaddingCompact)
                .frame(minWidth: Sizing.minimumHitTarget, minHeight: Sizing.chipHeight)
                .background(
                    isSelected ? Color.controlSelected : Color.surfaceControl,
                    in: RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier(identifier)
    }
}
