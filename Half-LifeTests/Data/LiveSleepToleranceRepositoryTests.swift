//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests LiveSleepToleranceRepositoryTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the live sleep tolerance repository against fake data sources (TOLREPO-1 to TOLREPO-7 in the Insights
/// article).
@Suite(.timeLimit(.minutes(1)))
struct LiveSleepToleranceRepositoryTests {

    static let hour: TimeInterval = 3_600
    static let day: TimeInterval = 24 * hour

    static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()

    /// Midnight at the start of day 0, in UTC.
    static let start = Date(timeIntervalSinceReferenceDate: 0)
    /// Noon on day 40.
    static let now = date(day: 40, hour: 12)

    static func date(day: Int, hour: Double) -> Date {
        start.addingTimeInterval(Double(day) * Self.day + hour * Self.hour)
    }

    /// Two espressos at 8am every day, and on every even day two more at 5pm, marked demo when `lateAreDemo`.
    static func drinks(lateAreDemo: Bool = false) -> [LoggedDrink] {
        (0...40).flatMap { day -> [LoggedDrink] in
            let morning = LoggedDrink(
                type: .espresso, quantity: 2, milligrams: 128, consumedAt: date(day: day, hour: 8), isDemo: false)
            guard day.isMultiple(of: 2) else { return [morning] }
            let late = LoggedDrink(
                type: .espresso, quantity: 2, milligrams: 128, consumedAt: date(day: day, hour: 17),
                isDemo: lateAreDemo)
            return [morning, late]
        }
    }

    /// A night from 11pm on each of days 11 to 39: 6 hours asleep after an even day, and 8 after an odd one.
    static let intervals: [SleepStageInterval] = (11...39).map { day in
        SleepStageInterval(
            stage: .core, start: date(day: day, hour: 23),
            end: date(day: day, hour: 23 + (day.isMultiple(of: 2) ? 6 : 8)))
    }

    /// The demo's nights: 7 hours from 11pm on each of days 11 to 39, with time in bed from 10:30pm.
    static let demoIntervals: [SleepStageInterval] = (11...39).flatMap { day in
        [
            SleepStageInterval(stage: .inBed, start: date(day: day, hour: 22.5), end: date(day: day, hour: 30.2)),
            SleepStageInterval(stage: .core, start: date(day: day, hour: 23), end: date(day: day, hour: 30)),
        ]
    }

    /// The analysis the rule gives for what the fake data sources hold.
    static func expected(
        intervals: [SleepStageInterval] = intervals, drinks: [LoggedDrink] = drinks(), isDemo: Bool = false,
        halfLife: CaffeineHalfLife = .standard, now: Date = now
    ) -> SleepCaffeineAnalysis? {
        let inputs = SleepToleranceRule.Inputs(
            intervals: intervals, intakes: drinks.filter { isDemo || !$0.isDemo }.map(\.intake),
            kinetics: CaffeineKinetics(halfLife: halfLife, absorption: .standard), isDemo: isDemo)
        return SleepToleranceRule().analysis(inputs, now: now, calendar: utc)
    }

    /// The fake data sources behind one repository.
    struct Sources {
        let health: FakeSleepDataSource
        let demo: FakeSleepDataSource
        let authorization: FakeHealthAuthorizationDataSource
        let flag: FakeDemoHealthDataFlagDataSource
        let drinkLog: FakeDrinkLogDataSource
        let halfLife: FakeHalfLifeDataSource
        let tolerances: FakeSleepToleranceDataSource
        let bedtime = FakeBedtimeDataSource(value: .standard)
        let clock = SteppedClockDataSource(now: LiveSleepToleranceRepositoryTests.now)

