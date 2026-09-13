//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests AppLockSettingsFeatureTests
//

import ComposableArchitecture
import Testing

@testable import Half_Life

/// Checks Settings' App lock section against SETLOCK-1 to SETLOCK-3 in the App Lock article.
@MainActor
struct AppLockSettingsFeatureTests {

    struct ChangeFailed: Error {}

    static let lockOff = AppLock(isEnabled: false, isLocked: false)
    static let lockOn = AppLock(isEnabled: true, isLocked: false)
    static let faceIDAllowed = Permissions(
        health: .notRequested, notifications: .notRequested, biometrics: .allowed(.faceID))

    // MARK: - SETLOCK-1: Settings runs the section, which shows the lock and the biometrics from their repositories

    @Test func settingsRunsTheAppLockSection() async {
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }

        await store.send(.appLock(.appLockUpdated(Self.lockOn))) {
            $0.appLock.appLock = Self.lockOn
        }
    }

    @Test func taskReducesTheLock() async {
        let store = TestStore(initialState: AppLockSettingsFeature.State()) {
            AppLockSettingsFeature()
        } withDependencies: {
            $0.observeAppLock = ObserveAppLockUseCase(repository: FakeAppLockRepository(streamed: [Self.lockOff]))
            $0.observePermissions = ObservePermissionsUseCase(repository: FakePermissionsRepository())
        }

        await store.send(.task)
        await store.receive(\.appLockUpdated) {
            $0.appLock = Self.lockOff
        }
        await store.finish()
    }

    @Test func taskReducesTheBiometrics() async {
        let store = TestStore(initialState: AppLockSettingsFeature.State()) {
            AppLockSettingsFeature()
        } withDependencies: {
            $0.observeAppLock = ObserveAppLockUseCase(repository: FakeAppLockRepository())
            $0.observePermissions = ObservePermissionsUseCase(
                repository: FakePermissionsRepository(streamed: [Self.faceIDAllowed]))
        }

        await store.send(.task)
        await store.receive(\.permissionsUpdated) {
            $0.biometrics = .allowed(.faceID)
        }
        await store.finish()
    }

    // MARK: - SETLOCK-2: the switch turns the lock on or off, and waits for the repository

    @Test func switchingOnTurnsTheLockOn() async {
        let appLock = FakeAppLockRepository()
        let store = TestStore(
            initialState: AppLockSettingsFeature.State(appLock: Self.lockOff, biometrics: .allowed(.faceID))
        ) {
            AppLockSettingsFeature()
        } withDependencies: {
            $0.turnOnAppLock = TurnOnAppLockUseCase(
                permissions: FakeBiometricPermissionsRepository(biometrics: .allowed(.faceID)), appLock: appLock)
        }

        await store.send(.lockSwitched(true)) {
            $0.isChanging = true
        }
        await store.receive(\.changeFinished) {
            $0.isChanging = false
        }

        #expect(await appLock.turnOnCount == 1)
    }

    @Test func switchingOffTurnsTheLockOff() async {
        let appLock = FakeAppLockRepository()
        let store = TestStore(
            initialState: AppLockSettingsFeature.State(appLock: Self.lockOn, biometrics: .allowed(.faceID))
        ) {
            AppLockSettingsFeature()
        } withDependencies: {
            $0.turnOffAppLock = TurnOffAppLockUseCase(repository: appLock)
        }

        await store.send(.lockSwitched(false)) {
            $0.isChanging = true
        }
        await store.receive(\.changeFinished) {
            $0.isChanging = false
        }

        #expect(await appLock.turnOffCount == 1)
    }

    // MARK: - SETLOCK-3: a failed change says so until the next try, and a switch while changing does nothing

    @Test func aFailedChangeSaysSoUntilTheNextTry() async {
        let store = TestStore(
            initialState: AppLockSettingsFeature.State(appLock: Self.lockOn, biometrics: .allowed(.faceID))
        ) {
            AppLockSettingsFeature()
        } withDependencies: {
            $0.turnOffAppLock = TurnOffAppLockUseCase(repository: FakeAppLockRepository(error: ChangeFailed()))
        }

        await store.send(.lockSwitched(false)) {
            $0.isChanging = true
        }
        await store.receive(\.changeFinished) {
            $0.isChanging = false
            $0.changeFailed = true
        }
        await store.send(.lockSwitched(false)) {
            $0.isChanging = true
            $0.changeFailed = false
        }
        await store.receive(\.changeFinished) {
            $0.isChanging = false
            $0.changeFailed = true
        }
    }

    @Test func switchingWhileAChangeIsUnderWayDoesNothing() async {
        let store = TestStore(
            initialState: AppLockSettingsFeature.State(
                appLock: Self.lockOff, biometrics: .allowed(.faceID), isChanging: true)
        ) {
            AppLockSettingsFeature()
        }

        await store.send(.lockSwitched(true))
        await store.send(.lockSwitched(false))
    }
}
