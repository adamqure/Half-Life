//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests LivePermissionsRepositoryTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the permissions repository against PERM-1, PERM-2, and PERM-4 in the Onboarding article, with fake data
/// sources.
@Suite(.timeLimit(.minutes(1)))
struct LivePermissionsRepositoryTests {

    struct Failed: Error {}

    /// The fakes behind one repository.
    struct Sources {
        var health = FakeHealthAuthorizationDataSource()
        var notifications = FakeNotificationAuthorizationDataSource()
        var biometrics = FakeBiometricAuthenticationDataSource()
        var history = FakePermissionHistoryDataSource()
        var settings = FakeSystemSettingsDataSource()

        var repository: LivePermissionsRepository {
            LivePermissionsRepository(
                health: health, notifications: notifications, biometrics: biometrics, history: history,
                settings: settings)
        }
    }

    static let nothingAsked = Permissions(
        health: .notRequested, notifications: .notRequested, biometrics: .notRequested(.faceID))

    // MARK: - PERM-1: the current permissions first, then each change

    @Test func aNewSubscriberGetsTheCurrentPermissions() async throws {
        let repository = Sources().repository

        var permissions = repository.permissions().makeAsyncIterator()

        #expect(await permissions.next() == Self.nothingAsked)
    }

    @Test func aRefreshPublishesOnlyWhenSomethingChanged() async throws {
        let sources = Sources()
        let repository = sources.repository
        var permissions = repository.permissions().makeAsyncIterator()
        _ = await permissions.next()

        await repository.refresh()
        await sources.notifications.set(.denied)
        await repository.refresh()

        // Had the first refresh published a duplicate, it would arrive here instead.
        let next = await permissions.next()
        #expect(next?.notifications == .denied)
    }

    @Test func everySubscriberGetsEachChange() async throws {
        let repository = Sources().repository
        var first = repository.permissions().makeAsyncIterator()
        var second = repository.permissions().makeAsyncIterator()
        _ = await first.next()
        _ = await second.next()

        try await repository.requestNotifications()

        #expect(await first.next()?.notifications == .allowed)
        #expect(await second.next()?.notifications == .allowed)
    }

    @Test func aNewSubscriberThatSeesAChangeTellsTheOthers() async throws {
        let sources = Sources()
        let repository = sources.repository
        var first = repository.permissions().makeAsyncIterator()
        _ = await first.next()

        await sources.notifications.set(.allowed)
        var second = repository.permissions().makeAsyncIterator()

        #expect(await second.next()?.notifications == .allowed)
        #expect(await first.next()?.notifications == .allowed)
    }

    // MARK: - PERM-2: Health is requested after its request, whatever the user chose

    @Test func requestingHealthAccessPublishesRequested() async throws {
        let sources = Sources()
        let repository = sources.repository
        var permissions = repository.permissions().makeAsyncIterator()
        _ = await permissions.next()

        try await repository.requestHealthAccess()

        #expect(await permissions.next()?.health == .requested)
        #expect(await sources.health.requestCount == 1)
    }

    @Test func aFailedHealthRequestThrowsAndStaysNotRequested() async throws {
        var sources = Sources()
        sources.health = FakeHealthAuthorizationDataSource(requestError: Failed())
        let repository = sources.repository
        var permissions = repository.permissions().makeAsyncIterator()
        _ = await permissions.next()

        await #expect(throws: Failed.self) {
            try await repository.requestHealthAccess()
        }
        await sources.notifications.set(.allowed)
        await repository.refresh()

        #expect(
            await permissions.next()
                == Permissions(
                    health: .notRequested, notifications: .allowed, biometrics: .notRequested(.faceID)))
    }

    // MARK: - Notifications

    @Test func requestingNotificationsPublishesWhatTheUserChose() async throws {
        var sources = Sources()
        sources.notifications = FakeNotificationAuthorizationDataSource(afterRequest: .denied)
        let repository = sources.repository
        var permissions = repository.permissions().makeAsyncIterator()
        _ = await permissions.next()

        try await repository.requestNotifications()

        #expect(await permissions.next()?.notifications == .denied)
        #expect(await sources.notifications.requestCount == 1)
    }

    @Test func aFailedNotificationRequestThrows() async {
        var sources = Sources()
        sources.notifications = FakeNotificationAuthorizationDataSource(requestError: Failed())

        await #expect(throws: Failed.self) {
            try await sources.repository.requestNotifications()
        }
    }

    // MARK: - PERM-4: Face ID isn't requested until it has been, even though it's available

    @Test func availableFaceIDIsNotRequestedUntilRequested() async throws {
        let sources = Sources()
        let repository = sources.repository
        var permissions = repository.permissions().makeAsyncIterator()
        #expect(await permissions.next()?.biometrics == .notRequested(.faceID))

        try await repository.requestBiometrics()

        #expect(await permissions.next()?.biometrics == .allowed(.faceID))
        #expect(sources.biometrics.authenticateCount == 1)
        #expect(await sources.history.recordCount == 1)
    }

    @Test func aDeniedPromptIsRecordedAndPublishedAsDenied() async throws {
        var sources = Sources()
        sources.biometrics = FakeBiometricAuthenticationDataSource(availabilityAfterAuthenticating: .denied(.faceID))
        let repository = sources.repository
        var permissions = repository.permissions().makeAsyncIterator()
        _ = await permissions.next()

        try await repository.requestBiometrics()

        #expect(await permissions.next()?.biometrics == .denied(.faceID))
        #expect(await sources.history.recordCount == 1)
    }

    @Test func aRequestedAvailableBiometryIsAllowed() async {
        var sources = Sources()
        sources.history = FakePermissionHistoryDataSource(requested: true)

        var permissions = sources.repository.permissions().makeAsyncIterator()

        #expect(await permissions.next()?.biometrics == .allowed(.faceID))
    }

    @Test func deniedNotEnrolledAndUnavailableBiometricsPassThrough() async {
        let cases: [(BiometricAvailability, BiometricPermission)] = [
            (.denied(.faceID), .denied(.faceID)), (.notEnrolled(.touchID), .notEnrolled(.touchID)),
            (.unavailable, .unavailable),
        ]
        for (availability, expected) in cases {
            var sources = Sources()
            sources.biometrics = FakeBiometricAuthenticationDataSource(availability: availability)
            sources.history = FakePermissionHistoryDataSource(requested: true)

            var permissions = sources.repository.permissions().makeAsyncIterator()

            #expect(await permissions.next()?.biometrics == expected)
        }
    }

    @Test func anUnreadableHistoryCountsAsNotRequested() async {
        var sources = Sources()
        sources.history = FakePermissionHistoryDataSource(requested: true, readError: Failed())

        var permissions = sources.repository.permissions().makeAsyncIterator()

        #expect(await permissions.next()?.biometrics == .notRequested(.faceID))
    }

    @Test func anUnexpectedBiometricErrorThrowsAndIsntRecorded() async {
        var sources = Sources()
        sources.biometrics = FakeBiometricAuthenticationDataSource(authenticateError: Failed())

        await #expect(throws: Failed.self) {
            try await sources.repository.requestBiometrics()
        }
        #expect(await sources.history.recordCount == 0)
    }

    @Test func aFailedRecordThrows() async {
        var sources = Sources()
        sources.history = FakePermissionHistoryDataSource(recordError: Failed())

        await #expect(throws: Failed.self) {
            try await sources.repository.requestBiometrics()
        }
    }

    // MARK: - Settings

    @Test func openingSettingsOpensTheSettingsApp() async {
        let sources = Sources()

        await sources.repository.openSettings()

        #expect(sources.settings.openCount == 1)
    }
}
