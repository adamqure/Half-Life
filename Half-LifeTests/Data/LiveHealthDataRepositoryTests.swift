//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests LiveHealthDataRepositoryTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the Health data repository against HREPO-1 to HREPO-8 in the Apple Health Card article.
///
/// Every data source is a fake, so no test reads real Health data (constitution Article V.3.5). "Now" is 9am on
/// June 15, 2026, in New York, on a clock that moves only when a test advances it.
struct LiveHealthDataRepositoryTests {

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

    /// Core sleep from 11pm to 6am, ending this morning: 7 hours.
    var lastNightsSleep: [SleepStageInterval] {
        [SleepStageInterval(stage: .core, start: at(-1), end: at(6))]
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

    // MARK: - HREPO-1: a new subscriber gets today's summary at once

    @Test func aNewSubscriberGetsTodaysSummary() async {
        let live = FakeHealthData(intervals: lastNightsSleep, steps: 8_420, restingHeartRate: 58)
        let summaries = Collected(harness(live: live).repository.summary(in: calendar))

        let received = await summaries.waitForCount(1)

        #expect(
            received == [
                HealthSummary(lastNight: .asleep(seconds: 7 * 3_600), stepsToday: 8_420, restingHeartRateToday: 58)
            ])
        summaries.cancel()
    }

    // MARK: - HREPO-2: any combination of metrics gives exactly those metrics

