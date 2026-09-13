//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests SleepToleranceUseCaseTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the Sleep screen's use cases against a fake repository (TOLUSE-1 and TOLUSE-2 in the Insights article).
struct SleepToleranceUseCaseTests {

    // MARK: - TOLUSE-1: observing streams every analysis the repository publishes, in order

    @Test func observingStreamsEveryAnalysisTheRepositoryPublishes() async throws {
        let analyses = [SleepCaffeineAnalysis.empty(), .empty(isDemo: true)]
        let observe = ObserveSleepCaffeineAnalysisUseCase(
            repository: FakeSleepToleranceRepository(analyses: analyses))

        var received: [SleepCaffeineAnalysis] = []
        for await analysis in try await executeThroughProtocol(observe, ()) {
            received.append(analysis)
        }

        #expect(received == analyses)
    }

    // MARK: - TOLUSE-3: observing the caffeine nights streams the repository's 31 nights in the given calendar

    @Test func observingTheCaffeineNightsStreamsThe31NightsInTheCalendar() async throws {
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let tokyoTimeZone = tokyo.timeZone
        let history = CaffeineNightHistory(nights: [], threshold: .standard, isDemo: true)
        let repository = FakeSleepToleranceRepository(caffeineNights: { days, calendar in
            days == 31 && calendar.timeZone == tokyoTimeZone ? [history] : []
        })

        var received: [CaffeineNightHistory] = []
        let observe = ObserveCaffeineNightsUseCase(repository: repository)
        for await nights in try await executeThroughProtocol(observe, tokyo) {
            received.append(nights)
        }

        #expect(received == [history])
    }

    // MARK: - TOLUSE-2: keeping the tolerance current subscribes until the stream ends

    @Test func keepingTheToleranceCurrentSubscribesUntilTheStreamEnds() async throws {
        let repository = FakeSleepToleranceRepository(analyses: [.empty()])

        try await executeThroughProtocol(KeepSleepToleranceCurrentUseCase(repository: repository), ())

        #expect(repository.subscriptions.value == 1)
    }
}
