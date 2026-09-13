//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests InsightsFeatureStepsTests
//

import ComposableArchitecture
import Testing

@testable import Half_Life

/// Checks that the Insights tab pushes the steps screen (INSIGHTS-6 in the Insights article).
@MainActor
struct InsightsFeatureStepsTests {

    /// INSIGHTS-6: tapping the steps button pushes the steps screen onto the tab's navigation stack.
    @Test func tappingStepsPushesTheStepsScreen() async {
        let store = TestStore(initialState: InsightsFeature.State()) {
            InsightsFeature()
        }

        await store.send(.healthData(.kindTapped(.steps))) {
            $0.path.append(.steps(StepsDetailFeature.State()))
        }
    }
}
