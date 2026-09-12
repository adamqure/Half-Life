//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests SimulatedPermissionDataSourcesTests
//

import Testing

@testable import Half_Life

/// Checks the simulated permission data sources that UI tests and previews use instead of the system's prompts.
@Suite(.timeLimit(.minutes(1)))
struct SimulatedPermissionDataSourcesTests {

    @Test func healthIsNotRequestedUntilItIsRequested() async throws {
        let source = SimulatedHealthAccessDataSource()
        #expect(await source.status() == .notRequested)

        await source.requestAccess()

        #expect(await source.status() == .requested)
    }

    @Test func notificationsAreAllowedOnceRequested() async throws {
        let source = SimulatedNotificationsDataSource()
        #expect(await source.status() == .notRequested)

        await source.requestAuthorization()

        #expect(await source.status() == .allowed)
    }

    @Test func faceIDIsAvailableAndAuthenticates() async throws {
        let source = SimulatedBiometricsDataSource()

        #expect(source.availability() == .available(.faceID))
        try await source.authenticate()
    }

    @Test func theHistoryRemembersARequestInMemory() async throws {
        let history = InMemoryPermissionHistoryDataSource()
        #expect(await history.hasRequestedBiometrics() == false)

        await history.recordBiometricsRequested()

        #expect(await history.hasRequestedBiometrics())
    }

    @MainActor
    @Test func openingSettingsDoesNothing() async {
        await SimulatedSystemSettingsDataSource().openSettings()
    }

    @Test func theSimulatedRepositoryAllowsEverythingItsAskedFor() async throws {
        let repository = LivePermissionsRepository.simulated()
        var permissions = repository.permissions().makeAsyncIterator()
        #expect(
            await permissions.next()
                == Permissions(health: .notRequested, notifications: .notRequested, biometrics: .notRequested(.faceID)))

        try await repository.requestHealthAccess()
        try await repository.requestNotifications()
        try await repository.requestBiometrics()

        _ = await permissions.next()
        _ = await permissions.next()
        #expect(
            await permissions.next()
                == Permissions(health: .requested, notifications: .allowed, biometrics: .allowed(.faceID)))
    }
}
