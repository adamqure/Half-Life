//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests LogDrinkUseCaseTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks logging a drink against the Drink Composer article: requirements USE-1 to USE-3.
struct LogDrinkUseCaseTests {

    struct StoreFailed: Error {}

    let now = Date(timeIntervalSinceReferenceDate: 0)

    func useCase(_ drinkLog: FakeDrinkLogRepository) -> LogDrinkUseCase {
        LogDrinkUseCase(currentTime: FakeCurrentTimeRepository(date: now), drinkLog: drinkLog)
    }

    // MARK: - USE-1: the drink is built from the input and the current time

    @Test func logsTheDrinkConsumedSecondsAgo() async throws {
        let drinkLog = FakeDrinkLogRepository()

        try await executeThroughProtocol(
            useCase(drinkLog), LogDrinkUseCase.Input(type: .latte, quantity: 2, secondsAgo: 3_600))

        let logged = await drinkLog.logged
        try #require(logged.count == 1)
        #expect(logged[0].type == .latte)
        #expect(logged[0].quantity == 2)
        #expect(logged[0].milligrams == DrinkType.latte.estimatedMilligrams(quantity: 2))
        #expect(logged[0].consumedAt == now.addingTimeInterval(-3_600))
    }

    // MARK: - USE-2: zero seconds ago is the current time

    @Test func logsADrinkConsumedNow() async throws {
        let drinkLog = FakeDrinkLogRepository()

        try await executeThroughProtocol(
            useCase(drinkLog), LogDrinkUseCase.Input(type: .cola, quantity: 1, secondsAgo: 0))

        #expect(await drinkLog.logged.map(\.consumedAt) == [now])
    }

    // MARK: - USE-3: the repository's error reaches the caller

    @Test func throwsTheRepositorysError() async {
        let log = useCase(FakeDrinkLogRepository(logError: DrinkLogRule.Violation.consumedInFuture))

        await #expect(throws: DrinkLogRule.Violation.consumedInFuture) {
            try await executeThroughProtocol(log, LogDrinkUseCase.Input(type: .matcha, quantity: 1, secondsAgo: -60))
        }
    }

    @Test func throwsAStoreFailure() async {
        let log = useCase(FakeDrinkLogRepository(logError: StoreFailed()))

        await #expect(throws: StoreFailed.self) {
            try await executeThroughProtocol(log, LogDrinkUseCase.Input(type: .greenTea, quantity: 1, secondsAgo: 0))
        }
    }
}
