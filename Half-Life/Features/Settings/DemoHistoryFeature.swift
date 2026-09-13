//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life DemoHistoryFeature
//

import ComposableArchitecture
import Foundation
import OSLog

/// Settings' Demo data section: whether the drink log holds demo drinks, and a button that adds or removes them.
///
/// Whether the log holds demo drinks comes only from the repository, so the button changes once the change is stored
/// (constitution Article I.5). While a change is under way, another tap does nothing. A failed change says so until
/// the next try. See the Settings article, SETDEMO-1 to SETDEMO-4.
@Reducer nonisolated struct DemoHistoryFeature {
    private static let logger = Logger(for: DemoHistoryFeature.self)

    /// The section's state.
    @ObservableState
    struct State: Equatable {
        /// Whether the log holds demo drinks, or `nil` until the repository answers.
        var hasDemoHistory: Bool?
        /// Whether an add or a removal is under way.
        var isChanging = false
        /// Whether the last add or removal failed.
        var changeFailed = false
    }

    /// What can happen in the section.
    enum Action {
        /// The section appeared, so it starts observing whether the log holds demo drinks.
        case task
        /// The repository answered whether the log holds demo drinks.
        case demoHistoryUpdated(Bool)
        /// The user tapped the button that adds the demo drinks.
        case addTapped
        /// The user tapped the button that removes the demo drinks.
        case removeTapped
        /// An add or a removal finished. `failed` is whether it failed.
        case changeFinished(failed: Bool)
    }

    @Dependency(\.calendar) var calendar
    @Dependency(\.observeDemoHistory) var observeDemoHistory
    @Dependency(\.addDemoHistory) var addDemoHistory
    @Dependency(\.removeDemoHistory) var removeDemoHistory

    /// Adds or removes the demo drinks on request, and reduces the repository's answer into `State`.
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                return .run { [observeDemoHistory] send in
                    for await hasDemoHistory in observeDemoHistory.execute(()) {
                        await send(.demoHistoryUpdated(hasDemoHistory))
                    }
                }
            case let .demoHistoryUpdated(hasDemoHistory):
                state.hasDemoHistory = hasDemoHistory
                return .none
            case .addTapped:
                guard !state.isChanging else { return .none }
                state.isChanging = true
                state.changeFailed = false
                return change("add") { [addDemoHistory, calendar] in try await addDemoHistory.execute(calendar) }
            case .removeTapped:
                guard !state.isChanging else { return .none }
                state.isChanging = true
                state.changeFailed = false
                return change("remove") { [removeDemoHistory] in try await removeDemoHistory.execute(()) }
            case let .changeFinished(failed):
                state.isChanging = false
                state.changeFailed = failed
                return .none
            }
        }
    }

    /// Runs an add or a removal, and reports whether it failed. A failure is logged with its domain and code only.
    private func change(_ name: String, _ operation: @escaping @Sendable () async throws -> Void) -> Effect<Action> {
        .run { send in
            do {
                try await operation()
                await send(.changeFinished(failed: false))
            } catch {
                let error = error as NSError
                Self.logger.error(
                    """
                    Couldn't \(name, privacy: .public) the demo history: \
                    \(error.domain, privacy: .public) \(error.code, privacy: .public)
                    """
                )
                await send(.changeFinished(failed: true))
            }
        }
    }
}
