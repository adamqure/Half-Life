//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests IntentValuesTests
//

import AppIntents
import Foundation
import Testing

@testable import Half_Life

/// INTENT-VALUE-1 to INTENT-VALUE-4 in the App Intents article: the values the read intents return.
struct IntentValuesTests {

    /// INTENT-VALUE-1: the status in whole milligrams, with the bedtime.
    @Test func theStatusValueHasTheLevelsInWholeMilligramsAndTheBedtime() throws {
        let status = try AppIntentTesting.status()

        let value = CaffeineStatusEntity(status)

        #expect(value.milligramsNow == 85)
        #expect(value.milligramsAtBedtime == 34)
        #expect(value.bedtime == status.levelAtBedtime?.date)
    }

    /// INTENT-VALUE-2: the cutoff's drink, latest cup, bedtime, and threshold.
    @Test func theCutoffValueHasTheDrinkTheLatestCupAndTheBedtime() throws {
        let cutoff = try AppIntentTesting.cutoff()

        let value = CaffeineCutoffEntity(cutoff)

        #expect(value.drink == "Latte")
        #expect(value.quantity == 2)
        #expect(value.latestCup == cutoff.latestCup)
        #expect(value.bedtime == cutoff.bedtime)
        #expect(value.thresholdMilligrams == 40)
    }

    /// INTENT-VALUE-3: the day, its total in whole milligrams, and how many drinks.
    @Test func theIntakeValueHasTheDayTheTotalAndTheNumberOfDrinks() throws {
        let day = try AppIntentTesting.day(7)

        let value = CaffeineIntakeEntity(day)

        #expect(value.day == day.intake.day)
        #expect(value.milligrams == 188)
        #expect(value.drinkCount == 2)
    }

    /// INTENT-VALUE-4: the window, when caffeine clears, and the bedtime.
    @Test func theSleepTimeValueHasTheWindowTheClearingTimeAndTheBedtime() throws {
        let window = try AppIntentTesting.sleepWindow(clearHour: 23, clearMinute: 10)

        let value = SleepTimeEntity(window)

        #expect(value.windowStart == window.window?.start)
        #expect(value.windowEnd == window.window?.end)
        #expect(value.clearsAt == window.clearsAt)
        #expect(value.bedtime == window.bedtime)
    }
}
