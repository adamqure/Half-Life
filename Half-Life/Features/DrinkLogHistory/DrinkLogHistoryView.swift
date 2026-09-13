//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life DrinkLogHistoryView
//

import ComposableArchitecture
import SwiftUI

/// The Today screen's history card: one day of the drink log, with buttons for the day before and after, and for
/// today from an earlier day, the day's total, and a way to delete a drink.
///
/// Each drink's × asks to delete it, and the row then offers Keep and Delete, so a mis-tap never deletes a drink. The
/// confirmation is part of the card rather than a system dialog, because a dialog's buttons can't carry the
/// accessibility identifiers UI tests find elements by (constitution Article II.6). At accessibility text sizes each
/// row stacks, so nothing is cut off (Article VI.2). See the Today Screen article.
@MainActor
struct DrinkLogHistoryView: View {
    /// The card's store.
    let store: StoreOf<DrinkLogHistoryFeature>

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private static let clockTime = Date.FormatStyle.dateTime.hour().minute()
    private static let dayDate = Date.FormatStyle.dateTime.weekday(.wide).month(.abbreviated).day()

    /// The card's title and buttons, then its drinks and total.
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sectionHeaderGap) {
            header
            if let day = store.day {
                // While the next day loads, the last one keeps its place, unseen and untouchable, so the Today screen
                // keeps its height and doesn't scroll away from the card (HIST-10).
                card(day)
                    .opacity(store.showsSelectedDay ? 1 : 0)
                    .allowsHitTesting(store.showsSelectedDay)
                    .accessibilityHidden(!store.showsSelectedDay)
            }
        }
        .task { await store.send(.task).finish() }
        .onDisappear { store.send(.disappeared) }
    }

    /// "LOGGED TODAY", with the buttons for the day before and after, and Today on an earlier day. At accessibility
    /// text sizes, the buttons sit under the title.
    private var header: some View {
        let layout =
            dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.itemGap))
            : AnyLayout(HStackLayout(alignment: .center, spacing: Spacing.itemGap))
        return layout {
            title
                .font(.eyebrow)
                .textCase(.uppercase)
                .foregroundStyle(Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier(DrinkLogHistoryViewAccessibilityID.title)
            if !dynamicTypeSize.isAccessibilitySize {
                Spacer(minLength: 0)
            }
            dayButtons
        }
    }

    /// Today, on an earlier day, then the buttons for the day before and after. They keep their natural size, and the
    /// title wraps instead. Squeezed, Today's label wrapped onto two lines, and the taller header moved the card.
    private var dayButtons: some View {
        HStack(spacing: Spacing.itemGap) {
            if store.canShowToday {
                todayButton
            }
            DayButton(
                symbolName: "chevron.left", label: "Previous day", isEnabled: store.title != nil,
                identifier: DrinkLogHistoryViewAccessibilityID.previousDayButton
            ) {
                store.send(.previousDayTapped)
            }
            DayButton(
                symbolName: "chevron.right", label: "Next day", isEnabled: store.canShowNextDay,
                identifier: DrinkLogHistoryViewAccessibilityID.nextDayButton
            ) {
                store.send(.nextDayTapped)
            }
        }
        .fixedSize()
    }

    /// The button that returns the card to today, in the style of the card's Keep button.
    private var todayButton: some View {
        Button {
            store.send(.todayTapped)
        } label: {
            Text("Today")
                .font(.callout.weight(.semibold))
                .foregroundStyle(Color.textPrimary)
                .padding(.horizontal, Spacing.cardPaddingCompact)
                .frame(minWidth: Sizing.minimumHitTarget, minHeight: Sizing.minimumHitTarget)
                .background(Color.surfaceControl, in: Capsule())
                .overlay(Capsule().strokeBorder(Color.controlBorder))
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text("Shows the drinks logged today."))
        .accessibilityIdentifier(DrinkLogHistoryViewAccessibilityID.todayButton)
    }

    private var title: Text {
        switch store.title {
        case .today, nil:
            Text("Logged today")
        case .yesterday:
            Text("Logged yesterday")
        case let .date(date):
            Text("Logged on \(date.formatted(Self.dayDate))")
        }
    }

    private func card(_ day: DrinkLogDay) -> some View {
        VStack(alignment: .leading, spacing: Spacing.itemGap) {
            if day.drinks.isEmpty {
                Text("No drinks logged.")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .accessibilityIdentifier(DrinkLogHistoryViewAccessibilityID.emptyMessage)
            } else {
                ForEach(day.drinks) { drink in
                    row(drink)
                    Rectangle()
                        .fill(Color.separatorOnCard)
                        .frame(height: 1)
                        .accessibilityHidden(true)
                }
            }
            total(day.intake.milligrams)
            if store.deletionFailed {
                deletionError
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
    }

    /// One drink: its time, name, quantity, and caffeine, then its × or, while it waits to be deleted, Keep and
    /// Delete.
    private func row(_ drink: LoggedDrink) -> some View {
        let isPending = store.pendingDeletion == drink.id
        return VStack(alignment: .trailing, spacing: Spacing.itemGap) {
            HStack(alignment: .center, spacing: Spacing.itemGap) {
                details(drink)
                if !isPending {
                    deleteButton(drink)
                }
            }
            if isPending {
                confirmation
            }
        }
    }

    /// The drink's time, name, quantity, and caffeine, read by VoiceOver as one element. They stack at accessibility
    /// text sizes.
    private func details(_ drink: LoggedDrink) -> some View {
        let layout =
            dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.sectionHeaderGap / 2))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: Spacing.itemGap))
        return layout {
            Text(drink.consumedAt, format: Self.clockTime)
                .font(.footnote)
                .monospacedDigit()
                .foregroundStyle(Color.textSecondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(drink.type.displayName)
                    .font(.body)
                    .foregroundStyle(Color.textPrimary)
                Text(drink.type.unit.quantityText(drink.quantity))
                    .font(.footnote)
                    .foregroundStyle(Color.textSecondary)
                if drink.isDemo {
                    DemoTag()
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            if !dynamicTypeSize.isAccessibilitySize {
                Spacer(minLength: 0)
            }
            Text(CaffeineFormat.milligrams(drink.milligrams))
                .font(.body)
                .monospacedDigit()
                .foregroundStyle(Color.textAccent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(DrinkLogHistoryViewAccessibilityID.drink)
    }

    private func deleteButton(_ drink: LoggedDrink) -> some View {
        Button {
            store.send(.deleteTapped(drink.id))
        } label: {
            Image(systemName: "xmark")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.textSecondary)
                .frame(width: Sizing.minimumHitTarget, height: Sizing.minimumHitTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            Text("Delete \(Text(drink.type.displayName)) at \(Text(drink.consumedAt, format: Self.clockTime))")
        )
        .accessibilityIdentifier(DrinkLogHistoryViewAccessibilityID.deleteButton)
    }

    /// Keep and Delete, for the drink waiting to be deleted.
    private var confirmation: some View {
        HStack(spacing: Spacing.itemGap) {
            Button {
                store.send(.deleteCancelled)
            } label: {
                Text("Keep")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                    .padding(.horizontal, Spacing.cardPaddingCompact)
                    .frame(minWidth: Sizing.minimumHitTarget, minHeight: Sizing.minimumHitTarget)
                    .background(Color.surfaceControl, in: Capsule())
                    .overlay(Capsule().strokeBorder(Color.controlBorder))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(DrinkLogHistoryViewAccessibilityID.cancelDeleteButton)
            Button {
                store.send(.deleteConfirmed)
            } label: {
                Text("Delete")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Color.textOnEmphasis)
                    .padding(.horizontal, Spacing.cardPaddingCompact)
                    .frame(minWidth: Sizing.minimumHitTarget, minHeight: Sizing.minimumHitTarget)
                    .background(Color.actionPrimary, in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityHint(Text("Removes the drink from your log and your caffeine curve."))
            .accessibilityIdentifier(DrinkLogHistoryViewAccessibilityID.confirmDeleteButton)
        }
    }

    /// The day's total, such as "Total 192 mg".
    private func total(_ milligrams: Double) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.itemGap) {
            Text("Total")
                .font(.eyebrow)
                .textCase(.uppercase)
                .foregroundStyle(Color.textSecondary)
            Spacer(minLength: 0)
            Text(CaffeineFormat.milligrams(milligrams))
                .font(.headline)
                .monospacedDigit()
                .foregroundStyle(Color.textPrimary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(DrinkLogHistoryViewAccessibilityID.total)
    }

    private var deletionError: some View {
        Label {
            Text("The drink couldn't be deleted. Try again.")
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
                .accessibilityHidden(true)
        }
        .font(.footnote)
        .foregroundStyle(Color.feedbackCaution)
        .padding(Spacing.itemGap)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.feedbackCautionBackground, in: RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
        )
        .accessibilityIdentifier(DrinkLogHistoryViewAccessibilityID.errorMessage)
    }
}

/// The label on a demo drink, so a drink Settings added is never mistaken for one the user logged. It's text, so
/// VoiceOver reads it as part of the row. See the Settings article.
@MainActor
private struct DemoTag: View {
    var body: some View {
        Text("Demo")
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.textPrimary)
            .padding(.horizontal, Spacing.itemGap / 2)
            .padding(.vertical, 2)
            .background(Color.surfaceMuted, in: Capsule())
    }
}

/// A round button that moves the card a day back or forward. When it can't, it's disabled and its arrow is dimmed.
@MainActor
private struct DayButton: View {
    let symbolName: String
    let label: LocalizedStringKey
    let isEnabled: Bool
    let identifier: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbolName)
                .font(.body.weight(.semibold))
                .foregroundStyle(isEnabled ? Color.textPrimary : Color.textSecondary)
                .frame(width: Sizing.minimumHitTarget, height: Sizing.minimumHitTarget)
                .background(Color.surfaceControl, in: Circle())
                .overlay(Circle().strokeBorder(Color.controlBorder))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel(Text(label))
        .accessibilityIdentifier(identifier)
    }
}

#Preview {
    DrinkLogHistoryView(
        store: Store(initialState: DrinkLogHistoryFeature.State()) {
            DrinkLogHistoryFeature()
        })
}
