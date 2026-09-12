//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FakeHalfLifeDataSource
//

import Foundation

@testable import Half_Life

/// A half-life data source that returns a given half-life, for repository tests.
///
/// A test can change the half-life and signal the change, as the live data source does after a store.
actor FakeHalfLifeDataSource: HalfLifeDataSource {
    /// The half-life that `halfLife()` returns.
    private(set) var value: CaffeineHalfLife
    private var continuations: [UUID: AsyncStream<Void>.Continuation] = [:]

    init(value: CaffeineHalfLife) {
        self.value = value
    }

    func halfLife() -> CaffeineHalfLife {
        value
    }

    func changes() -> AsyncStream<Void> {
        let (stream, continuation) = AsyncStream.makeStream(of: Void.self)
        continuations[UUID()] = continuation
        return stream
    }

    /// Changes the half-life and signals every subscriber.
    func change(to halfLife: CaffeineHalfLife) {
        value = halfLife
        for continuation in continuations.values {
            continuation.yield()
        }
    }
}
