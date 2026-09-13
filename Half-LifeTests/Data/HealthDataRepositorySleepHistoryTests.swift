//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests HealthDataRepositorySleepHistoryTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the Health data repository's sleep history against SHREPO-1 to SHREPO-6 in the Insights article.
///
/// Every data source is a fake, so no test reads real Health data (constitution Article V.3.5). "Now" is 9am on June
/// 15, 2026, in New York, on a clock that moves only when a test advances it. Each test keeps its harness alive until
/// it ends, because a stream alone doesn't keep the repository alive.
struct HealthDataRepositorySleepHistoryTests {

    /// The repository and the fakes behind it.
    struct Harness {
        let repository: LiveHealthDataRepository
        let authorization: FakeHealthAuthorizationDataSource
        let clock: SteppedClockDataSource
    }

    struct ReadFailure: Error {}

    let rule = SleepHistoryRule()
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

    /// Core sleep from 11pm to 6am, ending this morning, and from 11:30pm to 6:30am the night before.
    var twoNights: [SleepStageInterval] {
        [
            SleepStageInterval(stage: .core, start: at(-1), end: at(6)),
            SleepStageInterval(stage: .core, start: at(-24.5), end: at(-17.5)),
        ]
    }

    func harness(
        live: FakeHealthData = FakeHealthData(), demo: FakeHealthData = FakeHealthData(),
        access: HealthAccessStatus = .requested, flag: FakeDemoHealthDataFlagDataSource = .init()
    ) -> Harness {
        let authorization = FakeHealthAuthorizationDataSource(status: access)
        let clock = SteppedClockDataSource(now: at(9))
        let repository = LiveHealthDataRepository(
            live: LiveHealthDataRepository.Sources(live), demo: LiveHealthDataRepository.Sources(demo),
            authorization: authorization, flag: flag, clock: clock)
        return Harness(repository: repository, authorization: authorization, clock: clock)
    }

    func expected(_ intervals: [SleepStageInterval], at now: Date? = nil, isDemo: Bool = false) -> SleepHistory {
        SleepHistory(
            nights: rule.nights(from: intervals, endingAt: now ?? at(9), days: 7, calendar: calendar), isDemo: isDemo)
    }

    // MARK: - SHREPO-1: a new subscriber gets the history at once, from Apple Health

    @Test func aNewSubscriberGetsTheHistory() async {
        let harness = harness(live: FakeHealthData(intervals: twoNights))
        let histories = Collected(harness.repository.sleepHistory(days: 7, in: calendar))

        let received = await histories.waitForCount(1)

        #expect(received == [expected(twoNights)])
        #expect(received.first?.hasSleep == true)
        withExtendedLifetime(harness) {}
    }

    // MARK: - SHREPO-2: with the demo switch on, the history comes from the demo, marked as demo

    @Test func withTheSwitchOnTheHistoryIsTheDemos() async {
        let demoNight = [SleepStageInterval(stage: .deep, start: at(-2), end: at(5))]
        let harness = harness(
            live: FakeHealthData(intervals: twoNights), demo: FakeHealthData(intervals: demoNight),
            flag: FakeDemoHealthDataFlagDataSource(isOn: true))
        let histories = Collected(harness.repository.sleepHistory(days: 7, in: calendar))

        let received = await histories.waitForCount(1)

        #expect(received == [expected(demoNight, isDemo: true)])
        withExtendedLifetime(harness) {}
    }

    // MARK: - SHREPO-3: while Health access hasn't been requested, every night is empty, until it is

    @Test func untilAccessIsRequestedEveryNightIsEmpty() async throws {
        let harness = harness(live: FakeHealthData(intervals: twoNights), access: .notRequested)
        let histories = Collected(harness.repository.sleepHistory(days: 7, in: calendar))

        let beforeAccess = await histories.settled()
        #expect(beforeAccess == [expected([])])

        try await harness.authorization.requestAccess()
        harness.clock.advance(to: at(9 + 1 / 60))
        let afterAccess = await histories.waitForCount(2)

        #expect(afterAccess.last == expected(twoNights, at: at(9 + 1 / 60)))
        withExtendedLifetime(harness) {}
    }

    // MARK: - SHREPO-4: a change the sleep data source signals sends the new history

    @Test func aSleepChangeSendsTheNewHistory() async {
        let live = FakeHealthData(intervals: [twoNights[0]])
        let harness = harness(live: live)
        let histories = Collected(harness.repository.sleepHistory(days: 7, in: calendar))
        _ = await histories.waitForCount(1)

        await live.hold(intervals: twoNights)
        await live.signalChange()
        let received = await histories.waitForCount(2)

        #expect(received == [expected([twoNights[0]]), expected(twoNights)])
        withExtendedLifetime(harness) {}
    }

    // MARK: - SHREPO-5: the history moves on at the first minute of a new day, and other minutes send nothing

    @Test func theHistoryMovesOnAtANewDay() async {
        let harness = harness(live: FakeHealthData(intervals: twoNights))
        let histories = Collected(harness.repository.sleepHistory(days: 7, in: calendar))
        _ = await histories.waitForCount(1)

        harness.clock.advance(to: at(10))
        let afterAnotherMinute = await histories.settled()
        #expect(afterAnotherMinute.count == 1)

        harness.clock.advance(to: at(24.01))
        let afterMidnight = await histories.waitForCount(2)

        #expect(afterMidnight.last == expected(twoNights, at: at(24.01)))
        withExtendedLifetime(harness) {}
    }

    // MARK: - SHREPO-6: sleep that can't be read gives empty nights

    @Test func sleepThatCantBeReadGivesEmptyNights() async {
        let live = FakeHealthData(intervals: twoNights)
        await live.fail(sleep: ReadFailure())
        let harness = harness(live: live)
        let histories = Collected(harness.repository.sleepHistory(days: 7, in: calendar))

        let received = await histories.waitForCount(1)

        #expect(received == [expected([])])
        withExtendedLifetime(harness) {}
    }
}
