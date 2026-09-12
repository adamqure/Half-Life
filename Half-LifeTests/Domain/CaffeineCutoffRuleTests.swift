//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests CaffeineCutoffRuleTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the cutoff against CUTOFF-1 to CUTOFF-8 in the Caffeine Cutoff article. The rule is pure, so its tests need
/// no fakes. They check it against ``CaffeineDecayRule``'s levels, so the cutoff and the curve always agree.
struct CaffeineCutoffRuleTests {

    let rule = CaffeineCutoffRule()
    let decay = CaffeineDecayRule()

    static let midnight = Date(timeIntervalSinceReferenceDate: 0)
    static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()
    /// 10:30pm on the first day, the standard bedtime.
    static let bedtime = date(22.5)
    static let threshold = SleepThreshold.standard
    /// Two espresso shots in a latte: 125.4 mg.
    static let latte = FavouriteDrink(type: .latte, quantity: 2)
    /// One cup of green tea: 28.4 mg, less than the threshold on its own.
    static let greenTea = FavouriteDrink(type: .greenTea, quantity: 1)

    static func date(_ hours: Double) -> Date {
        midnight.addingTimeInterval(hours * 3_600)
    }

    static func intake(_ milligrams: Double, hours: Double) -> CaffeineIntake {
        CaffeineIntake(id: UUID(), milligrams: milligrams, consumedAt: date(hours))
    }

    /// The level at `bedtime` after `intakes`, plus `drink` consumed at `cupAt`.
    func levelAtBedtime(
        _ drink: FavouriteDrink, cupAt: Date, after intakes: [CaffeineIntake] = [], bedtime: Date = bedtime,
        kinetics: CaffeineKinetics = .standard
    ) -> Double {
        let cup = CaffeineIntake(
            id: UUID(), milligrams: drink.type.estimatedMilligrams(quantity: drink.quantity), consumedAt: cupAt)
        return decay.level(at: bedtime, from: intakes + [cup], kinetics: kinetics).milligrams
    }

    func cutoff(
        _ drink: FavouriteDrink = latte, after intakes: [CaffeineIntake] = [], now: Date = date(8),
        kinetics: CaffeineKinetics = .standard, calendar: Calendar = utc
    ) throws -> CaffeineCutoff {
        let inputs = CaffeineCutoffRule.Inputs(
            drink: drink, intakes: intakes, kinetics: kinetics, threshold: Self.threshold, bedtime: .standard)
        return try #require(rule.cutoff(inputs, now: now, calendar: calendar))
    }

    // MARK: - CUTOFF-1: the latest time the usual cup leaves at most the threshold at bedtime, down to the half hour

    /// Two shots' exact cutoff is 1:06pm, so the cutoff is 1:00pm. Half an hour later leaves more than the threshold.
    @Test func latestCupIsTheExactCutoffRoundedDownToTheHalfHour() throws {
        let latestCup = try #require(try cutoff().latestCup)

        #expect(latestCup == Self.date(13))
        #expect(levelAtBedtime(Self.latte, cupAt: latestCup) <= Self.threshold.milligrams)
        #expect(levelAtBedtime(Self.latte, cupAt: latestCup.addingTimeInterval(30 * 60)) > Self.threshold.milligrams)
    }

    /// Nepal is 5 hours 45 minutes ahead of UTC, so its half hours fall at a quarter past and a quarter to in UTC.
    @Test func roundsDownToTheHalfHourInTheGivenCalendar() throws {
        var kathmandu = Calendar(identifier: .gregorian)
        kathmandu.timeZone = try #require(TimeZone(identifier: "Asia/Kathmandu"))

        let latestCup = try #require(try cutoff(now: Self.date(0), calendar: kathmandu).latestCup)

        #expect(kathmandu.component(.minute, from: latestCup) % 30 == 0)
        #expect(kathmandu.component(.second, from: latestCup) == 0)
    }

    @Test func saysWhichDrinkBedtimeAndThresholdItsFor() throws {
        let cutoff = try cutoff()

        #expect(cutoff.drink == Self.latte)
        #expect(cutoff.bedtime == Self.bedtime)
        #expect(cutoff.threshold == Self.threshold)
    }

    // MARK: - CUTOFF-2: the caffeine already in the body counts

