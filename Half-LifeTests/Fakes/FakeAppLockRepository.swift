//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FakeAppLockRepository
//

@testable import Half_Life

/// An app lock repository for use case and feature tests. It streams the locks it's given, and counts each command.
actor FakeAppLockRepository: AppLockRepository {
    /// The locks that `appLock()` streams, in order.
    let streamed: [AppLock]
    /// The error that turning on, turning off, and unlocking throw, if any.
    let error: (any Error)?
    /// How many times the lock was turned on.
    private(set) var turnOnCount = 0
    /// How many times the lock was turned off.
    private(set) var turnOffCount = 0
    /// How many times the app was locked.
    private(set) var lockCount = 0
    /// How many times the app was unlocked.
    private(set) var unlockCount = 0

    init(streamed: [AppLock] = [], error: (any Error)? = nil) {
        self.streamed = streamed
        self.error = error
    }

    nonisolated func appLock() -> AsyncStream<AppLock> {
        AsyncStream { continuation in
            for lock in streamed {
                continuation.yield(lock)
            }
            continuation.finish()
        }
    }

    func turnOn() throws {
        turnOnCount += 1
        if let error { throw error }
    }

    func turnOff() throws {
        turnOffCount += 1
        if let error { throw error }
    }

    func lock() {
        lockCount += 1
    }

    func unlock() throws {
        unlockCount += 1
        if let error { throw error }
    }
}
