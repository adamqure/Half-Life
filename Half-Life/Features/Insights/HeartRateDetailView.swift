//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life HeartRateDetailView
//

import Charts
import ComposableArchitecture
import SwiftUI

/// The resting heart rate screen: what the user's own days show about their resting heart rate after a caffeine night.
///
/// A headline says what the last 30 days show: the difference in beats per minute, no clear difference, or that there
/// aren't enough days yet. Under it, the two groups' averages and day counts, then a dot for each day, filled after a
/// caffeine night and hollow after the others, so the groups never depend on color alone (constitution Article VI.3).
/// A footnote says what the comparison can't claim, how nights with no recorded sleep were measured, and where the
/// data comes from. Amounts, numbers, and dates are formatted for the locale (Article VII.3). At accessibility text
/// sizes, the groups stack. See the Insights article.
@MainActor
struct HeartRateDetailView: View {
    /// The screen's store.
    let store: StoreOf<HeartRateDetailFeature>

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .largeTitle) private var heroSize = Typography.metricHeroSize * 0.7
    @ScaledMetric(relativeTo: .body) private var dotSize: CGFloat = 10

    private static let wholeNumber = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(0))
    private static let amountStyle = Measurement<UnitMass>.FormatStyle(
        width: .abbreviated, usage: .asProvided, numberFormatStyle: wholeNumber)
    private static let spokenAmountStyle = Measurement<UnitMass>.FormatStyle(
        width: .wide, usage: .asProvided, numberFormatStyle: wholeNumber)
    private static let dayStyle = Date.FormatStyle.dateTime.month(.abbreviated).day()

    /// The title, then, once the first comparison arrives, the headline, the groups, the chart, and the footnote.
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.sectionGap) {
                heading
                if let comparison = store.comparison {
                    headline(comparison)
                    groups(comparison)
                    chart(comparison)
                    footnote(comparison)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.screenMargin)
            .padding(.vertical, Spacing.sectionGap)
        }
        .background {
            LinearGradient(
                colors: [.backgroundCanvasTop, .backgroundCanvasBottom], startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
        }
        .task { await store.send(.task).finish() }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(HeartRateDetailViewAccessibilityID.screen)
    }

    /// The heart symbol and the title. The title is a heading in the content, not the navigation bar's, so its robot
    /// can find it by identifier (Article II.6).
    private var heading: some View {
        HStack(spacing: Spacing.itemGap) {
            Image(systemName: HealthDataKind.restingHeartRate.symbolName)
                .font(.title2)
                .foregroundStyle(Color.dataHeart)
                .accessibilityHidden(true)
            Text(HealthDataKind.restingHeartRate.title)
                .font(.titleLarge)
                .foregroundStyle(Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier(HeartRateDetailViewAccessibilityID.title)
        }
    }

    // MARK: - Headline

    /// What the days show, large, with the sentence that explains it.
    private func headline(_ comparison: RestingHeartRateComparison) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sectionHeaderGap) {
            headlineFigure(comparison)
                .accessibilityIdentifier(HeartRateDetailViewAccessibilityID.headline)
            Text(Self.detail(of: comparison))
                .font(.body)
                .foregroundStyle(Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier(HeartRateDetailViewAccessibilityID.headlineDetail)
        }
        .card()
    }

    /// The difference in beats per minute when it's a pattern, or what the days show in words.
    @ViewBuilder
    private func headlineFigure(_ comparison: RestingHeartRateComparison) -> some View {
        if comparison.finding == .pattern, let difference = comparison.difference {
            let beats = Int(difference.rounded())
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(beats.formatted(.number.sign(strategy: .always())))
                    .font(.system(size: heroSize, weight: .light))
                    .monospacedDigit()
                Text("bpm")
                    .font(.system(size: heroSize * Typography.metricUnitScale, weight: .regular))
            }
            .foregroundStyle(Color.textPrimary)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                Text(
                    beats > 0
                        ? "\(abs(beats)) beats per minute higher" : "\(abs(beats)) beats per minute lower"))
        } else {
            Text(comparison.finding == .notEnoughDays ? "Not enough days yet" : "No clear difference")
                .font(.title.bold())
                .foregroundStyle(Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// The sentence under the headline.
    ///
    /// - Parameter comparison: The comparison to explain.
    /// - Returns: The sentence, with its amounts and counts formatted for the locale.
    static func detail(of comparison: RestingHeartRateComparison) -> LocalizedStringResource {
        let amount = Measurement(value: comparison.threshold.milligrams, unit: UnitMass.milligrams)
            .formatted(amountStyle)
        switch comparison.finding {
        case .pattern where (comparison.difference ?? 0) < 0:
            return "Your resting heart rate was lower the day after a night that began with over \(amount) of caffeine."
        case .pattern:
            return
                "Your resting heart rate was higher the day after a night that began with over \(amount) of caffeine."
        case .noClearDifference:
            return """
                After nights that began with over \(amount) of caffeine, your resting heart rate stayed within its \
                usual day-to-day range.
                """
        case .notEnoughDays:
            let needed = RestingHeartRateComparisonRule.minimumDays
            let after = comparison.afterCaffeine.dayCount
            let other = comparison.otherDays.dayCount
            return """
                This needs \(needed) days after a night that began with over \(amount) of caffeine, and \(needed) \
                after other nights. So far there are \(after) and \(other).
                """
        }
    }

    // MARK: - Groups

    /// The two groups' averages and day counts, side by side, or stacked at accessibility text sizes.
    private func groups(_ comparison: RestingHeartRateComparison) -> some View {
        let layout =
            dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.itemGap))
            : AnyLayout(HStackLayout(alignment: .top, spacing: Spacing.itemGap))
        return layout {
            group(
                "After a caffeine night", comparison.afterCaffeine, isFilled: true,
                identifier: HeartRateDetailViewAccessibilityID.afterCaffeine)
            group(
                "After other nights", comparison.otherDays, isFilled: false,
                identifier: HeartRateDetailViewAccessibilityID.otherDays)
        }
    }

    /// One group: its dot, its name, its average, and how many days it has. VoiceOver reads it as one element.
    private func group(
        _ name: LocalizedStringResource, _ group: RestingHeartRateComparison.Group, isFilled: Bool,
        identifier: String
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sectionHeaderGap / 2) {
            HStack(spacing: 6) {
                dot(isFilled: isFilled)
                    .accessibilityHidden(true)
                Text(name)
                    .font(.eyebrow)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text(Self.average(group))
                .font(.title2.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(Color.textPrimary)
            Text("\(group.dayCount) days")
                .font(.footnote)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(name))
        .accessibilityValue(Text(Self.spokenAverage(group)))
        .accessibilityIdentifier(identifier)
    }

    /// A group's average, such as "61 bpm", or a dash with no days.
    private static func average(_ group: RestingHeartRateComparison.Group) -> LocalizedStringResource {
        guard let average = group.averageBeatsPerMinute else { return "–" }
        return "\(Int(average.rounded())) bpm"
    }

    /// A group's average and days, as VoiceOver reads them.
    private static func spokenAverage(_ group: RestingHeartRateComparison.Group) -> LocalizedStringResource {
        guard let average = group.averageBeatsPerMinute else { return "No days yet" }
        let days = String(localized: "\(group.dayCount) days")
        return "\(Int(average.rounded())) beats per minute on average, \(days)"
    }

}

