//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests AppFeatureWidgetTests
//

import ComposableArchitecture
import Testing

@testable import Half_Life

/// Checks that the root keeps the widgets current from launch: requirement WAPP-1 in the Widgets article.
@MainActor
struct AppFeatureWidgetTests {

    // MARK: - WAPP-1: launching keeps the widgets current

    @Test func launchingKeepsTheWidgetsCurrent() async {
        let repository = FakeWidgetSnapshotRepository()
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.keepWidgetsCurrent = KeepWidgetsCurrentUseCase(repository: repository)
            $0.keepSleepToleranceCurrent = KeepSleepToleranceCurrentUseCase(repository: FakeSleepToleranceRepository())
        }

        await store.send(.launched)
        await store.finish()

        #expect(repository.subscriptions.value == 1)
    }
}
