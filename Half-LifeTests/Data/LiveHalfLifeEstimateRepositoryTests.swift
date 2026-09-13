//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests LiveHalfLifeEstimateRepositoryTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the live half-life estimate repository against fake data sources (ESTREPO-1 to ESTREPO-8 in the Half-Life
/// Estimator article).
@Suite(.timeLimit(.minutes(1)))
struct LiveHalfLifeEstimateRepositoryTests {

    static let hour: TimeInterval = 3_600
    static let day: TimeInterval = 24 * hour

    static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()

    /// Noon on 15 June 2026, in UTC.
    static let now = utc.date(from: DateComponents(year: 2026, month: 6, day: 15, hour: 12)) ?? .distantPast
    /// Midnight at the start of 20 May 2026, in UTC: the first day with drinks.
    static let firstDay = utc.date(from: DateComponents(year: 2026, month: 5, day: 20)) ?? .distantPast

    static func midnight(ofDay index: Int) -> Date {
        firstDay.addingTimeInterval(Double(index) * day)
    }

    static func halfLife(hours: Double) throws -> CaffeineHalfLife {
        try #require(CaffeineHalfLife(seconds: hours * hour))
    }

    /// Two espressos at 9am on each of 26 days, and two more at 4pm on every third day.
    static func drinks(isDemo: Bool = false) -> [LoggedDrink] {
        (0..<26).flatMap { index -> [LoggedDrink] in
            let midnight = midnight(ofDay: index)
            let morning = LoggedDrink(
                type: .espresso, quantity: 2, milligrams: 128, consumedAt: midnight.addingTimeInterval(9 * hour),
                isDemo: isDemo)
            guard index.isMultiple(of: 3) else { return [morning] }
            let afternoon = LoggedDrink(
                type: .espresso, quantity: 2, milligrams: 128, consumedAt: midnight.addingTimeInterval(16 * hour),
                isDemo: isDemo)
            return [morning, afternoon]
        }
    }

    /// Twenty nights, from day 5 to day 24, each with some deep sleep and time awake that vary from night to night.
    static let intervals: [SleepStageInterval] = (5..<25).flatMap { index -> [SleepStageInterval] in
        let onset = midnight(ofDay: index).addingTimeInterval(23 * hour + Double(index % 4) * 900)
        func at(_ hours: Double) -> Date { onset.addingTimeInterval(hours * hour) }
        let awakeEnd = at(4).addingTimeInterval(Double(10 + (index % 5) * 8) * 60)
        return [
            SleepStageInterval(stage: .core, start: onset, end: at(3)),
            SleepStageInterval(stage: .deep, start: at(3), end: at(4).addingTimeInterval(-Double(index % 3) * 600)),
            SleepStageInterval(stage: .awake, start: at(4), end: awakeEnd),
            SleepStageInterval(stage: .core, start: awakeEnd, end: at(8)),
        ]
    }

    /// The steps on the day that contains `date`, varying from day to day.
    @Sendable static func steps(on date: Date) -> Int? {
        6_000 + (utc.ordinality(of: .day, in: .era, for: date) ?? 0) % 7 * 1_000
    }

    /// The estimate the rules give for what the fake data sources hold.
    static func expected(
        prior: CaffeineHalfLife = .standard, drinks: [LoggedDrink] = drinks(), withSteps: Bool = true
    ) -> HalfLifeEstimate {
        let nights = SleepNightRule().nights(from: intervals).map { sleep in
            HalfLifeEstimationRule.Night(
                sleep: sleep, steps: withSteps ? steps(on: sleep.sleepOnset.addingTimeInterval(-6 * hour)) : nil,
                restingHeartRate: 60)
        }
        let inputs = HalfLifeEstimationRule.Inputs(
            prior: prior, nights: nights, intakes: drinks.filter { !$0.isDemo }.map(\.intake), absorption: .standard)
        return HalfLifeEstimationRule().estimate(inputs, calendar: utc, now: now)
    }

