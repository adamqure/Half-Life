//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life InsightsView
//

import ComposableArchitecture
import SwiftUI

/// The Insights tab: "What we noticed", tonight's sleep window, the last 7 days, and the Health data buttons, whose
/// screens it pushes onto its navigation stack.
///
/// Its cards stack in a scroll view over the page gradient, under the title "Insights". It scrolls, so nothing is lost
/// at the largest Dynamic Type sizes (constitution Article VI.2). See the Insights article.
@MainActor
struct InsightsView: View {
    /// The tab's store.
    @Bindable var store: StoreOf<InsightsFeature>

    /// The tab's cards, under its title.
    var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.sectionGap) {
                    WhatWeNoticedView(store: store.scope(state: \.whatWeNoticed, action: \.whatWeNoticed))
                    SleepWindowView(store: store.scope(state: \.sleepWindow, action: \.sleepWindow))
                    LastSevenDaysView(store: store.scope(state: \.lastSevenDays, action: \.lastSevenDays))
                    HealthDataListView(store: store.scope(state: \.healthData, action: \.healthData))
                }
                .padding(.horizontal, Spacing.screenMargin)
                .padding(.vertical, Spacing.sectionGap)
            }
            .accessibilityIdentifier(InsightsViewAccessibilityID.content)
            .background {
                LinearGradient(
                    colors: [.backgroundCanvasTop, .backgroundCanvasBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }
            .navigationTitle(Text("Insights"))
            // The Health data card is hidden until a kind is available, and a hidden view can't start its own task.
            .task { await store.send(.healthData(.task)).finish() }
            // "What we noticed" is hidden until its finding is written, so its task starts here too.
            .task { await store.send(.whatWeNoticed(.task)).finish() }
        } destination: { store in
            switch store.case {
            case let .sleep(sleep):
                SleepDetailView(store: sleep)
            case let .steps(steps):
                StepsDetailView(store: steps)
            case let .restingHeartRate(detail):
                HeartRateDetailView(store: detail)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(InsightsViewAccessibilityID.screen)
    }
}

#Preview {
    InsightsView(store: Store(initialState: InsightsFeature.State()) { InsightsFeature() })
}
