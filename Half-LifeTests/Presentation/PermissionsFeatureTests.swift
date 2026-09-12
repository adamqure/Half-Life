//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests PermissionsFeatureTests
//

import ComposableArchitecture
import Testing

@testable import Half_Life

/// Checks the permissions step (ONB-7 in the Onboarding article).
@MainActor
struct PermissionsFeatureTests {

    static let notAsked = Permissions(
        health: .notRequested, notifications: .notRequested, biometrics: .notRequested(.faceID))
    static let asked = Permissions(health: .requested, notifications: .allowed, biometrics: .allowed(.faceID))

    static func store(_ repository: FakePermissionsRepository) -> TestStoreOf<PermissionsFeature> {
        TestStore(initialState: PermissionsFeature.State()) {
            PermissionsFeature()
        } withDependencies: {
            $0.observePermissions = ObservePermissionsUseCase(repository: repository)
            $0.requestHealthAccess = RequestHealthAccessUseCase(repository: repository)
            $0.requestNotificationPermission = RequestNotificationPermissionUseCase(repository: repository)
            $0.requestBiometricPermission = RequestBiometricPermissionUseCase(repository: repository)
            $0.refreshPermissions = RefreshPermissionsUseCase(repository: repository)
            $0.openAppSettings = OpenAppSettingsUseCase(repository: repository)
        }
    }

    @Test func taskReducesEachPermissionsIntoState() async {
        let store = Self.store(FakePermissionsRepository(streamed: [Self.notAsked, Self.asked]))

        await store.send(.task)
        await store.receive(\.permissionsUpdated) {
            $0.permissions = Self.notAsked
        }
        await store.receive(\.permissionsUpdated) {
            $0.permissions = Self.asked
        }
        await store.finish()
    }

    // MARK: - ONB-7: each row's action calls its request

    @Test func allowingHealthRequestsHealthAccess() async {
        let repository = FakePermissionsRepository()
        let store = Self.store(repository)

        await store.send(.allowHealthTapped)
        await store.finish()

        #expect(await repository.healthRequestCount == 1)
    }

    @Test func allowingNotificationsRequestsThem() async {
        let repository = FakePermissionsRepository()
        let store = Self.store(repository)

        await store.send(.allowNotificationsTapped)
        await store.finish()

        #expect(await repository.notificationRequestCount == 1)
    }

    @Test func allowingBiometricsRequestsThem() async {
        let repository = FakePermissionsRepository()
        let store = Self.store(repository)

        await store.send(.allowBiometricsTapped)
        await store.finish()

        #expect(await repository.biometricRequestCount == 1)
    }

    @Test func aFailedRequestChangesNothing() async {
        let repository = FakePermissionsRepository(requestError: FakeDataSourceError())
        let store = Self.store(repository)

        await store.send(.allowHealthTapped)
        await store.send(.allowNotificationsTapped)
        await store.send(.allowBiometricsTapped)
        await store.finish()

        #expect(await repository.healthRequestCount == 1)
    }

    // MARK: - ONB-7: returning to the app refreshes, and a denied row opens Settings

    @Test func becomingActiveRefreshesThePermissions() async {
        let repository = FakePermissionsRepository()
        let store = Self.store(repository)

        await store.send(.appBecameActive)
        await store.finish()

        #expect(await repository.refreshCount == 1)
    }

    @Test func openSettingsOpensTheSettingsApp() async {
        let repository = FakePermissionsRepository()
        let store = Self.store(repository)

        await store.send(.openSettingsTapped)
        await store.finish()

        #expect(await repository.openSettingsCount == 1)
    }

    @Test func continueMovesOn() async {
        let store = Self.store(FakePermissionsRepository())

        await store.send(.continueTapped)
        await store.receive(\.delegate.continued)
    }
}
