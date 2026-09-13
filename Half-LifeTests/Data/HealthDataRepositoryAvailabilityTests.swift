//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests HealthDataRepositoryAvailabilityTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the Health data repository's available kinds against AVREPO-1 to AVREPO-4 in the Insights article.
///
/// Every data source is a fake, so no test reads real Health data (constitution Article V.3.5). "Now" is 9am on June
/// 15, 2026, in New York, on a clock that moves only when a test advances it. Each test keeps its harness alive until
/// it ends, because a stream alone doesn't keep the repository alive.
struct HealthDataRepositoryAvailabilityTests {

    /// The repository and the fakes behind it.
    struct Harness {
        let repository: LiveHealthDataRepository
        let authorization: FakeHealthAuthorizationDataSource
        let clock: SteppedClockDataSource
    }

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

    /// Core sleep from 11pm to 6am, ending this morning.
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

    // MARK: - AVREPO-1: a new subscriber gets the kinds Apple Health has data for

    @Test func aNewSubscriberGetsTheKindsHealthHasDataFor() async {
        let harness = harness(live: FakeHealthData(intervals: lastNightsSleep, steps: 8_420, restingHeartRate: 58))
        let kinds = Collected(harness.repository.availableKinds(days: 30, in: calendar))

        #expect(await kinds.waitForCount(1) == [[.sleep, .steps, .restingHeartRate]])
        withExtendedLifetime(harness) {}
    }

    @Test func onlyTheKindsWithDataAreAvailable() async {
        let inBedOnly = [SleepStageInterval(stage: .inBed, start: at(-1), end: at(6))]
        let harness = harness(live: FakeHealthData(intervals: inBedOnly, steps: 0))
        let kinds = Collected(harness.repository.availableKinds(days: 30, in: calendar))

        #expect(await kinds.waitForCount(1) == [[.steps]])
        withExtendedLifetime(harness) {}
    }

    // MARK: - AVREPO-2: with the demo switch on, the kinds are the demo's

    @Test func withTheSwitchOnTheKindsAreTheDemos() async {
        let harness = harness(
            live: FakeHealthData(steps: 8_420), demo: FakeHealthData(intervals: lastNightsSleep),
            flag: FakeDemoHealthDataFlagDataSource(isOn: true))
        let kinds = Collected(harness.repository.availableKinds(days: 30, in: calendar))

        #expect(await kinds.waitForCount(1) == [[.sleep]])
        withExtendedLifetime(harness) {}
    }

    // MARK: - AVREPO-3: until Health access is requested, no kind is available

    @Test func untilAccessIsRequestedNoKindIsAvailable() async throws {
        let harness = harness(live: FakeHealthData(steps: 8_420), access: .notRequested)
        let kinds = Collected(harness.repository.availableKinds(days: 30, in: calendar))

        #expect(await kinds.settled() == [[]])

        try await harness.authorization.requestAccess()
        harness.clock.advance(to: at(9 + 1 / 60))

        #expect(await kinds.waitForCount(2) == [[], [.steps]])
        withExtendedLifetime(harness) {}
    }

    // MARK: - AVREPO-4: a change a data source signals sends the new kinds, only when they change

    @Test func aChangeSendsTheNewKinds() async {
        let live = FakeHealthData(steps: 8_420)
        let harness = harness(live: live)
        let kinds = Collected(harness.repository.availableKinds(days: 30, in: calendar))
        _ = await kinds.waitForCount(1)

        await live.signalChange()
        await live.hold(restingHeartRate: 58)
        await live.signalChange()

        #expect(await kinds.waitForCount(2) == [[.steps], [.steps, .restingHeartRate]])
        withExtendedLifetime(harness) {}
    }
}
