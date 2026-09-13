//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life HealthSummaryFeature
//

import ComposableArchitecture
import Foundation

/// The Today screen's Apple Health card: last night's sleep, today's steps, and today's resting heart rate.
///
/// It observes today's Health summary, and reduces each value into `State`. Its only command is ``Action/task``. The
/// card is hidden until a summary with a metric arrives, so ``TodayView`` sends `task` from a view that's always on
/// screen, not from the card. The Apple Health Card article lists its requirements, HCARD-1 and HCARD-2.
@Reducer nonisolated struct HealthSummaryFeature {
    /// What the card shows.
    @ObservableState
    struct State: Equatable {
        /// Today's Health summary, or `nil` until the first one arrives.
        var summary: HealthSummary?

        /// Whether the card shows: once a summary with at least one metric has arrived.
        var isShown: Bool {
            summary.map { !$0.isEmpty } ?? false
        }
    }

    /// What can happen to the card.
    enum Action {
        /// Subscribes to today's Health summary, for as long as the Today screen is on screen.
        case task
        /// The Health data repository published today's summary.
        case summaryUpdated(HealthSummary)
    }

    @Dependency(\.calendar) private var calendar
    @Dependency(\.observeHealthSummary) private var observeHealthSummary

    /// Starts the observation, and reduces each summary it emits into `State`.
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                return .run { [observeHealthSummary, calendar] send in
                    for await summary in observeHealthSummary.execute(calendar) {
                        await send(.summaryUpdated(summary))
                    }
                }
            case let .summaryUpdated(summary):
                state.summary = summary
                return .none
            }
        }
    }
}
