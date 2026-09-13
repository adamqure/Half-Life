//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests CaffeineNightsRepositoryTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the live sleep tolerance repository's caffeine nights, the one stream every Insights comparison reads
/// (TOLREPO-8 to TOLREPO-11 in the Insights article), against the same fakes as its analysis.
@Suite(.timeLimit(.minutes(1)))
struct CaffeineNightsRepositoryTests {

    typealias Fixture = LiveSleepToleranceRepositoryTests

    /// The history ``CaffeineNightRule`` gives for what the fake data sources hold, judged against the analysis's
    /// threshold.
    static func expected(
        intervals: [SleepStageInterval] = Fixture.intervals, drinks: [LoggedDrink] = Fixture.drinks(),
        bedtime: Bedtime = .standard, days: Int = 31
    ) throws -> CaffeineNightHistory {
        let intakes = drinks.filter { !$0.isDemo }.map(\.intake)
        let analysis = try #require(Fixture.expected(intervals: intervals, drinks: drinks))
        let inputs = CaffeineNightRule.Inputs(
            onsets: SleepToleranceRule().onsets(from: intervals, intakes: intakes, now: Fixture.now), intakes: intakes,
            kinetics: .standard, bedtime: bedtime, threshold: analysis.threshold, isDemo: false)
        return CaffeineNightRule().history(inputs, days: days, now: Fixture.now, calendar: Fixture.utc)
    }

    // MARK: - TOLREPO-8: a new subscriber gets each night's caffeine, judged against the threshold in use

    @Test func aNewSubscriberGetsEachNightsCaffeineAgainstTheTolerance() async throws {
        let sources = Fixture.Sources()
        let repository = sources.repository()
        let histories = Collected(repository.caffeineNights(days: 31, in: Fixture.utc))

        let first = try #require(await histories.waitForCount(1).first)

        #expect(first == (try Self.expected()))
        #expect(first.threshold == Fixture.expected()?.threshold)
        #expect(first.threshold != .standard)
        #expect(first.nights.count == 31)
        #expect(first.nights.contains { $0.measuredAt == .sleepOnset })
        #expect(first.nights.contains { $0.measuredAt == .bedtime })
    }

    // MARK: - TOLREPO-9: a bedtime change sends the new nights

    @Test func aBedtimeChangeSendsTheNewNights() async throws {
        let later = try #require(Bedtime(hour: 23, minute: 30))
        let sources = Fixture.Sources()
        let repository = sources.repository()
        let histories = Collected(repository.caffeineNights(days: 31, in: Fixture.utc))
        _ = await histories.waitForCount(1)

        await sources.bedtime.change(to: later)

        #expect(await histories.waitForCount(2).last == (try Self.expected(bedtime: later)))
    }

    // MARK: - TOLREPO-10: nights before the analysis's period still get their recorded onsets

    @Test func nightsBeforeThePeriodStillGetTheirRecordedOnsets() async throws {
        let early = SleepStageInterval(
            stage: .core, start: Fixture.date(day: 5, hour: 23), end: Fixture.date(day: 6, hour: 7))
        let intervals = Fixture.intervals + [early]
        let sources = Fixture.Sources(healthIntervals: intervals)
        let repository = sources.repository()
        let histories = Collected(repository.caffeineNights(days: 35, in: Fixture.utc))

        let first = try #require(await histories.waitForCount(1).first)

        #expect(first.nights.first { $0.day == Fixture.date(day: 5, hour: 0) }?.measuredAt == .sleepOnset)
        #expect(first == (try Self.expected(intervals: intervals, days: 35)))
    }

    // MARK: - TOLREPO-11: a change that leaves the nights alone sends nothing

    @Test func aChangeThatLeavesTheNightsAloneSendsNothing() async {
        let sources = Fixture.Sources()
        let repository = sources.repository()
        let histories = Collected(repository.caffeineNights(days: 31, in: Fixture.utc))
        _ = await histories.waitForCount(1)

        await sources.drinkLog.signalChange()

        #expect(await histories.settled().count == 1)
    }
}
