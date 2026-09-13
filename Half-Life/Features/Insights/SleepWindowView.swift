//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life SleepWindowView
//

import ComposableArchitecture
import SwiftUI

/// The Insights tab's "Best time to sleep tonight" card: the 90 minutes to fall asleep in, why they're there, and
/// tonight's caffeine against the sleep threshold.
///
/// It runs its feature's observation for as long as it's on screen. Times and amounts are formatted for the locale
/// (constitution Article VII.3). The window's times are written above the chart, and the chart's start and end are
/// labeled with theirs, so the window's place never depends on color (Article VI.3). The chart is
/// ``SleepWindowChart``, which Siri's snippet draws too. See the Insights article.
@MainActor
struct SleepWindowView: View {
    /// The card's store.
    let store: StoreOf<SleepWindowFeature>

    private static let clockTime = Date.FormatStyle.dateTime.hour().minute()

    /// The card's heading and, once the first window arrives, its times, summary, chart, and footnote.
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.itemGap) {
            Text("Best time to sleep tonight")
                .font(.eyebrow)
                .textCase(.uppercase)
                .foregroundStyle(Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            if let window = store.window {
                times(of: window)
                    .font(.largeTitle.weight(.light))
                    .monospacedDigit()
                    .foregroundStyle(Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier(InsightsViewAccessibilityID.sleepWindowTimes)
                Text(SleepWindowChart.summary(of: window))
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier(InsightsViewAccessibilityID.sleepWindowSummary)
                SleepWindowChart(window: window)
                Text(footnote(for: window))
                    .font(.footnote)
                    .foregroundStyle(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier(InsightsViewAccessibilityID.sleepWindowFootnote)
            }
        }
        .padding(Spacing.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                .fill(Color.surfaceCard)
                .shadow(
                    color: Color.textPrimary.opacity(Elevation.card.opacity),
                    radius: Elevation.card.radius,
                    y: Elevation.card.yOffset
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                .strokeBorder(Color.borderCard, lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(InsightsViewAccessibilityID.sleepWindowCard)
        .task { await store.send(.task).finish() }
    }

    /// The window's start and end as clock times, such as "12:24 AM – 1:54 AM", or "Not tonight" when caffeine
    /// doesn't clear. They're formatted one at a time, because an interval that crosses midnight would add its dates.
    @ViewBuilder
    private func times(of window: SleepWindow) -> some View {
        if let interval = window.window {
            let start = interval.start.formatted(Self.clockTime)
            let end = interval.end.formatted(Self.clockTime)
            Text("\(start) – \(end)")
        } else {
            Text("Not tonight")
        }
    }

    /// Where the threshold comes from: the trend in the user's time asleep, or, until their nights show one, clinical
    /// sleep studies. It doesn't claim the threshold is safe.
    private func footnote(for window: SleepWindow) -> LocalizedStringResource {
        let threshold = SleepWindowChart.amount(window.threshold.milligrams)
        switch window.threshold.source {
        case .learned:
            return "\(threshold) is where your time asleep starts to drop, from the trend in your recent nights."
        case .sleepStudies:
            return """
                Until your nights show a trend, this is \(threshold), a level clinical sleep studies support for the \
                average person.
                """
        }
    }
}
