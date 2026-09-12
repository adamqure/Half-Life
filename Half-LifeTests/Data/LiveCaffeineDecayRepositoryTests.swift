//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests LiveCaffeineDecayRepositoryTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the live decay repository against REPO-1 to REPO-6 in the Caffeine Decay Model article, with a fake drink
/// log, a fake half-life, a fake absorption rate, and a fixed clock. The time limit turns a curve that never arrives
/// into a failure instead of a hang.
@Suite(.timeLimit(.minutes(1)))
struct LiveCaffeineDecayRepositoryTests {

    let rule = CaffeineDecayRule()

    static let midnight = Date(timeIntervalSinceReferenceDate: 0)
    /// 8:00pm on the worked examples' day.
    static let evening = date(20)

    static func date(_ hours: Double) -> Date {
        midnight.addingTimeInterval(hours * 3_600)
    }

    static func drink(_ milligrams: Double, hours: Double) -> LoggedDrink {
        LoggedDrink(type: .espresso, quantity: 1, milligrams: milligrams, consumedAt: date(hours))
    }

    /// The worked examples' day of drinks: 128 mg at 8:00am, 64 mg at 10:45am, and 205 mg at 3:00pm.
    static let dayOfDrinks = [drink(128, hours: 8), drink(64, hours: 10.75), drink(205, hours: 15)]

    static func repository(
        _ source: FakeDrinkLogDataSource, halfLife: CaffeineHalfLife = .standard,
        absorption: CaffeineAbsorptionRate = .standard, now: Date = evening
    ) -> LiveCaffeineDecayRepository {
        LiveCaffeineDecayRepository(
            drinkLog: source,
            halfLife: FakeHalfLifeDataSource(value: halfLife),
            absorption: FakeAbsorptionRateDataSource(value: absorption),
            bedtime: FakeBedtimeDataSource(value: .standard),
            clock: FakeClockDataSource(date: now, minuteDates: []))
    }

    /// The rule's curve for `drinks`, with the standard half-life and absorption rate unless given others.
    func expected(
        _ drinks: [LoggedDrink], halfLife: CaffeineHalfLife = .standard, absorption: CaffeineAbsorptionRate = .standard,
        now: Date = evening
    ) -> [CaffeineLevel] {
        rule.curve(
            from: drinks.map(\.intake), kinetics: CaffeineKinetics(halfLife: halfLife, absorption: absorption), now: now
        )
    }

    // MARK: - REPO-2: a new subscriber gets a curve for the current time

    @Test func newSubscriberGetsACurveCalculatedForTheCurrentTime() async throws {
        let repository = Self.repository(FakeDrinkLogDataSource(drinks: Self.dayOfDrinks))

        var curves = repository.curve().makeAsyncIterator()
        let curve = try #require(await curves.next())

        #expect(curve == expected(Self.dayOfDrinks))
    }

    // MARK: - REPO-1: only drinks that aren't marked negligible

    @Test func readsOnlyTheDrinksThatArentMarkedNegligible() async throws {
        let marked = Self.drink(200, hours: 19)
        let source = FakeDrinkLogDataSource(drinks: Self.dayOfDrinks + [marked], negligibleIDs: [marked.id])
        let repository = Self.repository(source)

        var curves = repository.curve().makeAsyncIterator()
        let curve = try #require(await curves.next())

        #expect(curve == expected(Self.dayOfDrinks))
        #expect(await source.nonNegligibleDrinksCallCount > 0)
        #expect(await source.drinksCallCount == 0)
    }

    // MARK: - REPO-3: marks exactly the negligible intakes

    /// 64 mg stops counting after about 38.82 hours. At 51 hours, the window's first sample is 39 hours, just past it.
    @Test func marksExactlyTheIntakesNegligibleAtTheWindowsFirstSample() async throws {
        let old = Self.drink(64, hours: 0)
        let recent = Self.drink(200, hours: 40)
        let source = FakeDrinkLogDataSource(drinks: [old, recent])
        let repository = Self.repository(source, now: Self.date(51))

        var curves = repository.curve().makeAsyncIterator()
        _ = try #require(await curves.next())

        #expect(await source.markedIntakes == [[old.intake]])
    }

