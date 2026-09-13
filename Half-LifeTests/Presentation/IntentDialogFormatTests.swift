//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests IntentDialogFormatTests
//

import Foundation
import Testing

@testable import Half_Life

/// INTENT-FORMAT-1 to INTENT-FORMAT-6 in the App Intents article, in New York's time zone and the `en_US` locale.
struct IntentDialogFormatTests {

    // MARK: - INTENT-FORMAT-1: a logged drink

    @Test func aLoggedDrinkGivesItsNameQuantityAndCaffeine() throws {
        let format = try AppIntentTesting.format()

        #expect(String(localized: format.logged(.latte, quantity: 2)) == "Logged Latte, 2 shots: about 125 mg.")
    }

    // MARK: - INTENT-FORMAT-2: the status

    @Test func theStatusGivesTheLevelNowAndAtBedtime() throws {
        let format = try AppIntentTesting.format()
        let bedtime = try AppIntentTesting.date(day: 7, hour: 22, minute: 30)

        #expect(
            String(localized: format.status(try AppIntentTesting.status()))
                == "About 85 mg in your system now. Down to about 34 mg by \(format.time(bedtime)).")
    }

    @Test func theStatusLeavesOutABedtimeItDoesntHave() throws {
        let format = try AppIntentTesting.format()
        let full = try AppIntentTesting.status()
        let status = CaffeineStatus(
            level: full.level, activeIntakes: full.activeIntakes, lastIntakeHalfGoneAt: nil, levelAtBedtime: nil)

        #expect(String(localized: format.status(status)) == "About 85 mg in your system now.")
    }

    @Test func theStatusWithNothingCountingSaysSoAsTheDecayCardDoes() throws {
        let format = try AppIntentTesting.format()
        let full = try AppIntentTesting.status()
        let status = CaffeineStatus(
            level: CaffeineLevel(date: full.level.date, milligrams: 0), activeIntakes: [], lastIntakeHalfGoneAt: nil,
            levelAtBedtime: full.levelAtBedtime)

        #expect(String(localized: format.status(status)) == "Nothing in your system right now.")
    }

    // MARK: - INTENT-FORMAT-3: the cutoff

    @Test func theCutoffGivesTheUsualDrinkTheLatestCupAndTheBedtime() throws {
        let format = try AppIntentTesting.format()
        let latestCup = format.time(try AppIntentTesting.date(day: 7, hour: 14, minute: 30))
        let bedtime = format.time(try AppIntentTesting.date(day: 7, hour: 22, minute: 30))

        #expect(
            String(localized: format.cutoff(try AppIntentTesting.cutoff()))
                == "Have your usual Latte, 2 shots, by \(latestCup) to be at 40 mg or less by your \(bedtime) bedtime.")
    }

    @Test func theCutoffWithNoLatestCupSaysTheresNoMoreToday() throws {
        let format = try AppIntentTesting.format()
        let bedtime = format.time(try AppIntentTesting.date(day: 7, hour: 22, minute: 30))

        #expect(
            String(localized: format.cutoff(try AppIntentTesting.cutoff(latestCup: false)))
                == "No more caffeine today if you want to be at 40 mg or less by your \(bedtime) bedtime.")
    }

    // MARK: - INTENT-FORMAT-4: a day of the log

    @Test func todayListsEachDrinkAndTheTotalAndMarksDemoData() throws {
        let format = try AppIntentTesting.format()
        let latte = format.time(try AppIntentTesting.date(day: 7, hour: 8, minute: 10))
        let espresso = format.time(try AppIntentTesting.date(day: 7, hour: 13, minute: 5))

        #expect(
            String(localized: format.day(try AppIntentTesting.day(7), today: try AppIntentTesting.now()))
                == "Today you've logged about 188 mg: Latte (2 shots) at \(latte) and Espresso (1 shot) at "
                + "\(espresso), from the demo data.")
    }

    @Test func yesterdayIsCalledYesterday() throws {
        let format = try AppIntentTesting.format()
        let latte = format.time(try AppIntentTesting.date(day: 6, hour: 8, minute: 10))
        let espresso = format.time(try AppIntentTesting.date(day: 6, hour: 13, minute: 5))

        #expect(
            String(localized: format.day(try AppIntentTesting.day(6), today: try AppIntentTesting.now()))
                == "Yesterday you logged about 188 mg: Latte (2 shots) at \(latte) and Espresso (1 shot) at "
                + "\(espresso), from the demo data.")
    }

    @Test func anEarlierDayIsNamed() throws {
        let format = try AppIntentTesting.format()
        let latte = format.time(try AppIntentTesting.date(day: 1, hour: 8, minute: 10))
        let espresso = format.time(try AppIntentTesting.date(day: 1, hour: 13, minute: 5))

        #expect(
            String(localized: format.day(try AppIntentTesting.day(1), today: try AppIntentTesting.now()))
                == "On Tuesday, September 1, you logged about 188 mg: Latte (2 shots) at \(latte) and Espresso "
                + "(1 shot) at \(espresso), from the demo data.")
    }

    @Test(arguments: [
        (7, "No drinks logged today."), (6, "No drinks logged yesterday."),
        (1, "No drinks logged on Tuesday, September 1."),
    ])
    func aDayWithNoDrinksSaysSo(day: Int, expected: String) throws {
        let format = try AppIntentTesting.format()
        let empty = DrinkLogDay(
            intake: DailyCaffeineIntake(day: try AppIntentTesting.date(day: day, hour: 0, minute: 0), milligrams: 0),
            drinks: [])

        #expect(String(localized: format.day(empty, today: try AppIntentTesting.now())) == expected)
    }

    // MARK: - INTENT-FORMAT-5: the sleep window

    @Test func aWindowAfterTheBedtimeSaysWhenCaffeineClears() throws {
        let format = try AppIntentTesting.format()
        let start = format.time(try AppIntentTesting.date(day: 7, hour: 23, minute: 10))
        let end = format.time(try AppIntentTesting.date(day: 8, hour: 0, minute: 40))
        let bedtime = format.time(try AppIntentTesting.date(day: 7, hour: 22, minute: 30))

        #expect(
            String(localized: format.sleepWindow(try AppIntentTesting.sleepWindow(clearHour: 23, clearMinute: 10)))
                == "Your best time to fall asleep is \(start) to \(end). Caffeine should drop under 40 mg at about "
                + "\(start), after your \(bedtime) bedtime.")
    }

    @Test func aWindowAtTheBedtimeSaysCaffeineIsUnderByThen() throws {
        let format = try AppIntentTesting.format()
        let bedtime = format.time(try AppIntentTesting.date(day: 7, hour: 22, minute: 30))
        let end = format.time(try AppIntentTesting.date(day: 8, hour: 0, minute: 0))

        #expect(
            String(localized: format.sleepWindow(try AppIntentTesting.sleepWindow(clearHour: 21)))
                == "Your best time to fall asleep is \(bedtime) to \(end). Caffeine should be under 40 mg by your "
                + "\(bedtime) bedtime.")
    }

    @Test func noWindowSaysCaffeineStaysOverTheThreshold() throws {
        let format = try AppIntentTesting.format()

        #expect(
            String(localized: format.sleepWindow(try AppIntentTesting.sleepWindow(clearHour: nil)))
                == "Caffeine should stay over 40 mg until after noon tomorrow, so there's no good time to fall asleep "
                + "tonight.")
    }

    // MARK: - INTENT-FORMAT-6: amounts and times

    @Test func amountsAreWholeMilligramsAndTimesAreClockTimesInTheCalendar() throws {
        let format = try AppIntentTesting.format()

        #expect(format.amount(84.6) == "85 mg")
        #expect(format.time(try AppIntentTesting.date(day: 7, hour: 22, minute: 30)) == "10:30\u{202F}PM")
    }

    // MARK: - INTENT-FAIL-1: failures

    @Test func eachFailureSaysWhatWentWrong() {
        #expect(
            String(localized: IntentFailure.notLogged(.quantityBelowOne).localizedStringResource)
                == "Half-Life can only log a quantity of 1 or more.")
        #expect(
            String(localized: IntentFailure.notLogged(.consumedInFuture).localizedStringResource)
                == "Half-Life can't log a drink in the future.")
        #expect(
            String(localized: IntentFailure.saveFailed.localizedStringResource)
                == "The drink couldn't be saved. Try again.")
        #expect(
            String(localized: IntentFailure.unavailable.localizedStringResource)
                == "That isn't available right now. Open Half-Life to see your caffeine.")
        #expect(
            String(localized: IntentFailure.couldntAnswer.localizedStringResource)
                == "Half-Life couldn't answer that. Try again.")
    }
}
