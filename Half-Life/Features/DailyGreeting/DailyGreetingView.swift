//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life DailyGreetingView
//

import ComposableArchitecture
import SwiftUI

/// The Today screen's greeting: "GOOD AFTERNOON, ALEX" above today's date.
///
/// It runs its feature's observations for as long as it's on screen. The greeting and the date form one accessibility
/// element, which is the screen's heading. See the Today Screen article.
@MainActor
struct DailyGreetingView: View {
    /// The greeting's store.
    let store: StoreOf<DailyGreetingFeature>

    /// The greeting and the date, once the first minute has arrived.
    var body: some View {
        VStack(alignment: .leading) {
            if let timeOfDay = store.timeOfDay {
                Text(greeting(for: timeOfDay.period))
                    .font(.eyebrow)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.textSecondary)
                Text(timeOfDay.date, format: .dateTime.weekday(.wide).month(.abbreviated).day())
                    .font(.titleLarge)
                    .foregroundStyle(Color.textPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        .accessibilityIdentifier(DailyGreetingViewAccessibilityID.header)
        .task { await store.send(.task).finish() }
    }

    private func greeting(for period: DayPeriod) -> LocalizedStringResource {
        switch (period, store.name) {
        case (.morning, nil): "Good morning"
        case let (.morning, name?): "Good morning, \(name)"
        case (.afternoon, nil): "Good afternoon"
        case let (.afternoon, name?): "Good afternoon, \(name)"
        case (.evening, nil): "Good evening"
        case let (.evening, name?): "Good evening, \(name)"
        }
    }
}
