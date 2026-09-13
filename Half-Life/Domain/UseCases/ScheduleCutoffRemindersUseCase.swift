//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life ScheduleCutoffRemindersUseCase
//

/// Schedules the reminders at the user's caffeine cutoffs, replacing every reminder scheduled before.
///
/// See the Cutoff Reminder article.
nonisolated struct ScheduleCutoffRemindersUseCase: UseCase {
    /// The repository that owns the reminders.
    let repository: any CutoffReminderRepository

    /// Schedules `reminders`.
    ///
    /// - Parameter reminders: The reminders to deliver.
    /// - Throws: The repository's error if they couldn't be scheduled.
    func execute(_ reminders: [CutoffReminder]) async throws {
        try await repository.schedule(reminders)
    }
}
