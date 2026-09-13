//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests UserNotificationsReminderDataSourceTests
//

import Foundation
import Testing
import UserNotifications

@testable import Half_Life

/// Checks how ``UserNotificationsReminderDataSource`` schedules and reads the cutoff reminders, through stand-ins for
/// the notification center, so no test schedules a real notification (REMINDSRC-1 to REMINDSRC-4 in the Cutoff
/// Reminder article).
struct UserNotificationsReminderDataSourceTests {

    struct AddFailed: Error {}

    /// 1:00pm UTC on 1 January 2001.
    static let reminder = CutoffReminder(
        date: Date(timeIntervalSinceReferenceDate: 13 * 3_600), title: "Last cup", body: "Tonight's body")
    static let tomorrow = CutoffReminder(
        date: Date(timeIntervalSinceReferenceDate: 37 * 3_600), title: "Last cup", body: "Tomorrow's body")
    static let other = UNNotificationRequest(
        identifier: "somethingElse", content: UNMutableNotificationContent(), trigger: nil)

    static func dataSource(
        pending: [UNNotificationRequest] = [], added: Recorded<[UNNotificationRequest]> = Recorded([]),
        removed: Recorded<[String]> = Recorded([]), addError: (any Error)? = nil
    ) -> UserNotificationsReminderDataSource {
        UserNotificationsReminderDataSource(
            pending: { pending },
            add: { request in
                added.update { $0.append(request) }
                if let addError { throw addError }
            },
            remove: { identifiers in removed.update { $0.append(contentsOf: identifiers) } })
    }

    // MARK: - REMINDSRC-1: each reminder becomes a request delivered once, at its date, with its text

    @Test func eachReminderBecomesARequestDeliveredOnceAtItsDate() async throws {
        let added = Recorded<[UNNotificationRequest]>([])

        try await Self.dataSource(added: added).replace(with: [Self.reminder, Self.tomorrow])

        #expect(added.value.count == 2)
        #expect(Set(added.value.map(\.identifier)).count == 2)
        let request = try #require(added.value.first)
        #expect(request.content.title == "Last cup")
        #expect(request.content.body == "Tonight's body")
        #expect(request.content.sound != nil)
        let trigger = try #require(request.trigger as? UNCalendarNotificationTrigger)
        #expect(!trigger.repeats)
        #expect(trigger.dateComponents.date == Self.reminder.date)
    }

    // MARK: - REMINDSRC-2: replacing removes every pending cutoff reminder, and nothing else

    @Test func replacingRemovesThePendingCutoffRemindersOnly() async throws {
        let stale = UserNotificationsReminderDataSource.request(for: Self.reminder)
        let removed = Recorded<[String]>([])

        try await Self.dataSource(pending: [Self.other, stale], removed: removed).replace(with: [])

        #expect(removed.value == [stale.identifier])
    }

    // MARK: - REMINDSRC-3: the scheduled reminders are the pending cutoff reminders, soonest first

    @Test func readsBackThePendingCutoffRemindersSoonestFirst() async {
        let pending = [
            UserNotificationsReminderDataSource.request(for: Self.tomorrow), Self.other,
            UserNotificationsReminderDataSource.request(for: Self.reminder),
        ]

        #expect(await Self.dataSource(pending: pending).scheduled() == [Self.reminder, Self.tomorrow])
    }

    // MARK: - REMINDSRC-4: a request the notification center refuses throws its error

    @Test func aRefusedRequestThrowsTheCentersError() async {
        await #expect(throws: AddFailed.self) {
            try await Self.dataSource(addError: AddFailed()).replace(with: [Self.reminder])
        }
    }
}
