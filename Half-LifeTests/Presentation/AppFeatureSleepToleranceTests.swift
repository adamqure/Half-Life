//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests AppFeatureSleepToleranceTests
//

import ComposableArchitecture
import Testing

@testable import Half_Life

/// Checks that the root keeps the caffeine tolerance current from launch: requirement TOLAPP-1 in the Insights
/// article.
@MainActor
struct AppFeatureSleepToleranceTests {

    // MARK: - TOLAPP-1: launching keeps the tolerance current

    @Test func launchingKeepsTheToleranceCurrent() async {
        let repository = FakeSleepToleranceRepository(analyses: [.empty()])
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.keepWidgetsCurrent = KeepWidgetsCurrentUseCase(repository: FakeWidgetSnapshotRepository())
            $0.keepSleepToleranceCurrent = KeepSleepToleranceCurrentUseCase(repository: repository)
        }

        await store.send(.launched)
        await store.finish()

        #expect(repository.subscriptions.value == 1)
    }
}
