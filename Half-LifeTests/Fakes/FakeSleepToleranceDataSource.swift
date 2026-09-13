//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FakeSleepToleranceDataSource
//

import Foundation

@testable import Half_Life

/// An in-memory caffeine tolerance data source, for repository and data source tests.
///
/// It stores one tolerance, or none, signals every subscriber after each successful store, and can be told to fail its
/// reads or stores.
actor FakeSleepToleranceDataSource: SleepToleranceDataSource {
    /// The stored tolerance, or `nil` for none.
    private(set) var stored: SleepTolerance?
    /// How many stores succeeded, including stores of none.
    private(set) var storeCount = 0
    private let readError: (any Error)?
    private let storeError: (any Error)?
    private var continuations: [UUID: AsyncStream<Void>.Continuation] = [:]

    init(stored: SleepTolerance? = nil, readError: (any Error)? = nil, storeError: (any Error)? = nil) {
        self.stored = stored
        self.readError = readError
        self.storeError = storeError
    }

    func storedTolerance() throws -> SleepTolerance? {
        if let readError { throw readError }
        return stored
    }

    func store(_ tolerance: SleepTolerance?) throws {
        if let storeError { throw storeError }
        stored = tolerance
        storeCount += 1
        for continuation in continuations.values {
            continuation.yield()
        }
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
