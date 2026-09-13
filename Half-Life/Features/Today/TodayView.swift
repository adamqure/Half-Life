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

/// The Today screen: the greeting, the decay card, the "Today" and "Last cup" tiles, the one-tap row, the history card,
/// and, at the bottom, the Apple Health card when Health has something to show.
///
/// Its cards stack in a scroll view over the page gradient. The Apple Health card is hidden until it has something to
/// show, and a hidden view never runs `.task`, so the scroll view starts its observation. See the Today Screen and
/// Apple Health Card articles.
@MainActor
struct TodayView: View {
    /// The screen's store.
    let store: StoreOf<TodayFeature>

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// The screen's cards.
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.sectionGap) {
                DailyGreetingView(store: store.scope(state: \.greeting, action: \.greeting))
                VStack(spacing: Spacing.cardGap) {
                    CaffeineDecayView(store: store.scope(state: \.caffeineDecay, action: \.caffeineDecay))
                    tiles
                }
                OneTapLogView(store: store.scope(state: \.oneTapLog, action: \.oneTapLog))
                DrinkLogHistoryView(store: store.scope(state: \.history, action: \.history))
                HealthSummaryView(store: store.scope(state: \.healthSummary, action: \.healthSummary))
            }
            .padding(.horizontal, Spacing.screenMargin)
            .padding(.vertical, Spacing.sectionGap)
        }
        .task { await store.send(.healthSummary(.task)).finish() }
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

    /// The row of tiles under the decay card: the "Today" tile in the leading half and the "Last cup" tile in the
    /// trailing half, at the same height. At accessibility text sizes the tiles stack, each at full width.
    private var tiles: some View {
        let layout =
            dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: Spacing.cardGap))
            : AnyLayout(HStackLayout(alignment: .top, spacing: Spacing.cardGap))
        return layout {
            CaffeineIntakeTodayView(store: store.scope(state: \.caffeineIntakeToday, action: \.caffeineIntakeToday))
            LastCupView(store: store.scope(state: \.lastCup, action: \.lastCup))
        }
        // Each tile fills the row's height, which is its taller tile's.
        .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    TodayView(store: Store(initialState: TodayFeature.State()) { TodayFeature() })
}
