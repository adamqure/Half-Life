//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FakeHealthData
//

import Foundation

@testable import Half_Life

/// Sleep, step count, and resting heart rate for repository tests, in one stand-in, so no test reads real Health data.
///
/// A test changes what it holds and signals a change, as HealthKit's observer queries do. Its one `changes()` serves
/// all three protocols, so a signal stands for a change to any of them. It counts its reads and its listeners.
actor FakeHealthData: SleepDataSource, StepCountDataSource, RestingHeartRateDataSource {
    private var intervals: [SleepStageInterval]
    private var steps: Int?
    private var restingHeartRate: Double?
    private var sleepError: (any Error)?
    private var stepsError: (any Error)?
    private var heartRateError: (any Error)?
    private var continuations: [UUID: AsyncStream<Void>.Continuation] = [:]
    /// How many reads of any metric it has answered or failed.
    private(set) var readCount = 0

    init(intervals: [SleepStageInterval] = [], steps: Int? = nil, restingHeartRate: Double? = nil) {
        self.intervals = intervals
        self.steps = steps
        self.restingHeartRate = restingHeartRate
    }

    /// How many subscribers are listening to its changes now.
    var listenerCount: Int {
        continuations.count
    }

    /// Replaces what it holds. It doesn't signal.
    func hold(intervals: [SleepStageInterval]? = nil, steps: Int?? = nil, restingHeartRate: Double?? = nil) {
        if let intervals { self.intervals = intervals }
        if let steps { self.steps = steps }
        if let restingHeartRate { self.restingHeartRate = restingHeartRate }
    }

    /// Makes the reads of each given metric throw.
    func fail(sleep: (any Error)? = nil, steps: (any Error)? = nil, restingHeartRate: (any Error)? = nil) {
        sleepError = sleep
        stepsError = steps
        heartRateError = restingHeartRate
    }

    /// Signals a change to every subscriber, as an observer query does.
    func signalChange() {
        for continuation in continuations.values {
            continuation.yield()
        }
    }

    func sleepIntervals(in range: DateInterval) throws -> [SleepStageInterval] {
        readCount += 1
        if let sleepError { throw sleepError }
        return intervals.filter { $0.end >= range.start && $0.start < range.end }
    }

    func stepCount(on day: Date) throws -> Int? {
        readCount += 1
        if let stepsError { throw stepsError }
        return steps
    }

    func averageRestingHeartRate(on day: Date) throws -> Double? {
        readCount += 1
        if let heartRateError { throw heartRateError }
        return restingHeartRate
    }

    func changes() -> AsyncStream<Void> {
        let (stream, continuation) = AsyncStream.makeStream(of: Void.self)
        let id = UUID()
        continuations[id] = continuation
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeContinuation(id) }
        }
        return stream
    }

    private func removeContinuation(_ id: UUID) {
        continuations[id] = nil
    }
}
