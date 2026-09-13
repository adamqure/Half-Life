//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life SplashView
//

import SwiftUI

/// The screen the app shows while it launches, until the first profile and the app lock have arrived.
///
/// It continues iOS's launch screen: the same page color, with the brand mark, one cup's decay curve, at the same size
/// in the middle of the screen, so the launch screen hands over to it with no visible change. If the launch takes
/// longer than ``detailDelay``, the app's name and a loading indicator fade in beneath the mark. A quick launch never
/// shows them, so they don't flash up and vanish. It has no store: it shows nothing that changes, and ``AppView``
/// replaces it once ``AppFeature/State/isLaunching`` turns false. See the Splash Screen article.
@MainActor
struct SplashView: View {
    /// How long the launch runs before the app's name and the loading indicator appear.
    static let detailDelay: Duration = .milliseconds(600)

    /// Whether the app's name and the loading indicator show. It's purely visual, so it's view state (constitution
    /// Article I.2).
    @State private var showsDetail = false

    /// The mark in the middle of the screen, with the name and the indicator beneath it once the delay has passed.
    var body: some View {
        // The two flexible regions share the height equally, so the mark sits in the middle of the whole screen,
        // where the launch screen draws it, whatever the detail's size.
        VStack(spacing: 0) {
            Color.clear
                .frame(maxHeight: .infinity)
            Image(.brandMark)
                .accessibilityHidden(true)
            detail
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .padding(.horizontal, Spacing.screenMargin)
        .background(Color.backgroundCanvasTop)
        .ignoresSafeArea()
        .task {
            try? await Task.sleep(for: Self.detailDelay)
            withAnimation(.easeIn(duration: 0.3)) {
                showsDetail = true
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(SplashViewAccessibilityID.screen)
    }

    /// The app's name and the loading indicator, once the delay has passed.
    @ViewBuilder private var detail: some View {
        if showsDetail {
            VStack(spacing: Spacing.itemGap) {
                Text("Half-Life")
                    .font(.titleLarge)
                    .foregroundStyle(Color.textPrimary)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier(SplashViewAccessibilityID.wordmark)
                ProgressView()
                    .tint(Color.textSecondary)
                    .accessibilityIdentifier(SplashViewAccessibilityID.progress)
            }
            .padding(.top, Spacing.sectionGap)
            .transition(.opacity)
        }
    }
}

#Preview {
    SplashView()
}
