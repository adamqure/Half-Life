//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests LiveCutoffReminderRepositoryTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the live cutoff reminder repository against REMINDREPO-1 to REMINDREPO-5 in the Cutoff Reminder article,
/// with a fake reminder data source, notification permission, and clock. The clock stands at 9:00am. The time limit
/// turns a value that never arrives into a failure instead of a hang.
@Suite(.timeLimit(.minutes(1)))
struct LiveCutoffReminderRepositoryTests {

    struct ReplaceFailed: Error {}

    static let now = Date(timeIntervalSinceReferenceDate: 9 * 3_600)

    static func reminder(_ hours: Double) -> CutoffReminder {
        CutoffReminder(
            date: Date(timeIntervalSinceReferenceDate: hours * 3_600), title: "Last cup", body: "At hour \(hours)")
    }

    static func repository(
        _ source: FakeCutoffReminderDataSource, notifications: NotificationPermission = .allowed
    ) -> LiveCutoffReminderRepository {
        LiveCutoffReminderRepository(
            reminders: source, notifications: FakeNotificationAuthorizationDataSource(status: notifications),
            clock: FakeClockDataSource(date: now, minuteDates: []))
    }

    // MARK: - REMINDREPO-1: a new subscriber gets the reminders already scheduled

    @Test func aNewSubscriberGetsTheRemindersAlreadyScheduled() async {
        let source = FakeCutoffReminderDataSource(scheduled: [Self.reminder(13)])

        var reminders = Self.repository(source).reminders().makeAsyncIterator()

        #expect(await reminders.next() == [Self.reminder(13)])
    }

    // MARK: - REMINDREPO-2: scheduling replaces every reminder with those still to come, and publishes them

    @Test func schedulingReplacesTheRemindersWithThoseStillToComeAndPublishesThem() async throws {
        let source = FakeCutoffReminderDataSource()
        let repository = Self.repository(source)
        var reminders = repository.reminders().makeAsyncIterator()
        #expect(await reminders.next() == [])

        try await repository.schedule([Self.reminder(8), Self.reminder(9), Self.reminder(13), Self.reminder(37)])

        #expect(await source.replacements == [[Self.reminder(13), Self.reminder(37)]])
        #expect(await reminders.next() == [Self.reminder(13), Self.reminder(37)])
    }

    // MARK: - REMINDREPO-3: without notification permission, scheduling removes every reminder

    @Test(arguments: [NotificationPermission.notRequested, .denied])
    func withoutPermissionSchedulingRemovesEveryReminder(permission: NotificationPermission) async throws {
        let source = FakeCutoffReminderDataSource(scheduled: [Self.reminder(13)])
        let repository = Self.repository(source, notifications: permission)
        var reminders = repository.reminders().makeAsyncIterator()
        _ = await reminders.next()

        try await repository.schedule([Self.reminder(37)])

        #expect(await source.replacements == [[]])
        #expect(await reminders.next() == [])
    }

    // MARK: - REMINDREPO-4: a failed replacement throws, and publishes nothing

    @Test func aFailedReplacementThrowsAndPublishesNothing() async throws {
        let source = FakeCutoffReminderDataSource(replaceError: ReplaceFailed())
        let repository = Self.repository(source)
        var reminders = repository.reminders().makeAsyncIterator()
        _ = await reminders.next()

        await #expect(throws: ReplaceFailed.self) {
            try await repository.schedule([Self.reminder(13)])
        }
        await source.failReplacements(with: nil)
        try await repository.schedule([Self.reminder(37)])

        // The next value published is the one after the second schedule, so the failed one published nothing.
        #expect(await reminders.next() == [Self.reminder(37)])
    }

    // MARK: - REMINDREPO-5: scheduling the same reminders again publishes nothing

    @Test func schedulingTheSameRemindersAgainPublishesNothing() async throws {
        let source = FakeCutoffReminderDataSource()
        let repository = Self.repository(source)
        var reminders = repository.reminders().makeAsyncIterator()
        _ = await reminders.next()

        try await repository.schedule([Self.reminder(13)])
        try await repository.schedule([Self.reminder(13)])
        try await repository.schedule([Self.reminder(37)])

        #expect(await reminders.next() == [Self.reminder(13)])
        #expect(await reminders.next() == [Self.reminder(37)])
    }
}
