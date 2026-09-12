//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life TodayView
//

import ComposableArchitecture
import SwiftUI

/// The Today screen: the greeting and the decay card now, and the drink-log cards as they're built.
///
/// Its cards stack in a scroll view over the page gradient. See the Today Screen article.
@MainActor
struct TodayView: View {
    /// The screen's store.
    let store: StoreOf<TodayFeature>

    /// The screen's cards.
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.sectionGap) {
                DailyGreetingView(store: store.scope(state: \.greeting, action: \.greeting))
                CaffeineDecayView(store: store.scope(state: \.caffeineDecay, action: \.caffeineDecay))
            }
            .padding(.horizontal, Spacing.screenMargin)
            .padding(.vertical, Spacing.sectionGap)
        }
        .background {
            LinearGradient(
                colors: [.backgroundCanvasTop, .backgroundCanvasBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(TodayViewAccessibilityID.screen)
    }
}

#Preview {
    TodayView(store: Store(initialState: TodayFeature.State()) { TodayFeature() })
}
