//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life LastSevenDaysView
//

import ComposableArchitecture
import SwiftUI

/// The Insights tab's "The last 7 days" card: a column for each day's caffeine and the sleep that followed it, and the
/// details of the chosen day.
///
/// Each column is a button that chooses its day: the day's caffeine as a bar above its weekday, and, once Apple Health
/// has sleep, the night's time asleep as a bar hanging below it. The chosen one has a bold label, full-color bars, and
/// an outline, so it never depends on color alone (constitution Article VI.3), and VoiceOver reads it as selected.
/// Amounts, times, and durations are formatted for the locale (Article VII.3). At accessibility text sizes, the
/// columns' labels shorten to one letter, and the details stack. With no sleep at all, a note says it appears when
/// Apple Health has it, and a line under the details says whether the sleep is Apple Health's or the demo's. See the
/// Insights article.
@MainActor
struct LastSevenDaysView: View {
    /// The card's store.
    let store: StoreOf<LastSevenDaysFeature>

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var barHeight: CGFloat = 88
    @ScaledMetric(relativeTo: .body) private var sleepBarHeight: CGFloat = 64

    private static let barWidth: CGFloat = 12
    private static let emptyBarHeight: CGFloat = 4
    private static let clockTime = Date.FormatStyle.dateTime.hour().minute()
    private static let wholeNumber = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(0))
    private static let shownAmount = Measurement<UnitMass>.FormatStyle(
        width: .abbreviated, usage: .asProvided, numberFormatStyle: wholeNumber)
    private static let spokenAmount = Measurement<UnitMass>.FormatStyle(
        width: .wide, usage: .asProvided, numberFormatStyle: wholeNumber)
    private static let shownDuration = Duration.UnitsFormatStyle(allowedUnits: [.hours, .minutes], width: .narrow)
    private static let spokenDuration = Duration.UnitsFormatStyle(allowedUnits: [.hours, .minutes], width: .wide)

    /// Whether any night in the week has sleep or time in bed to show.
    private var hasSleep: Bool {
        store.sleep?.hasSleep == true
    }

    /// The card's heading and, once the first week arrives, its columns, the chosen day's details, and the sleep's
    /// source, or the note that sleep appears with Apple Health.
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.itemGap) {
            Text("The last 7 days")
                .font(.eyebrow)
                .textCase(.uppercase)
                .foregroundStyle(Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            if let selected = store.selected {
                columns
                Divider()
                details(of: selected)
                footnote
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
        .accessibilityIdentifier(InsightsViewAccessibilityID.weekCard)
        .task { await store.send(.task).finish() }
    }

    /// Where the sleep comes from, or the note that it appears when Apple Health has it.
    @ViewBuilder
    private var footnote: some View {
        if let sleep = store.sleep, sleep.hasSleep {
            Text(sleep.isDemo ? "Demo sleep data" : "Sleep from Apple Health")
                .font(.footnote)
                .foregroundStyle(Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier(InsightsViewAccessibilityID.weekSleepSource)
        } else {
            Text("Sleep appears here when Apple Health has it.")
                .font(.footnote)
                .foregroundStyle(Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier(InsightsViewAccessibilityID.weekSleepNote)
        }
    }

    /// A column for each day, oldest first, with bars scaled to the week's largest day and longest night.
    private var columns: some View {
        let peak = max(store.days.map(\.intake.milligrams).max() ?? 0, 1)
        let longest = max(store.days.compactMap { Self.asleepSeconds(night(after: $0)) }.max() ?? 0, 1)
        return HStack(alignment: .top, spacing: 2) {
            ForEach(Array(store.days.enumerated()), id: \.element.intake.day) { index, day in
                column(for: day, at: index, peak: peak, longest: longest)
            }
        }
    }

    /// The button for one day: its caffeine bar, its weekday, and its sleep bar, outlined when it's chosen.
    private func column(for day: DrinkLogDay, at index: Int, peak: Double, longest: TimeInterval) -> some View {
        let isSelected = day == store.selected
        let identifiers = InsightsViewAccessibilityID.weekColumns
        // The last day is yesterday, so the columns line up with the identifiers from the end.
        let identifier = identifiers[max(0, min(identifiers.count - 1, identifiers.count - store.days.count + index))]
        let asleep = Self.asleepSeconds(night(after: day))
        return Button {
            store.send(.daySelected(day.intake.day))
        } label: {
            VStack(spacing: Spacing.itemGap / 2) {
                RoundedRectangle(cornerRadius: Self.barWidth / 2, style: .continuous)
                    .fill(isSelected ? Color.dataCaffeine : Color.dataCaffeineSubtle)
                    .frame(
                        width: Self.barWidth,
                        height: max(Self.emptyBarHeight, barHeight * day.intake.milligrams / peak)
                    )
                    .frame(height: barHeight, alignment: .bottom)
                Text(day.intake.day, format: .dateTime.weekday(weekdayWidth))
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundStyle(isSelected ? Color.textPrimary : Color.textSecondary)
                if hasSleep {
                    RoundedRectangle(cornerRadius: Self.barWidth / 2, style: .continuous)
                        .fill(isSelected ? Color.dataSleep : Color.dataSleepSubtle)
                        .frame(width: Self.barWidth, height: asleep.map { sleepBarHeight * $0 / longest } ?? 0)
                        .frame(height: sleepBarHeight, alignment: .top)
                }
            }
            .padding(.vertical, Spacing.itemGap / 2)
            .frame(maxWidth: .infinity, minHeight: Sizing.minimumHitTarget)
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                        .strokeBorder(Color.borderCard, lineWidth: 1)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(name(of: day, at: index))
        .accessibilityValue(Text(spokenValue(of: day)))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier(identifier)
    }

    /// The night that followed `day`, from the card's state.
    private func night(after day: DrinkLogDay) -> SleepHistoryNight? {
        store.state.night(after: day)
    }

    /// The weekday's width: abbreviated, or one letter at accessibility text sizes.
    private var weekdayWidth: Date.FormatStyle.Symbol.Weekday {
        dynamicTypeSize.isAccessibilitySize ? .narrow : .abbreviated
    }

    /// The chosen day's name, caffeine, sleep, and last cup. At accessibility text sizes, the details stack.
    private func details(of day: DrinkLogDay) -> some View {
        let index = store.days.firstIndex(of: day) ?? store.days.count - 1
        let layout =
            dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.itemGap))
            : AnyLayout(HStackLayout(alignment: .top, spacing: Spacing.cardGap))
        return VStack(alignment: .leading, spacing: Spacing.itemGap) {
            name(of: day, at: index)
                .font(.headline)
                .foregroundStyle(Color.textPrimary)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier(InsightsViewAccessibilityID.weekDetailTitle)
            layout {
                detail("Caffeine", value: Text(Self.measurement(day.intake.milligrams).formatted(Self.shownAmount)))
                    .accessibilityIdentifier(InsightsViewAccessibilityID.weekDetailCaffeine)
                if hasSleep {
                    sleepDetail(of: day)
                        .accessibilityIdentifier(InsightsViewAccessibilityID.weekDetailSleep)
                }
                detail("Last cup", value: lastCup(of: day))
                    .accessibilityIdentifier(InsightsViewAccessibilityID.weekDetailLastCup)
            }
        }
    }

    /// The night after the day: "Slept" with the time asleep, "In bed" with the time in bed when no sleep was
    /// recorded, or "Not recorded".
    private func sleepDetail(of day: DrinkLogDay) -> some View {
        switch night(after: day)?.sleep {
        case let .asleep(seconds)?:
            detail("Slept", value: Text(Duration.seconds(seconds), format: Self.shownDuration))
        case let .inBedOnly(seconds)?:
            detail("In bed", value: Text(Duration.seconds(seconds), format: Self.shownDuration))
        case nil:
            detail("Slept", value: Text("Not recorded"))
        }
    }

    /// A detail's small uppercase label above its figure. VoiceOver reads both as one element.
    private func detail(_ title: LocalizedStringKey, value: Text) -> some View {
        VStack(alignment: .leading, spacing: Spacing.itemGap / 3) {
            Text(title)
                .font(.eyebrow)
                .textCase(.uppercase)
                .foregroundStyle(Color.textSecondary)
            value
                .font(.title2)
                .monospacedDigit()
                .foregroundStyle(Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    /// The column's spoken value: the day's caffeine, and the night's time asleep or in bed when there is one.
    private func spokenValue(of day: DrinkLogDay) -> LocalizedStringResource {
        let amount = Self.measurement(day.intake.milligrams).formatted(Self.spokenAmount)
        switch night(after: day)?.sleep {
        case let .asleep(seconds)?:
            return "\(amount), slept \(Duration.seconds(seconds).formatted(Self.spokenDuration))"
        case let .inBedOnly(seconds)?:
            return "\(amount), in bed \(Duration.seconds(seconds).formatted(Self.spokenDuration))"
        case nil:
            return "\(amount)"
        }
    }

    /// The time of the day's last drink, or "None".
    private func lastCup(of day: DrinkLogDay) -> Text {
        guard let last = day.drinks.map(\.consumedAt).max() else { return Text("None") }
        return Text(last, format: Self.clockTime)
    }

    /// "Yesterday" for the last day, or the weekday, such as "Thursday".
    private func name(of day: DrinkLogDay, at index: Int) -> Text {
        index == store.days.count - 1 ? Text("Yesterday") : Text(day.intake.day, format: .dateTime.weekday(.wide))
    }

    /// The night's time asleep, in seconds, or `nil` for time in bed alone or no night. Time in bed isn't sleep, so it
    /// gets no bar.
    private static func asleepSeconds(_ night: SleepHistoryNight?) -> TimeInterval? {
        guard case let .asleep(seconds)? = night?.sleep else { return nil }
        return seconds
    }

    private static func measurement(_ milligrams: Double) -> Measurement<UnitMass> {
        Measurement(value: milligrams, unit: .milligrams)
    }
}
