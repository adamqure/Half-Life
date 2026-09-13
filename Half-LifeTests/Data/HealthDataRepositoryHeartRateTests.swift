//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests HealthDataRepositoryHeartRateTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the Health data repository's resting heart rate history against RHRREPO-1 to RHRREPO-6 in the Insights
/// article.
///
/// Every data source is a fake, so no test reads real Health data (constitution Article V.3.5). "Now" is 9am on June
/// 15, 2026, in New York, on a clock that moves only when a test advances it, and each test follows the last 3 days.
/// Each test keeps its harness alive until it ends, because a stream alone doesn't keep the repository alive.
struct HealthDataRepositoryHeartRateTests {

    /// The repository and the fakes behind it.
    struct Harness {
        let repository: LiveHealthDataRepository
        let authorization: FakeHealthAuthorizationDataSource
        let clock: SteppedClockDataSource
    }

    struct ReadFailure: Error {}

    let calendar: Calendar
    /// Midnight at the start of June 15, 2026, in New York.
    let june15: Date

    init() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/New_York"))
        self.calendar = calendar
        june15 = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 15)))
    }

    /// `hours` after midnight on June 15.
    func at(_ hours: Double) -> Date {
        june15.addingTimeInterval(hours * 3_600)
    }

    /// Midnight at the start of the day `offset` days from June 15. No daylight saving change falls near it.
    func day(_ offset: Int) -> Date {
        at(Double(offset) * 24)
    }

    func harness(
        live: LiveHealthDataRepository.Sources, demo: FakeHealthData = FakeHealthData(),
        access: HealthAccessStatus = .requested, flag: FakeDemoHealthDataFlagDataSource = .init()
    ) -> Harness {
        let authorization = FakeHealthAuthorizationDataSource(status: access)
        let clock = SteppedClockDataSource(now: at(9))
        let repository = LiveHealthDataRepository(
            live: live, demo: LiveHealthDataRepository.Sources(demo), authorization: authorization, flag: flag,
            clock: clock)
        return Harness(repository: repository, authorization: authorization, clock: clock)
    }

    /// The history of `values`, one per day, oldest first, ending with the day `last` days from June 15.
    func expected(_ values: [Double?], endingOn last: Int = 0, isDemo: Bool = false) -> RestingHeartRateHistory {
        let first = last - values.count + 1
        return RestingHeartRateHistory(
            days: values.enumerated().map { RestingHeartRateDay(day: day(first + $0), beatsPerMinute: $1) },
            isDemo: isDemo)
    }

    // MARK: - RHRREPO-1: a new subscriber gets each day's reading at once, oldest first, from Apple Health

    @Test func aNewSubscriberGetsEachDaysReadingOldestFirst() async {
        let calendar = calendar
        let (june13, june14) = (day(-2), day(-1))
        let heartRate = FakeRestingHeartRateDataSource { date in
            if calendar.isDate(date, inSameDayAs: june13) { return 57 }
            if calendar.isDate(date, inSameDayAs: june14) { return nil }
            return 60
        }
        let harness = harness(
            live: LiveHealthDataRepository.Sources(
                sleep: FakeHealthData(), steps: FakeHealthData(), restingHeartRate: heartRate))
        let histories = Collected(harness.repository.restingHeartRates(days: 3, in: calendar))

        let received = await histories.waitForCount(1)

        #expect(received == [expected([57, nil, 60])])
        withExtendedLifetime(harness) {}
    }

    // MARK: - RHRREPO-2: with the demo switch on, the readings are the demo's, marked as demo

    @Test func withTheSwitchOnTheReadingsAreTheDemos() async {
        let harness = harness(
            live: LiveHealthDataRepository.Sources(FakeHealthData(restingHeartRate: 60)),
            demo: FakeHealthData(restingHeartRate: 55), flag: FakeDemoHealthDataFlagDataSource(isOn: true))
        let histories = Collected(harness.repository.restingHeartRates(days: 3, in: calendar))

        let received = await histories.waitForCount(1)

        #expect(received == [expected([55, 55, 55], isDemo: true)])
        withExtendedLifetime(harness) {}
    }

    // MARK: - RHRREPO-3: until Health access is requested, every day is empty, then the readings are sent

    @Test func untilAccessIsRequestedEveryDayIsEmpty() async throws {
        let harness = harness(
            live: LiveHealthDataRepository.Sources(FakeHealthData(restingHeartRate: 60)), access: .notRequested)
        let histories = Collected(harness.repository.restingHeartRates(days: 3, in: calendar))

        let beforeAccess = await histories.settled()
        #expect(beforeAccess == [expected([nil, nil, nil])])

        try await harness.authorization.requestAccess()
        harness.clock.advance(to: at(9 + 1 / 60))
        let afterAccess = await histories.waitForCount(2)

        #expect(afterAccess.last == expected([60, 60, 60]))
        withExtendedLifetime(harness) {}
    }

    // MARK: - RHRREPO-4: a change a data source signals sends the new readings, only when they change

    @Test func aChangeSendsTheNewReadingsOnlyWhenTheyChange() async {
        let live = FakeHealthData(restingHeartRate: 58)
        let harness = harness(live: LiveHealthDataRepository.Sources(live))
        let histories = Collected(harness.repository.restingHeartRates(days: 3, in: calendar))
        _ = await histories.waitForCount(1)

        await live.signalChange()
        let afterNoChange = await histories.settled()
        #expect(afterNoChange.count == 1)

        await live.hold(restingHeartRate: 61)
        await live.signalChange()
        let received = await histories.waitForCount(2)

        #expect(received == [expected([58, 58, 58]), expected([61, 61, 61])])
        withExtendedLifetime(harness) {}
    }

    // MARK: - RHRREPO-5: the readings move on at the first minute of a new day, and other minutes send nothing

    @Test func theReadingsMoveOnAtANewDay() async {
        let harness = harness(live: LiveHealthDataRepository.Sources(FakeHealthData(restingHeartRate: 58)))
        let histories = Collected(harness.repository.restingHeartRates(days: 3, in: calendar))
        _ = await histories.waitForCount(1)

        harness.clock.advance(to: at(10))
        let afterAnotherMinute = await histories.settled()
        #expect(afterAnotherMinute.count == 1)

        harness.clock.advance(to: at(24.01))
        let afterMidnight = await histories.waitForCount(2)

        #expect(afterMidnight.last == expected([58, 58, 58], endingOn: 1))
        withExtendedLifetime(harness) {}
    }

    // MARK: - RHRREPO-6: a reading that can't be read is missing

    @Test func aReadingThatCantBeReadIsMissing() async {
        let live = FakeHealthData(restingHeartRate: 58)
        await live.fail(restingHeartRate: ReadFailure())
        let harness = harness(live: LiveHealthDataRepository.Sources(live))
        let histories = Collected(harness.repository.restingHeartRates(days: 3, in: calendar))

        let received = await histories.waitForCount(1)

        #expect(received == [expected([nil, nil, nil])])
        withExtendedLifetime(harness) {}
    }
}
