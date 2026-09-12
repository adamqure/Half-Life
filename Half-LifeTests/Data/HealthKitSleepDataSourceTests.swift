//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests HealthKitSleepDataSourceTests
//

import Foundation
import HealthKit
import Synchronization
import Testing

@testable import Half_Life

/// Checks the HealthKit sleep data source against SLEEP-1 to SLEEP-8 in the Sleep Data article.
///
/// Each test replaces HealthKit's sample query and observer query with a stand-in that records what it's asked and
/// answers it, so no test reads real Health data (constitution Article V.3.5).
struct HealthKitSleepDataSourceTests {

    /// Stands in for HealthKit. It records every query and observer, answers each query with `answer`, and lets a
    /// test report changes to the observers it started.
    final class HealthKitStandIn: Sendable {
        let queries = Mutex<[HKSampleQueryDescriptor<HKCategorySample>]>([])
        let observedTypes = Mutex<[HKSampleType]>([])
        let handlers = Mutex<[@Sendable ((any Error)?) -> Void]>([])
        let stopCount = Mutex(0)
        let answer: @Sendable () throws -> [HKCategorySample]

        init(answer: @escaping @Sendable () throws -> [HKCategorySample]) {
            self.answer = answer
        }

        var dataSource: HealthKitSleepDataSource {
            HealthKitSleepDataSource(
                samples: { query in
                    self.queries.withLock { $0.append(query) }
                    return try self.answer()
                },
                observe: { type, handler in
                    self.observedTypes.withLock { $0.append(type) }
                    self.handlers.withLock { $0.append(handler) }
                    return { self.stopCount.withLock { $0 += 1 } }
                })
        }

        /// Reports a change, or an error, to every observer started so far, as HealthKit's observer query does.
        func report(_ error: (any Error)? = nil) {
            for handler in handlers.withLock({ $0 }) {
                handler(error)
            }
        }
    }

    static let midnight = Date(timeIntervalSinceReferenceDate: 0)
    /// 22:00 to 07:00 the next morning.
    static let night = DateInterval(start: at(22), end: at(31))

    static func at(_ hours: Double) -> Date {
        midnight.addingTimeInterval(hours * 3_600)
    }

    static func sample(_ value: HKCategoryValueSleepAnalysis, from start: Double, to end: Double) -> HKCategorySample {
        HKCategorySample(type: HKCategoryType(.sleepAnalysis), value: value.rawValue, start: at(start), end: at(end))
    }

    /// Runs one query for `range`, and returns the query HealthKit was asked.
    static func query(for range: DateInterval) async throws -> HKSampleQueryDescriptor<HKCategorySample> {
        let standIn = HealthKitStandIn { [] }
        _ = try await standIn.dataSource.sleepIntervals(in: range)
        let queries = standIn.queries.withLock { $0 }
        try #require(queries.count == 1)
        return queries[0]
    }

    /// Whether `query` counts a sleep sample that starts and ends at the given hours.
    static func counts(
        _ query: HKSampleQueryDescriptor<HKCategorySample>, from start: Double, to end: Double
    ) throws -> Bool {
        try #require(query.predicates.count == 1)
        let predicate = try #require(query.predicates[0].nsPredicate)
        return predicate.evaluate(with: sample(.asleepCore, from: start, to: end))
    }

    /// Counts the signals `changes` delivers for `work`. Signals are buffered, so after a short wait every signal
    /// the work sent has been counted, and cancelling ends the count.
    static func signalCount(_ changes: AsyncStream<Void>, during work: () -> Void) async throws -> Int {
        let counter = Task {
            var count = 0
            for await _ in changes {
                count += 1
            }
            return count
        }
        work()
        try await Task.sleep(for: .milliseconds(200))
        counter.cancel()
        return await counter.value
    }

    // MARK: - SLEEP-1: every sleep analysis sample that overlaps the range

    @Test func asksForEverySleepAnalysisSample() async throws {
        let query = try await Self.query(for: Self.night)

        #expect(query.predicates.map(\.sampleType) == [HKCategoryType(.sleepAnalysis)])
        #expect(query.limit == nil)
    }

    @Test func countsEverySampleThatOverlapsTheRange() async throws {
        let query = try await Self.query(for: Self.night)

        #expect(try Self.counts(query, from: 23, to: 30))
        #expect(try Self.counts(query, from: 21, to: 23))
        #expect(try Self.counts(query, from: 30, to: 32))
        #expect(try Self.counts(query, from: 21, to: 32))
        #expect(try !Self.counts(query, from: 20, to: 21))
        #expect(try !Self.counts(query, from: 31, to: 32))
    }

    // MARK: - SLEEP-2: each sample becomes an interval with its stage and the times Health recorded

