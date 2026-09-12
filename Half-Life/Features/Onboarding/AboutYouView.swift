//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life AboutYouView
//

import ComposableArchitecture
import SwiftUI

/// Onboarding's About you step: a first name field and an age picker, both optional.
///
/// The name field offers the first name from the user's contact card through AutoFill, with no permission. See the
/// Onboarding article.
@MainActor
struct AboutYouView: View {
    /// The step's store.
    @Bindable var store: StoreOf<AboutYouFeature>

    /// Tells the step the user tapped Continue.
    private func continueTapped() {
        store.send(.continueTapped)
    }

    /// The step's content.
    var body: some View {
        OnboardingStepLayout(
            step: 1, title: Text("About you"),
            lead: Text(
                """
                Both are optional. Your name is for the greeting, and your age sets how much sleep Half-Life compares \
                yours with.
                """
            ),
            screenIdentifier: AboutYouViewAccessibilityID.screen,
            contentIdentifier: AboutYouViewAccessibilityID.content, buttonTitle: Text("Continue"),
            buttonIdentifier: AboutYouViewAccessibilityID.continueButton, isButtonDisabled: store.isSaving,
            action: continueTapped
        ) {
            VStack(alignment: .leading, spacing: Spacing.sectionGap) {
                VStack(alignment: .leading, spacing: Spacing.sectionHeaderGap) {
                    OnboardingEyebrow(text: Text("First name"))
                    TextField(text: $store.name, prompt: Text("What should we call you?"), axis: .vertical) {
                        Text("First name")
                    }
                    .lineLimit(1...3)
                    .textContentType(.givenName)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .font(.body)
                    .foregroundStyle(Color.textPrimary)
                    .padding(.horizontal, Spacing.cardPaddingCompact)
                    .padding(.vertical, Spacing.itemGap)
                    .frame(minHeight: Sizing.chipHeight)
                    .background(
                        Color.surfaceControl, in: RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                    )
                    .accessibilityIdentifier(AboutYouViewAccessibilityID.nameField)
                }
                VStack(alignment: .leading, spacing: Spacing.sectionHeaderGap) {
                    OnboardingEyebrow(text: Text("Age"))
                    Picker(selection: $store.age) {
                        Text("Prefer not to say").tag(Int?.none)
                        ForEach(AboutYouFeature.ages, id: \.self) { age in
                            Text(age.formatted()).tag(Int?.some(age))
                        }
                    } label: {
                        Text("Age")
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .background(
                        Color.surfaceCard, in: RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                    )
                    .accessibilityIdentifier(AboutYouViewAccessibilityID.agePicker)
                }
            }
        }
        .task { await store.send(.task).finish() }
    }
}
