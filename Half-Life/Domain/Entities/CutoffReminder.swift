//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life CutoffReminder
//

import Foundation

/// A notification delivered at a caffeine cutoff: the latest time the user's usual drink still leaves no more than
/// the sleep threshold in the body at bedtime.
///
/// ``CutoffReminderFeature`` writes its text from a ``CaffeineCutoff``, and ``CutoffReminderRepository`` schedules it.
/// See the Cutoff Reminder article.
nonisolated struct CutoffReminder: Sendable, Equatable {
    /// When it's delivered: the cutoff.
    let date: Date
    /// Its title, already localized.
    let title: String
    /// Its body, already localized.
    let body: String
}
