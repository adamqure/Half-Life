//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life HalfLifeFactorsView
//

import ComposableArchitecture
import SwiftUI

/// Onboarding's step that asks what changes how fast the user clears caffeine.
///
/// Each option shows whether it's chosen with a checkmark and the selected trait, not by its fill alone (constitution
/// Article VI.3). The step never shows the half-life the choices give. It says plainly that Half-Life isn't medical
/// advice. See the Onboarding article.
@MainActor
struct HalfLifeFactorsView: View {
    /// The step's store.
    let store: StoreOf<HalfLifeFactorsFeature>

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Tells the step the user tapped Continue.
    private func continueTapped() {
        store.send(.continueTapped)
    }

    /// The step's content.
    var body: some View {
        OnboardingStepLayout(
            step: 2, title: Text("Caffeine and your body"),
            lead: Text("Some things change how fast your body clears caffeine. Choose any that apply."),
            screenIdentifier: HalfLifeFactorsViewAccessibilityID.screen,
            contentIdentifier: HalfLifeFactorsViewAccessibilityID.content, buttonTitle: Text("Continue"),
            buttonIdentifier: HalfLifeFactorsViewAccessibilityID.continueButton,
            action: continueTapped
        ) {
            VStack(alignment: .leading, spacing: Spacing.itemGap) {
                FactorOption(
                    title: Text("None of these"), detail: nil,
                    isSelected: store.factors.isEmpty && !store.isChoosingTrimester,
                    identifier: HalfLifeFactorsViewAccessibilityID.noneOption
                ) {
                    store.send(.noneTapped)
                }
                FactorOption(
                    title: Text("I'm pregnant"), detail: Text("Caffeine clears more slowly as a pregnancy goes on."),
                    isSelected: store.trimester != nil, identifier: HalfLifeFactorsViewAccessibilityID.pregnantOption
                ) {
                    store.send(.pregnantTapped)
                }
                if store.isChoosingTrimester || store.trimester != nil {
                    trimesterChoices
                }
                FactorOption(
                    title: Text("I take estrogen"),
                    detail: Text("The combined pill, patch, or ring, or hormone therapy."),
                    isSelected: store.factors.contains(.estrogen),
                    identifier: HalfLifeFactorsViewAccessibilityID.estrogenOption
                ) {
                    store.send(.factorTapped(.estrogen))
                }
                FactorOption(
                    title: Text("I smoke cigarettes"),
                    detail: Text("Smoke speeds up how fast caffeine clears. Vaping and nicotine patches don't."),
                    isSelected: store.factors.contains(.smokes),
                    identifier: HalfLifeFactorsViewAccessibilityID.smokesOption
                ) {
                    store.send(.factorTapped(.smokes))
                }
                FactorOption(
                    title: Text("I have cirrhosis of the liver"), detail: nil,
                    isSelected: store.factors.contains(.cirrhosis),
                    identifier: HalfLifeFactorsViewAccessibilityID.cirrhosisOption
                ) {
                    store.send(.factorTapped(.cirrhosis))
                }
                FactorOption(
                    title: Text("I take fluvoxamine (Luvox)"), detail: Text("It slows caffeine down a great deal."),
                    isSelected: store.factors.contains(.fluvoxamine),
                    identifier: HalfLifeFactorsViewAccessibilityID.fluvoxamineOption
                ) {
                    store.send(.factorTapped(.fluvoxamine))
                }
                Text(
                    """
                    Half-Life isn't medical advice. If you're pregnant or have liver disease, ask your doctor how much \
                    caffeine is right for you.
                    """
                )
                .font(.footnote)
                .foregroundStyle(Color.textPrimary)
                .padding(.top, Spacing.itemGap)
            }
        }
        .task { await store.send(.task).finish() }
    }

    /// The trimester choices: a row, or a column from the xxLarge text size up.
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
                TrimesterChoice(
                    title: Text("First"), label: Text("First trimester"), isSelected: store.trimester == .first,
                    identifier: HalfLifeFactorsViewAccessibilityID.firstTrimester
                ) {
                    store.send(.trimesterTapped(.first))
                }
                TrimesterChoice(
                    title: Text("Second"), label: Text("Second trimester"), isSelected: store.trimester == .second,
                    identifier: HalfLifeFactorsViewAccessibilityID.secondTrimester
                ) {
                    store.send(.trimesterTapped(.second))
                }
                TrimesterChoice(
                    title: Text("Third"), label: Text("Third trimester"), isSelected: store.trimester == .third,
                    identifier: HalfLifeFactorsViewAccessibilityID.thirdTrimester
                ) {
                    store.send(.trimesterTapped(.third))
                }
            }
        }
        .padding(.leading, Spacing.cardPaddingCompact)
    }
}

/// One option: a checkmark circle, a title, and an optional detail, filled dark when chosen.
@MainActor
private struct FactorOption: View {
    let title: Text
    let detail: Text?
    let isSelected: Bool
    let identifier: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: Spacing.itemGap) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.accentOnEmphasis : Color.controlBorder)
                    .accessibilityHidden(true)
                VStack(alignment: .leading) {
                    title
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(isSelected ? Color.textOnEmphasis : Color.textPrimary)
                    if let detail {
                        detail
                            .font(.footnote)
                            .foregroundStyle(isSelected ? Color.textOnEmphasisSecondary : Color.textSecondary)
                    }
                }
                .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(Spacing.cardPaddingCompact)
            .frame(maxWidth: .infinity, minHeight: Sizing.minimumHitTarget, alignment: .leading)
            .background(
                isSelected ? Color.surfaceSelected : Color.surfaceCard,
                in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier(identifier)
    }
}

/// One trimester chip.
@MainActor
private struct TrimesterChoice: View {
    let title: Text
    let label: Text
    let isSelected: Bool
    let identifier: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
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
