//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests DemoHistoryUseCaseTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the demo history's use cases against DEMOUSE-1 to DEMOUSE-3 in the Settings article, with an in-memory
/// drink log repository.
struct DemoHistoryUseCaseTests {

    struct RepositoryFailed: Error {}

    static let tokyo: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 9 * 3_600) ?? .gmt
        return calendar
    }()

    // MARK: - DEMOUSE-1: adding the demo history asks the repository, in the given calendar

    @Test func addingAsksTheRepositoryInTheGivenCalendar() async throws {
        let drinkLog = FakeDrinkLogRepository()

        try await executeThroughProtocol(AddDemoHistoryUseCase(drinkLog: drinkLog), Self.tokyo)

        #expect(await drinkLog.demoHistoryAdded == [Self.tokyo])
    }

    @Test func addingThrowsTheRepositorysError() async {
        let add = AddDemoHistoryUseCase(drinkLog: FakeDrinkLogRepository(demoHistoryError: RepositoryFailed()))

        await #expect(throws: RepositoryFailed.self) {
            try await executeThroughProtocol(add, Self.tokyo)
        }
    }

    // MARK: - DEMOUSE-2: removing the demo history asks the repository

    @Test func removingAsksTheRepository() async throws {
        let drinkLog = FakeDrinkLogRepository()

        try await executeThroughProtocol(RemoveDemoHistoryUseCase(drinkLog: drinkLog), ())

        #expect(await drinkLog.demoHistoryRemovedCount == 1)
    }

    @Test func removingThrowsTheRepositorysError() async {
        let remove = RemoveDemoHistoryUseCase(drinkLog: FakeDrinkLogRepository(demoHistoryError: RepositoryFailed()))

        await #expect(throws: RepositoryFailed.self) {
            try await executeThroughProtocol(remove, ())
        }
    }

    // MARK: - DEMOUSE-3: observing streams whether the log holds demo drinks

    @Test func observingStreamsTheRepositorysAnswers() async throws {
        let drinkLog = FakeDrinkLogRepository(hasDemoHistory: [false, true])

        var answers: [Bool] = []
        for await answer in try await executeThroughProtocol(ObserveDemoHistoryUseCase(drinkLog: drinkLog), ()) {
            answers.append(answer)
        }

        #expect(answers == [false, true])
    }
}
