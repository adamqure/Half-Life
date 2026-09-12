//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life DrinkLogHistoryFeature
//

import ComposableArchitecture
import Foundation
import OSLog

/// The Today screen's history card: one day of the drink log, its total, and a way to delete a drink.
///
/// It opens on today, and follows today when midnight passes. The previous and next buttons move a day at a time,
/// never past today, and Today returns to today from an earlier day. When the day changes, the card keeps the last
/// day in place until the next one arrives, so the Today screen doesn't shrink and scroll away from the card. It
/// observes the day it shows through ``ObserveDrinkLogDayUseCase``, and deletes through ``DeleteDrinkUseCase`` once
/// the user confirms. A deleted drink leaves the card, the day's total, the "Today" tile, and the decay curve when the
/// drink log's data source signals the change. See the Today Screen article.
@Reducer nonisolated struct DrinkLogHistoryFeature {
    /// What the card's title names.
    enum Title: Equatable {
        /// Today.
        case today
        /// Yesterday.
        case yesterday
        /// An earlier day, by its midnight.
        case date(Date)
    }

    /// What the card shows.
    @ObservableState
    struct State: Equatable {
        /// Today's midnight, or `nil` until the first minute arrives.
        var today: Date?
        /// The midnight of the day the card shows, or `nil` until the first minute arrives.
        var selectedDay: Date?
        /// How many days before today the card's day is. 0 is today.
        var daysAgo = 0
        /// The day's drinks and total, or `nil` until the drink log publishes the day.
        var day: DrinkLogDay?
        /// The drink the user asked to delete, until they confirm or keep it.
        var pendingDeletion: LoggedDrink.ID?
        /// Whether the last deletion failed.
        var deletionFailed = false

        /// What the title names, or `nil` until there's a day to show.
        var title: Title? {
            guard let selectedDay else { return nil }
            switch daysAgo {
            case 0: return .today
            case 1: return .yesterday
            default: return .date(selectedDay)
            }
        }

        /// Whether the card can move to the next day. It can't move past today.
        var canShowNextDay: Bool {
            daysAgo > 0
        }

        /// Whether the card can return to today. It can from any earlier day.
        var canShowToday: Bool {
            daysAgo > 0
        }

        /// Whether `day` is the day the card is set to. Just after the day changes, `day` is still the last one, kept
        /// in place while the next one loads (HIST-10).
        var showsSelectedDay: Bool {
            day?.intake.day == selectedDay
        }
    }

    /// What can happen to the card.
    enum Action {
        /// Subscribes to the time of day, and to the day showing, for as long as the view is on screen.
        case task
        /// The view left the screen, so the card stops observing its day.
        case disappeared
        /// A new minute arrived.
        case timeOfDayUpdated(TimeOfDay)
        /// The drink log published a day.
        case dayUpdated(DrinkLogDay)
        /// The user asked for the day before.
        case previousDayTapped
        /// The user asked for the day after.
        case nextDayTapped
        /// The user asked to return to today.
        case todayTapped
        /// The user asked to delete a drink, which waits for confirmation.
        case deleteTapped(LoggedDrink.ID)
        /// The user kept the drink.
        case deleteCancelled
        /// The user confirmed the deletion.
        case deleteConfirmed
        /// The drink couldn't be deleted.
        case deletionFailed
    }

    private enum CancelID {
        case day
    }

    private static let logger = Logger(for: DrinkLogHistoryFeature.self)

    @Dependency(\.calendar) private var calendar
    @Dependency(\.observeTimeOfDay) private var observeTimeOfDay
    @Dependency(\.observeDrinkLogDay) private var observeDrinkLogDay
    @Dependency(\.deleteDrink) private var deleteDrink

    /// Follows today, observes the day showing, and deletes a drink once the user confirms.
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                let timeOfDay = Effect<Action>.run { [observeTimeOfDay, calendar] send in
                    for await timeOfDay in observeTimeOfDay.execute(calendar) {
                        await send(.timeOfDayUpdated(timeOfDay))
                    }
                }
                guard let selectedDay = state.selectedDay else { return timeOfDay }
                return .merge(timeOfDay, observe(selectedDay))
            case .disappeared:
                return .cancel(id: CancelID.day)
            case let .timeOfDayUpdated(timeOfDay):
                return moveToday(to: calendar.startOfDay(for: timeOfDay.date), state: &state)
            case let .dayUpdated(day):
                guard day.intake.day == state.selectedDay else { return .none }
                state.day = day
                if let pending = state.pendingDeletion, !day.drinks.contains(where: { $0.id == pending }) {
                    state.pendingDeletion = nil
                }
                return .none
            case .previousDayTapped:
                return showDay(daysAgo: state.daysAgo + 1, state: &state)
            case .nextDayTapped:
                guard state.canShowNextDay else { return .none }
                return showDay(daysAgo: state.daysAgo - 1, state: &state)
            case .todayTapped:
                guard state.canShowToday else { return .none }
                return showDay(daysAgo: 0, state: &state)
            case let .deleteTapped(id):
                state.pendingDeletion = id
                state.deletionFailed = false
                return .none
            case .deleteCancelled:
                state.pendingDeletion = nil
                return .none
            case .deleteConfirmed:
                guard let id = state.pendingDeletion else { return .none }
                state.pendingDeletion = nil
                return .run { [deleteDrink] _ in
                    try await deleteDrink.execute(id)
                } catch: { error, send in
                    Self.logFailure(error)
                    await send(.deletionFailed)
                }
            case .deletionFailed:
                state.deletionFailed = true
                return .none
            }
        }
    }

    /// Records a new today. The card follows it if it was showing today, and otherwise keeps its day, which is now
    /// further back.
    private func moveToday(to newToday: Date, state: inout State) -> Effect<Action> {
        guard newToday != state.today else { return .none }
        let wasShowingToday = state.today == nil || state.daysAgo == 0
        state.today = newToday
        let days = state.selectedDay.flatMap { calendar.dateComponents([.day], from: $0, to: newToday).day } ?? 0
        guard !wasShowingToday, days > 0 else { return showDay(daysAgo: 0, state: &state) }
        state.daysAgo = days
        return .none
    }

    /// Shows the day `daysAgo` days before today, and observes it in place of the day showing before.
    ///
    /// It keeps the last day in `State` until the new one arrives. Clearing it removed the card for a moment, which
    /// shrank the Today screen and left it scrolled away from the card (HIST-10).
    private func showDay(daysAgo: Int, state: inout State) -> Effect<Action> {
        guard let today = state.today, let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else {
            return .none
        }
        let day = calendar.startOfDay(for: date)
        state.daysAgo = daysAgo
        state.selectedDay = day
        state.pendingDeletion = nil
        return observe(day)
    }

    /// Observes the day that starts at `day`, cancelling the observation of any other day.
    private func observe(_ day: Date) -> Effect<Action> {
        .run { [observeDrinkLogDay, calendar] send in
            let input = ObserveDrinkLogDayUseCase.Input(date: day, calendar: calendar)
            for await published in observeDrinkLogDay.execute(input) {
                await send(.dayUpdated(published))
            }
        }
        .cancellable(id: CancelID.day, cancelInFlight: true)
    }

    /// Logs a failed deletion with the error's domain and code, and never the drink (constitution Article XI.6–7).
    private static func logFailure(_ error: any Error) {
        let nsError = error as NSError
        logger.error(
            """
            Deleting a drink failed: \(nsError.domain, privacy: .public) \(nsError.code, privacy: .public), \
            \(nsError.localizedDescription, privacy: .private)
            """
        )
    }
}
