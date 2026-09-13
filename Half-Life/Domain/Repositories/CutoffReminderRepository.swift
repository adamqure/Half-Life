//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life CutoffReminderRepository
//

/// The source of truth for the reminders scheduled at the user's caffeine cutoffs.
///
/// The reminders are system state: local notifications, scheduled through a data source. An implementation schedules
/// only when notifications are allowed, and only the reminders that are still to come. The Cutoff Reminder article
/// lists its requirements, REMINDREPO-1 to REMINDREPO-5.
///
/// It isn't marked `nonisolated`: an actor that conforms to a `nonisolated` protocol in the same module inherits
/// `nonisolated`, which an actor can't be (constitution Article IV.1).
protocol CutoffReminderRepository: Sendable {
    /// Streams the scheduled reminders: the current ones as soon as it's subscribed to, then each change.
    func reminders() -> AsyncStream<[CutoffReminder]>

    /// Replaces every scheduled reminder with those of `reminders` that are still to come. When notifications aren't
    /// allowed, it removes every reminder instead.
    ///
    /// - Parameter reminders: The reminders to deliver, at the cutoffs of the next several nights.
    /// - Throws: An error if the reminders couldn't be scheduled.
    func schedule(_ reminders: [CutoffReminder]) async throws
}
