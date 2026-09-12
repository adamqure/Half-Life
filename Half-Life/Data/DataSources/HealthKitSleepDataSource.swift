//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life HealthKitSleepDataSource
//

import Foundation
import HealthKit
import OSLog

/// The live sleep data source: HealthKit's sleep analysis samples, read with a sample query and watched with an
/// observer query.
///
/// It maps each sample to a ``SleepStageInterval`` and leaves overlapping samples as they are. It only reads, on the
/// app's shared `HKHealthStore.halfLife`, and never requests authorization (constitution Article V.3.1). Both queries
/// run through closures that tests replace, so no test reads real Health data. The Sleep Data article lists its
/// requirements, SLEEP-1 to SLEEP-8.
struct HealthKitSleepDataSource: SleepDataSource {
    /// Handles one report from an observer query: `nil` after a change, or the error HealthKit reported.
    typealias ChangeHandler = @Sendable ((any Error)?) -> Void

    private static let logger = Logger(for: HealthKitSleepDataSource.self)
    private static let sleepAnalysis = HKCategoryType(.sleepAnalysis)

    /// Runs a sample query and returns its samples.
    let samples: @Sendable (HKSampleQueryDescriptor<HKCategorySample>) async throws -> [HKCategorySample]
    /// Starts an observer query for a sample type, and returns a function that stops it.
    let observe: @Sendable (HKSampleType, @escaping ChangeHandler) -> @Sendable () -> Void

    /// Creates a sleep data source.
    ///
    /// - Parameters:
    ///   - samples: Runs a sample query and returns its samples. Defaults to running it on `HKHealthStore.halfLife`.
    ///   - observe: Starts an observer query for a sample type, and returns a function that stops it. Defaults to
    ///     running it on `HKHealthStore.halfLife`.
    init(
        samples: @escaping @Sendable (HKSampleQueryDescriptor<HKCategorySample>) async throws -> [HKCategorySample] = {
            try await $0.result(for: .halfLife)
        },
        observe: @escaping @Sendable (HKSampleType, @escaping ChangeHandler) -> @Sendable () -> Void = {
            HealthKitSleepDataSource.startObserving($0, handler: $1)
        }
    ) {
        self.samples = samples
        self.observe = observe
    }

    /// Returns every sleep interval that overlaps `range`, in order of start, with the times Health recorded.
    ///
    /// A sample whose value this version doesn't recognize is skipped, and the skip is logged without any sleep data.
    ///
    /// - Parameter range: The time to read sleep for.
    /// - Returns: The intervals, or none if Health has no sleep in `range` or reading it isn't allowed.
    /// - Throws: HealthKit's error if the query failed. It's logged with its domain and code only.
    func sleepIntervals(in range: DateInterval) async throws -> [SleepStageInterval] {
        let query = HKSampleQueryDescriptor(
            predicates: [
                .categorySample(
                    type: Self.sleepAnalysis,
                    predicate: HKQuery.predicateForSamples(withStart: range.start, end: range.end))
            ],
            sortDescriptors: [])
        let found: [HKCategorySample]
        do {
            found = try await samples(query)
        } catch {
            Self.logFailure("read sleep", error)
            throw error
        }
        let intervals = found.compactMap(Self.interval(from:))
        if intervals.count < found.count {
            Self.logger.error("Skipped a sleep sample whose stage this version doesn't recognize.")
        }
        return intervals.sorted { $0.start < $1.start }
    }

    /// Returns a stream for one subscriber that yields after each change HealthKit reports to sleep analysis.
    ///
    /// Each subscriber gets its own observer query, which stops when the subscriber stops listening. An error
    /// HealthKit reports is logged with its domain and code only, and signals nothing.
    func changes() -> AsyncStream<Void> {
        let (stream, continuation) = AsyncStream.makeStream(of: Void.self)
        let stop = observe(Self.sleepAnalysis) { error in
            if let error {
                Self.logFailure("observe sleep", error)
            } else {
                continuation.yield()
            }
        }
        continuation.onTermination = { _ in stop() }
        return stream
    }

    /// Returns the stage for a sleep analysis value, or `nil` for a value this version doesn't recognize, such as
    /// one a later iOS adds.
    ///
    /// - Parameter value: A sleep analysis sample's value.
    static func stage(forValue value: Int) -> SleepStageInterval.Stage? {
        guard let value = HKCategoryValueSleepAnalysis(rawValue: value) else { return nil }
        switch value {
        case .inBed: return .inBed
        case .asleepUnspecified: return .asleepUnspecified
        case .awake: return .awake
        case .asleepCore: return .core
        case .asleepDeep: return .deep
        case .asleepREM: return .rem
        @unknown default: return nil
        }
    }

    private static func interval(from sample: HKCategorySample) -> SleepStageInterval? {
        stage(forValue: sample.value).map {
            SleepStageInterval(stage: $0, start: sample.startDate, end: sample.endDate)
        }
    }

    /// Starts an observer query on the shared health store, and returns a function that stops it.
    private static func startObserving(_ type: HKSampleType, handler: @escaping ChangeHandler) -> @Sendable () -> Void {
        let query = HKObserverQuery(sampleType: type, predicate: nil) { _, completionHandler, error in
            handler(error)
            completionHandler()
        }
        HKHealthStore.halfLife.execute(query)
        return { HKHealthStore.halfLife.stop(query) }
    }

    /// Logs a failed operation with the error's domain and code, and no sleep data (constitution Article XI.6).
    private static func logFailure(_ operation: String, _ error: any Error) {
        let domain = (error as NSError).domain
        let code = (error as NSError).code
        logger.error("Couldn't \(operation, privacy: .public): \(domain, privacy: .public) \(code, privacy: .public)")
    }
}
