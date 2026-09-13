//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life SleepWindowChart
//

import Charts
import SwiftUI

/// Tonight's caffeine against the sleep threshold, with the window to fall asleep in shaded: the chart on the Insights
/// tab's "Best time to sleep tonight" card, and in Siri's answer to "When should I go to sleep?".
///
/// It's stateless, so the card, which has a store, and the App Intent's snippet, which doesn't, both draw it. The
/// chart's start and end are labeled with their times, so the window's place never depends on color (constitution
/// Article VI.3). VoiceOver reads the chart as one element, with the summary as its value. See the Insights and App
/// Intents articles.
@MainActor
struct SleepWindowChart: View {
    /// The night to draw.
    let window: SleepWindow

    private static let clockTime = Date.FormatStyle.dateTime.hour().minute()
    private static let wholeNumber = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(0))
    private static let shownAmount = Measurement<UnitMass>.FormatStyle(
        width: .abbreviated, usage: .asProvided, numberFormatStyle: wholeNumber)

    /// Creates the chart for a night. It's `nonisolated`, so an App Intent can build its snippet off the main actor.
    ///
    /// - Parameter window: The night to draw.
    nonisolated init(window: SleepWindow) {
        self.window = window
    }

    /// Tonight's caffeine as a line, the threshold as a dashed rule, and the window as a shaded band, with the chart's
    /// start and end times under it.
    var body: some View {
        let peak = window.levels.map(\.milligrams).max() ?? 0
        return VStack(spacing: Spacing.sectionHeaderGap / 2) {
            Chart {
                if let interval = window.window {
                    RectangleMark(
                        xStart: .value("Window start", interval.start), xEnd: .value("Window end", interval.end)
                    )
                    .foregroundStyle(Color.dataSleepSubtle)
                }
                ForEach(window.levels, id: \.date) { level in
                    LineMark(x: .value("Time", level.date), y: .value("Caffeine", level.milligrams))
                        .foregroundStyle(Color.dataCaffeine)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                }
                RuleMark(y: .value("Threshold", window.threshold.milligrams))
                    .foregroundStyle(Color.textSecondary)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text(Self.amount(window.threshold.milligrams))
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }
            }
            .chartXScale(domain: window.evening...window.chartEnd)
            .chartYScale(domain: 0...max(peak, window.threshold.milligrams * 1.5))
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: Sizing.curveHeight)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("Caffeine tonight"))
            .accessibilityValue(Text(Self.summary(of: window)))
            .accessibilityIdentifier(InsightsViewAccessibilityID.sleepWindowChart)
            HStack {
                Text(window.evening, format: Self.clockTime)
                Spacer()
                Text(window.chartEnd, format: Self.clockTime)
            }
            .font(.footnote)
            .monospacedDigit()
            .foregroundStyle(Color.textSecondary)
        }
    }

    /// Why the window is where it is: caffeine clears by the bedtime, after it, or not by noon.
    ///
    /// - Parameter window: The night to explain.
    /// - Returns: The sentence, with its amount and times formatted for the locale.
    static func summary(of window: SleepWindow) -> LocalizedStringResource {
        let amount = amount(window.threshold.milligrams)
        let bedtime = window.bedtime.formatted(clockTime)
        guard let clearsAt = window.clearsAt else {
            return "Caffeine should stay over \(amount) until after noon tomorrow."
        }
        if window.clearsBeforeBedtime {
            return "Caffeine should be under \(amount) by your \(bedtime) bedtime."
        }
        let clears = clearsAt.formatted(clockTime)
        return "Caffeine should drop under \(amount) at about \(clears), after your \(bedtime) bedtime."
    }

    /// An amount in whole milligrams, such as "40 mg".
    ///
    /// - Parameter milligrams: The amount, in milligrams.
    /// - Returns: The amount, formatted for the locale.
    static func amount(_ milligrams: Double) -> String {
        Measurement(value: milligrams, unit: UnitMass.milligrams).formatted(shownAmount)
    }
}
