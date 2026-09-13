//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life SimulatedCutoffReminderDataSource
//

/// Cutoff reminders held in memory, for UI tests and previews, so neither schedules a real notification.
///
/// See the Cutoff Reminder article.
actor SimulatedCutoffReminderDataSource: CutoffReminderDataSource {
    private var reminders: [CutoffReminder] = []

    /// Returns the reminders it holds, soonest first.
    func scheduled() -> [CutoffReminder] {
        reminders.sorted { $0.date < $1.date }
    }

    /// Holds `reminders` in place of the ones before.
    func replace(with reminders: [CutoffReminder]) {
        self.reminders = reminders
    }
}

extension LiveCutoffReminderRepository {
    /// A repository over the simulated data sources, for UI tests and previews.
    ///
    /// Its notification permission starts not requested, as on a fresh install, so it schedules nothing.
    static func simulated() -> LiveCutoffReminderRepository {
        LiveCutoffReminderRepository(
            reminders: SimulatedCutoffReminderDataSource(), notifications: SimulatedNotificationsDataSource(),
            clock: SystemClockDataSource())
    }
}
