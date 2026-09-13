//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life StepsDetailView
//

import Charts
import ComposableArchitecture
import SwiftUI

/// The steps screen: the steps on days after a caffeine night, against the other days, over the last 30 days.
///
/// A verdict card says what the comparison can honestly say, above each side's average steps and day count. A chart
/// shows each day's steps, and marks each day after a caffeine night with a coffee cup, the espresso drinks' symbol, as
/// well as a stronger color, so the mark never depends on color alone (constitution Article VI.3). VoiceOver reads the
/// chart as one element, with both sides' averages as its value. The title is a heading in the content rather than the
/// navigation bar's title, so its robot can find it by identifier (Article II.6). At accessibility text sizes, the
/// averages stack. See the Insights article.
@MainActor
struct StepsDetailView: View {
    /// The screen's store.
    let store: StoreOf<StepsDetailFeature>

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private static let wholeNumber = FloatingPointFormatStyle<Double>.number.precision(
        .fractionLength(0))
    private static let roundHundred = FloatingPointFormatStyle<Double>.number
        .rounded(rule: .toNearestOrAwayFromZero, increment: 100)
    private static let shortDate = Date.FormatStyle.dateTime.month(.abbreviated).day()
    /// The coffee cup the espresso drinks use, which marks a day after a caffeine night.
    private static let caffeineNightSymbol = "cup.and.saucer.fill"
    /// What a caffeine night is, in words rather than the threshold's amount.
    private static let definition: LocalizedStringResource = """
        A caffeine night is one with more than your recommended caffeine in you when you fell asleep, \
        or at your bedtime if Apple Health has no sleep that night.
        """