    @Test func marksNothingWhenNoIntakeIsNegligible() async throws {
        let source = FakeDrinkLogDataSource(drinks: Self.dayOfDrinks)
        let repository = Self.repository(source)

        var curves = repository.curve().makeAsyncIterator()
        _ = try #require(await curves.next())

        #expect(await source.markedIntakes.isEmpty)
    }

    // MARK: - REPO-4: marking changes no level

    @Test func curveIsTheSameWhetherOrNotTheNegligibleIntakeIsMarked() async throws {
        let old = Self.drink(64, hours: 0)
        let recent = Self.drink(200, hours: 40)
        let now = Self.date(51)
        let repository = Self.repository(FakeDrinkLogDataSource(drinks: [old, recent]), now: now)

        var curves = repository.curve().makeAsyncIterator()
        let curve = try #require(await curves.next())

        let withOld = expected([old, recent], now: now)
        let withoutOld = expected([recent], now: now)
        #expect(withOld == withoutOld)
        #expect(curve == withoutOld)
    }

    struct DataSourceFailed: Error {}

    /// Marking only saves work, so a failed mark is logged and the curve is still published.
    @Test func curveIsStillPublishedWhenMarkingFails() async throws {
        let old = Self.drink(64, hours: 0)
        let recent = Self.drink(200, hours: 40)
        let now = Self.date(51)
        let source = FakeDrinkLogDataSource(drinks: [old, recent])
        await source.failMarks(with: DataSourceFailed())
        let repository = Self.repository(source, now: now)

        var curves = repository.curve().makeAsyncIterator()
        let curve = try #require(await curves.next())

        #expect(curve == expected([recent], now: now))
        #expect(await source.negligibleIDs.isEmpty)
    }

    // MARK: - Failures

    /// A failed read publishes nothing, and the next change, once the drinks can be read, publishes a curve.
    @Test func failedReadPublishesNothingAndTheNextChangeRecovers() async throws {
        let source = FakeDrinkLogDataSource(drinks: Self.dayOfDrinks)
        await source.failReads(with: DataSourceFailed())
        let repository = Self.repository(source)
        var curves = repository.curve().makeAsyncIterator()
        while await source.nonNegligibleDrinksCallCount == 0 {
            await Task.yield()
        }

        await source.failReads(with: nil)
        await source.signalChange()

        #expect(await curves.next() == expected(Self.dayOfDrinks))
    }

    // MARK: - REPO-5: a change reaches every subscriber

    @Test func everySubscriberGetsARecalculatedCurveWhenTheDataSourceSignalsAChange() async throws {
        let source = FakeDrinkLogDataSource(drinks: Self.dayOfDrinks)
        let repository = Self.repository(source)
        var first = repository.curve().makeAsyncIterator()
        var second = repository.curve().makeAsyncIterator()
        _ = try #require(await first.next())
        _ = try #require(await second.next())

        let lateCup = Self.drink(95, hours: 19)
        await source.insert(lateCup)
        await source.signalChange()

        let expected = expected(Self.dayOfDrinks + [lateCup])
        #expect(await first.next() == expected)
        #expect(await second.next() == expected)
    }

    // MARK: - REPO-6: the half-life and absorption rate from their data sources

    @Test func calculatesWithTheHalfLifeFromTheDataSource() async throws {
        let oneHour = try #require(CaffeineHalfLife(seconds: 3_600))
        let repository = Self.repository(FakeDrinkLogDataSource(drinks: Self.dayOfDrinks), halfLife: oneHour)

        var curves = repository.curve().makeAsyncIterator()
        let curve = try #require(await curves.next())

        #expect(curve == expected(Self.dayOfDrinks, halfLife: oneHour))
    }

    @Test func calculatesWithTheAbsorptionRateFromTheDataSource() async throws {
        let oneHour = try #require(CaffeineAbsorptionRate(halfLifeSeconds: 3_600))
        let repository = Self.repository(FakeDrinkLogDataSource(drinks: Self.dayOfDrinks), absorption: oneHour)

        var curves = repository.curve().makeAsyncIterator()
        let curve = try #require(await curves.next())

        #expect(curve == expected(Self.dayOfDrinks, absorption: oneHour))
        #expect(curve != expected(Self.dayOfDrinks))
    }
}
