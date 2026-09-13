//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life PrivacyCover
//

import SwiftUI

/// Covers a screen while the app isn't active and the app lock is on, so the app switcher's snapshot shows no caffeine
/// or health data.
///
/// The app goes inactive before the background, and iOS takes the snapshot on the way, before the lock screen could
/// replace the content. So the cover follows the scene's phase directly: it's purely visual, and holds no state
/// (constitution Article I.2). It also shows while the unlock prompt is up, over the lock screen, which shows nothing
/// either way. See the App Lock article.
@MainActor
struct PrivacyCover: ViewModifier {
    /// Whether the app lock is on.
    let isEnabled: Bool

    @Environment(\.scenePhase) private var scenePhase

    private var isCovered: Bool {
        isEnabled && scenePhase != .active
    }

    /// The content, hidden from VoiceOver and covered while the app isn't active.
    func body(content: Content) -> some View {
        content
            .accessibilityHidden(isCovered)
            .overlay {
                if isCovered {
                    PrivacyCoverView()
                }
            }
    }
}

extension View {
    /// Covers the view while the app isn't active and the app lock is on.
    ///
    /// - Parameter isEnabled: Whether the app lock is on.
    func privacyCover(isEnabled: Bool) -> some View {
        modifier(PrivacyCover(isEnabled: isEnabled))
    }
}

/// The cover itself: the app's page with its name, and nothing else.
@MainActor
private struct PrivacyCoverView: View {
    var body: some View {
        VStack(spacing: Spacing.sectionHeaderGap) {
            Image(systemName: "chart.line.downtrend.xyaxis")
                .font(.largeTitle)
                .accessibilityHidden(true)
            Text("Half-Life")
                .font(.titleLarge)
        }
        .foregroundStyle(Color.textPrimary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { OnboardingStepBackground() }
    }
}
