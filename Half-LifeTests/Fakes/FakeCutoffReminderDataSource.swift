//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FakeCutoffReminderDataSource
//

import Foundation

@testable import Half_Life

/// A cutoff reminder data source for repository tests. It holds the scheduled reminders in memory, and records every
/// replacement that succeeds. A test can make replacements fail, and succeed again, with `failReplacements(with:)`.
actor FakeCutoffReminderDataSource: CutoffReminderDataSource {
    /// The reminders scheduled now.
    private(set) var current: [CutoffReminder]
    /// Each successful replacement's reminders, in order.
    private(set) var replacements: [[CutoffReminder]] = []
    private var replaceError: (any Error)?

    init(scheduled: [CutoffReminder] = [], replaceError: (any Error)? = nil) {
        current = scheduled
        self.replaceError = replaceError
    }

    /// Makes every later replacement throw `error`, or succeed again when it's `nil`.
    func failReplacements(with error: (any Error)?) {
        replaceError = error
    }

    func scheduled() -> [CutoffReminder] {
        current
    }

    func replace(with reminders: [CutoffReminder]) throws {
        if let replaceError { throw replaceError }
        replacements.append(reminders)
        current = reminders
    }
}
