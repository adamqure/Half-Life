//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FakeCutoffReminderRepository
//

import Foundation

@testable import Half_Life

/// A cutoff reminder repository for use case and reducer tests. It streams the reminders it's given, then finishes,
/// and records every set of reminders it's asked to schedule.
actor FakeCutoffReminderRepository: CutoffReminderRepository {
    /// The values that `reminders()` streams, in order.
    let streamed: [[CutoffReminder]]
    /// The error scheduling throws, if any.
    let scheduleError: (any Error)?
    /// Each set of reminders it was asked to schedule, in order.
    private(set) var scheduled: [[CutoffReminder]] = []

    init(streamed: [[CutoffReminder]] = [], scheduleError: (any Error)? = nil) {
        self.streamed = streamed
        self.scheduleError = scheduleError
    }

    nonisolated func reminders() -> AsyncStream<[CutoffReminder]> {
        AsyncStream { continuation in
            for reminders in streamed {
                continuation.yield(reminders)
            }
            continuation.finish()
        }
    }

    func schedule(_ reminders: [CutoffReminder]) throws {
        scheduled.append(reminders)
        if let scheduleError { throw scheduleError }
    }
}
