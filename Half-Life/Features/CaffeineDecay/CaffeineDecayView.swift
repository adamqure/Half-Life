//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life CaffeineDecayView
//

import Charts
import ComposableArchitecture
import SwiftUI

/// The Today screen's decay card: the caffeine in your system now, where it's heading, and the curve.
///
/// It runs its feature's observations for as long as it's on screen. Amounts stay in milligrams and are formatted
/// with locale-aware APIs (constitution Article VII.3). See the Today Screen article.
@MainActor
struct CaffeineDecayView: View {
    /// The card's store.
    let store: StoreOf<CaffeineDecayFeature>

    @ScaledMetric(relativeTo: .largeTitle) private var heroSize = Typography.metricHeroSize

    private static let wholeNumber = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(0))
    private static let clockTime = Date.FormatStyle.dateTime.hour().minute()

    /// Writes a day and a clock time, such as "Today, 3:50 AM" or "Tomorrow, 3:50 AM". The day names and the order
    /// come from the locale. `Date.FormatStyle` has no relative day names, so this is a `DateFormatter`.
    private static let dayAndTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()

    /// The card's figure, sentence, and curve.
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.itemGap) {
            header
            if let status = store.status {
                figure(status.level.milligrams)
            }
            if let summary = store.summary {
                Text(sentence(for: summary))
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            curve
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
        .task { await store.send(.task).finish() }
    }

    /// "IN YOUR SYSTEM NOW", with the time. VoiceOver reads both as one element, before the figure.
    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            // At large Dynamic Type sizes the heading wraps rather than truncating, and it takes its width first.
            Text("In your system now")
                .font(.eyebrow)
                .textCase(.uppercase)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
            Spacer()
            if let timeOfDay = store.timeOfDay {
                Text(timeOfDay.date, format: Self.clockTime)
                    .font(.footnote)
                    .monospacedDigit()
            }
        }
        .foregroundStyle(Color.textSecondary)
        .accessibilityElement(children: .combine)
    }

    /// The hero figure: the number in the accent color, with a smaller unit beside it. VoiceOver reads the amount in
    /// full, such as "85 milligrams", because the heading above it says what it is.
    private func figure(_ milligrams: Double) -> some View {
        Text(heroText(milligrams))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(Self.measurement(milligrams).formatted(Self.spokenAmount)))
            .accessibilityIdentifier(CaffeineDecayViewAccessibilityID.level)
    }

    private func heroText(_ milligrams: Double) -> AttributedString {
        var text = Self.measurement(milligrams).formatted(Self.shownAmount.attributed)
        text.font = .system(size: heroSize, weight: .light).monospacedDigit()
        text.foregroundColor = Color.accent
        let unitRanges = text.runs[\.measurement].compactMap { component, range in component == .unit ? range : nil }
        for range in unitRanges {
            text[range].font = .system(size: heroSize * Typography.metricUnitScale, weight: .light)
            text[range].foregroundColor = Color.textSecondary
        }
        return text
    }

    private func sentence(for summary: CaffeineDecayFeature.Summary) -> LocalizedStringResource {
        switch summary {
        case .clear:
            return "Nothing in your system right now."
        case let .bedtime(atBedtime):
            let amount = Self.measurement(atBedtime.milligrams).formatted(Self.shownAmount)
            let bedtime = atBedtime.date.formatted(Self.clockTime)
            return "Down to about \(amount) by \(bedtime)."
        case let .bedtimeAndHalfGone(atBedtime, halfGone):
            let amount = Self.measurement(atBedtime.milligrams).formatted(Self.shownAmount)
            let bedtime = atBedtime.date.formatted(Self.clockTime)
            let halfGoneTime = halfGone.formatted(Self.clockTime)
            return "Down to about \(amount) by \(bedtime) — half of your last cup is gone by \(halfGoneTime)."
        }
    }

    /// The curve across its whole window, with the clock times at its two ends underneath.
    private var curve: some View {
        VStack(alignment: .leading, spacing: Spacing.itemGap / 2) {
            if let timeSpan = store.timeSpan {
                chart.chartXScale(domain: timeSpan)
                timeLabels(timeSpan)
            } else {
                chart
            }
        }
    }

    /// The start and end of the curve's window, each as a day and a clock time, under its left and right edges.
    /// VoiceOver reads them as one element, after the curve.
    private func timeLabels(_ timeSpan: ClosedRange<Date>) -> some View {
        let start = Self.dayAndTime.string(from: timeSpan.lowerBound)
        let end = Self.dayAndTime.string(from: timeSpan.upperBound)
        return HStack(alignment: .firstTextBaseline) {
            // At large Dynamic Type sizes each time wraps rather than truncating.
            Text(start)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: Spacing.itemGap)
            Text(end)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(.caption)
        .monospacedDigit()
        .foregroundStyle(Color.textSecondary)
        // Combined, not ignored, so the element keeps its text's static-text trait, and the audit doesn't take it for
        // a control with too small a hit area.
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("From \(start) to \(end)"))
        .accessibilityIdentifier(CaffeineDecayViewAccessibilityID.timeSpan)
    }

    /// The curve itself, with a dashed rule and a dot at the current level.
    private var chart: some View {
        Chart {
            ForEach(store.curve, id: \.date) { level in
                AreaMark(x: .value("Time", level.date), y: .value("Caffeine", level.milligrams))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.dataCaffeine.opacity(0.25), Color.dataCaffeine.opacity(0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                LineMark(x: .value("Time", level.date), y: .value("Caffeine", level.milligrams))
                    .foregroundStyle(Color.dataCaffeine)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
            }
            if let now = store.status?.level {
                RuleMark(x: .value("Current time", now.date))
                    .foregroundStyle(Color.controlBorder)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                PointMark(x: .value("Current time", now.date), y: .value("Caffeine", now.milligrams))
                    .foregroundStyle(Color.accent)
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(height: Sizing.curveHeight)
        .accessibilityLabel(Text("Caffeine over the day"))
        .accessibilityIdentifier(CaffeineDecayViewAccessibilityID.curve)
    }

    private static func measurement(_ milligrams: Double) -> Measurement<UnitMass> {
        Measurement(value: milligrams, unit: .milligrams)
    }

    private static let shownAmount = Measurement<UnitMass>.FormatStyle(
        width: .abbreviated, usage: .asProvided, numberFormatStyle: wholeNumber)

    private static let spokenAmount = Measurement<UnitMass>.FormatStyle(
        width: .wide, usage: .asProvided, numberFormatStyle: wholeNumber)
}