    /// An estimate calculated `age` before ``now``, from `prior`.
    static func stored(age: TimeInterval, prior: CaffeineHalfLife = .standard) throws -> HalfLifeEstimate {
        HalfLifeEstimate(
            halfLife: try halfLife(hours: 6), lowerBound: try halfLife(hours: 4), upperBound: try halfLife(hours: 8),
            prior: prior, nightsUsed: 20, calculatedAt: now.addingTimeInterval(-age))
    }

    /// The fake data sources behind one repository.
    struct Sources {
        let drinkLog: FakeDrinkLogDataSource
        let sleep: FakeSleepDataSource
        let steps: FakeStepCountDataSource
        let heartRate: FakeRestingHeartRateDataSource
        let prior: FakeHalfLifeDataSource
        let estimates: FakeHalfLifeEstimateDataSource

        init(
            drinks: [LoggedDrink] = LiveHalfLifeEstimateRepositoryTests.drinks(), stored: HalfLifeEstimate? = nil,
            prior: CaffeineHalfLife = .standard, sleepError: (any Error)? = nil, stepsFail: Bool = false,
            storeError: (any Error)? = nil
        ) {
            drinkLog = FakeDrinkLogDataSource(drinks: drinks)
            sleep = FakeSleepDataSource(intervals: LiveHalfLifeEstimateRepositoryTests.intervals, readError: sleepError)
            steps = FakeStepCountDataSource { date in
                if stepsFail { throw FakeDataSourceError() }
                return LiveHalfLifeEstimateRepositoryTests.steps(on: date)
            }
            heartRate = FakeRestingHeartRateDataSource { _ in 60 }
            self.prior = FakeHalfLifeDataSource(value: prior)
            estimates = FakeHalfLifeEstimateDataSource(stored: stored, storeError: storeError)
        }

        func repository() -> LiveHalfLifeEstimateRepository {
            LiveHalfLifeEstimateRepository(
                drinkLog: drinkLog, sleep: sleep, steps: steps, restingHeartRate: heartRate, prior: prior,
                estimates: estimates, absorption: FakeAbsorptionRateDataSource(value: .standard),
                clock: FakeClockDataSource(date: LiveHalfLifeEstimateRepositoryTests.now, minuteDates: []),
                calendar: LiveHalfLifeEstimateRepositoryTests.utc)
        }
    }

    // MARK: - ESTREPO-1: with nothing stored, it calculates, stores, and publishes the estimate

    @Test func theFixtureGivesARealEstimate() {
        #expect(Self.expected().nightsUsed == 20)
    }

    @Test func withNothingStoredItCalculatesStoresAndPublishes() async {
        let sources = Sources()

        var estimates = sources.repository().estimate().makeAsyncIterator()

        #expect(await estimates.next() == Self.expected())
        #expect(await sources.estimates.stored == Self.expected())
    }

    // MARK: - ESTREPO-2: an estimate less than a week old, from the current survey, is kept

    @Test func anEstimateLessThanAWeekOldIsPublishedWithoutReadingHealth() async throws {
        let stored = try Self.stored(age: 7 * Self.day - 1)
        let sources = Sources(stored: stored)

        var estimates = sources.repository().estimate().makeAsyncIterator()

        #expect(await estimates.next() == stored)
        #expect(await sources.sleep.requestedRanges.isEmpty)
        #expect(await sources.estimates.storeCount == 0)
    }

    // MARK: - ESTREPO-3: an estimate a week old or more is recalculated

    @Test func aWeekOldEstimateIsRecalculated() async throws {
        let sources = Sources(stored: try Self.stored(age: 7 * Self.day))

        await sources.repository().refresh()

        #expect(await sources.estimates.stored == Self.expected())
    }

    // MARK: - ESTREPO-4: an estimate from an older survey is recalculated at once

