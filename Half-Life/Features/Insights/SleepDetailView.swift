//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life SleepDetailView
//

import ComposableArchitecture
import SwiftUI

/// The Insights tab's Sleep screen: time asleep, and the time to fall asleep, against the caffeine at sleep onset.
///
/// Its title is a heading in the content rather than the navigation bar's, so its robot can find it (constitution
/// Article II.6). The time asleep card says what the nights show, the tolerance, no drop, or too few nights, then
/// charts each night and compares the averages either side of the threshold. The time to fall asleep card does the
/// same with the nights that have time in bed. A footnote says it's a pattern, not proof, and where the sleep comes
/// from. Amounts and durations are formatted for the locale (Article VII.3), the charts never rely on color alone
/// (Article VI.3), and at accessibility text sizes the averages stack. See the Insights article.
@MainActor
struct SleepDetailView: View {
    /// The screen's store.
    let store: StoreOf<SleepDetailFeature>

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private static let asleepUnits: Set<Duration.UnitsFormatStyle.Unit> = [.hours, .minutes]
    private static let fallingAsleepUnits: Set<Duration.UnitsFormatStyle.Unit> = [.minutes]

    /// The title, then, once the first analysis arrives, the analysis, the two chart cards, and the footnote.
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.sectionGap) {
                header
                if let analysis = store.analysis, let finding = store.finding {
                    analysisCard(finding)
                    timeAsleepCard(analysis)
                    fallingAsleepCard(analysis)
                    footnote(analysis)
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
        .accessibilityIdentifier(SleepDetailViewAccessibilityID.screen)
        .task { await store.send(.task).finish() }
    }

    /// The symbol and the title.
    ///
    /// The title stands alone: body text just under the navigation bar sits in its scroll edge effect, which the
    /// accessibility audit reads as low contrast. Large text needs only 3:1, so the title passes.
    private var header: some View {
        HStack(spacing: Spacing.itemGap) {
            Image(systemName: HealthDataKind.sleep.symbolName)
                .font(.title2)
                .foregroundStyle(HealthDataKind.sleep.color)
                .accessibilityHidden(true)
            Text("Sleep")
                .font(.titleLarge)
                .foregroundStyle(Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier(SleepDetailViewAccessibilityID.title)
        }
    }

    /// What the nights show across both charts: a headline about time asleep, and a sentence about both measures. It
    /// has a card of its own above them, because it draws on both (SLEEPSCREEN-4).
    private func analysisCard(_ finding: SleepDetailFeature.Finding) -> some View {
        card(SleepDetailViewAccessibilityID.analysisCard) {
            eyebrow("What your nights show")
            VStack(alignment: .leading, spacing: Spacing.itemGap / 2) {
                Text(Self.headline(finding))
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)
                Text(Self.explanation(finding, fallingAsleep: store.fallingAsleep))
                    .font(.subheadline)
                    .foregroundStyle(Color.textPrimary)
            }
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier(SleepDetailViewAccessibilityID.finding)
        }
    }

    /// Each night's time asleep as a chart, and the averages either side of the threshold.
    private func timeAsleepCard(_ analysis: SleepCaffeineAnalysis) -> some View {
        let points = analysis.nights.map {
            SleepCaffeineChart.Point(milligrams: $0.caffeineAtOnset, seconds: $0.asleepSeconds)
        }
        return card(SleepDetailViewAccessibilityID.timeAsleepCard) {
            eyebrow("Time asleep")
            if !points.isEmpty {
                SleepCaffeineChart(
                    points: points, threshold: analysis.threshold.milligrams, units: Self.asleepUnits,
                    label: "Time asleep against caffeine",
                    summary: Self.summary(
                        of: analysis.timeAsleep, count: points.count, threshold: analysis.threshold,
                        units: Self.asleepUnits)
                )
                .accessibilityIdentifier(SleepDetailViewAccessibilityID.timeAsleepChart)
            }
            if let comparison = analysis.timeAsleep {
                averages(comparison, threshold: analysis.threshold, units: Self.asleepUnits)
                    .accessibilityIdentifier(SleepDetailViewAccessibilityID.timeAsleepComparison)
            }
        }
    }

    /// The nights with time in bed as a chart and their averages, or why the time to fall asleep can't be compared: too
    /// few nights, or no time in bed recorded for any of them.
    private func fallingAsleepCard(_ analysis: SleepCaffeineAnalysis) -> some View {
        let points = analysis.nights.compactMap { night in
            night.secondsToFallAsleep.map { SleepCaffeineChart.Point(milligrams: night.caffeineAtOnset, seconds: $0) }
        }
        let amount = SleepWindowChart.amount(analysis.threshold.milligrams)
        return card(SleepDetailViewAccessibilityID.fallingAsleepCard) {
            eyebrow("Time to fall asleep")
            if points.isEmpty && !analysis.nights.isEmpty {
                note(
                    """
                    Apple Health hasn't recorded when you got into bed, so the time you took to fall asleep can't be \
                    measured.
                    """
                )
            } else if points.isEmpty {
                note(Self.needsNightsInBed(amount))
            } else {
                SleepCaffeineChart(
                    points: points, threshold: analysis.threshold.milligrams, units: Self.fallingAsleepUnits,
                    label: "Time to fall asleep against caffeine",
                    summary: Self.summary(
                        of: analysis.timeToFallAsleep, count: points.count,
                        threshold: analysis.threshold, units: Self.fallingAsleepUnits)
                )
                .accessibilityIdentifier(SleepDetailViewAccessibilityID.fallingAsleepChart)
                if let comparison = analysis.timeToFallAsleep {
                    averages(comparison, threshold: analysis.threshold, units: Self.fallingAsleepUnits)
                        .accessibilityIdentifier(SleepDetailViewAccessibilityID.fallingAsleepComparison)
                } else {
                    note(Self.needsNightsInBed(amount))
                }
            }
        }
    }

    /// What the screen compares, that it's a pattern, not proof, and where the sleep comes from, on a card's surface.
    private func footnote(_ analysis: SleepCaffeineAnalysis) -> some View {
        VStack(alignment: .leading, spacing: Spacing.itemGap / 2) {
            Text(
                """
                Your last \(SleepToleranceRule.days) days of sleep, against the caffeine in you when you fell \
                asleep.
                """
            )
            Text("A pattern in your own nights, not proof that caffeine caused it.")
            Text(analysis.isDemo ? "Demo sleep data" : "Sleep from Apple Health")
                .accessibilityIdentifier(SleepDetailViewAccessibilityID.source)
        }
        .font(.footnote)
        .foregroundStyle(Color.textSecondary)
        .fixedSize(horizontal: false, vertical: true)
        .padding(Spacing.cardPaddingCompact)
        .frame(maxWidth: .infinity, alignment: .leading)
        // On a card's surface: the accessibility audit failed long text straight on the page's gradient, even in
        // primary text, wherever it sat.
        .background(Color.surfaceCard, in: RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
    }

    /// The average either side of the threshold, each with its number of nights. At accessibility text sizes, they
    /// stack.
    private func averages(
        _ comparison: SleepComparison, threshold: SleepThreshold, units: Set<Duration.UnitsFormatStyle.Unit>
    ) -> some View {
        let amount = SleepWindowChart.amount(threshold.milligrams)
        let layout =
            dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.itemGap))
            : AnyLayout(HStackLayout(alignment: .top, spacing: Spacing.cardGap))
        return layout {
            average(
                "At or under \(amount)", seconds: comparison.underSeconds, nights: comparison.nightsUnder, units: units)
            average("Over \(amount)", seconds: comparison.overSeconds, nights: comparison.nightsOver, units: units)
        }
    }

    /// One side's small uppercase label, its average, and its number of nights. VoiceOver reads them as one element.
    private func average(
        _ title: LocalizedStringResource, seconds: TimeInterval, nights: Int,
        units: Set<Duration.UnitsFormatStyle.Unit>
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.itemGap / 3) {
            Text(title)
                .font(.eyebrow)
                .textCase(.uppercase)
                .foregroundStyle(Color.textSecondary)
            Text(Duration.seconds(seconds), format: Duration.UnitsFormatStyle(allowedUnits: units, width: .narrow))
                .font(.title2)
                .monospacedDigit()
                .foregroundStyle(Color.textPrimary)
            Text("\(nights) nights")
                .font(.footnote)
                .foregroundStyle(Color.textSecondary)
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    /// A card's small uppercase heading.
    private func eyebrow(_ title: LocalizedStringResource) -> some View {
        Text(title)
            .font(.eyebrow)
            .textCase(.uppercase)
            .foregroundStyle(Color.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }

    /// A sentence that says why a comparison isn't shown.
    private func note(_ text: LocalizedStringResource) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(Color.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier(SleepDetailViewAccessibilityID.fallingAsleepNote)
    }

    /// `content` on a card, with the Insights tab's cards' surface, border, and shadow.
    private func card(_ identifier: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Spacing.itemGap, content: content)
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
            .accessibilityIdentifier(identifier)
    }

}

#Preview {
    NavigationStack {
        SleepDetailView(store: Store(initialState: SleepDetailFeature.State()) { SleepDetailFeature() })
    }
}
