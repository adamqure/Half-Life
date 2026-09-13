//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life CutoffReminderDataSource
//

/// Schedules the cutoff reminders as local notifications, and reads back the ones scheduled.
///
/// An implementation is the only code that touches the system's scheduled notifications (constitution Article I.14).
/// See the Cutoff Reminder article.
protocol CutoffReminderDataSource: Sendable {
    /// Returns the cutoff reminders scheduled and not yet delivered, soonest first.
    func scheduled() async -> [CutoffReminder]

    /// Replaces every scheduled cutoff reminder with `reminders`, leaving any other notification alone.
    ///
    /// - Parameter reminders: The reminders to deliver, each at its date.
    /// - Throws: An error if a reminder couldn't be scheduled.
    func replace(with reminders: [CutoffReminder]) async throws
}
