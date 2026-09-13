//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life CutoffReminderDependencies
//

import ComposableArchitecture

extension DependencyValues {
    /// The app's cutoff reminder repository (constitution Article I.15).
    ///
    /// Live, it's one app-scoped ``LiveCutoffReminderRepository`` over UserNotifications and the system clock, or over
    /// the simulated data sources when a UI test launched the app, so no test schedules a real notification. Previews
    /// use the simulated data sources too. In tests, using it without overriding it reports an issue.
    var cutoffReminderRepository: any CutoffReminderRepository {
        get { self[CutoffReminderRepositoryKey.self] }
        set { self[CutoffReminderRepositoryKey.self] = newValue }
    }

    /// Schedules the cutoff reminders through the app-scoped ``cutoffReminderRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var scheduleCutoffReminders: ScheduleCutoffRemindersUseCase {
        get { self[ScheduleCutoffRemindersUseCaseKey.self] }
        set { self[ScheduleCutoffRemindersUseCaseKey.self] = newValue }
    }
}

/// Registers the app-scoped cutoff reminder repository. It's private, because only the use case in this file is built
/// from it.
private enum CutoffReminderRepositoryKey: DependencyKey {
    static let liveValue: any CutoffReminderRepository =
        UITestLaunchConfiguration.current.isUITest
        ? LiveCutoffReminderRepository.simulated()
        : LiveCutoffReminderRepository(
            reminders: UserNotificationsReminderDataSource(), notifications: UserNotificationsAuthorizationDataSource(),
            clock: SystemClockDataSource())
    static let previewValue: any CutoffReminderRepository = LiveCutoffReminderRepository.simulated()
    static let testValue: any CutoffReminderRepository = UnimplementedCutoffReminderRepository()
}

// Built from the repository key's values directly, not through `@Dependency`, following the Architecture article's
// "Registering a repository and its use cases".
private enum ScheduleCutoffRemindersUseCaseKey: DependencyKey {
    static let liveValue = ScheduleCutoffRemindersUseCase(repository: CutoffReminderRepositoryKey.liveValue)
    static let previewValue = ScheduleCutoffRemindersUseCase(repository: CutoffReminderRepositoryKey.previewValue)
    static let testValue = ScheduleCutoffRemindersUseCase(repository: CutoffReminderRepositoryKey.testValue)
}

/// The cutoff reminder repository in tests that haven't overridden it. Using it reports an issue.
private struct UnimplementedCutoffReminderRepository: CutoffReminderRepository {
    func reminders() -> AsyncStream<[CutoffReminder]> {
        reportIssue("A test observed the cutoff reminders without overriding \\.cutoffReminderRepository.")
        return AsyncStream { $0.finish() }
    }

    func schedule(_ reminders: [CutoffReminder]) async throws {
        reportIssue("A test scheduled cutoff reminders without overriding \\.cutoffReminderRepository.")
    }
}
