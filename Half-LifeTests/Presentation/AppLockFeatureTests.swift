//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests AppLockFeatureTests
//

import ComposableArchitecture
import Testing

@testable import Half_Life

/// Checks the lock screen against LOCKSCREEN-1 and LOCKSCREEN-2 in the App Lock article.
@MainActor
struct AppLockFeatureTests {

    struct UnlockFailed: Error {}

    static func store(
        _ repository: FakeAppLockRepository, state: AppLockFeature.State = AppLockFeature.State()
    ) -> TestStoreOf<AppLockFeature> {
        TestStore(initialState: state) {
            AppLockFeature()
        } withDependencies: {
            $0.unlockApp = UnlockAppUseCase(repository: repository)
        }
    }

    // MARK: - LOCKSCREEN-1: the screen asks once when the app is active, and again only after the background

    @Test func becomingActiveAsksToUnlockOnce() async {
        let repository = FakeAppLockRepository()
        let store = Self.store(repository)

        await store.send(.becameActive) {
            $0.hasPrompted = true
            $0.isUnlocking = true
        }
        await store.receive(\.unlockFinished) {
            $0.isUnlocking = false
        }
        // Dismissing the prompt makes the app active again, which mustn't ask again.
        await store.send(.becameActive)

        #expect(await repository.unlockCount == 1)
    }

    @Test func afterTheBackgroundBecomingActiveAsksAgain() async {
        let repository = FakeAppLockRepository()
        let store = Self.store(repository, state: AppLockFeature.State(hasPrompted: true))

        await store.send(.enteredBackground) {
            $0.hasPrompted = false
        }
        await store.send(.becameActive) {
            $0.hasPrompted = true
            $0.isUnlocking = true
        }
        await store.receive(\.unlockFinished) {
            $0.isUnlocking = false
        }

        #expect(await repository.unlockCount == 1)
    }

    // MARK: - LOCKSCREEN-2: the Unlock button asks, a second tap waits, and a failure lets it ask again

    @Test func theUnlockButtonAsks() async {
        let repository = FakeAppLockRepository()
        let store = Self.store(repository, state: AppLockFeature.State(hasPrompted: true))

        await store.send(.unlockTapped) {
            $0.isUnlocking = true
        }
        await store.receive(\.unlockFinished) {
            $0.isUnlocking = false
        }

        #expect(await repository.unlockCount == 1)
    }

    @Test func whileAskingNothingAsksAgain() async {
        let repository = FakeAppLockRepository()
        let store = Self.store(repository, state: AppLockFeature.State(isUnlocking: true))

        await store.send(.unlockTapped)
        await store.send(.becameActive) {
            $0.hasPrompted = true
        }

        #expect(await repository.unlockCount == 0)
    }

    @Test func aFailedPromptLetsTheButtonAskAgain() async {
        let repository = FakeAppLockRepository(error: UnlockFailed())
        let store = Self.store(repository, state: AppLockFeature.State(hasPrompted: true))

        await store.send(.unlockTapped) {
            $0.isUnlocking = true
        }
        await store.receive(\.unlockFinished) {
            $0.isUnlocking = false
        }
        await store.send(.unlockTapped) {
            $0.isUnlocking = true
        }
        await store.receive(\.unlockFinished) {
            $0.isUnlocking = false
        }

        #expect(await repository.unlockCount == 2)
    }
}