// The chart and the footnote, in an extension that keeps the view's body short. In this file, it reaches private
// members.
extension HeartRateDetailView {
    // MARK: - Chart

    /// A dot for each day's resting heart rate, filled after a caffeine night and hollow after the others, with a
    /// legend, and the first and last days under it. VoiceOver reads it as one element, with the groups' averages.
    private func chart(_ comparison: RestingHeartRateComparison) -> some View {
        let beats = comparison.days.map(\.beatsPerMinute)
        let low = ((beats.min() ?? 50) - 3).rounded(.down)
        let high = ((beats.max() ?? 70) + 3).rounded(.up)
        let amount = Measurement(value: comparison.threshold.milligrams, unit: UnitMass.milligrams)
            .formatted(Self.amountStyle)
        return VStack(alignment: .leading, spacing: Spacing.itemGap) {
            Text("The last 30 days")
                .font(.eyebrow)
                .textCase(.uppercase)
                .foregroundStyle(Color.textSecondary)
                .accessibilityAddTraits(.isHeader)
            Chart(comparison.days, id: \.day) { day in
                PointMark(
                    x: .value("Day", day.day, unit: .day), y: .value("Resting heart rate", day.beatsPerMinute)
                )
                .symbol { dot(isFilled: day.followsCaffeine) }
            }
            .chartYScale(domain: low...high)
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { _ in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .frame(height: Sizing.curveHeight)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("Resting heart rate, the last 30 days"))
            .accessibilityValue(Text(Self.chartSummary(of: comparison)))
            .accessibilityIdentifier(HeartRateDetailViewAccessibilityID.chart)
            if let first = comparison.days.first, let last = comparison.days.last {
                HStack {
                    Text(first.day, format: Self.dayStyle)
                    Spacer()
                    Text(last.day, format: Self.dayStyle)
                }
                .font(.footnote)
                .foregroundStyle(Color.textSecondary)
                .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 6) {
                legend("Over \(amount) of caffeine when the night began", isFilled: true)
                legend("\(amount) or less", isFilled: false)
            }
        }
        .card()
    }

