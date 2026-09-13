//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests CaffeineCutoffWarningTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the drink composer's pre-log warning against WARN-1 to WARN-5 in the Caffeine Cutoff article. The rule is
/// pure, so its tests need no fakes. They check it against ``CaffeineDecayRule``'s levels and the cutoff itself.
struct CaffeineCutoffWarningTests {

    let rule = CaffeineCutoffRule()
    let decay = CaffeineDecayRule()

    static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()
    /// Two espresso shots in a latte: 125.4 mg. With nothing logged, its cutoff is 1:00pm.
    static let latte = FavouriteDrink(type: .latte, quantity: 2)
    static let oneShot = FavouriteDrink(type: .latte, quantity: 1)
    static let greenTea = FavouriteDrink(type: .greenTea, quantity: 1)

    static func date(_ hours: Double) -> Date {
        Date(timeIntervalSinceReferenceDate: hours * 3_600)
    }

    static func inputs(_ drink: FavouriteDrink, after intakes: [CaffeineIntake] = []) -> CaffeineCutoffRule.Inputs {
        CaffeineCutoffRule.Inputs(
            drink: drink, intakes: intakes, kinetics: .standard, threshold: .standard, bedtime: .standard)
    }

    func warning(
        _ drink: FavouriteDrink, at hours: Double, after intakes: [CaffeineIntake] = []
    ) -> CutoffWarning? {
        rule.warning(Self.inputs(drink, after: intakes), consumedAt: Self.date(hours), calendar: Self.utc)
    }

    // MARK: - WARN-1: no warning when the drink leaves at most the threshold at bedtime

    @Test func aDrinkThatFitsGetsNoWarning() {
        #expect(warning(Self.latte, at: 9) == nil)
    }

    // MARK: - WARN-2: more than the threshold at bedtime, with every intake logged, warns with the level

    @Test func aDrinkThatLeavesTooMuchWarnsWithTheLevelAtBedtime() throws {
        let cup = CaffeineIntake(
            id: UUID(), milligrams: DrinkType.latte.estimatedMilligrams(quantity: 2), consumedAt: Self.date(15))

        let found = try #require(warning(Self.latte, at: 15))

        guard case .tooMuchAtBedtime(let level, let threshold) = found else {
            Issue.record("Expected too much at bedtime, got \(found)")
            return
        }
        let expected = decay.level(at: Self.date(22.5), from: [cup], kinetics: .standard)
        #expect(level.date == expected.date)
        #expect(abs(level.milligrams - expected.milligrams) < 0.000_001)
        #expect(level.milligrams > 40)
        #expect(threshold == .standard)
    }

    /// 64 mg at 8:00am moves one shot's cutoff from 6:30pm to 4:00pm, so one at 5:00pm fits without it, not with it.
    @Test func caffeineAlreadyLoggedCounts() {
        let morning = [CaffeineIntake(id: UUID(), milligrams: 64, consumedAt: Self.date(8))]

        #expect(warning(Self.oneShot, at: 17) == nil)
        #expect(warning(Self.oneShot, at: 17, after: morning) != nil)
    }

    // MARK: - WARN-3: a drink less than the peak delay before bedtime is still rising at bedtime

    /// One green tea never leaves 40 mg on its own, but at 10:00pm it hasn't peaked by 10:30pm.
    @Test func aDrinkTooCloseToBedtimeIsStillRising() {
        #expect(warning(Self.greenTea, at: 21) == nil)
        #expect(warning(Self.greenTea, at: 22) == .stillRisingAtBedtime(bedtime: Self.date(22.5)))
    }

    // MARK: - WARN-4: the bedtime is the next one at or after the drink

    /// A drink at 11:00pm is after tonight's bedtime, so it's checked against tomorrow night's.
    @Test func aDrinkAfterBedtimeIsCheckedAgainstTheNextBedtime() {
        #expect(warning(Self.greenTea, at: 23) == nil)
        #expect(warning(Self.greenTea, at: 46) == .stillRisingAtBedtime(bedtime: Self.date(46.5)))
    }

    // MARK: - WARN-5: a drink at its cutoff never warns; half an hour later does

    @Test func theCutoffAndTheWarningAgree() throws {
        let cutoff = try #require(
            rule.cutoff(Self.inputs(Self.latte), now: Self.date(8), calendar: Self.utc)?.latestCup)
        let hours = cutoff.timeIntervalSinceReferenceDate / 3_600

        #expect(warning(Self.latte, at: hours) == nil)
        #expect(warning(Self.latte, at: hours + 0.5) != nil)
    }
}
