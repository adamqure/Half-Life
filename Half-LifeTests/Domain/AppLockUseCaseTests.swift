//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests AppLockUseCaseTests
//

import Testing

@testable import Half_Life

/// Checks the app lock's use cases against LOCKUSE-1 to LOCKUSE-4 in the App Lock article, with in-memory
/// repositories.
@Suite(.timeLimit(.minutes(1)))
struct AppLockUseCaseTests {

    struct RepositoryFailed: Error {}

    static func turnOn(
        _ permissions: FakeBiometricPermissionsRepository, _ appLock: FakeAppLockRepository
    ) -> TurnOnAppLockUseCase {
        TurnOnAppLockUseCase(permissions: permissions, appLock: appLock)
    }

    // MARK: - LOCKUSE-1: observing streams the repository's lock

    @Test func observingStreamsTheRepositorysLock() async throws {
        let locks = [AppLock(isEnabled: true, isLocked: true), AppLock(isEnabled: true, isLocked: false)]
        let observe = ObserveAppLockUseCase(repository: FakeAppLockRepository(streamed: locks))

        var received: [AppLock] = []
        for await lock in try await executeThroughProtocol(observe, ()) {
            received.append(lock)
        }

        #expect(received == locks)
    }

    // MARK: - LOCKUSE-2: turning on asks for Face ID first, and turns the lock on only once it's allowed

    @Test func turningOnAsksForFaceIDThenTurnsTheLockOnOnceItsAllowed() async throws {
        let permissions = FakeBiometricPermissionsRepository(
            biometrics: .notRequested(.faceID), afterRequest: .allowed(.faceID))
        let appLock = FakeAppLockRepository()

        try await executeThroughProtocol(Self.turnOn(permissions, appLock), ())

        #expect(await permissions.biometricRequestCount == 1)
        #expect(await appLock.turnOnCount == 1)
    }

    @Test func turningOnLeavesTheLockOffWhenTheUserSaysNoToFaceID() async throws {
        let permissions = FakeBiometricPermissionsRepository(
            biometrics: .notRequested(.touchID), afterRequest: .denied(.touchID))
        let appLock = FakeAppLockRepository()

        try await executeThroughProtocol(Self.turnOn(permissions, appLock), ())

        #expect(await permissions.biometricRequestCount == 1)
        #expect(await appLock.turnOnCount == 0)
    }

    @Test(arguments: [BiometricPermission.denied(.faceID), .notEnrolled(.faceID), .unavailable])
    func turningOnDoesNothingWithoutUsableBiometrics(_ biometrics: BiometricPermission) async throws {
        let permissions = FakeBiometricPermissionsRepository(biometrics: biometrics)
        let appLock = FakeAppLockRepository()

        try await executeThroughProtocol(Self.turnOn(permissions, appLock), ())

        #expect(await permissions.biometricRequestCount == 0)
        #expect(await appLock.turnOnCount == 0)
    }

    @Test func aFailedRequestThrowsAndLeavesTheLockOff() async {
        let permissions = FakeBiometricPermissionsRepository(
            biometrics: .notRequested(.faceID), afterRequest: .allowed(.faceID), requestError: RepositoryFailed())
        let appLock = FakeAppLockRepository()

        await #expect(throws: RepositoryFailed.self) {
            try await executeThroughProtocol(Self.turnOn(permissions, appLock), ())
        }
        #expect(await appLock.turnOnCount == 0)
    }

    // MARK: - LOCKUSE-3: turning on when Face ID is already allowed doesn't ask again

    @Test func turningOnWhenFaceIDIsAllowedDoesntAskAgain() async throws {
        let permissions = FakeBiometricPermissionsRepository(biometrics: .allowed(.faceID))
        let appLock = FakeAppLockRepository()

        try await executeThroughProtocol(Self.turnOn(permissions, appLock), ())

        #expect(await permissions.biometricRequestCount == 0)
        #expect(await appLock.turnOnCount == 1)
    }

    @Test func turningOnThrowsTheRepositorysError() async {
        let permissions = FakeBiometricPermissionsRepository(biometrics: .allowed(.faceID))
        let appLock = FakeAppLockRepository(error: RepositoryFailed())

        await #expect(throws: RepositoryFailed.self) {
            try await executeThroughProtocol(Self.turnOn(permissions, appLock), ())
        }
    }

    // MARK: - LOCKUSE-4: turning off, locking, and unlocking go to the repository, and its errors pass through

    @Test func turningOffLockingAndUnlockingGoToTheRepository() async throws {
        let appLock = FakeAppLockRepository()

        try await executeThroughProtocol(TurnOffAppLockUseCase(repository: appLock), ())
        try await executeThroughProtocol(LockAppUseCase(repository: appLock), ())
        try await executeThroughProtocol(UnlockAppUseCase(repository: appLock), ())

        #expect(await appLock.turnOffCount == 1)
        #expect(await appLock.lockCount == 1)
        #expect(await appLock.unlockCount == 1)
    }

    @Test func turningOffAndUnlockingThrowTheRepositorysError() async {
        let appLock = FakeAppLockRepository(error: RepositoryFailed())

        await #expect(throws: RepositoryFailed.self) {
            try await executeThroughProtocol(TurnOffAppLockUseCase(repository: appLock), ())
        }
        await #expect(throws: RepositoryFailed.self) {
            try await executeThroughProtocol(UnlockAppUseCase(repository: appLock), ())
        }
    }
}