    @Test(arguments: [
        (HKCategoryValueSleepAnalysis.inBed, SleepStageInterval.Stage.inBed),
        (.asleepUnspecified, .asleepUnspecified),
        (.awake, .awake),
        (.asleepCore, .core),
        (.asleepDeep, .deep),
        (.asleepREM, .rem),
    ])
    func eachSampleBecomesAnIntervalInItsStage(
        value: HKCategoryValueSleepAnalysis, stage: SleepStageInterval.Stage
    ) async throws {
        let standIn = HealthKitStandIn { [Self.sample(value, from: 23, to: 24.5)] }

        let intervals = try await standIn.dataSource.sleepIntervals(in: Self.night)

        #expect(intervals == [SleepStageInterval(stage: stage, start: Self.at(23), end: Self.at(24.5))])
    }

    @Test func intervalsAreNotClippedToTheRange() async throws {
        let standIn = HealthKitStandIn { [Self.sample(.inBed, from: 21, to: 32)] }

        let intervals = try await standIn.dataSource.sleepIntervals(in: Self.night)

        #expect(intervals == [SleepStageInterval(stage: .inBed, start: Self.at(21), end: Self.at(32))])
    }

    /// HealthKit also returns nothing when the user hasn't allowed reading sleep, because it doesn't reveal a denial.
    @Test func returnsNoIntervalsWhenHealthHasNoSleep() async throws {
        let standIn = HealthKitStandIn { [] }

        #expect(try await standIn.dataSource.sleepIntervals(in: Self.night).isEmpty)
    }

    // MARK: - SLEEP-3: intervals come back in order of their start

    @Test func intervalsComeBackInOrderOfStart() async throws {
        let standIn = HealthKitStandIn {
            [
                Self.sample(.asleepDeep, from: 24, to: 25),
                Self.sample(.inBed, from: 22.5, to: 30),
                Self.sample(.awake, from: 23, to: 23.25),
            ]
        }

        let starts = try await standIn.dataSource.sleepIntervals(in: Self.night).map(\.start)

        #expect(starts == [Self.at(22.5), Self.at(23), Self.at(24)])
    }

    // MARK: - SLEEP-4: a value this version doesn't recognize has no stage

    /// HealthKit won't create a sample with an unknown value, so this checks the mapping directly. A later iOS can
    /// add a sleep value, and a sample with it is then skipped rather than failing the whole read.
    @Test(arguments: [-1, 6, 99])
    func aValueThisVersionDoesntRecognizeHasNoStage(value: Int) {
        #expect(HealthKitSleepDataSource.stage(forValue: value) == nil)
    }

    // MARK: - SLEEP-5: a failed query throws HealthKit's error

    @Test func aFailedQueryThrowsHealthKitsError() async throws {
        let source = HealthKitStandIn { throw HKError(.errorDatabaseInaccessible) }.dataSource

        let error = await #expect(throws: HKError.self) {
            try await source.sleepIntervals(in: Self.night)
        }
        #expect(error?.code == .errorDatabaseInaccessible)
    }

    // MARK: - SLEEP-6: each subscriber observes sleep analysis, and gets a signal per change HealthKit reports

    @Test func eachSubscriberObservesSleepAnalysis() async {
        let standIn = HealthKitStandIn { [] }
        let source = standIn.dataSource

        let first = source.changes()
        let second = source.changes()

        #expect(
            standIn.observedTypes.withLock { $0 } == [HKCategoryType(.sleepAnalysis), HKCategoryType(.sleepAnalysis)])
        withExtendedLifetime((first, second)) {}
    }

    @Test func signalsOncePerReportedChange() async throws {
        let standIn = HealthKitStandIn { [] }
        let changes = standIn.dataSource.changes()

        let count = try await Self.signalCount(changes) {
            standIn.report()
            standIn.report()
        }

        #expect(count == 2)
    }

    // MARK: - SLEEP-7: an error HealthKit reports signals nothing

    @Test func aReportedErrorSignalsNothing() async throws {
        let standIn = HealthKitStandIn { [] }
        let changes = standIn.dataSource.changes()

        let count = try await Self.signalCount(changes) {
            standIn.report(HKError(.errorAuthorizationNotDetermined))
        }

        #expect(count == 0)
    }

    // MARK: - SLEEP-8: the observer stops when its subscriber stops listening

    @Test func stopsObservingWhenTheSubscriberStops() async {
        let standIn = HealthKitStandIn { [] }
        let changes = standIn.dataSource.changes()

        let listener = Task {
            for await _ in changes {}
        }
        listener.cancel()
        await listener.value

        #expect(standIn.stopCount.withLock { $0 } == 1)
    }
}
