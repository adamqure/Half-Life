//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FakeSleepDataSource
//

import Foundation

@testable import Half_Life

/// A sleep data source that returns given intervals, for repository tests, so no test reads real Health data.
///
/// It records every range it's asked for, and can be told to fail its reads.
actor FakeSleepDataSource: SleepDataSource {
    /// The intervals held.
    let intervals: [SleepStageInterval]
    /// The error every read throws, if any.
    let readError: (any Error)?
    /// The range of each read, in order.
    private(set) var requestedRanges: [DateInterval] = []

    init(intervals: [SleepStageInterval] = [], readError: (any Error)? = nil) {
        self.intervals = intervals
        self.readError = readError
    }

    /// Returns the intervals that overlap `range`, as HealthKit's predicate does.
    func sleepIntervals(in range: DateInterval) throws -> [SleepStageInterval] {
        requestedRanges.append(range)
        if let readError { throw readError }
        return intervals.filter { $0.end >= range.start && $0.start < range.end }
    }

    func changes() -> AsyncStream<Void> {
        AsyncStream { $0.finish() }
    }
}