    @Test(arguments: 0..<8)
    func eachCombinationOfMetricsGivesExactlyThoseMetrics(_ combination: Int) async {
        let hasSleep = combination & 1 != 0
        let hasSteps = combination & 2 != 0
        let hasHeartRate = combination & 4 != 0
        let live = FakeHealthData(
            intervals: hasSleep ? lastNightsSleep : [], steps: hasSteps ? 8_420 : nil,
            restingHeartRate: hasHeartRate ? 58 : nil)
        let summaries = Collected(harness(live: live).repository.summary(in: calendar))

        let received = await summaries.waitForCount(1)

        #expect(
            received == [
                HealthSummary(
                    lastNight: hasSleep ? .asleep(seconds: 7 * 3_600) : nil, stepsToday: hasSteps ? 8_420 : nil,
                    restingHeartRateToday: hasHeartRate ? 58 : nil)
            ])
        summaries.cancel()
    }

    // MARK: - HREPO-3: a metric that can't be read is missing, and the others still show

    @Test func aMetricThatCantBeReadIsMissingAndTheOthersStillShow() async {
        let live = FakeHealthData(intervals: lastNightsSleep, steps: 8_420, restingHeartRate: 58)
        await live.fail(steps: ReadFailure())
        let summaries = Collected(harness(live: live).repository.summary(in: calendar))

        let received = await summaries.waitForCount(1)

        #expect(received == [HealthSummary(lastNight: .asleep(seconds: 7 * 3_600), restingHeartRateToday: 58)])
        summaries.cancel()
    }

    // MARK: - HREPO-4: nothing is read until Health access is requested

    @Test func nothingIsReadUntilHealthAccessIsRequested() async throws {
        let live = FakeHealthData(steps: 8_420)
        let harness = harness(live: live, access: .notRequested)
        let summaries = Collected(harness.repository.summary(in: calendar))

        let beforeAccess = await summaries.settled()
        let readsBeforeAccess = await live.readCount
        let listenersBeforeAccess = await live.listenerCount
        try await harness.authorization.requestAccess()
        harness.clock.advance(to: at(9 + 1 / 60))
        let afterAccess = await summaries.waitForCount(2)

        #expect(beforeAccess == [.empty])
        #expect(readsBeforeAccess == 0)
        #expect(listenersBeforeAccess == 0)
        #expect(afterAccess == [.empty, HealthSummary(stepsToday: 8_420)])
        summaries.cancel()
    }

    // MARK: - HREPO-5: a change signal re-reads the summary, and so does a new day

    @Test func aChangeSignalReReadsTheSummary() async {
        let live = FakeHealthData(steps: 8_420)
        // The harness keeps the repository alive, as the app does. A stream alone doesn't.
        let harness = harness(live: live)
        let summaries = Collected(harness.repository.summary(in: calendar))
        _ = await summaries.waitForCount(1)

        await live.hold(steps: 9_000)
        await live.signalChange()
        let received = await summaries.waitForCount(2)

        #expect(received == [HealthSummary(stepsToday: 8_420), HealthSummary(stepsToday: 9_000)])
        summaries.cancel()
    }

    @Test func aNewDayReReadsTheSummaryAndOtherMinutesDoNot() async {
        let live = FakeHealthData(intervals: lastNightsSleep, steps: 8_420)
        let harness = harness(live: live)
        let summaries = Collected(harness.repository.summary(in: calendar))
        _ = await summaries.waitForCount(1)
        let readsAtFirst = await live.readCount

        harness.clock.advance(to: at(10))
        let afterAnotherMinute = await summaries.settled()
        let readsAfterAnotherMinute = await live.readCount
        harness.clock.advance(to: at(24.01))
        let afterMidnight = await summaries.waitForCount(2)

        #expect(afterAnotherMinute.count == 1)
        #expect(readsAfterAnotherMinute == readsAtFirst)
        // Just after midnight, last night is the night ending tomorrow morning, which hasn't been recorded.
        #expect(afterMidnight.last == HealthSummary(stepsToday: 8_420))
        summaries.cancel()
    }

    // MARK: - HREPO-6: an equal summary isn't sent again

    @Test func anEqualSummaryIsNotSentAgain() async {
        let live = FakeHealthData(steps: 8_420)
        let harness = harness(live: live)
        let summaries = Collected(harness.repository.summary(in: calendar))
        _ = await summaries.waitForCount(1)
        let readsAtFirst = await live.readCount

        await live.signalChange()
        let received = await summaries.settled()
        let readsAfterTheSignal = await live.readCount

        // The signal was followed, and the summary it read was equal, so nothing was sent.
        #expect(readsAfterTheSignal > readsAtFirst)
        #expect(received == [HealthSummary(stepsToday: 8_420)])
        summaries.cancel()
    }

    // MARK: - HREPO-7: the demo switch chooses the demo data sources, which need no Health access

    @Test func withTheSwitchOnTheSummaryIsTheDemosAndNeedsNoHealthAccess() async {
        let live = FakeHealthData(steps: 100)
        let demo = FakeHealthData(intervals: lastNightsSleep, steps: 5_000, restingHeartRate: 60)
        let harness = harness(
            live: live, demo: demo, access: .notRequested, flag: FakeDemoHealthDataFlagDataSource(isOn: true))
        let summaries = Collected(harness.repository.summary(in: calendar))

        let received = await summaries.waitForCount(1)
        let liveReads = await live.readCount

        #expect(
            received == [
                HealthSummary(
                    lastNight: .asleep(seconds: 7 * 3_600), stepsToday: 5_000, restingHeartRateToday: 60, isDemo: true)
            ])
        #expect(liveReads == 0)
        summaries.cancel()
    }

    @Test func turningTheSwitchPublishesTheOtherSetsSummary() async throws {
        let harness = harness(live: FakeHealthData(steps: 100), demo: FakeHealthData(steps: 5_000))
        let summaries = Collected(harness.repository.summary(in: calendar))
        _ = await summaries.waitForCount(1)

        try await harness.repository.setUsesDemoData(true)
        _ = await summaries.waitForCount(2)
        try await harness.repository.setUsesDemoData(false)
        let received = await summaries.waitForCount(3)

        #expect(
            received == [
                HealthSummary(stepsToday: 100), HealthSummary(stepsToday: 5_000, isDemo: true),
                HealthSummary(stepsToday: 100),
            ])
        summaries.cancel()
    }

    @Test func theDemoSourcesChangesAreFollowedWhileTheSwitchIsOn() async {
        let demo = FakeHealthData(steps: 5_000)
        let harness = harness(demo: demo, flag: FakeDemoHealthDataFlagDataSource(isOn: true))
        let summaries = Collected(harness.repository.summary(in: calendar))
        _ = await summaries.waitForCount(1)

        await demo.hold(steps: 5_100)
        await demo.signalChange()
        let received = await summaries.waitForCount(2)

        #expect(received.last == HealthSummary(stepsToday: 5_100, isDemo: true))
        summaries.cancel()
    }

    // MARK: - HREPO-8: the switch's stream, and storing it

    @Test func theSwitchStreamSendsTheCurrentAnswerThenEachChange() async throws {
        let flag = FakeDemoHealthDataFlagDataSource()
        let repository = harness(flag: flag).repository
        let answers = Collected(repository.usesDemoData())
        _ = await answers.waitForCount(1)

        try await repository.setUsesDemoData(true)
        _ = await answers.waitForCount(2)
        try await repository.setUsesDemoData(true)
        let received = await answers.settled()

        #expect(received == [false, true])
        #expect(await flag.storedValues == [true, true])
        answers.cancel()
    }

    @Test func aFailedStoreThrowsAndChangesNothing() async {
        let flag = FakeDemoHealthDataFlagDataSource(storeError: ReadFailure())
        let repository = harness(flag: flag).repository
        let answers = Collected(repository.usesDemoData())
        _ = await answers.waitForCount(1)

        await #expect(throws: ReadFailure.self) {
            try await repository.setUsesDemoData(true)
        }
        let received = await answers.settled()

        #expect(received == [false])
        answers.cancel()
    }
}
