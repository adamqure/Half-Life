//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life CaffeineDecayFeature
//

import ComposableArchitecture
import Foundation

/// The Today screen's decay card: the caffeine in your system now, where it's heading, and the curve.
///
/// It observes the curve, the caffeine status, and the time of day, and reduces each value into `State`. Its only
/// command is ``Action/task``, which starts all three observations and refreshes the personal half-life estimate, so
/// a week-old estimate is recalculated when the curve that uses it appears. See the Today Screen and Half-Life
/// Estimator articles.
@Reducer nonisolated struct CaffeineDecayFeature {
    /// Which of the card's sentences to show.
    enum Summary: Equatable {
        /// Nothing is in the user's system.
        case clear
        /// The level at the next bedtime. The last cup is already past half gone.
        case bedtime(CaffeineLevel)
        /// The level at the next bedtime, and when the last cup is half gone.
        case bedtimeAndHalfGone(CaffeineLevel, halfGone: Date)
    }

    /// What the card shows.
    @ObservableState
    struct State: Equatable {
        /// The active curve, or empty until the first one arrives.
        var curve: [CaffeineLevel] = []
        /// The caffeine status, or `nil` until the first one arrives.
        var status: CaffeineStatus?
        /// The current minute, or `nil` until the first one arrives.
        var timeOfDay: TimeOfDay?

        /// The sentence to show under the figure, or `nil` until there's a status to describe.
        var summary: Summary? {
            guard let status else { return nil }
            guard !status.activeIntakes.isEmpty else { return .clear }
            guard let atBedtime = status.levelAtBedtime else { return nil }
            if let halfGone = status.lastIntakeHalfGoneAt {
                return .bedtimeAndHalfGone(atBedtime, halfGone: halfGone)
            }
            return .bedtime(atBedtime)
        }

        /// The curve's window, from its first level to one spacing past its last, or `nil` until the curve has two
        /// levels. The levels are evenly spaced, and each stands for the interval up to the next, so a 24-hour window's
        /// two ends share a clock time. The view labels the curve's two ends with it, and pins the chart's time axis
        /// to it.
        var timeSpan: ClosedRange<Date>? {
            guard curve.count > 1, let first = curve.first?.date, let last = curve.last?.date else { return nil }
            let end = last.addingTimeInterval(curve[1].date.timeIntervalSince(first))
            guard first <= end else { return nil }
            return first...end
        }
    }

    /// What can happen to the card.
    enum Action {
        /// Subscribes to the curve, the status, and the time of day, for as long as the view is on screen, and
        /// refreshes the half-life estimate.
        case task
        /// The decay repository published a curve.
        case curveUpdated([CaffeineLevel])
        /// The decay repository published a status.
        case statusUpdated(CaffeineStatus)
        /// A new minute arrived.
        case timeOfDayUpdated(TimeOfDay)
    }

    @Dependency(\.calendar) private var calendar
    @Dependency(\.observeCaffeineCurve) private var observeCaffeineCurve
    @Dependency(\.observeCaffeineStatus) private var observeCaffeineStatus
    @Dependency(\.observeTimeOfDay) private var observeTimeOfDay
    @Dependency(\.refreshHalfLifeEstimate) private var refreshHalfLifeEstimate

    /// Starts the observations, refreshes the half-life estimate, and reduces each value the observations emit into
    /// `State`.
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                return .merge(
                    .run { [observeCaffeineCurve] send in
                        for await curve in observeCaffeineCurve.execute(()) {
                            await send(.curveUpdated(curve))
                        }
                    },
                    .run { [observeCaffeineStatus, calendar] send in
                        for await status in observeCaffeineStatus.execute(calendar) {
                            await send(.statusUpdated(status))
                        }
                    },
                    .run { [observeTimeOfDay, calendar] send in
                        for await timeOfDay in observeTimeOfDay.execute(calendar) {
                            await send(.timeOfDayUpdated(timeOfDay))
                        }
                    },
                    .run { [refreshHalfLifeEstimate] _ in
                        await refreshHalfLifeEstimate.execute(())
                    }
                )
            case let .curveUpdated(curve):
                state.curve = curve
                return .none
            case let .statusUpdated(status):
                state.status = status
                return .none
            case let .timeOfDayUpdated(timeOfDay):
                state.timeOfDay = timeOfDay
                return .none
            }
        }
    }
}
