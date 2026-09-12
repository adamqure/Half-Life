//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life HealthKitRestingHeartRateDataSource
//

import Foundation
import HealthKit
import OSLog

/// The live resting heart rate data source: a HealthKit statistics query for one day's average.
///
/// It asks HealthKit for the discrete average of the resting heart rate samples that start during the calendar day
/// (RHR-1, RHR-2). A sample spanning midnight counts only on the day it starts, so no sample counts twice. It only
/// reads, and it doesn't request authorization. The query runs through `averageQuantity`, which tests replace, so no
/// test reads real Health data. The Resting Heart Rate article lists its requirements, RHR-1 to RHR-5.
struct HealthKitRestingHeartRateDataSource: RestingHeartRateDataSource {
    private static let logger = Logger(for: HealthKitRestingHeartRateDataSource.self)
    private static let beatsPerMinute = HKUnit.count().unitDivided(by: .minute())

    /// The calendar whose days are averaged over.
    let calendar: Calendar
    /// Runs a statistics query, and returns its average quantity, or `nil` if no sample matched.
    let averageQuantity: @Sendable (HKStatisticsQueryDescriptor) async throws -> HKQuantity?

    /// Creates a resting heart rate data source.
    ///
    /// - Parameters:
    ///   - calendar: The calendar whose days are averaged over. Defaults to the user's current calendar, which
    ///     follows changes to the time zone.
    ///   - averageQuantity: Runs a statistics query and returns its average quantity. Defaults to running it on
    ///     the app's shared health store, `HKHealthStore.halfLife`.
    init(
        calendar: Calendar = .autoupdatingCurrent,
        averageQuantity: @escaping @Sendable (HKStatisticsQueryDescriptor) async throws -> HKQuantity? = {
            try await $0.result(for: .halfLife)?.averageQuantity()
        }
    ) {
        self.calendar = calendar
        self.averageQuantity = averageQuantity
    }

    /// Returns the average of the resting heart rates recorded during the calendar day that contains `day`.
    ///
    /// - Parameter day: Any moment in the day to average.
    /// - Returns: The average, in beats per minute, or `nil` if Health has no resting heart rate for that day.
    /// - Throws: HealthKit's error if the query failed. It's logged with its domain and code only.
    func averageRestingHeartRate(on day: Date) async throws -> Double? {
        guard let interval = calendar.dateInterval(of: .day, for: day) else {
            Self.logger.fault("The calendar has no day containing the requested date.")
            return nil
        }
        let query = HKStatisticsQueryDescriptor(
            predicate: .quantitySample(
                type: HKQuantityType(.restingHeartRate),
                predicate: HKQuery.predicateForSamples(
                    withStart: interval.start, end: interval.end, options: .strictStartDate)),
            options: .discreteAverage)
        do {
            return try await averageQuantity(query)?.doubleValue(for: Self.beatsPerMinute)
        } catch {
            let domain = (error as NSError).domain
            let code = (error as NSError).code
            Self.logger.error(
                "Couldn't read resting heart rate: \(domain, privacy: .public) \(code, privacy: .public)")
            throw error
        }
    }
}