    /// One line of the chart's legend: its dot and what it means.
    private func legend(_ text: LocalizedStringResource, isFilled: Bool) -> some View {
        HStack(spacing: 8) {
            dot(isFilled: isFilled)
                .accessibilityHidden(true)
            Text(text)
                .font(.footnote)
                .foregroundStyle(Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// What the chart shows, as VoiceOver reads it.
    private static func chartSummary(of comparison: RestingHeartRateComparison) -> LocalizedStringResource {
        let amount = Measurement(value: comparison.threshold.milligrams, unit: UnitMass.milligrams)
            .formatted(spokenAmountStyle)
        let after = spokenAverage(comparison.afterCaffeine)
        let other = spokenAverage(comparison.otherDays)
        return "After nights that began with over \(amount) of caffeine: \(after). After other nights: \(other)."
    }

    /// A day's marker: a filled dot after a caffeine night, a hollow one after the others.
    @ViewBuilder
    private func dot(isFilled: Bool) -> some View {
        if isFilled {
            Circle().fill(Color.dataHeart).frame(width: dotSize, height: dotSize)
        } else {
            Circle().strokeBorder(Color.dataHeart, lineWidth: 2).frame(width: dotSize, height: dotSize)
        }
    }

    // MARK: - Footnote

    /// What the comparison can't claim, how nights with no recorded sleep were measured, and where the data comes
    /// from, on a card.
    private func footnote(_ comparison: RestingHeartRateComparison) -> some View {
        let atBedtime = comparison.days.filter { $0.measuredAt == .bedtime }.count
        return VStack(alignment: .leading, spacing: Spacing.itemGap) {
            Text(
                """
                A pattern in your own days, not proof that caffeine caused it. Resting heart rate also moves with \
                exercise, illness, alcohol, and stress.
                """
            )
            .accessibilityIdentifier(HeartRateDetailViewAccessibilityID.footnote)
            if atBedtime > 0 {
                Text(
                    """
                    Caffeine is measured when Apple Health recorded you falling asleep. For nights with no sleep \
                    recorded, it's measured at your bedtime: \(atBedtime) of \(comparison.days.count).
                    """
                )
            }
            Text(comparison.isDemo ? "Demo heart rate and sleep" : "Heart rate and sleep from Apple Health")
                .accessibilityIdentifier(HeartRateDetailViewAccessibilityID.source)
        }
        .font(.footnote)
        .foregroundStyle(Color.textPrimary)
        .fixedSize(horizontal: false, vertical: true)
        // On a card: long text straight on the page gradient fails the accessibility audit's contrast check, and the
        // same text on a card's surface passes (half-life-ff's finding for UI-INS-12, in the Insights article).
        .card()
    }
}

extension View {
    /// Sets the view on a card: the card surface, with its corner, border, and shadow.
    fileprivate func card() -> some View {
        padding(Spacing.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                    .fill(Color.surfaceCard)
                    .shadow(
                        color: Color.textPrimary.opacity(Elevation.card.opacity), radius: Elevation.card.radius,
                        y: Elevation.card.yOffset)
            }
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                    .strokeBorder(Color.borderCard, lineWidth: 1)
            }
    }
}

#Preview {
    HeartRateDetailView(
        store: Store(initialState: HeartRateDetailFeature.State()) { HeartRateDetailFeature() })
}
