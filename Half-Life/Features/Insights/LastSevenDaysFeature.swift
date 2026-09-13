//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life LastSevenDaysFeature
//

import ComposableArchitecture
import Foundation

/// The Insights tab's "The last 7 days" card: each day's caffeine, and the details of the day the user chose.
///
/// It observes the 7 days before today in the drink log and the sleep that followed each, and reduces each into
/// `State`. Today is left out, because its night hasn't happened. ``Action/task`` starts both observations, and
/// ``Action/daySelected(_:)`` chooses a day. With no day chosen, or once the chosen one has left the week, yesterday is
/// selected. The days are in the calendar dependency, so they follow the
/// user's time zone. See the Insights article.
@Reducer nonisolated struct LastSevenDaysFeature {
    /// What the card shows.
    @ObservableState
    struct State: Equatable {
        /// The 7 days before today, yesterday last, or none until the first set arrives.
        var days: [DrinkLogDay] = []
        /// The midnight of the day the user chose, or `nil` for yesterday.
        var selectedDay: Date?
        /// The sleep that followed each day, or `nil` until the first history arrives.
        var sleep: SleepHistory?

        /// The day whose details show: the one the user chose while it's in the week, or yesterday.
        var selected: DrinkLogDay? {
            days.first { $0.intake.day == selectedDay } ?? days.last
        }

        /// The night that followed `day`, or `nil` if the history hasn't arrived or doesn't hold that day.
        ///
        /// - Parameter day: One of the week's days.
        func night(after day: DrinkLogDay) -> SleepHistoryNight? {
            sleep?.nights.first { $0.day == day.intake.day }
        }
    }

    /// What can happen to the card.
    enum Action {
        /// Subscribes to the week, for as long as the view is on screen.
        case task
        /// The drink log repository published the week.
        case daysUpdated([DrinkLogDay])
        /// The user chose the day that starts at this midnight.
        case daySelected(Date)
        /// The Health data repository published the sleep week.
        case sleepUpdated(SleepHistory)
    }

    @Dependency(\.calendar) private var calendar
    @Dependency(\.observeDrinkLogWeek) private var observeDrinkLogWeek
    @Dependency(\.observeSleepWeek) private var observeSleepWeek

    /// Starts the observation, reduces each week it emits into `State`, and records the day the user chooses.
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                return .merge(
                    .run { [observeDrinkLogWeek, calendar] send in
                        for await days in observeDrinkLogWeek.execute(calendar) {
                            await send(.daysUpdated(days))
                        }
                    },
                    .run { [observeSleepWeek, calendar] send in
                        for await history in observeSleepWeek.execute(calendar) {
                            await send(.sleepUpdated(history))
                        }
                    }
                )
            case let .daysUpdated(days):
                state.days = days
                return .none
            case let .daySelected(day):
                state.selectedDay = day
                return .none
            case let .sleepUpdated(history):
                state.sleep = history
                return .none
            }
        }
    }
}
