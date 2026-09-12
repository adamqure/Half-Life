//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FakeUserProfileDataSource
//

import Foundation

@testable import Half_Life

/// An in-memory user profile data source, for repository tests.
///
/// It stores one profile, signals every subscriber after each successful store, and can be told to fail its reads or
/// stores. A test can also replace the profile without a signal, then signal by hand, as another writer would.
actor FakeUserProfileDataSource: UserProfileDataSource {
    /// The stored profile, or `nil` for none.
    private(set) var stored: UserProfile?
    /// How many stores succeeded.
    private(set) var storeCount = 0
    /// The error every read throws, if any.
    private let readError: (any Error)?
    /// The error every store throws, if any.
    private let storeError: (any Error)?
    private var continuations: [UUID: AsyncStream<Void>.Continuation] = [:]

    init(stored: UserProfile?, readError: (any Error)? = nil, storeError: (any Error)? = nil) {
        self.stored = stored
        self.readError = readError
        self.storeError = storeError
    }

    func storedProfile() throws -> UserProfile? {
        if let readError { throw readError }
        return stored
    }

    func store(_ profile: UserProfile) throws {
        if let storeError { throw storeError }
        stored = profile
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

    /// Replaces the stored profile without signalling.
    func replace(with profile: UserProfile?) {
        stored = profile
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

/// An error a fake data source throws on request.
struct FakeDataSourceError: Error, Equatable {}
