//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FakeHalfLifeEstimateDataSource
//

import Foundation

@testable import Half_Life

/// An in-memory half-life estimate data source, for repository and data source tests.
///
/// It stores one estimate, signals every subscriber after each successful store, and can be told to fail its reads or
/// stores.
actor FakeHalfLifeEstimateDataSource: HalfLifeEstimateDataSource {
    /// The stored estimate, or `nil` for none.
    private(set) var stored: HalfLifeEstimate?
    /// How many stores succeeded.
    private(set) var storeCount = 0
    /// The error every read throws, if any.
    private let readError: (any Error)?
    /// The error every store throws, if any.
    private let storeError: (any Error)?
    private var continuations: [UUID: AsyncStream<Void>.Continuation] = [:]

    init(stored: HalfLifeEstimate? = nil, readError: (any Error)? = nil, storeError: (any Error)? = nil) {
        self.stored = stored
        self.readError = readError
        self.storeError = storeError
    }

    func storedEstimate() throws -> HalfLifeEstimate? {
        if let readError { throw readError }
        return stored
    }

    func store(_ estimate: HalfLifeEstimate) throws {
        if let storeError { throw storeError }
        stored = estimate
        storeCount += 1
        signalChange()
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

    /// Replaces the stored estimate without signalling.
    func replace(with estimate: HalfLifeEstimate?) {
        stored = estimate
    }

    /// Signals every subscriber, as the live data source does after a store.
    func signalChange() {
        for continuation in continuations.values {
            continuation.yield()
        }
    }

    private func removeContinuation(_ id: UUID) {
        continuations[id] = nil
    }
}
