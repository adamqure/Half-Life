//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life HealthKitStepCountDataSource
//

import Foundation
import HealthKit
import OSLog

/// The live step count data source: a HealthKit statistics query for one day's total.
///
/// It asks HealthKit for the cumulative sum of the step count samples that start during the calendar day (STEPS-1,
/// STEPS-2). HealthKit merges overlapping samples from different sources, such as an iPhone and an Apple Watch,
/// before it sums them, so a step recorded by both counts once. A sample spanning midnight counts only on the day it
/// starts, so no sample counts twice. It only reads, and it doesn't request authorization (constitution Article
/// V.3.1). The query runs through `sumQuantity`, which tests replace, so no test reads real Health data. The Step
/// Count article lists its requirements, STEPS-1 to STEPS-5.
struct HealthKitStepCountDataSource: StepCountDataSource {
    private static let logger = Logger(for: HealthKitStepCountDataSource.self)

    /// The calendar whose days are totalled.
    let calendar: Calendar
    /// Runs a statistics query, and returns its sum quantity, or `nil` if no sample matched.
    let sumQuantity: @Sendable (HKStatisticsQueryDescriptor) async throws -> HKQuantity?
    /// Starts an observer query for a sample type, and returns a function that stops it.
    let observe: @Sendable (HKSampleType, @escaping @Sendable ((any Error)?) -> Void) -> @Sendable () -> Void

    /// Creates a step count data source.
    ///
    /// - Parameters:
    ///   - calendar: The calendar whose days are totalled. Defaults to the user's current calendar, which follows
    ///     changes to the time zone.
    ///   - sumQuantity: Runs a statistics query and returns its sum quantity. Defaults to running it on the app's
    ///     shared health store, ``HealthKit/HKHealthStore/halfLife``.
    ///   - observe: Starts an observer query for a sample type, and returns a function that stops it. Defaults to
    ///     running it on the shared health store.
    init(
        calendar: Calendar = .autoupdatingCurrent,
        sumQuantity: @escaping @Sendable (HKStatisticsQueryDescriptor) async throws -> HKQuantity? = {
            try await $0.result(for: .halfLife)?.sumQuantity()
        },
        observe:
            @escaping @Sendable (HKSampleType, @escaping @Sendable ((any Error)?) -> Void) -> @Sendable () -> Void = {
                HKHealthStore.observeHalfLife($0, handler: $1)
            }
    ) {
        self.calendar = calendar
        self.sumQuantity = sumQuantity
        self.observe = observe
    }

    /// Returns the total number of steps recorded during the calendar day that contains `day`.
    ///
    /// - Parameter day: Any moment in the day to total.
    /// - Returns: The day's steps, rounded to the nearest whole step, or `nil` if Health has no step count for that
    ///   day.
    /// - Throws: HealthKit's error if the query failed. It's logged with its domain and code only.
    func stepCount(on day: Date) async throws -> Int? {
        guard let interval = calendar.dateInterval(of: .day, for: day) else {
            Self.logger.fault("The calendar has no day containing the requested date.")
            return nil
        }
        let query = HKStatisticsQueryDescriptor(
            predicate: .quantitySample(
                type: HKQuantityType(.stepCount),
                predicate: HKQuery.predicateForSamples(
                    withStart: interval.start, end: interval.end, options: .strictStartDate)),
            options: .cumulativeSum)
        do {
            guard let sum = try await sumQuantity(query) else { return nil }
            return Int(sum.doubleValue(for: .count()).rounded())
        } catch {
            let domain = (error as NSError).domain
            let code = (error as NSError).code
            Self.logger.error("Couldn't read step count: \(domain, privacy: .public) \(code, privacy: .public)")
            throw error
        }
    }

    /// Returns a stream for one subscriber that yields after each change HealthKit reports to step count.
    ///
    /// Each subscriber gets its own observer query, which stops when the subscriber stops listening. An error
    /// HealthKit reports is logged with its domain and code only, and signals nothing (STEPS-6 to STEPS-8).
    func changes() -> AsyncStream<Void> {
        let (stream, continuation) = AsyncStream.makeStream(of: Void.self)
        let stop = observe(HKQuantityType(.stepCount)) { error in
            if let error {
                let domain = (error as NSError).domain
                let code = (error as NSError).code
                Self.logger.error("Couldn't observe step count: \(domain, privacy: .public) \(code, privacy: .public)")
            } else {
                continuation.yield()
            }
        }
        continuation.onTermination = { _ in stop() }
        return stream
    }
}
