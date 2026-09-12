//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life OnboardingView
//

import ComposableArchitecture
import SwiftUI

/// Onboarding: a navigation stack with Welcome at its root and each step pushed from its state.
///
/// The stack's back button returns to the previous step, and swiping back works too. See the Onboarding article.
@MainActor
struct OnboardingView: View {
    /// Onboarding's store.
    @Bindable var store: StoreOf<OnboardingFeature>

    /// The navigation stack.
    var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            WelcomeView {
                store.send(.getStartedTapped)
            }
        } destination: { step in
            switch step.case {
            case let .aboutYou(store):
                AboutYouView(store: store)
            case let .halfLifeFactors(store):
                HalfLifeFactorsView(store: store)
            case let .bedtime(store):
                BedtimeView(store: store)
            case let .permissions(store):
                PermissionsView(store: store)
            case let .summary(store):
                OnboardingSummaryView(store: store)
            }
        }
        .tint(Color.textPrimary)
    }
}

/// Onboarding's first screen: what Half-Life does, the one way in, and what happens to the user's data.
///
/// The prototype's "Continue with Apple" and "Continue with email" are cut, because the brief rules out accounts. Its
/// footer is reworded to be true: the drink log syncs to the user's private iCloud database (constitution Article V.1).
@MainActor
struct WelcomeView: View {
    /// What Get started does.
    let getStarted: () -> Void

    /// The screen's content.
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.sectionGap) {
                Image(systemName: "chart.line.downtrend.xyaxis")
                    .font(.largeTitle)
                    .foregroundStyle(Color.textPrimary)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: Spacing.sectionHeaderGap) {
                    Text("Half-Life")
                        .font(.titleLarge)
                        .foregroundStyle(Color.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                    Text(
                        """
                        Log your coffee in one tap. Half-Life borrows your sleep, steps, and heart rate from Apple \
                        Health, and shows you what your caffeine is actually doing.
                        """
                    )
                    .font(.body)
                    .foregroundStyle(Color.textPrimary)
                }
            }
            .padding(.horizontal, Spacing.screenMargin)
            .padding(.top, Spacing.sectionGap * 2)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityIdentifier(WelcomeViewAccessibilityID.content)
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: Spacing.itemGap) {
                OnboardingPrimaryButton(
                    title: Text("Get started"), identifier: WelcomeViewAccessibilityID.getStartedButton,
                    action: getStarted)
                Text(
                    """
                    Your health data stays on this iPhone. Your drink log syncs only to your own iCloud. No account \
                    needed.
                    """
                )
                .font(.footnote)
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Spacing.screenMargin)
            .padding(.bottom, Spacing.itemGap)
        }
        .background { OnboardingStepBackground() }
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(WelcomeViewAccessibilityID.screen)
    }
}

#Preview {
    OnboardingView(store: Store(initialState: OnboardingFeature.State()) { OnboardingFeature() })
}
