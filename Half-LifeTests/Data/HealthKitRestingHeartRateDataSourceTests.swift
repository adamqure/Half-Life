//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests HealthKitRestingHeartRateDataSourceTests
//

import Foundation
import HealthKit
import Synchronization
import Testing

@testable import Half_Life

/// Checks the HealthKit resting heart rate data source against RHR-1 to RHR-5 in the Resting Heart Rate article.
///
/// Each test replaces HealthKit's statistics query with a stand-in that records the query and answers it, so no
/// test reads real Health data (constitution Article V.3.5). Days are in New York's time zone.
struct HealthKitRestingHeartRateDataSourceTests {

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

        func dataSource(calendar: Calendar) -> HealthKitRestingHeartRateDataSource {
            HealthKitRestingHeartRateDataSource(calendar: calendar) { query in
                self.queries.withLock { $0.append(Query(predicate: query.predicate, options: query.options)) }
                return try self.answer()
            }
        }
    }

    static let beatsPerMinute = HKUnit.count().unitDivided(by: .minute())

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
        _ = try await standIn.dataSource(calendar: calendar).averageRestingHeartRate(on: day)
        let queries = standIn.queries.withLock { $0 }
        try #require(queries.count == 1)
        return queries[0]
    }

    /// Whether `query` counts a resting heart rate sample that starts and ends at the given times.
    static func counts(_ query: Query, from start: Date, to end: Date) throws -> Bool {
        let sample = HKQuantitySample(
            type: HKQuantityType(.restingHeartRate), quantity: HKQuantity(unit: beatsPerMinute, doubleValue: 60),
            start: start, end: end)
        let predicate = try #require(query.predicate.nsPredicate)
        return predicate.evaluate(with: sample)
    }

    // MARK: - RHR-1: the calendar day that contains the date, and a sample counts on the day it starts

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
        #expect(HealthKitRestingHeartRateDataSource().calendar == .autoupdatingCurrent)
    }

    // MARK: - RHR-2: the discrete average of resting heart rate samples

    @Test func asksHealthKitForTheDiscreteAverageOfRestingHeartRate() async throws {
        let calendar = try Self.newYork()
        let query = try await Self.query(on: Self.date(calendar, 2026, 9, 11, 14), calendar: calendar)

        #expect(query.predicate.sampleType == HKQuantityType(.restingHeartRate))
        #expect(query.options == .discreteAverage)
    }

    // MARK: - RHR-3: the average, in beats per minute

    @Test func returnsTheAverageInBeatsPerMinute() async throws {
        let standIn = StatisticsStandIn { HKQuantity(unit: Self.beatsPerMinute, doubleValue: 57.5) }

        let average = try await standIn.dataSource(calendar: Self.newYork()).averageRestingHeartRate(on: .now)

        #expect(average == 57.5)
    }

    @Test func convertsAnAverageInAnotherUnitToBeatsPerMinute() async throws {
        let standIn = StatisticsStandIn { HKQuantity(unit: .count().unitDivided(by: .second()), doubleValue: 1) }

        let average = try await standIn.dataSource(calendar: Self.newYork()).averageRestingHeartRate(on: .now)

        #expect(average == 60)
    }

    // MARK: - RHR-4: nil when the day has no resting heart rate

    @Test func returnsNilWhenTheDayHasNoRestingHeartRate() async throws {
        let standIn = StatisticsStandIn { nil }

        #expect(try await standIn.dataSource(calendar: Self.newYork()).averageRestingHeartRate(on: .now) == nil)
    }

    // MARK: - RHR-5: a failed query throws HealthKit's error

    @Test func aFailedQueryThrowsHealthKitsError() async throws {
        let standIn = StatisticsStandIn { throw HKError(.errorDatabaseInaccessible) }
        let source = try standIn.dataSource(calendar: Self.newYork())

        let error = await #expect(throws: HKError.self) {
            try await source.averageRestingHeartRate(on: .now)
        }
        #expect(error?.code == .errorDatabaseInaccessible)
    }
}
