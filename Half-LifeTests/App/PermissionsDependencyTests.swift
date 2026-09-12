//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests PermissionsDependencyTests
//

import ComposableArchitecture
import Testing

@testable import Half_Life

/// Checks the permissions repository's and use cases' registrations (constitution Article I.15).
struct PermissionsDependencyTests {

    /// DEP-1: in previews, the repository is a live repository, over simulated data sources.
    @Test func previewPermissionsRepositoryIsALiveRepository() {
        withDependencies {
            $0.context = .preview
        } operation: {
            @Dependency(\.permissionsRepository) var repository
            #expect(repository is LivePermissionsRepository)
        }
    }

    /// DEP-3: every use case holds the one app-scoped repository.
    @Test func previewUseCasesUseTheAppScopedRepository() {
        withDependencies {
            $0.context = .preview
        } operation: {
            @Dependency(\.permissionsRepository) var repository
            @Dependency(\.observePermissions) var observe
            @Dependency(\.requestHealthAccess) var requestHealth
            @Dependency(\.requestNotificationPermission) var requestNotifications
            @Dependency(\.requestBiometricPermission) var requestBiometrics
            @Dependency(\.refreshPermissions) var refresh
            @Dependency(\.openAppSettings) var openSettings
            let expected = repository as AnyObject
            #expect((observe.repository as AnyObject) === expected)
            #expect((requestHealth.repository as AnyObject) === expected)
            #expect((requestNotifications.repository as AnyObject) === expected)
            #expect((requestBiometrics.repository as AnyObject) === expected)
            #expect((refresh.repository as AnyObject) === expected)
            #expect((openSettings.repository as AnyObject) === expected)
        }
    }

    /// DEP-2: a test that observes the permissions without overriding the repository fails.
    @Test func testPermissionsRepositoryReportsAnIssueWhenObserved() async {
        await withKnownIssue {
            @Dependency(\.permissionsRepository) var repository
            for await _ in repository.permissions() {}
        }
    }

    /// DEP-2: a test that sends any command without overriding the repository fails.
    @Test func testPermissionsRepositoryReportsAnIssueForEachCommand() async {
        @Dependency(\.permissionsRepository) var repository
        await withKnownIssue {
            try await repository.requestHealthAccess()
        }
        await withKnownIssue {
            try await repository.requestNotifications()
        }
        await withKnownIssue {
            try await repository.requestBiometrics()
        }
        await withKnownIssue {
            await repository.refresh()
        }
        await withKnownIssue {
            await repository.openSettings()
        }
    }
}
