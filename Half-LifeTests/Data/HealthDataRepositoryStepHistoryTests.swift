//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests HealthDataRepositoryStepHistoryTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the Health data repository's step history against STEPSREPO-1 to STEPSREPO-6 in the Insights article.
///
/// Every data source is a fake, so no test reads real Health data (constitution Article V.3.5). "Now" is 9am on June
/// 15, 2026, in New York, on a clock that moves only when a test advances it. Each test keeps its harness alive until
/// it ends, because a stream alone doesn't keep the repository alive.
struct HealthDataRepositoryStepHistoryTests {

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

    func harness(
        live: LiveHealthDataRepository.Sources = .init(FakeHealthData()),
        demo: LiveHealthDataRepository.Sources = .init(FakeHealthData()),
        access: HealthAccessStatus = .requested,
        flag: FakeDemoHealthDataFlagDataSource = .init()
    ) -> Harness {
        let authorization = FakeHealthAuthorizationDataSource(status: access)
        let clock = SteppedClockDataSource(now: at(9))
        let repository = LiveHealthDataRepository(
            live: live, demo: demo, authorization: authorization, flag: flag, clock: clock)
        return Harness(repository: repository, authorization: authorization, clock: clock)
    }

    /// The 30 days before the day `now` falls in, oldest first, each with the steps `steps` gives its midnight.
    func expected(at now: Date? = nil, isDemo: Bool = false, _ steps: (Date) -> Int?) -> StepHistory {
        let today = calendar.startOfDay(for: now ?? at(9))
        let days = (1...30).reversed().compactMap {
            calendar.date(byAdding: .day, value: -$0, to: today)
        }
        return StepHistory(days: days.map { DailySteps(day: $0, steps: steps($0)) }, isDemo: isDemo)
    }

    // MARK: - STEPSREPO-1: a new subscriber gets the steps of the 30 days before today, from Apple Health

    @Test func aNewSubscriberGetsTheStepsOfTheDaysBeforeToday() async {
        let calendar = calendar
        // Each day's steps are 100 times its day of the month, and June 1 has none.
        let perDay: @Sendable (Date) -> Int? = { day in
            let dayOfMonth = calendar.component(.day, from: day)
            return calendar.component(.month, from: day) == 6 && dayOfMonth == 1 ? nil : dayOfMonth * 100
        }
        let live = LiveHealthDataRepository.Sources(
            sleep: FakeHealthData(), steps: FakeStepCountDataSource(steps: perDay),
            restingHeartRate: FakeHealthData())
        let harness = harness(live: live)
        let histories = Collected(harness.repository.stepHistory(days: 30, in: calendar))

        let received = await histories.waitForCount(1)

        #expect(received == [expected(perDay)])
        #expect(
            received.first?.days.first?.day == calendar.date(byAdding: .day, value: -30, to: june15))
        #expect(received.first?.days.last?.day == calendar.date(byAdding: .day, value: -1, to: june15))
        withExtendedLifetime(harness) {}
    }

    // MARK: - STEPSREPO-2: with the demo switch on, the steps are the demo's, marked as demo

    @Test func withTheSwitchOnTheStepsAreTheDemos() async {
        let harness = harness(
            live: .init(FakeHealthData(steps: 8_000)), demo: .init(FakeHealthData(steps: 5_000)),
            flag: FakeDemoHealthDataFlagDataSource(isOn: true))
        let histories = Collected(harness.repository.stepHistory(days: 30, in: calendar))

        let received = await histories.waitForCount(1)

        #expect(received == [expected(isDemo: true) { _ in 5_000 }])
        withExtendedLifetime(harness) {}
    }

    // MARK: - STEPSREPO-3: while Health access hasn't been requested, every day is empty, until it is

    @Test func untilAccessIsRequestedEveryDayIsEmpty() async throws {
        let harness = harness(live: .init(FakeHealthData(steps: 8_000)), access: .notRequested)
        let histories = Collected(harness.repository.stepHistory(days: 30, in: calendar))

        let beforeAccess = await histories.settled()
        #expect(beforeAccess == [expected { _ in nil }])

        try await harness.authorization.requestAccess()
        harness.clock.advance(to: at(9 + 1 / 60))
        let afterAccess = await histories.waitForCount(2)

        #expect(afterAccess.last == expected(at: at(9 + 1 / 60)) { _ in 8_000 })
        withExtendedLifetime(harness) {}
    }

    // MARK: - STEPSREPO-4: a change a data source signals sends the new steps, only when they change

    @Test func aStepsChangeSendsTheNewStepsOnlyWhenTheyChange() async {
        let live = FakeHealthData(steps: 8_000)
        let harness = harness(live: .init(live))
        let histories = Collected(harness.repository.stepHistory(days: 30, in: calendar))
        _ = await histories.waitForCount(1)

        await live.signalChange()
        let afterNoChange = await histories.settled()
        #expect(afterNoChange.count == 1)

        await live.hold(steps: 9_000)
        await live.signalChange()
        let received = await histories.waitForCount(2)

        #expect(received == [expected { _ in 8_000 }, expected { _ in 9_000 }])
        withExtendedLifetime(harness) {}
    }

    // MARK: - STEPSREPO-5: the history moves on at the first minute of a new day, and other minutes send nothing

    @Test func theHistoryMovesOnAtANewDay() async {
        let calendar = calendar
        let perDay: @Sendable (Date) -> Int? = { calendar.component(.day, from: $0) * 100 }
        let live = LiveHealthDataRepository.Sources(
            sleep: FakeHealthData(), steps: FakeStepCountDataSource(steps: perDay),
            restingHeartRate: FakeHealthData())
        let harness = harness(live: live)
        let histories = Collected(harness.repository.stepHistory(days: 30, in: calendar))
        _ = await histories.waitForCount(1)

        harness.clock.advance(to: at(10))
        let afterAnotherMinute = await histories.settled()
        #expect(afterAnotherMinute.count == 1)

        harness.clock.advance(to: at(24.01))
        let afterMidnight = await histories.waitForCount(2)

        #expect(afterMidnight.last == expected(at: at(24.01), perDay))
        withExtendedLifetime(harness) {}
    }

    // MARK: - STEPSREPO-6: steps that can't be read give empty days

    @Test func stepsThatCantBeReadGiveEmptyDays() async {
        let live = FakeHealthData(steps: 8_000)
        await live.fail(steps: ReadFailure())
        let harness = harness(live: .init(live))
        let histories = Collected(harness.repository.stepHistory(days: 30, in: calendar))

        let received = await histories.waitForCount(1)

        #expect(received == [expected { _ in nil }])
        withExtendedLifetime(harness) {}
    }
}
