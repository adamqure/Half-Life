//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests HealthKitStepCountDataSourceTests
//

import Foundation
import HealthKit
import Synchronization
import Testing

@testable import Half_Life

/// Checks the HealthKit step count data source against STEPS-1 to STEPS-5 in the Step Count article.
///
/// Each test replaces HealthKit's statistics query with a stand-in that records the query and answers it, so no
/// test reads real Health data (constitution Article V.3.5). Days are in New York's time zone.
struct HealthKitStepCountDataSourceTests {

    /// The parts of a statistics query that a test checks.
    struct Query: Sendable {
        let predicate: HKSamplePredicate<HKQuantitySample>
        let options: HKStatisticsOptions
    }

    /// Stands in for HealthKit's statistics query. It records every query, and answers each with `answer`.
    final class StatisticsStandIn: Sendable {
        let queries = Mutex<[Query]>([])
        let answer: @Sendable () throws -> HKQuantity?

        init(answer: @escaping @Sendable () throws -> HKQuantity?) {
            self.answer = answer
        }

        func dataSource(calendar: Calendar) -> HealthKitStepCountDataSource {
            HealthKitStepCountDataSource(calendar: calendar) { query in
                self.queries.withLock { $0.append(Query(predicate: query.predicate, options: query.options)) }
                return try self.answer()
            }
        }
    }

    static func steps(_ count: Double) -> HKQuantity {
        HKQuantity(unit: .count(), doubleValue: count)
    }

    static func newYork() throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/New_York"))
        return calendar
    }

    static func date(
        _ calendar: Calendar, _ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0, _ second: Int = 0
    ) throws -> Date {
        try #require(
            calendar.date(
                from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute, second: second)))
    }

    /// Runs one query for the day containing `day`, and returns the query HealthKit was asked.
    static func query(on day: Date, calendar: Calendar) async throws -> Query {
        let standIn = StatisticsStandIn { nil }
        _ = try await standIn.dataSource(calendar: calendar).stepCount(on: day)
        let queries = standIn.queries.withLock { $0 }
        try #require(queries.count == 1)
        return queries[0]
    }

    /// Whether `query` counts a step count sample that starts and ends at the given times.
    static func counts(_ query: Query, from start: Date, to end: Date) throws -> Bool {
        let sample = HKQuantitySample(
            type: HKQuantityType(.stepCount), quantity: steps(100), start: start, end: end)
        let predicate = try #require(query.predicate.nsPredicate)
        return predicate.evaluate(with: sample)
    }

    /// Returns what the data source reports for a day on which HealthKit's sum is `answer`.
    static func stepCount(whenHealthKitSums answer: HKQuantity?) async throws -> Int? {
        let standIn = StatisticsStandIn { answer }
        return try await standIn.dataSource(calendar: newYork()).stepCount(on: .now)
    }

    // MARK: - STEPS-1: the calendar day that contains the date, and a sample counts on the day it starts

    @Test func coversTheWholeDayThatContainsTheDate() async throws {
        let calendar = try Self.newYork()
        let query = try await Self.query(on: Self.date(calendar, 2026, 9, 11, 14), calendar: calendar)

        let midnight = try Self.date(calendar, 2026, 9, 11, 0)
        let lastSecond = try Self.date(calendar, 2026, 9, 11, 23, 59, 59)
        let dayBefore = try Self.date(calendar, 2026, 9, 10, 23, 59, 59)
        let dayAfter = try Self.date(calendar, 2026, 9, 12, 0)
        #expect(try Self.counts(query, from: midnight, to: midnight))
        #expect(try Self.counts(query, from: lastSecond, to: lastSecond))
        #expect(try !Self.counts(query, from: dayBefore, to: dayBefore))
        #expect(try !Self.counts(query, from: dayAfter, to: dayAfter))
    }

    @Test func aDateAtMidnightMeansTheDayThatStarts() async throws {
        let calendar = try Self.newYork()
        let midnight = try Self.date(calendar, 2026, 9, 11, 0)
        let query = try await Self.query(on: midnight, calendar: calendar)

        #expect(try Self.counts(query, from: midnight, to: midnight))
        #expect(try !Self.counts(query, from: midnight.addingTimeInterval(-1), to: midnight.addingTimeInterval(-1)))
    }

    /// Clocks go back an hour on Sunday 2026-11-01 in New York, so that day is 25 hours long.
    @Test func coversAll25HoursOfTheDayClocksGoBack() async throws {
        let calendar = try Self.newYork()
        let query = try await Self.query(on: Self.date(calendar, 2026, 11, 1, 12), calendar: calendar)

        let lateEvening = try Self.date(calendar, 2026, 11, 1, 23, 30)
        let nextMidnight = try Self.date(calendar, 2026, 11, 2, 0)
        #expect(try Self.counts(query, from: lateEvening, to: lateEvening))
        #expect(try !Self.counts(query, from: nextMidnight, to: nextMidnight))
    }

    @Test func aSampleSpanningMidnightCountsOnTheDayItStarts() async throws {
        let calendar = try Self.newYork()
        let start = try Self.date(calendar, 2026, 9, 10, 23, 50)
        let end = try Self.date(calendar, 2026, 9, 11, 0, 10)

        let dayItStarts = try await Self.query(on: Self.date(calendar, 2026, 9, 10, 12), calendar: calendar)
        let dayItEnds = try await Self.query(on: Self.date(calendar, 2026, 9, 11, 12), calendar: calendar)

        #expect(try Self.counts(dayItStarts, from: start, to: end))
        #expect(try !Self.counts(dayItEnds, from: start, to: end))
    }

    @Test func usesTheUsersCurrentCalendarByDefault() {
        #expect(HealthKitStepCountDataSource().calendar == .autoupdatingCurrent)
    }

    // MARK: - STEPS-2: the cumulative sum of step count samples

    @Test func asksHealthKitForTheCumulativeSumOfSteps() async throws {
        let calendar = try Self.newYork()
        let query = try await Self.query(on: Self.date(calendar, 2026, 9, 11, 14), calendar: calendar)

        #expect(query.predicate.sampleType == HKQuantityType(.stepCount))
        #expect(query.options == .cumulativeSum)
    }

    // MARK: - STEPS-3: the sum, rounded to the nearest whole step

    @Test func roundsTheSumToTheNearestWholeStep() async throws {
        #expect(try await Self.stepCount(whenHealthKitSums: Self.steps(8_419.6)) == 8_420)
        #expect(try await Self.stepCount(whenHealthKitSums: Self.steps(8_419.4)) == 8_419)
    }

    @Test func aSumOfZeroIsZeroSteps() async throws {
        #expect(try await Self.stepCount(whenHealthKitSums: Self.steps(0)) == 0)
    }

    // MARK: - STEPS-4: nil when the day has no steps

    @Test func returnsNilWhenTheDayHasNoSteps() async throws {
        #expect(try await Self.stepCount(whenHealthKitSums: nil) == nil)
    }

    // MARK: - STEPS-5: a failed query throws HealthKit's error

    @Test func aFailedQueryThrowsHealthKitsError() async throws {
        let standIn = StatisticsStandIn { throw HKError(.errorDatabaseInaccessible) }
        let source = try standIn.dataSource(calendar: Self.newYork())

        let error = await #expect(throws: HKError.self) {
            try await source.stepCount(on: .now)
        }
        #expect(error?.code == .errorDatabaseInaccessible)
    }
}