        init(
            drinks: [LoggedDrink] = LiveSleepToleranceRepositoryTests.drinks(), access: HealthAccessStatus = .requested,
            demoOn: Bool = false, sleepError: (any Error)? = nil, stored: SleepTolerance? = nil,
            healthIntervals: [SleepStageInterval] = LiveSleepToleranceRepositoryTests.intervals
        ) {
            health = FakeSleepDataSource(intervals: healthIntervals, readError: sleepError)
            demo = FakeSleepDataSource(intervals: LiveSleepToleranceRepositoryTests.demoIntervals)
            authorization = FakeHealthAuthorizationDataSource(status: access)
            flag = FakeDemoHealthDataFlagDataSource(isOn: demoOn)
            drinkLog = FakeDrinkLogDataSource(drinks: drinks)
            halfLife = FakeHalfLifeDataSource(value: .standard)
            tolerances = FakeSleepToleranceDataSource(stored: stored)
        }

        func repository() -> LiveSleepToleranceRepository {
            LiveSleepToleranceRepository(
                health: health, demo: demo, authorization: authorization, flag: flag, drinkLog: drinkLog,
                halfLife: halfLife, absorption: FakeAbsorptionRateDataSource(value: .standard), bedtime: bedtime,
                tolerances: tolerances, clock: clock, calendar: LiveSleepToleranceRepositoryTests.utc)
        }
    }

    @Test func theFixtureHasAToleranceAndItsDemoDrinksDont() throws {
        #expect(try #require(Self.expected()).tolerance != nil)
        #expect(try #require(Self.expected(drinks: Self.drinks(lateAreDemo: true))).tolerance == nil)
    }

    // MARK: - TOLREPO-1: a new subscriber gets the analysis of Apple Health's sleep, with the user's own drinks

    @Test func aNewSubscriberGetsTheAnalysisOfHealthsSleep() async {
        let sources = Sources()
        let repository = sources.repository()
        let values = Collected(repository.analysis())

        #expect(await values.waitForCount(1).first == Self.expected())
    }

    @Test func withTheSwitchOffDemoDrinksDontCount() async {
        let drinks = Self.drinks(lateAreDemo: true)
        let sources = Sources(drinks: drinks)
        let repository = sources.repository()
        let values = Collected(repository.analysis())

        #expect(await values.waitForCount(1).first == Self.expected(drinks: drinks))
    }

    // MARK: - TOLREPO-2: with the demo switch on, the sleep is the demo's, and every drink counts

    @Test func withTheSwitchOnTheSleepIsTheDemosAndEveryDrinkCounts() async throws {
        let drinks = Self.drinks(lateAreDemo: true)
        let sources = Sources(drinks: drinks, demoOn: true)
        let repository = sources.repository()
        let values = Collected(repository.analysis())

        let first = try #require(await values.waitForCount(1).first)

        #expect(first == Self.expected(intervals: Self.demoIntervals, drinks: drinks, isDemo: true))
        #expect(first.isDemo)
    }

    @Test func turningTheSwitchOnSendsTheDemosAnalysis() async throws {
        let sources = Sources()
        let repository = sources.repository()
        let values = Collected(repository.analysis())
        _ = await values.waitForCount(1)

        try await sources.flag.setUsesDemoData(true)

        #expect(await values.waitForCount(2).last == Self.expected(intervals: Self.demoIntervals, isDemo: true))
    }

    // MARK: - TOLREPO-3: until Health access is requested, there are no nights

    @Test func untilHealthAccessIsRequestedThereAreNoNightsThenTheyreSent() async throws {
        let sources = Sources(access: .notRequested)
        let repository = sources.repository()
        let values = Collected(repository.analysis())

        let first = try #require(await values.waitForCount(1).first)
        #expect(first.nights.isEmpty)
        #expect(await sources.health.requestedRanges.isEmpty)

        try await sources.authorization.requestAccess()
        sources.clock.advance(to: Self.now + 60)

        #expect(await values.waitForCount(2).last == Self.expected())
    }

    // MARK: - TOLREPO-4: a change the data sources signal sends the new analysis, only when it changed

