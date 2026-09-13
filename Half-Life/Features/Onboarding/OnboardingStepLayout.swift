//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life OnboardingStepLayout
//

import SwiftUI

/// The layout onboarding's steps share: the step's place in the flow, a title, a lead, the step's content, and a
/// primary button pinned to the bottom.
///
/// The content scrolls, so nothing is lost at the largest Dynamic Type sizes (constitution Article VI.2). The step's
/// place is written out ("Step 2 of 5") rather than drawn as dots, so it doesn't rely on color (Article VI.3).
@MainActor
struct OnboardingStepLayout<Content: View>: View {
    /// The step's place among the five numbered steps, from 1.
    let step: Int
    /// The step's title.
    let title: Text
    /// The line under the title.
    let lead: Text
    /// The step's `screen` accessibility identifier.
    let screenIdentifier: String
    /// The step's `content` accessibility identifier, on its scroll view.
    let contentIdentifier: String
    /// The primary button's title.
    let buttonTitle: Text
    /// The primary button's accessibility identifier.
    let buttonIdentifier: String
    /// Whether the primary button is disabled, such as while the step saves.
    var isButtonDisabled = false
    /// What the primary button does.
    let action: () -> Void
    /// The step's own content.
    @ViewBuilder let content: Content

    /// The step's layout.
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.sectionGap) {
                VStack(alignment: .leading, spacing: Spacing.sectionHeaderGap) {
                    OnboardingEyebrow(text: Text("Step \(step) of 5"))
                    title
                        .font(.titleLarge)
                        .foregroundStyle(Color.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                    lead
                        .font(.body)
                        .foregroundStyle(Color.textPrimary)
                }
                content
            }
            .padding(.horizontal, Spacing.screenMargin)
            .padding(.vertical, Spacing.itemGap)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityIdentifier(contentIdentifier)
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom) {
            OnboardingPrimaryButton(
                title: buttonTitle, identifier: buttonIdentifier, isDisabled: isButtonDisabled, action: action
            )
            .padding(.horizontal, Spacing.screenMargin)
            .padding(.bottom, Spacing.itemGap)
        }
        .background { OnboardingStepBackground() }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(screenIdentifier)
    }
}

/// Onboarding's primary button: full width, in the primary action color.
@MainActor
struct OnboardingPrimaryButton: View {
    /// The button's title.
    let title: Text
    /// The button's accessibility identifier.
    let identifier: String
    /// Whether the button is disabled.
    var isDisabled = false
    /// What the button does.
    let action: () -> Void

    /// The button.
    var body: some View {
        Button(action: action) {
            title
                .font(.headline)
                .foregroundStyle(Color.textOnEmphasis)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.itemGap)
                .frame(maxWidth: .infinity, minHeight: Sizing.buttonHeight)
                // No shadow, like the drink composer's Add button: on the summary, a shadow fell under "Take me to
                // Today", which the accessibility audit then failed for contrast.
                .background(
                    Color.actionPrimary, in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .accessibilityIdentifier(identifier)
    }
}

/// The page behind every onboarding screen: the canvas's top color, solid.
///
/// Over the gradient, the accessibility audit's contrast check failed text on the pushed steps, even `textPrimary` at
/// over 10:1 by the tokens' values, and failed Welcome's small `textSecondary` footer on some runs. On a solid page
/// it passes. Text set directly on this page uses `textPrimary`, because the audit also failed small `textSecondary`
/// text on it, which the tokens put at 5.6:1. Text on cards keeps the two tones. See the Onboarding article.
@MainActor
struct OnboardingStepBackground: View {
    /// The solid page, under the safe areas.
    var body: some View {
        Color.backgroundCanvasTop
            .ignoresSafeArea()
    }
}

/// A section label in onboarding: the eyebrow style, set uppercase, in the primary tone for the solid page.
@MainActor
struct OnboardingEyebrow: View {
    /// The label's text.
    let text: Text

    /// The label.
    var body: some View {
        text
            .font(.eyebrow)
            .textCase(.uppercase)
            .foregroundStyle(Color.textPrimary)
    }
}
