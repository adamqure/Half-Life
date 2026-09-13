//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests LogDrinkIntentTests
//

import AppIntents
import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// INTENT-LOG-1 to INTENT-LOG-4 in the App Intents article, with the use case built on fakes.
struct LogDrinkIntentTests {

    /// An intent whose use case logs into `drinkLog` at ``AppIntentTesting/now()``.
    static func intent(
        drinkLog: FakeDrinkLogRepository, make: () -> LogDrinkIntent
    ) throws -> LogDrinkIntent {
        let now = try AppIntentTesting.now()
        let calendar = try AppIntentTesting.newYork()
        return withDependencies {
            $0.calendar = calendar
            $0.logDrink = LogDrinkUseCase(currentTime: FakeCurrentTimeRepository(date: now), drinkLog: drinkLog)
        } operation: {
            make()
        }
    }

    /// INTENT-LOG-1: the drink and quantity it's given, consumed now.
    @Test func itLogsTheDrinkAndQuantityConsumedNow() async throws {
        let drinkLog = FakeDrinkLogRepository()
        let intent = try Self.intent(drinkLog: drinkLog) { LogDrinkIntent(drink: .coldBrew, quantity: 3) }

        _ = try await intent.perform()

        let logged = await drinkLog.logged
        #expect(logged.map(\.type) == [.coldBrew])
        #expect(logged.map(\.quantity) == [3])
        #expect(logged.map(\.milligrams) == [DrinkType.coldBrew.estimatedMilligrams(quantity: 3)])
        #expect(logged.map(\.consumedAt) == [try AppIntentTesting.now()])
    }

    /// INTENT-LOG-2: without a quantity, the drink's default quantity.
    @Test func withoutAQuantityItLogsTheDrinksDefault() async throws {
        let drinkLog = FakeDrinkLogRepository()
        let intent = try Self.intent(drinkLog: drinkLog) {
            let intent = LogDrinkIntent()
            intent.drink = .latte
            return intent
        }

        _ = try await intent.perform()

        #expect(await drinkLog.logged.map(\.quantity) == [DrinkType.latte.defaultQuantity])
    }

    /// INTENT-LOG-3: a drink the rule refuses isn't logged, and the failure says why.
    @Test func aDrinkTheRuleRefusesFailsWithTheReason() async throws {
        let drinkLog = FakeDrinkLogRepository(logError: DrinkLogRule.Violation.quantityBelowOne)
        let intent = try Self.intent(drinkLog: drinkLog) { LogDrinkIntent(drink: .latte, quantity: 0) }

        await #expect(throws: IntentFailure.notLogged(.quantityBelowOne)) {
            _ = try await intent.perform()
        }
    }

    /// INTENT-LOG-4: any other error fails with "couldn't be saved".
    @Test func anyOtherErrorFailsAsNotSaved() async throws {
        let drinkLog = FakeDrinkLogRepository(logError: AppIntentTesting.StoreFailed())
        let intent = try Self.intent(drinkLog: drinkLog) { LogDrinkIntent(drink: .latte, quantity: 2) }

        await #expect(throws: IntentFailure.saveFailed) {
            _ = try await intent.perform()
        }
    }
}
