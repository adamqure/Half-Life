//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life AppView
//

import ComposableArchitecture
import SwiftUI

/// The app's root screen: the system tab bar with the Today screen, and the log button just above the bar, with
/// onboarding over it, full screen, until the profile is complete.
///
/// The log button is the tab bar's bottom accessory, an ordinary view, because the system tab bar's own buttons carry
/// no accessibility identifiers for UI tests (constitution Article II.6). It presents the drink composer as a sheet.
/// Patterns joins the bar as a second tab when it's built (roadmap rank 15). Until the first profile arrives, nothing
/// shows, so the Today screen never flashes up behind onboarding. See the Onboarding article.
@MainActor
struct AppView: View {
    /// The root store.
    @Bindable var store: StoreOf<AppFeature>

    /// The tab bar, its screen, and the log button, with onboarding presented over them.
    var body: some View {
        Group {
            if store.hasLoadedProfile {
                TabView {
                    Tab("Today", systemImage: "sun.max") {
                        TodayView(store: store.scope(state: \.today, action: \.today))
                    }
                }
                .tabViewBottomAccessory {
                    logButton
                }
                // The selected tab's label is small text, so it takes the text-safe accent. The brighter accent
                // color, meant for graphics, is below 4.5:1 on the bar.
                .tint(Color.textAccent)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AppViewAccessibilityID.screen)
        .sheet(item: $store.scope(state: \.composer, action: \.composer)) { composerStore in
            DrinkComposerView(store: composerStore)
        }
        .fullScreenCover(
            item: $store.scope(state: \.onboarding, action: \.onboarding),
            onDismiss: onboardingDismissed
        ) { onboardingStore in
            OnboardingView(store: onboardingStore)
        }
        .task { await store.send(.task).finish() }
    }

    /// Tells the root that onboarding's cover has finished going away.
    private func onboardingDismissed() {
        store.send(.onboardingDismissed)
    }

    /// The log button, drawn as an opaque capsule in the primary action color. On the accessory's glass alone, its
    /// label's contrast depends on whatever scrolls behind it, and the accessibility audit failed it.
    private var logButton: some View {
        Button {
            store.send(.logButtonTapped)
        } label: {
            Label("Log a drink", systemImage: "plus")
                .font(.headline)
                .foregroundStyle(Color.textOnEmphasis)
                .frame(maxWidth: .infinity, minHeight: Sizing.minimumHitTarget)
                .background(Color.actionPrimary, in: Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(AppViewAccessibilityID.logButton)
    }
}

#Preview {
    AppView(store: Store(initialState: AppFeature.State()) { AppFeature() })
}