    /// The title and question, then, once the first comparison arrives, the verdict, the chart, and the source.
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.sectionGap) {
                header
                if let comparison = store.comparison {
                    verdictCard(comparison)
                    chartCard(comparison)
                    Text(comparison.isDemo ? "Demo steps" : "Steps from Apple Health")
                        .font(.footnote)
                        .foregroundStyle(Color.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier(StepsDetailViewAccessibilityID.source)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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
        .accessibilityIdentifier(StepsDetailViewAccessibilityID.screen)
        .task { await store.send(.task).finish() }
    }

    /// The symbol and "Steps", and the question the screen answers.
    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.itemGap) {
            HStack(spacing: Spacing.itemGap) {
                Image(systemName: HealthDataKind.steps.symbolName)
                    .font(.title2)
                    .foregroundStyle(HealthDataKind.steps.color)
                    .accessibilityHidden(true)
                Text(HealthDataKind.steps.title)
                    .font(.titleLarge)
                    .foregroundStyle(Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier(StepsDetailViewAccessibilityID.title)
            }
            Text("Do you walk less the day after a caffeine night?")
                .font(.body)
                .foregroundStyle(Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// The verdict, what it means, and each side's average and day count.
    private func verdictCard(_ comparison: StepsComparison) -> some View {
        let layout =
            dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.itemGap))
            : AnyLayout(HStackLayout(alignment: .top, spacing: Spacing.cardGap))
        return card {
            Text("The last 30 days")
                .font(.eyebrow)
                .textCase(.uppercase)
                .foregroundStyle(Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Text(Self.headline(comparison.verdict))
                .font(.title2.bold())
                .foregroundStyle(Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier(StepsDetailViewAccessibilityID.verdict)
            Text(Self.explanation(comparison.verdict))
                .font(.body)
                .foregroundStyle(Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Divider()
            layout {
                side("After a caffeine night", comparison.afterCaffeineNight)
                    .accessibilityIdentifier(StepsDetailViewAccessibilityID.afterCaffeine)
                side("Other days", comparison.otherDays)
                    .accessibilityIdentifier(StepsDetailViewAccessibilityID.otherDays)
            }
            Text(Self.definition)
                .font(.footnote)
                .foregroundStyle(Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier(StepsDetailViewAccessibilityID.definition)
        }
    }

    /// One side's label, average steps, and day count, or "None yet". VoiceOver reads them as one element.
    private func side(_ title: LocalizedStringKey, _ group: StepsComparison.Group?) -> some View {
        VStack(alignment: .leading, spacing: Spacing.itemGap / 3) {
            Text(title)
                .font(.eyebrow)
                .textCase(.uppercase)
                .foregroundStyle(Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            if let group {
                Text("\(group.averageSteps.formatted(Self.wholeNumber)) steps")
                    .font(.title2)
                    .monospacedDigit()
                    .foregroundStyle(Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(group.dayCount) days")
                    .font(.footnote)
                    .foregroundStyle(Color.textSecondary)
            } else {
                Text("None yet")
                    .font(.title2)
                    .foregroundStyle(Color.textPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    /// Each day's steps as a bar, with the days after a caffeine night marked, a legend, and the first and last dates.
    private func chartCard(_ comparison: StepsComparison) -> some View {
        card {
            Text("Each day")
                .font(.eyebrow)
                .textCase(.uppercase)
                .foregroundStyle(Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Chart(comparison.days, id: \.day) { day in
                if let steps = day.steps {
                    BarMark(x: .value("Day", day.day, unit: .day), y: .value("Steps", steps))
                        .foregroundStyle(
                            day.followsCaffeineNight ? Color.dataActivity : Color.dataActivitySubtle
                        )
                        .annotation(position: .top, spacing: 2) {
                            if day.followsCaffeineNight {
                                Image(systemName: Self.caffeineNightSymbol)
                                    .font(.caption2)
                                    .foregroundStyle(Color.dataActivity)
                                    .accessibilityHidden(true)
                            }
                        }
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: Sizing.curveHeight)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("Steps each day"))
            .accessibilityValue(Text(Self.spokenSummary(comparison)))
            .accessibilityIdentifier(StepsDetailViewAccessibilityID.chart)
            if let first = comparison.days.first?.day, let last = comparison.days.last?.day {
                HStack {
                    Text(first, format: Self.shortDate)
                    Spacer()
                    Text(last, format: Self.shortDate)
                }
                .font(.footnote)
                .monospacedDigit()
                .foregroundStyle(Color.textSecondary)
            }
            legend
        }
    }

    /// What the bars' marks mean.
    private var legend: some View {
        VStack(alignment: .leading, spacing: Spacing.itemGap / 2) {
            Label {
                Text("The day after a caffeine night")
            } icon: {
                Image(systemName: Self.caffeineNightSymbol)
                    .foregroundStyle(Color.dataActivity)
            }
            Label {
                Text("Other days")
            } icon: {
                RoundedRectangle(cornerRadius: CornerRadius.extraSmall / 2, style: .continuous)
                    .fill(Color.dataActivitySubtle)
                    .frame(width: 10, height: 14)
            }
        }
        .font(.footnote)
        .foregroundStyle(Color.textPrimary)
        .accessibilityHidden(true)
    }

    /// A card: the content on the card surface, with its border and shadow.
    private func card(@ViewBuilder _ content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Spacing.itemGap) {
            content()
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
    }

    /// The verdict in a few words.
    private static func headline(_ verdict: StepsComparison.Verdict) -> LocalizedStringResource {
        switch verdict {
        case .tooFewDays:
            "Too few days to compare yet"
        case .noClearDifference:
            "No clear difference"
        case .fewerAfterCaffeineNight(let steps):
            "About \(steps.formatted(roundHundred)) fewer steps after a caffeine night"
        case .moreAfterCaffeineNight(let steps):
            "About \(steps.formatted(roundHundred)) more steps after a caffeine night"
        }
    }

    /// What the verdict means, and how far it can be trusted.
    private static func explanation(_ verdict: StepsComparison.Verdict) -> LocalizedStringResource {
        switch verdict {
        case .tooFewDays:
            "It needs at least 5 days with steps after a caffeine night, and 5 other days."
        case .noClearDifference:
            "The gap between the two is within your normal day-to-day swing, so it could be chance."
        case .fewerAfterCaffeineNight, .moreAfterCaffeineNight:
            "That's more than your day-to-day swing explains, but it's a pattern, not proof caffeine caused it."
        }
    }

    /// Both sides' averages and day counts, for VoiceOver.
    private static func spokenSummary(_ comparison: StepsComparison) -> LocalizedStringResource {
        let after = spoken(comparison.afterCaffeineNight)
        let other = spoken(comparison.otherDays)
        return "After a caffeine night: \(after). Other days: \(other)."
    }

    /// One side's average and day count, such as "8,420 steps over 30 days", or "none yet".
    private static func spoken(_ group: StepsComparison.Group?) -> String {
        guard let group else { return String(localized: "none yet") }
        let steps = group.averageSteps.formatted(wholeNumber)
        return String(localized: "\(steps) steps over \(group.dayCount) days")
    }
}

#Preview("A clear difference") {
    StepsDetailView(
        store: Store(
            initialState: StepsDetailFeature.State(
                comparison: StepsDetailPreviews.comparison(verdict: .fewerAfterCaffeineNight(steps: 1_540)))
        ) { StepsDetailFeature() })
}

#Preview("No clear difference, largest text") {
    StepsDetailView(
        store: Store(
            initialState: StepsDetailFeature.State(
                comparison: StepsDetailPreviews.comparison(verdict: .noClearDifference))
        ) { StepsDetailFeature() }
    )
    .dynamicTypeSize(.accessibility5)
}

/// Sample comparisons for the previews.
private enum StepsDetailPreviews {
    /// 30 days of steps, every third day after a caffeine night, with `verdict`.
    static func comparison(verdict: StepsComparison.Verdict) -> StepsComparison {
        let today = Calendar.current.startOfDay(for: .now)
        let days = (1...30).reversed().map { daysAgo in
            StepsComparison.Day(
                day: Calendar.current.date(byAdding: .day, value: -daysAgo, to: today) ?? today,
                steps: 6_000 + (daysAgo * 1_373) % 6_000, followsCaffeineNight: daysAgo % 3 == 0)
        }
        return StepsComparison(
            days: days, afterCaffeineNight: StepsComparison.Group(averageSteps: 7_380, dayCount: 10),
            otherDays: StepsComparison.Group(averageSteps: 8_920, dayCount: 20), verdict: verdict,
            threshold: .standard, isDemo: true)
    }
}
