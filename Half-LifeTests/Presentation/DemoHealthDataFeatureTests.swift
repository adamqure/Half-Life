//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests DemoHealthDataFeatureTests
//

import ComposableArchitecture
import Testing

@testable import Half_Life

/// Checks Settings' demo Health data switch against HDEMO-1 and HDEMO-2 in the Apple Health Card article.
@MainActor
struct DemoHealthDataFeatureTests {
    struct StoreFailure: Error {}

    // MARK: - HDEMO-1: the switch shows the repository's answer, and turning it waits for the repository

    @Test func theSwitchShowsTheRepositorysAnswer() async {
        let store = TestStore(initialState: DemoHealthDataFeature.State()) {
            DemoHealthDataFeature()
        } withDependencies: {
            $0.observeDemoHealthData = ObserveDemoHealthDataUseCase(
                repository: FakeHealthDataRepository(demoAnswers: [false, true]))
        }

        await store.send(.task)
        await store.receive(\.demoDataUpdated) {
            $0.usesDemoData = false
        }
        await store.receive(\.demoDataUpdated) {
            $0.usesDemoData = true
        }
        await store.finish()
    }

    @Test func turningItOnGoesThroughTheUseCaseAndWaitsForTheRepository() async {
        let repository = FakeHealthDataRepository()
        let store = TestStore(initialState: DemoHealthDataFeature.State(usesDemoData: false)) {
            DemoHealthDataFeature()
        } withDependencies: {
            $0.setDemoHealthData = SetDemoHealthDataUseCase(repository: repository)
        }

        await store.send(.toggled(true)) {
            $0.isChanging = true
        }
        await store.receive(\.changeFinished) {
            $0.isChanging = false
        }

        #expect(repository.storedValues.value == [true])
    }

    @Test func turningItWhileAChangeIsUnderWayDoesNothing() async {
        let repository = FakeHealthDataRepository()
        let store = TestStore(initialState: DemoHealthDataFeature.State(usesDemoData: false, isChanging: true)) {
            DemoHealthDataFeature()
        } withDependencies: {
            $0.setDemoHealthData = SetDemoHealthDataUseCase(repository: repository)
        }

        await store.send(.toggled(true))

        #expect(repository.storedValues.value.isEmpty)
    }

    /// HDEMO-1: Settings' Demo data screen runs the demo drinks and the demo Health data switch side by side.
    @Test func theDemoDataScreenRunsTheDemoDrinksAndTheSwitch() async {
        let store = TestStore(initialState: DemoDataFeature.State()) {
            DemoDataFeature()
        }

        await store.send(.history(.demoHistoryUpdated(true))) {
            $0.history.hasDemoHistory = true
        }
        await store.send(.health(.demoDataUpdated(true))) {
            $0.health.usesDemoData = true
        }
    }

    // MARK: - HDEMO-2: a failed change says so until the next try

    @Test func aFailedChangeSaysSoUntilTheNextTry() async {
        let repository = FakeHealthDataRepository(setError: StoreFailure())
        let store = TestStore(initialState: DemoHealthDataFeature.State(usesDemoData: false)) {
            DemoHealthDataFeature()
        } withDependencies: {
            $0.setDemoHealthData = SetDemoHealthDataUseCase(repository: repository)
        }

        await store.send(.toggled(true)) {
            $0.isChanging = true
        }
        await store.receive(\.changeFinished) {
            $0.isChanging = false
            $0.changeFailed = true
        }
        await store.send(.toggled(true)) {
            $0.isChanging = true
            $0.changeFailed = false
        }
        await store.receive(\.changeFinished) {
            $0.isChanging = false
            $0.changeFailed = true
        }
    }
}
