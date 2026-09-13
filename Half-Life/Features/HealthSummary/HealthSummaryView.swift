//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life HealthSummaryView
//

import ComposableArchitecture
import SwiftUI

/// The Today screen's Apple Health card: a cell for each of last night's sleep, today's steps, and today's resting
/// heart rate that Health has, under an eyebrow that says where they came from.
///
/// It shows nothing until a summary with a metric arrives, and nothing at all when Health has none of them, so the
/// Today screen leaves no gap for it. It doesn't start its own observation, because a hidden view never runs `.task`:
/// ``TodayView`` sends the feature's `task`. Figures are formatted with locale-aware APIs (constitution Article
/// VII.3), and each cell is one element for VoiceOver, with its symbol hidden. See the Apple Health Card article.
@MainActor
struct HealthSummaryView: View {
    /// One metric the card shows.
    private struct Cell: Identifiable {
        /// The cell's accessibility identifier, which also identifies it.
        let id: String
        let label: LocalizedStringResource
        let figure: String
        let note: LocalizedStringResource?
        let symbol: String
        let color: Color
        let spokenLabel: String
    }

    /// The card's store.
    let store: StoreOf<HealthSummaryFeature>

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// The eyebrow and the card, when there's a metric to show.
    var body: some View {
        if let summary = store.summary, !summary.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.sectionHeaderGap) {
                Group {
                    if summary.isDemo {
                        Text("Demo Health data")
                    } else {
                        Text("From Apple Health")
                    }
                }
                .font(.eyebrow)
                .textCase(.uppercase)
                .foregroundStyle(Color.textSecondary)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier(HealthSummaryViewAccessibilityID.title)
                card(for: summary)
            }
        }
    }

    /// The cells in a row, or stacked at accessibility text sizes, with a line between each two.
    private func card(for summary: HealthSummary) -> some View {
        let layout =
            dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.itemGap))
            : AnyLayout(HStackLayout(alignment: .top, spacing: Spacing.itemGap))
        return layout {
            ForEach(Array(Self.cells(for: summary).enumerated()), id: \.element.id) { index, cell in
                if index > 0 {
                    divider
                }
                cellView(cell)
            }
        }
        // Each divider spans the row's height, which is its tallest cell's.
        .fixedSize(horizontal: false, vertical: true)
        .padding(Spacing.cardPaddingCompact)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background {
            RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                .fill(Color.surfaceMuted)
        }
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                .strokeBorder(Color.borderCard, lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(HealthSummaryViewAccessibilityID.card)
    }

    /// A hairline between two cells: upright in a row, and flat when the cells stack. It's decorative.
    private var divider: some View {
        Rectangle()
            .fill(Color.controlTrack)
            .frame(
                width: dynamicTypeSize.isAccessibilitySize ? nil : 1,
                height: dynamicTypeSize.isAccessibilitySize ? 1 : nil
            )
            .accessibilityHidden(true)
    }

    /// One metric: its symbol and label, its figure, and its note if it has one.
    private func cellView(_ cell: Cell) -> some View {
        VStack(alignment: .leading, spacing: Spacing.itemGap) {
            HStack(spacing: Spacing.itemGap / 2) {
                Image(systemName: cell.symbol)
                    .foregroundStyle(cell.color)
                    .accessibilityHidden(true)
                Text(cell.label)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .font(.eyebrow)
            // The Design System's `metric` style: 22 pt regular, scaling with `title2`.
            Text(cell.figure)
                .font(.title2)
                .monospacedDigit()
                .foregroundStyle(Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            if let note = cell.note {
                Text(note)
                    .font(.footnote)
                    .foregroundStyle(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(cell.spokenLabel))
        .accessibilityIdentifier(cell.id)
    }

    /// The cells for the metrics `summary` has, in the card's order: sleep, steps, then resting heart rate.
    private static func cells(for summary: HealthSummary) -> [Cell] {
        var cells: [Cell] = []
        switch summary.lastNight {
        case let .asleep(seconds)?:
            cells.append(
                Cell(
                    id: HealthSummaryViewAccessibilityID.lastNight, label: "Last night", figure: duration(seconds),
                    note: nil, symbol: "bed.double.fill", color: .dataSleep,
                    spokenLabel: String(localized: "Last night, \(spokenDuration(seconds)) asleep")))
        case let .inBedOnly(seconds)?:
            cells.append(
                Cell(
                    id: HealthSummaryViewAccessibilityID.inBed, label: "In bed", figure: duration(seconds),
                    note: "Time in bed, not sleep.", symbol: "bed.double.fill", color: .dataSleep,
                    spokenLabel: String(localized: "In bed, \(spokenDuration(seconds)). Time in bed, not sleep.")))
        case nil:
            break
        }
        if let steps = summary.stepsToday {
            cells.append(
                Cell(
                    id: HealthSummaryViewAccessibilityID.steps, label: "Steps today", figure: steps.formatted(),
                    note: nil, symbol: "figure.walk", color: .dataActivity,
                    spokenLabel: String(localized: "Steps today, \(steps.formatted())")))
        }
        if let restingHeartRate = summary.restingHeartRateToday {
            let beats = Int(restingHeartRate.rounded())
            cells.append(
                Cell(
                    id: HealthSummaryViewAccessibilityID.restingHeartRate, label: "Resting HR",
                    figure: String(localized: "\(beats) bpm"), note: nil, symbol: "heart.fill", color: .dataHeart,
                    spokenLabel: String(localized: "Resting heart rate, \(beats) beats per minute")))
        }
        return cells
    }

    /// A duration in hours and minutes, such as "6h 42m", for the locale.
    private static func duration(_ seconds: TimeInterval) -> String {
        Duration.seconds(seconds).formatted(.units(allowed: [.hours, .minutes], width: .narrow))
    }

    /// A duration in words, such as "6 hours, 42 minutes", for the locale, for VoiceOver.
    private static func spokenDuration(_ seconds: TimeInterval) -> String {
        Duration.seconds(seconds).formatted(.units(allowed: [.hours, .minutes], width: .wide))
    }
}

#Preview {
    HealthSummaryView(
        store: Store(
            initialState: HealthSummaryFeature.State(
                summary: HealthSummary(
                    lastNight: .asleep(seconds: 6.7 * 3_600), stepsToday: 8_420, restingHeartRateToday: 58))
        ) { HealthSummaryFeature() }
    )
    .padding()
}
