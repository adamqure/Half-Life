//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FakeBedtimeDataSource
//

import Foundation

@testable import Half_Life

/// A bedtime data source that returns a given bedtime, for repository tests.
///
/// A test can change the bedtime and signal the change, as the live data source does after a store.
actor FakeBedtimeDataSource: BedtimeDataSource {
    /// The bedtime that `bedtime()` returns.
    private(set) var value: Bedtime
    private var continuations: [UUID: AsyncStream<Void>.Continuation] = [:]

    init(value: Bedtime) {
        self.value = value
    }

    func bedtime() -> Bedtime {
        value
    }

    func changes() -> AsyncStream<Void> {
        let (stream, continuation) = AsyncStream.makeStream(of: Void.self)
        continuations[UUID()] = continuation
        return stream
    }

    /// Changes the bedtime and signals every subscriber.
    func change(to bedtime: Bedtime) {
        value = bedtime
        for continuation in continuations.values {
            continuation.yield()
        }
    }
}
