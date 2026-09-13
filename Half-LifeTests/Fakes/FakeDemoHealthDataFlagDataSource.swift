//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FakeDemoHealthDataFlagDataSource
//

import Foundation

@testable import Half_Life

/// The demo Health data switch, held in memory, for repository tests.
///
/// Storing a new value signals every subscriber, and storing the same value signals nothing, as the file does. It can
/// be told to fail its reads or its stores.
actor FakeDemoHealthDataFlagDataSource: DemoHealthDataFlagDataSource {
    private var isOn: Bool
    private let readError: (any Error)?
    private let storeError: (any Error)?
    private var continuations: [UUID: AsyncStream<Void>.Continuation] = [:]
    /// Every value it was asked to store, in order.
    private(set) var storedValues: [Bool] = []

    init(isOn: Bool = false, readError: (any Error)? = nil, storeError: (any Error)? = nil) {
        self.isOn = isOn
        self.readError = readError
        self.storeError = storeError
    }

    func usesDemoData() throws -> Bool {
        if let readError { throw readError }
        return isOn
    }

    func setUsesDemoData(_ isOn: Bool) throws {
        storedValues.append(isOn)
        if let storeError { throw storeError }
        guard isOn != self.isOn else { return }
        self.isOn = isOn
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