    @Test func anEstimateFromAnOlderSurveyIsRecalculated() async throws {
        let sources = Sources(stored: try Self.stored(age: Self.hour, prior: try Self.halfLife(hours: 8.25)))

        await sources.repository().refresh()

        #expect(await sources.estimates.stored == Self.expected())
    }

    @Test func aChangedSurveyRecalculatesAtOnce() async throws {
        let sources = Sources()
        let repository = sources.repository()
        let lengthened = try Self.halfLife(hours: 8.25)

        var estimates = repository.estimate().makeAsyncIterator()
        _ = await estimates.next()
        await sources.prior.change(to: lengthened)

        #expect(await estimates.next() == Self.expected(prior: lengthened))
    }

    // MARK: - ESTREPO-5: what it reads

    @Test func readsTheLastNinetyDaysOfSleep() async {
        let sources = Sources()

        await sources.repository().refresh()

        #expect(
            await sources.sleep.requestedRanges == [
                DateInterval(start: Self.now.addingTimeInterval(-90 * Self.day), end: Self.now)
            ])
    }

    @Test func readsEachNightsStepsAndHeartRateFromTheDayBefore() async {
        let sources = Sources()
        let dayBefore = SleepNightRule().nights(from: Self.intervals).map {
            $0.sleepOnset.addingTimeInterval(-6 * Self.hour)
        }

        await sources.repository().refresh()

        #expect(await sources.steps.requestedDays == dayBefore)
        #expect(await sources.heartRate.requestedDays == dayBefore)
    }

    @Test func leavesDemoDrinksOut() async {
        let sources = Sources(drinks: Self.drinks(isDemo: true))

        await sources.repository().refresh()

        let stored = await sources.estimates.stored
        #expect(stored == Self.expected(drinks: Self.drinks(isDemo: true)))
        #expect(stored?.nightsUsed == 0)
    }

    // MARK: - ESTREPO-6: what it does when a read fails

    @Test func whenSleepCantBeReadNothingIsStored() async {
        let sources = Sources(sleepError: FakeDataSourceError())

        await sources.repository().refresh()

        #expect(await sources.estimates.storeCount == 0)
    }

    @Test func whenSleepCantBeReadTheOldEstimateStays() async throws {
        let stored = try Self.stored(age: 8 * Self.day)
        let sources = Sources(stored: stored, sleepError: FakeDataSourceError())

        var estimates = sources.repository().estimate().makeAsyncIterator()

        #expect(await estimates.next() == stored)
        #expect(await sources.estimates.stored == stored)
    }

    @Test func stepsThatCantBeReadCountAsMissing() async {
        let sources = Sources(stepsFail: true)

        await sources.repository().refresh()

        #expect(await sources.estimates.stored == Self.expected(withSteps: false))
    }

    @Test func anEstimateThatCantBeStoredIsStillPublished() async {
        let sources = Sources(storeError: FakeDataSourceError())

        var estimates = sources.repository().estimate().makeAsyncIterator()

        #expect(await estimates.next() == Self.expected())
    }

    // MARK: - ESTREPO-7: refreshes that overlap calculate once

    @Test func overlappingRefreshesCalculateOnce() async {
        let sources = Sources()
        let repository = sources.repository()

        async let first: Void = repository.refresh()
        async let second: Void = repository.refresh()
        _ = await (first, second)

        #expect(await sources.sleep.requestedRanges.count == 1)
    }

    // MARK: - ESTREPO-8: every subscriber gets each new estimate

    @Test func everySubscriberGetsTheRecalculatedEstimate() async throws {
        let sources = Sources()
        let repository = sources.repository()
        let lengthened = try Self.halfLife(hours: 8.25)

        var first = repository.estimate().makeAsyncIterator()
        var second = repository.estimate().makeAsyncIterator()
        _ = await first.next()
        _ = await second.next()
        await sources.prior.change(to: lengthened)

        #expect(await first.next() == Self.expected(prior: lengthened))
        #expect(await second.next() == Self.expected(prior: lengthened))
    }
}
