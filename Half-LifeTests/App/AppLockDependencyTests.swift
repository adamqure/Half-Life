//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests AppLockDependencyTests
//

import ComposableArchitecture
import Testing

@testable import Half_Life

/// Checks the app lock's registrations (DEP-LOCK in the App Lock article) and the simulated data sources that UI tests
/// and previews use (LOCKSIM-1).
@Suite(.timeLimit(.minutes(1)))
struct AppLockDependencyTests {

    // MARK: - DEP-LOCK

    /// Each app lock use case holds the one app-scoped app lock repository, and turning on also holds the permissions
    /// repository.
    @Test func previewAppLockUseCasesUseTheAppScopedRepositories() {
        withDependencies {
            $0.context = .preview
        } operation: {
            @Dependency(\.appLockRepository) var repository
            @Dependency(\.permissionsRepository) var permissions
            @Dependency(\.observeAppLock) var observeAppLock
            @Dependency(\.turnOnAppLock) var turnOnAppLock
            @Dependency(\.turnOffAppLock) var turnOffAppLock
            @Dependency(\.lockApp) var lockApp
            @Dependency(\.unlockApp) var unlockApp

            #expect((observeAppLock.repository as AnyObject) === (repository as AnyObject))
            #expect((turnOnAppLock.appLock as AnyObject) === (repository as AnyObject))
            #expect((turnOnAppLock.permissions as AnyObject) === (permissions as AnyObject))
            #expect((turnOffAppLock.repository as AnyObject) === (repository as AnyObject))
            #expect((lockApp.repository as AnyObject) === (repository as AnyObject))
            #expect((unlockApp.repository as AnyObject) === (repository as AnyObject))
        }
    }

    /// Using an app lock use case in a test that hasn't overridden it reports an issue.
    @Test func testUseCasesReportAnIssue() async {
        await withKnownIssue {
            @Dependency(\.observeAppLock) var observeAppLock
            for await _ in observeAppLock.execute(()) {}
        }
        await withKnownIssue {
            @Dependency(\.turnOnAppLock) var turnOnAppLock
            try await turnOnAppLock.execute(())
        }
        await withKnownIssue {
            @Dependency(\.turnOffAppLock) var turnOffAppLock
            try await turnOffAppLock.execute(())
        }
        await withKnownIssue {
            @Dependency(\.lockApp) var lockApp
            await lockApp.execute(())
        }
        await withKnownIssue {
            @Dependency(\.unlockApp) var unlockApp
            try await unlockApp.execute(())
        }
    }

    // MARK: - LOCKSIM-1: the simulated lock starts off, and its user declines the first prompt, then passes

    @Test func theSimulatedSettingStartsOffAndRemembersAChange() async throws {
        let setting = InMemoryAppLockSettingDataSource()
        #expect(await setting.isEnabled() == false)

        await setting.setEnabled(true)

        #expect(await setting.isEnabled())
    }

    @Test func theSimulatedUserDeclinesTheFirstPromptThenPasses() async throws {
        let authentication = SimulatedDeviceOwnerDataSource()

        #expect(await authentication.authenticate() == .declined)
        #expect(await authentication.authenticate() == .passed)
        #expect(await authentication.authenticate() == .passed)
    }

    @Test func theSimulatedRepositoryStartsWithTheLockOff() async {
        var locks = LiveAppLockRepository.simulated().appLock().makeAsyncIterator()

        #expect(await locks.next() == AppLock(isEnabled: false, isLocked: false))
    }

    // MARK: - LOCKSIM-2: a held launch's setting doesn't answer, so the app stays on its splash screen

    @Test func theHeldSettingAnswersOnlyWhenCancelled() async {
        let setting = HeldAppLockSettingDataSource()
        let answer = Task { try await setting.isEnabled() }

        try? await Task.sleep(for: .milliseconds(100))
        answer.cancel()

        await #expect(throws: CancellationError.self) { try await answer.value }
    }
}
