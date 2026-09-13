//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life SleepCaffeineChart
//

import Charts
import SwiftUI

/// A scatter chart of nights on the Sleep screen: each night's caffeine at sleep onset across, and a sleep measure up,
/// with the threshold as a dashed rule.
///
/// Nights at or under the threshold are circles in `dataSleep`, and nights over it are triangles in `dataCaffeine`, so
/// the two groups never depend on color alone (constitution Article VI.3). The legend names them. VoiceOver reads the
/// chart as one element, with a summary as its value. See the Insights article.
@MainActor
struct SleepCaffeineChart: View {
    /// One night on the chart.
    struct Point: Hashable {
        /// The caffeine at sleep onset, in milligrams.
        let milligrams: Double
        /// The sleep measure, in seconds.
        let seconds: TimeInterval
    }

    /// The nights.
    let points: [Point]
    /// The threshold in use, in milligrams.
    let threshold: Double
    /// The units the measure's axis labels use, such as hours and minutes.
    let units: Set<Duration.UnitsFormatStyle.Unit>
    /// What VoiceOver calls the chart.
    let label: LocalizedStringResource
    /// What VoiceOver reads as the chart's value.
    let summary: LocalizedStringResource

    /// The nights as points, the threshold as a rule, the axes, and the legend.
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.itemGap / 2) {
            chart
                .frame(height: Sizing.curveHeight)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(label))
                .accessibilityValue(Text(summary))
            legend
        }
    }

    private var chart: some View {
        Chart {
            nightMarks
            thresholdRule
        }
        .chartXScale(domain: caffeineDomain)
        .chartYScale(domain: measureDomain)
        .chartXAxis { caffeineAxis }
        .chartYAxis { measureAxis }
        .chartXAxisLabel("Caffeine at sleep onset", alignment: .center)
    }

    /// A point for each night: a circle at or under the threshold, and a triangle over it.
    @ChartContentBuilder private var nightMarks: some ChartContent {
        ForEach(points.indices, id: \.self) { index in
            mark(for: points[index])
        }
    }

    private func mark(for point: Point) -> some ChartContent {
        let isOver = point.milligrams > threshold
        let symbol: BasicChartSymbolShape = isOver ? .triangle : .circle
        let color: Color = isOver ? .dataCaffeine : .dataSleep
        return PointMark(x: .value("Caffeine", point.milligrams), y: .value("Time", point.seconds))
            .foregroundStyle(color)
            .symbol(symbol)
    }

    /// The threshold, as a dashed rule.
    private var thresholdRule: some ChartContent {
        RuleMark(x: .value("Threshold", threshold))
            .foregroundStyle(Color.textSecondary)
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
    }

    /// From nothing to a little past the most caffeine, and always past the threshold.
    private var caffeineDomain: ClosedRange<Double> {
        let most = points.map(\.milligrams).max() ?? 0
        return 0...max(most * 1.1, threshold * 1.5)
    }

    /// From a little under the least to a little over the most, so the nights' spread fills the chart.
    private var measureDomain: ClosedRange<Double> {
        let seconds = points.map(\.seconds)
        let lowest = seconds.min() ?? 0
        let highest = seconds.max() ?? 0
        let padding = max((highest - lowest) * 0.15, 15 * 60)
        return max(0, lowest - padding)...(highest + padding)
    }

    /// Amounts in milligrams along the bottom.
    @AxisContentBuilder private var caffeineAxis: some AxisContent {
        AxisMarks(values: .automatic(desiredCount: 4)) { value in
            AxisGridLine()
            AxisValueLabel {
                if let amount = value.as(Double.self) {
                    Text(SleepWindowChart.amount(amount))
                }
            }
        }
    }

    /// How the measure's axis labels are written, such as "7h 30m".
    private var measureStyle: Duration.UnitsFormatStyle {
        Duration.UnitsFormatStyle(allowedUnits: units, width: .narrow)
    }

    /// Durations up the side, in the measure's units.
    @AxisContentBuilder private var measureAxis: some AxisContent {
        AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
            AxisGridLine()
            AxisValueLabel {
                if let seconds = value.as(Double.self) {
                    Text(Duration.seconds(seconds), format: measureStyle)
                }
            }
        }
    }

    /// The two groups' shapes and names. It's hidden from VoiceOver, because the chart's value says the same.
    private var legend: some View {
        let amount = SleepWindowChart.amount(threshold)
        let under = Label {
            Text("At or under \(amount)")
        } icon: {
            Image(systemName: "circle.fill").foregroundStyle(Color.dataSleep)
        }
        let over = Label {
            Text("Over \(amount)")
        } icon: {
            Image(systemName: "triangle.fill").foregroundStyle(Color.dataCaffeine)
        }
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: Spacing.cardGap) {
                under
                over
            }
            VStack(alignment: .leading, spacing: Spacing.itemGap / 2) {
                under
                over
            }
        }
        .font(.caption)
        .foregroundStyle(Color.textSecondary)
        .accessibilityHidden(true)
    }
}