    @Test func aDrinkLogChangeSendsTheNewAnalysis() async throws {
        let sources = Sources(drinks: Self.drinks(lateAreDemo: true))
        let repository = sources.repository()
        let values = Collected(repository.analysis())
        _ = await values.waitForCount(1)
        let late = LoggedDrink(
            type: .espresso, quantity: 2, milligrams: 128, consumedAt: Self.date(day: 30, hour: 20), isDemo: false)

        await sources.drinkLog.insert(late)
        await sources.drinkLog.signalChange()

        let received = await values.waitForCount(2)
        #expect(received.count == 2)
        #expect(received.last == Self.expected(drinks: Self.drinks(lateAreDemo: true) + [late]))
    }

    @Test func aChangeThatLeavesTheAnalysisAloneSendsNothing() async {
        let sources = Sources()
        let repository = sources.repository()
        let values = Collected(repository.analysis())
        _ = await values.waitForCount(1)

        await sources.drinkLog.signalChange()

        #expect(await values.settled().count == 1)
    }

    @Test func aHalfLifeChangeSendsTheNewAnalysis() async throws {
        let eightHours = try #require(CaffeineHalfLife(seconds: 8 * Self.hour))
        let sources = Sources()
        let repository = sources.repository()
        let values = Collected(repository.analysis())
        _ = await values.waitForCount(1)

        await sources.halfLife.change(to: eightHours)

        #expect(await values.waitForCount(2).last == Self.expected(halfLife: eightHours))
    }

    // MARK: - TOLREPO-5: the tolerance is stored whenever it differs from the stored one, none included

    @Test func theToleranceIsStoredBeforeItsSent() async throws {
        let expected = try #require(Self.expected()?.tolerance)
        let sources = Sources()
        let repository = sources.repository()
        let values = Collected(repository.analysis())
        _ = await values.waitForCount(1)

        #expect(await sources.tolerances.stored == expected)
        #expect(await sources.tolerances.storeCount == 1)
    }

    @Test func anUnchangedToleranceIsntStoredAgain() async throws {
        let sources = Sources(stored: try #require(Self.expected()?.tolerance))
        let repository = sources.repository()
        let values = Collected(repository.analysis())
        _ = await values.waitForCount(1)

        #expect(await sources.tolerances.storeCount == 0)
    }

    @Test func withNoToleranceNoneIsStored() async {
        let sources = Sources(
            drinks: Self.drinks(lateAreDemo: true),
            stored: SleepTolerance(milligrams: 60, nightsUnder: 10, nightsOver: 10))
        let repository = sources.repository()
        let values = Collected(repository.analysis())
        _ = await values.waitForCount(1)

        #expect(await sources.tolerances.stored == nil)
        #expect(await sources.tolerances.storeCount == 1)
    }

    // MARK: - TOLREPO-6: when an input can't be read, nothing is sent or stored

    @Test func aSleepReadThatFailsSendsAndStoresNothing() async {
        let sources = Sources(sleepError: FakeDataSourceError())
        let repository = sources.repository()
        let values = Collected(repository.analysis())

        #expect(await values.settled().isEmpty)
        #expect(await sources.tolerances.storeCount == 0)
    }

    // MARK: - TOLREPO-7: a new day's first minute sends the new period's analysis, and other minutes read nothing

    @Test func theFirstMinuteOfANewDaySendsTheNewPeriod() async throws {
        let sources = Sources()
        let repository = sources.repository()
        let values = Collected(repository.analysis())
        _ = await values.waitForCount(1)
        let reads = await sources.health.requestedRanges.count

        sources.clock.advance(to: Self.now + 60)
        #expect(await values.settled().count == 1)
        #expect(await sources.health.requestedRanges.count == reads)

        sources.clock.advance(to: Self.date(day: 41, hour: 0))
        #expect(await values.waitForCount(2).last?.period.start == Self.date(day: 12, hour: 0))
    }
}
