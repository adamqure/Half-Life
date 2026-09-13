//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life AppLockView
//

import ComposableArchitecture
import SwiftUI

/// The lock screen: the app's name, what's hidden, and an Unlock button, in place of the tab bar while the app is
/// locked.
///
/// It tells its feature when the app becomes active, so the screen asks by itself, and when the app goes to the
/// background, so it asks again on the way back. It shows no caffeine or health data. It's laid out like the Welcome
/// screen, and scrolls, so nothing is lost at the largest Dynamic Type sizes (constitution Article VI.2). See the
/// App Lock article.
@MainActor
struct AppLockView: View {
    /// The lock screen's store.
    let store: StoreOf<AppLockFeature>

    @Environment(\.scenePhase) private var scenePhase

    /// The screen's content.
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.sectionGap) {
                Image(.brandMark)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: Spacing.sectionHeaderGap) {
                    Text("Half-Life is locked")
                        .font(.titleLarge)
                        .foregroundStyle(Color.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                    Text("Unlock it to see your caffeine and health data.")
                        .font(.body)
                        .foregroundStyle(Color.textPrimary)
                }
            }
            .padding(.horizontal, Spacing.screenMargin)
            .padding(.top, Spacing.sectionGap * 2)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollBounceBehavior(.basedOnSize)
        // The screen's identifier is on the scroll view, not the whole screen. The whole screen is the only child of
        // the root's `appView.screen` container, and SwiftUI merged the two into one element, so the lock screen's
        // identifier was lost (the UI test UI-LOCK-1 caught it). The scroll view has the Unlock button beside it.
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AppLockViewAccessibilityID.screen)
        .safeAreaInset(edge: .bottom) {
            OnboardingPrimaryButton(
                title: Text("Unlock"), identifier: AppLockViewAccessibilityID.unlockButton,
                isDisabled: store.isUnlocking
            ) {
                store.send(.unlockTapped)
            }
            .padding(.horizontal, Spacing.screenMargin)
            .padding(.bottom, Spacing.itemGap)
        }
        .background { OnboardingStepBackground() }
        .onAppear {
            if scenePhase == .active {
                store.send(.becameActive)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active: store.send(.becameActive)
            case .background: store.send(.enteredBackground)
            default: break
            }
        }
    }
}

#Preview {
    AppLockView(store: Store(initialState: AppLockFeature.State(hasPrompted: true)) { AppLockFeature() })
}
