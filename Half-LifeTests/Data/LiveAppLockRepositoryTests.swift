//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests LiveAppLockRepositoryTests
//

import Testing

@testable import Half_Life

/// Checks the app lock repository against LOCKREPO-1 to LOCKREPO-5 in the App Lock article, with fake data sources.
@Suite(.timeLimit(.minutes(1)))
struct LiveAppLockRepositoryTests {

    struct Failed: Error {}

    static let off = AppLock(isEnabled: false, isLocked: false)
    static let locked = AppLock(isEnabled: true, isLocked: true)
    static let unlocked = AppLock(isEnabled: true, isLocked: false)

    static func repository(
        setting: FakeAppLockSettingDataSource = FakeAppLockSettingDataSource(),
        authentication: FakeDeviceOwnerAuthenticationDataSource = FakeDeviceOwnerAuthenticationDataSource()
    ) -> LiveAppLockRepository {
        LiveAppLockRepository(setting: setting, authentication: authentication)
    }

    /// The lock a new subscriber gets first: the repository's current lock.
    static func current(_ repository: LiveAppLockRepository) async -> AppLock? {
        var locks = repository.appLock().makeAsyncIterator()
        return await locks.next()
    }

    // MARK: - LOCKREPO-1: the current lock first, then each change, and the app starts locked when the lock is on

    @Test func withTheLockOffTheAppStartsUnlocked() async {
        #expect(await Self.current(Self.repository()) == Self.off)
    }

    @Test func withTheLockOnTheAppStartsLocked() async {
        let repository = Self.repository(setting: FakeAppLockSettingDataSource(enabled: true))

        #expect(await Self.current(repository) == Self.locked)
    }

    @Test func everySubscriberGetsEachChange() async throws {
        let repository = Self.repository()
        var first = repository.appLock().makeAsyncIterator()
        var second = repository.appLock().makeAsyncIterator()
        _ = await first.next()
        _ = await second.next()

        try await repository.turnOn()

        #expect(await first.next() == Self.unlocked)
        #expect(await second.next() == Self.unlocked)
    }

    // MARK: - LOCKREPO-2: an unreadable setting counts as on, so the app starts locked

    @Test func anUnreadableSettingCountsAsOn() async {
        let repository = Self.repository(setting: FakeAppLockSettingDataSource(readError: Failed()))

        #expect(await Self.current(repository) == Self.locked)
    }

    // MARK: - LOCKREPO-3: turning on and off stores the setting, and a failed write changes nothing

    @Test func turningOnStoresItAndLeavesTheAppUnlocked() async throws {
        let setting = FakeAppLockSettingDataSource()
        let repository = Self.repository(setting: setting)
        var locks = repository.appLock().makeAsyncIterator()
        _ = await locks.next()

        try await repository.turnOn()

        #expect(await locks.next() == Self.unlocked)
        #expect(await setting.writes == [true])
    }

    @Test func turningOffStoresItAndUnlocks() async throws {
        let setting = FakeAppLockSettingDataSource(enabled: true)
        let repository = Self.repository(setting: setting)
        var locks = repository.appLock().makeAsyncIterator()
        _ = await locks.next()

        try await repository.turnOff()

        #expect(await locks.next() == Self.off)
        #expect(await setting.writes == [false])
    }

    @Test func aFailedWriteThrowsAndChangesNothing() async {
        let repository = Self.repository(setting: FakeAppLockSettingDataSource(writeError: Failed()))

        await #expect(throws: Failed.self) {
            try await repository.turnOn()
        }

        #expect(await Self.current(repository) == Self.off)
    }

    // MARK: - LOCKREPO-4: leaving the app locks it only while the lock is on

    @Test func lockingLocksTheAppWhileTheLockIsOn() async throws {
        let repository = Self.repository()
        var locks = repository.appLock().makeAsyncIterator()
        _ = await locks.next()
        try await repository.turnOn()
        _ = await locks.next()

        await repository.lock()

        #expect(await locks.next() == Self.locked)
    }

    @Test func lockingDoesNothingWhileTheLockIsOff() async throws {
        let repository = Self.repository()
        var locks = repository.appLock().makeAsyncIterator()
        _ = await locks.next()

        await repository.lock()
        try await repository.turnOn()

        // Had locking published anything, it would arrive here instead.
        #expect(await locks.next() == Self.unlocked)
    }

    // MARK: - LOCKREPO-5: unlocking asks, and only a passed prompt or a missing passcode unlocks

    @Test func aPassedPromptUnlocks() async throws {
        let authentication = FakeDeviceOwnerAuthenticationDataSource(outcome: .passed)
        let repository = Self.repository(
            setting: FakeAppLockSettingDataSource(enabled: true), authentication: authentication)
        var locks = repository.appLock().makeAsyncIterator()
        _ = await locks.next()

        try await repository.unlock()

        #expect(await locks.next() == Self.unlocked)
        #expect(await authentication.promptCount == 1)
    }

    @Test func aDeclinedPromptStaysLocked() async throws {
        let repository = Self.repository(
            setting: FakeAppLockSettingDataSource(enabled: true),
            authentication: FakeDeviceOwnerAuthenticationDataSource(outcome: .declined))

        try await repository.unlock()

        #expect(await Self.current(repository) == Self.locked)
    }

    @Test func withNoPasscodeTheAppUnlocks() async throws {
        let repository = Self.repository(
            setting: FakeAppLockSettingDataSource(enabled: true),
            authentication: FakeDeviceOwnerAuthenticationDataSource(outcome: .unavailable))

        try await repository.unlock()

        #expect(await Self.current(repository) == Self.unlocked)
    }

    @Test func aFailedPromptThrowsAndStaysLocked() async {
        let repository = Self.repository(
            setting: FakeAppLockSettingDataSource(enabled: true),
            authentication: FakeDeviceOwnerAuthenticationDataSource(error: Failed()))

        await #expect(throws: Failed.self) {
            try await repository.unlock()
        }

        #expect(await Self.current(repository) == Self.locked)
    }

    @Test func unlockingAnUnlockedAppDoesntAsk() async throws {
        let authentication = FakeDeviceOwnerAuthenticationDataSource()
        let repository = Self.repository(authentication: authentication)

        try await repository.unlock()

        #expect(await authentication.promptCount == 0)
    }
}
