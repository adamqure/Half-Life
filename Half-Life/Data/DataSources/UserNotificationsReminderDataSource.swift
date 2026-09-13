//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life UserNotificationsReminderDataSource
//

import Foundation
import UserNotifications

/// Schedules the cutoff reminders as local notifications, through the current notification center.
///
/// Each reminder is a request whose identifier starts with ``identifierPrefix``, so replacing the reminders leaves
/// every other request alone. It's delivered once, at the reminder's date, with the default sound. The system shows it
/// only while Half-Life isn't in the foreground, where the "Last cup" tile already shows the cutoff. See the Cutoff
/// Reminder article.
nonisolated struct UserNotificationsReminderDataSource: CutoffReminderDataSource {
    /// What every cutoff reminder's identifier starts with.
    static let identifierPrefix = "cutoffReminder."

    /// The calendar a reminder's trigger is written in. Its time zone is fixed, so the trigger names the same moment
    /// wherever the user travels.
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()

    /// Reads the notification center's pending requests.
    let pending: @Sendable () async -> [UNNotificationRequest]
    /// Adds a request to the notification center.
    let add: @Sendable (UNNotificationRequest) async throws -> Void
    /// Removes the pending requests with the given identifiers.
    let remove: @Sendable ([String]) -> Void

    /// Creates the data source.
    ///
    /// - Parameters:
    ///   - pending: Reads the pending requests. Defaults to the current notification center's.
    ///   - add: Adds a request. Defaults to the current notification center.
    ///   - remove: Removes pending requests. Defaults to the current notification center.
    init(
        pending: @escaping @Sendable () async -> [UNNotificationRequest] = {
            await UNUserNotificationCenter.current().pendingNotificationRequests()
        },
        add: @escaping @Sendable (UNNotificationRequest) async throws -> Void = {
            try await UNUserNotificationCenter.current().add($0)
        },
        remove: @escaping @Sendable ([String]) -> Void = {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: $0)
        }
    ) {
        self.pending = pending
        self.add = add
        self.remove = remove
    }

    /// Returns the pending cutoff reminders, soonest first.
    func scheduled() async -> [CutoffReminder] {
        await pending()
            .filter { $0.identifier.hasPrefix(Self.identifierPrefix) }
            .compactMap(Self.reminder(from:))
            .sorted { $0.date < $1.date }
    }

    /// Removes every pending cutoff reminder, then adds a request for each of `reminders`.
    ///
    /// - Parameter reminders: The reminders to deliver.
    /// - Throws: The notification center's error if it refused a request.
    func replace(with reminders: [CutoffReminder]) async throws {
        remove(await pending().map(\.identifier).filter { $0.hasPrefix(Self.identifierPrefix) })
        for reminder in reminders {
            try await add(Self.request(for: reminder))
        }
    }

    /// The request that delivers `reminder`: once, at its date, with its title, its body, and the default sound.
    ///
    /// - Parameter reminder: The reminder to deliver.
    static func request(for reminder: CutoffReminder) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.body
        content.sound = .default
        let components = calendar.dateComponents(
            [.calendar, .timeZone, .year, .month, .day, .hour, .minute, .second], from: reminder.date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        return UNNotificationRequest(
            identifier: identifierPrefix + reminder.date.formatted(.iso8601), content: content, trigger: trigger)
    }

    /// The reminder a pending request delivers, or `nil` if its trigger isn't at a date.
    private static func reminder(from request: UNNotificationRequest) -> CutoffReminder? {
        guard let trigger = request.trigger as? UNCalendarNotificationTrigger, let date = trigger.dateComponents.date
        else { return nil }
        return CutoffReminder(date: date, title: request.content.title, body: request.content.body)
    }
}
