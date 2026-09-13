//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life HealthDataListFeature
//

import ComposableArchitecture
import Foundation

/// The Insights tab's Health data card: a button for each kind of Health data that has any data in the last 30 days.
///
/// It observes the available kinds, and reduces each set into `State`. ``Action/task`` starts the observation, and
/// ``Action/kindTapped(_:)`` is the button a user tapped, which ``InsightsFeature`` answers by pushing that kind's
/// screen. The card is hidden until a kind is available. See the Insights article.
@Reducer nonisolated struct HealthDataListFeature {
    /// What the card shows.
    @ObservableState
    struct State: Equatable {
        /// The kinds with any data, or `nil` until the first set arrives.
        var available: Set<HealthDataKind>?

        /// The buttons, one for each available kind, in ``HealthDataKind``'s order.
        var kinds: [HealthDataKind] {
            HealthDataKind.allCases.filter { available?.contains($0) == true }
        }

        /// Whether the card shows: once a kind is available.
        var isShown: Bool {
            !kinds.isEmpty
        }
    }

    /// What can happen to the card.
    enum Action {
        /// Subscribes to the available kinds, for as long as the Insights tab is on screen.
        case task
        /// The Health data repository published the available kinds.
        case kindsUpdated(Set<HealthDataKind>)
        /// The user tapped the button for a kind.
        case kindTapped(HealthDataKind)
    }

    @Dependency(\.calendar) private var calendar
    @Dependency(\.observeAvailableHealthData) private var observeAvailableHealthData

    /// Starts the observation, and reduces each set of kinds it emits into `State`.
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                return .run { [observeAvailableHealthData, calendar] send in
                    for await kinds in observeAvailableHealthData.execute(calendar) {
                        await send(.kindsUpdated(kinds))
                    }
                }
            case let .kindsUpdated(kinds):
                state.available = kinds
                return .none
            case .kindTapped:
                return .none
            }
        }
    }
}
