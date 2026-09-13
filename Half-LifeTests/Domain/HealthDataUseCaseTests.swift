//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests HealthDataUseCaseTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the Health data use cases against HUSE-1 and HUSE-2 in the Apple Health Card article, with the fake
/// repository.
struct HealthDataUseCaseTests {
    struct StoreFailure: Error {}

    // MARK: - HUSE-1: observing the summary streams what the repository publishes for the calendar

    @Test func observingTheSummaryStreamsWhatTheRepositoryPublishesForTheCalendar() async throws {
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let tokyoTimeZone = tokyo.timeZone
        let morning = HealthSummary(stepsToday: 1_200)
        let afternoon = HealthSummary(stepsToday: 6_400, restingHeartRateToday: 58)
        let repository = FakeHealthDataRepository(summaries: {
            $0.timeZone == tokyoTimeZone ? [morning, afternoon] : []
        })

        var received: [HealthSummary] = []
        let observe = ObserveHealthSummaryUseCase(repository: repository)
        for await summary in try await executeThroughProtocol(observe, tokyo) {
            received.append(summary)
        }

        #expect(received == [morning, afternoon])
    }

    // MARK: - HUSE-2: the switch's use cases go through the repository

    @Test func observingTheSwitchStreamsTheRepositorysAnswers() async throws {
        let repository = FakeHealthDataRepository(demoAnswers: [false, true])

        var received: [Bool] = []
        let observe = ObserveDemoHealthDataUseCase(repository: repository)
        for await answer in try await executeThroughProtocol(observe, ()) {
            received.append(answer)
        }

        #expect(received == [false, true])
    }

    @Test func settingTheSwitchStoresItThroughTheRepository() async throws {
        let repository = FakeHealthDataRepository()

        try await executeThroughProtocol(SetDemoHealthDataUseCase(repository: repository), true)

        #expect(repository.storedValues.value == [true])
    }

    @Test func aFailedSetPassesOnTheRepositorysError() async {
        let repository = FakeHealthDataRepository(setError: StoreFailure())

        await #expect(throws: StoreFailure.self) {
            try await executeThroughProtocol(SetDemoHealthDataUseCase(repository: repository), true)
        }
    }
}