    /// 64 mg at 8:00am still leaves about 11 mg at bedtime, so one shot's cutoff moves from 6:30pm to 4:00pm.
    @Test func caffeineAlreadyLoggedMovesTheCutoffEarlier() throws {
        let oneShot = FavouriteDrink(type: .latte, quantity: 1)
        let morning = [Self.intake(64, hours: 8)]
        let withoutIt = try #require(try cutoff(oneShot, now: Self.date(9)).latestCup)

        let latestCup = try #require(try cutoff(oneShot, after: morning, now: Self.date(9)).latestCup)

        #expect(latestCup < withoutIt)
        #expect(levelAtBedtime(oneShot, cupAt: latestCup, after: morning) <= Self.threshold.milligrams)
        #expect(
            levelAtBedtime(oneShot, cupAt: latestCup.addingTimeInterval(30 * 60), after: morning)
                > Self.threshold.milligrams)
    }

    // MARK: - CUTOFF-3: no cutoff when even a cup now would leave more than the threshold

    @Test func noCutoffWhenEvenACupNowWouldLeaveTooMuchAtBedtime() throws {
        #expect(try cutoff(after: [Self.intake(200, hours: 19)], now: Self.date(20)).latestCup == nil)
    }

    /// A minute after 1:00pm there's no cutoff, although the exact one, 1:06pm, is still to come.
    @Test func noCutoffOnceTheRoundedCutoffHasPassed() throws {
        let latestCup = try #require(try cutoff().latestCup)

        #expect(try cutoff(now: latestCup.addingTimeInterval(60)).latestCup == nil)
    }

    @Test func theCutoffStillShowsDuringItsOwnMinute() throws {
        let latestCup = try #require(try cutoff().latestCup)

        #expect(try cutoff(now: latestCup.addingTimeInterval(59)).latestCup == latestCup)
    }

    // MARK: - CUTOFF-4: the cup has to peak by bedtime

    /// The latest cup that peaks by 10:30pm is at 9:26pm, so the cutoff is 9:00pm.
    @Test func aCupTooSmallToReachTheThresholdStillHasToPeakByBedtime() throws {
        let latestPeakingCup = Self.bedtime.addingTimeInterval(-decay.peakDelay(for: .standard))
        #expect(latestPeakingCup > Self.date(21) && latestPeakingCup < Self.date(21.5))

        #expect(try cutoff(Self.greenTea).latestCup == Self.date(21))
    }

    @Test func noCutoffWithinThePeakDelayOfBedtime() throws {
        #expect(try cutoff(Self.greenTea, now: Self.date(22)).latestCup == nil)
    }

    // MARK: - CUTOFF-5: after bedtime, the cutoff is for the next bedtime

    @Test func afterBedtimeTheCutoffIsForTomorrowsBedtime() throws {
        let cutoff = try cutoff(now: Self.date(23))

        #expect(cutoff.bedtime == Self.date(46.5))
        let latestCup = try #require(cutoff.latestCup)
        #expect(latestCup > Self.date(23))
        #expect(levelAtBedtime(Self.latte, cupAt: latestCup, bedtime: Self.date(46.5)) <= Self.threshold.milligrams)
    }

    // MARK: - CUTOFF-6: a longer half-life never gives a later cutoff

    @Test(arguments: [3.0, 8.0, 14.0])
    func aLongerHalfLifeNeverGivesALaterCutoff(hours: Double) throws {
        let longer = try #require(CaffeineHalfLife(seconds: hours * 3_600))
        let kinetics = CaffeineKinetics(halfLife: longer, absorption: .standard)
        let standard = try #require(try cutoff().latestCup)

        let cutoff = try cutoff(kinetics: kinetics).latestCup

        if hours > 5.5 {
            #expect(cutoff.map { $0 <= standard } ?? true)
        } else {
            #expect(try #require(cutoff) >= standard)
        }
    }

    // MARK: - CUTOFF-7: the bedtime is in the given calendar

    /// 10:30pm in Tokyo is 1:30pm UTC.
    @Test func findsTheBedtimeInTheGivenCalendar() throws {
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))

        let cutoff = try cutoff(Self.greenTea, now: Self.date(0), calendar: tokyo)

        #expect(cutoff.bedtime == Self.date(13.5))
    }

    // MARK: - CUTOFF-8: the cup is the drink's catalog estimate

    @Test func aBiggerUsualDrinkGivesAnEarlierCutoff() throws {
        let oneShot = try #require(try cutoff(FavouriteDrink(type: .latte, quantity: 1)).latestCup)
        let twoShots = try #require(try cutoff(Self.latte).latestCup)

        #expect(twoShots < oneShot)
    }
}
