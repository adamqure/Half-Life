//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life LiveAppLockRepository
//

import Foundation
import OSLog

/// The live app lock repository: the source of truth for whether the lock is on and whether the app is locked.
///
/// It reads the setting once, the first time it's needed, and starts the app locked if the lock is on. A setting that
/// can't be read counts as on, so a damaged file never leaves the data unprotected, and the user can still unlock with
/// the passcode. It publishes the lock to a new subscriber at once, and to every subscriber whenever it changes. It's
/// an actor, off the main actor (constitution Article I.13). The App Lock article lists its requirements,
/// LOCKREPO-1 to LOCKREPO-5.
actor LiveAppLockRepository: AppLockRepository {
    private static let logger = Logger(for: LiveAppLockRepository.self)

    private let setting: any AppLockSettingDataSource
    private let authentication: any DeviceOwnerAuthenticationDataSource
    private var subscribers: [UUID: AsyncStream<AppLock>.Continuation] = [:]
    private var current: AppLock?

    /// Creates the repository.
    ///
    /// - Parameters:
    ///   - setting: Stores whether the lock is on.
    ///   - authentication: Asks the user to unlock the app.
    init(setting: any AppLockSettingDataSource, authentication: any DeviceOwnerAuthenticationDataSource) {
        self.setting = setting
        self.authentication = authentication
    }

    /// Streams the lock: the current one as soon as it's subscribed to, then each change. It never finishes.
    nonisolated func appLock() -> AsyncStream<AppLock> {
        let (stream, continuation) = AsyncStream.makeStream(of: AppLock.self)
        let id = UUID()
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeSubscriber(id) }
        }
        Task { await addSubscriber(id, continuation) }
        return stream
    }

    /// Stores the lock as on, and publishes it, leaving the app unlocked.
    ///
    /// - Throws: The data source's error if the setting couldn't be stored. Nothing changes.
    func turnOn() async throws {
        let loaded = await load()
        do {
            try await setting.setEnabled(true)
        } catch {
            Self.logError("turn the app lock on", error)
            throw error
        }
        Self.logger.notice("App lock turned on.")
        publish(AppLock(isEnabled: true, isLocked: loaded.isLocked))
    }

    /// Stores the lock as off, and publishes it, unlocking the app.
    ///
    /// - Throws: The data source's error if the setting couldn't be stored. Nothing changes.
    func turnOff() async throws {
        _ = await load()
        do {
            try await setting.setEnabled(false)
        } catch {
            Self.logError("turn the app lock off", error)
            throw error
        }
        Self.logger.notice("App lock turned off.")
        publish(AppLock(isEnabled: false, isLocked: false))
    }

    /// Locks the app if the lock is on and the app isn't already locked.
    func lock() async {
        let loaded = await load()
        guard loaded.isEnabled, !loaded.isLocked else { return }
        Self.logger.debug("App locked.")
        publish(AppLock(isEnabled: true, isLocked: true))
    }

    /// Asks the user to unlock the app, if it's locked, and unlocks it if they pass or the device has no passcode.
    ///
    /// - Throws: The data source's error if the prompt couldn't be shown. The app stays locked.
    func unlock() async throws {
        guard await load().isLocked else { return }
        let outcome: DeviceOwnerAuthenticationOutcome
        do {
            outcome = try await authentication.authenticate()
        } catch {
            Self.logError("ask to unlock the app", error)
            throw error
        }
        switch outcome {
        case .passed, .unavailable:
            Self.logger.debug("App unlocked.")
            publish(AppLock(isEnabled: current?.isEnabled ?? true, isLocked: false))
        case .declined:
            break
        }
    }

    /// Tells the new subscriber the current lock, reading the setting first if it hasn't been read.
    private func addSubscriber(_ id: UUID, _ continuation: AsyncStream<AppLock>.Continuation) async {
        let loaded = await load()
        subscribers[id] = continuation
        continuation.yield(current ?? loaded)
    }

    private func removeSubscriber(_ id: UUID) {
        subscribers[id] = nil
    }

    /// Returns the current lock, reading the setting the first time. An unreadable setting counts as on.
    private func load() async -> AppLock {
        if let current { return current }
        let isEnabled: Bool
        do {
            isEnabled = try await setting.isEnabled()
        } catch {
            Self.logError("read the app lock setting, so the app starts locked", error)
            isEnabled = true
        }
        // Another call may have loaded it while this one waited.
        if let current { return current }
        let loaded = AppLock(isEnabled: isEnabled, isLocked: isEnabled)
        current = loaded
        return loaded
    }

    /// Publishes `lock` to every subscriber, if it differs from the current one.
    private func publish(_ lock: AppLock) {
        guard lock != current else { return }
        current = lock
        for subscriber in subscribers.values {
            subscriber.yield(lock)
        }
    }

    /// Logs a failure with the error's domain and code only (constitution Article XI.6.4).
    private static func logError(_ what: String, _ error: any Error) {
        let domain = (error as NSError).domain
        let code = (error as NSError).code
        logger.error("Couldn't \(what, privacy: .public): \(domain, privacy: .public) \(code, privacy: .public)")
    }
}
