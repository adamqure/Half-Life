//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life DemoHealthDataFeature
//

import ComposableArchitecture

/// Settings' demo Health data switch: whether the Apple Health card shows demo data in place of Apple Health's.
///
/// Whether the switch is on comes only from the repository, so the switch changes once the change is stored
/// (constitution Article I.5). While a change is under way, another turn does nothing. A failed change says so until
/// the next try, and the repository logs it. The Apple Health Card article lists its requirements, HDEMO-1 and
/// HDEMO-2.
@Reducer nonisolated struct DemoHealthDataFeature {
    /// The switch's state.
    @ObservableState
    struct State: Equatable {
        /// Whether the switch is on, or `nil` until the repository answers.
        var usesDemoData: Bool?
        /// Whether a change is under way.
        var isChanging = false
        /// Whether the last change failed.
        var changeFailed = false
    }

    /// What can happen to the switch.
    enum Action {
        /// The switch appeared, so it starts observing the repository's answer.
        case task
        /// The repository answered whether the switch is on.
        case demoDataUpdated(Bool)
        /// The user turned the switch on or off.
        case toggled(Bool)
        /// A change finished. `failed` is whether it failed.
        case changeFinished(failed: Bool)
    }

    @Dependency(\.observeDemoHealthData) private var observeDemoHealthData
    @Dependency(\.setDemoHealthData) private var setDemoHealthData

    /// Stores the switch on request, and reduces the repository's answer into `State`.
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                return .run { [observeDemoHealthData] send in
                    for await isOn in observeDemoHealthData.execute(()) {
                        await send(.demoDataUpdated(isOn))
                    }
                }
            case let .demoDataUpdated(isOn):
                state.usesDemoData = isOn
                return .none
            case let .toggled(isOn):
                guard !state.isChanging else { return .none }
                state.isChanging = true
                state.changeFailed = false
                return .run { [setDemoHealthData] send in
                    do {
                        try await setDemoHealthData.execute(isOn)
                        await send(.changeFinished(failed: false))
                    } catch {
                        await send(.changeFinished(failed: true))
                    }
                }
            case let .changeFinished(failed):
                state.isChanging = false
                state.changeFailed = failed
                return .none
            }
        }
    }
}
