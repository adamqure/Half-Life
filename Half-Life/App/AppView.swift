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

/// The app's root screen: the system tab bar with the Today, Insights, and Settings tabs, and the log button just above
/// the bar, with onboarding over it, full screen, until the profile is complete.
///
/// The log button is the tab bar's bottom accessory, an ordinary view, because the system tab bar's own buttons carry
/// no accessibility identifiers for UI tests. It presents the drink composer as a sheet. Robots find the tabs by their
/// titles, the one exception constitution Article II.6 allows. Until the first profile and the app lock arrive, the
/// splash screen shows, so the Today screen never flashes up behind onboarding or before the lock screen. It fades into
/// the app. While the app lock has
/// locked the app, the lock screen takes the tab bar's place. While the lock is on and the app isn't active, a cover
/// hides the screen and the composer, so the app switcher's snapshot shows nothing. It also starts the cutoff reminder,
/// which has no screen. See the Onboarding, Settings, App Lock, and Cutoff Reminder articles.
@MainActor
struct AppView: View {
    /// The root store.
    @Bindable var store: StoreOf<AppFeature>

    @Environment(\.scenePhase) private var scenePhase

    /// Whether the app lock is on, so the privacy cover hides the app while it isn't active.
    private var isAppLockEnabled: Bool {
        store.appLock?.isEnabled == true
    }

    /// The tab bar, its screen, and the log button, or the lock screen, with onboarding presented over them.
    var body: some View {
        // The splash is the root container's sibling, not its child. As the container's only child, SwiftUI merged the
        // two into one element and lost the splash's identifier, as it did the lock screen's (see the App Lock
        // article). As an overlay, it took the empty container's size, and its text was clipped.
        ZStack {
            Group {
                if !store.isLaunching {
                    if let lockStore = store.scope(state: \.lock, action: \.lock) {
                        AppLockView(store: lockStore)
                    } else {
                        tabs
                    }
                }
            }
            .privacyCover(isEnabled: isAppLockEnabled)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(AppViewAccessibilityID.screen)
            if store.isLaunching {
                SplashView()
                    .transition(.opacity)
            }
        }
        // The splash fades into the app, rather than cutting to it.
        .animation(.easeOut(duration: 0.25), value: store.isLaunching)
        .sheet(item: $store.scope(state: \.composer, action: \.composer)) { composerStore in
            DrinkComposerView(store: composerStore)
                .privacyCover(isEnabled: isAppLockEnabled)
        }
        .fullScreenCover(
            item: $store.scope(state: \.onboarding, action: \.onboarding),
            onDismiss: onboardingDismissed
        ) { onboardingStore in
            OnboardingView(store: onboardingStore)
        }
        .task { await store.send(.task).finish() }
        .task { await store.send(.appLockTask).finish() }
        .task { await store.send(.cutoffReminder(.task)).finish() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                store.send(.enteredBackground)
            }
        }
    }

    /// The tab bar with its screens, and the log button above it.
    private var tabs: some View {
        TabView {
            // Each title is its catalog key's text, from `AppTab`, which the UI tests share, so the robot
            // finds the tab's button by the same title (constitution Article II.6).
            Tab(AppTab.today.title(), systemImage: "sun.max") {
                TodayView(store: store.scope(state: \.today, action: \.today))
            }
            Tab(AppTab.insights.title(), systemImage: "chart.xyaxis.line") {
                InsightsView(store: store.scope(state: \.insights, action: \.insights))
            }
            Tab(AppTab.settings.title(), systemImage: "gearshape") {
                SettingsView(store: store.scope(state: \.settings, action: \.settings))
            }
        }
        .tabViewBottomAccessory {
            logButton
        }
        // The selected tab's label is small text, so it takes the text-safe accent. The brighter accent
        // color, meant for graphics, is below 4.5:1 on the bar.
        .tint(Color.textAccent)
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
