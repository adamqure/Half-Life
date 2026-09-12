//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests PermissionsUseCaseTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks that each permissions use case performs its one operation on the permissions repository.
struct PermissionsUseCaseTests {

    struct RequestFailed: Error {}

    static let notAsked = Permissions(
        health: .notRequested, notifications: .notRequested, biometrics: .notRequested(.faceID))
    static let allAsked = Permissions(health: .requested, notifications: .allowed, biometrics: .allowed(.faceID))

    @Test func observeStreamsEveryPermissionsValueInOrder() async throws {
        let repository = FakePermissionsRepository(streamed: [Self.notAsked, Self.allAsked])
        let observe = ObservePermissionsUseCase(repository: repository)

        var received: [Permissions] = []
        for await permissions in try await executeThroughProtocol(observe, ()) {
            received.append(permissions)
        }

        #expect(received == [Self.notAsked, Self.allAsked])
    }

    @Test func requestHealthAccessAsksTheRepositoryOnce() async throws {
        let repository = FakePermissionsRepository()

        try await executeThroughProtocol(RequestHealthAccessUseCase(repository: repository), ())

        #expect(await repository.healthRequestCount == 1)
        #expect(await repository.notificationRequestCount == 0)
        #expect(await repository.biometricRequestCount == 0)
    }

    @Test func requestNotificationPermissionAsksTheRepositoryOnce() async throws {
        let repository = FakePermissionsRepository()

        try await executeThroughProtocol(RequestNotificationPermissionUseCase(repository: repository), ())

        #expect(await repository.notificationRequestCount == 1)
        #expect(await repository.healthRequestCount == 0)
    }

    @Test func requestBiometricPermissionAsksTheRepositoryOnce() async throws {
        let repository = FakePermissionsRepository()

        try await executeThroughProtocol(RequestBiometricPermissionUseCase(repository: repository), ())

        #expect(await repository.biometricRequestCount == 1)
        #expect(await repository.healthRequestCount == 0)
    }

    @Test func refreshPermissionsRefreshesTheRepositoryOnce() async throws {
        let repository = FakePermissionsRepository()

        try await executeThroughProtocol(RefreshPermissionsUseCase(repository: repository), ())

        #expect(await repository.refreshCount == 1)
    }

    @Test func openAppSettingsOpensSettingsOnce() async throws {
        let repository = FakePermissionsRepository()

        try await executeThroughProtocol(OpenAppSettingsUseCase(repository: repository), ())

        #expect(await repository.openSettingsCount == 1)
    }

    @Test func eachRequestThrowsTheRepositorysError() async {
        let repository = FakePermissionsRepository(requestError: RequestFailed())

        await #expect(throws: RequestFailed.self) {
            try await RequestHealthAccessUseCase(repository: repository).execute(())
        }
        await #expect(throws: RequestFailed.self) {
            try await RequestNotificationPermissionUseCase(repository: repository).execute(())
        }
        await #expect(throws: RequestFailed.self) {
            try await RequestBiometricPermissionUseCase(repository: repository).execute(())
        }
    }
}
