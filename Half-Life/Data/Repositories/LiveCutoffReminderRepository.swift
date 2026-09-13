//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life LiveCutoffReminderRepository
//

import Foundation
import OSLog

/// The live cutoff reminder repository: the source of truth for the reminders scheduled at the user's caffeine
/// cutoffs.
///
/// It schedules through its ``CutoffReminderDataSource``, only when its ``NotificationAuthorizationDataSource`` says
/// notifications are allowed, and only the reminders its ``ClockDataSource`` says are still to come. It publishes the
/// scheduled reminders to a new subscriber at once, reading them from the data source the first time, and to every
/// subscriber whenever they change. It's an actor, off the main actor (constitution Article I.13). The Cutoff Reminder
/// article lists its requirements, REMINDREPO-1 to REMINDREPO-5.
actor LiveCutoffReminderRepository: CutoffReminderRepository {
    private static let logger = Logger(for: LiveCutoffReminderRepository.self)

    private let source: any CutoffReminderDataSource
    private let notifications: any NotificationAuthorizationDataSource
    private let clock: any ClockDataSource
    private var subscribers: [UUID: AsyncStream<[CutoffReminder]>.Continuation] = [:]
    private var current: [CutoffReminder]?

    /// Creates the repository.
    ///
    /// - Parameters:
    ///   - reminders: Schedules the reminders, and reads back the ones scheduled.
    ///   - notifications: Reads whether notifications are allowed.
    ///   - clock: The current time, which a reminder has to be after.
    init(
        reminders: any CutoffReminderDataSource, notifications: any NotificationAuthorizationDataSource,
        clock: any ClockDataSource
    ) {
        source = reminders
        self.notifications = notifications
        self.clock = clock
    }

    /// Streams the scheduled reminders: the current ones as soon as it's subscribed to, then each change.
    nonisolated func reminders() -> AsyncStream<[CutoffReminder]> {
        let (stream, continuation) = AsyncStream.makeStream(of: [CutoffReminder].self)
        let id = UUID()
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeSubscriber(id) }
        }
        Task { await addSubscriber(id, continuation) }
        return stream
    }

    /// Replaces every scheduled reminder with those of `reminders` still to come, or with none when notifications
    /// aren't allowed, then publishes them if they changed.
    ///
    /// - Parameter reminders: The reminders to deliver.
    /// - Throws: The data source's error if they couldn't be scheduled. Nothing is published then.
    func schedule(_ reminders: [CutoffReminder]) async throws {
        let isAllowed = await notifications.status() == .allowed
        let now = clock.now()
        let upcoming = isAllowed ? reminders.filter { $0.date > now } : []
        do {
            try await source.replace(with: upcoming)
        } catch {
            let domain = (error as NSError).domain
            let code = (error as NSError).code
            Self.logger.error(
                "Couldn't schedule the cutoff reminders: \(domain, privacy: .public) \(code, privacy: .public)")
            throw error
        }
        // Rescheduling follows a logged drink, so its time is health data: `debug` only (constitution Article XI.7).
        if isAllowed {
            Self.logger.debug("Scheduled the cutoff reminders.")
        } else {
            Self.logger.debug("Removed the cutoff reminders, because notifications aren't allowed.")
        }
        publish(upcoming)
    }

    /// Sends the new subscriber the current reminders, reading them from the data source the first time.
    private func addSubscriber(_ id: UUID, _ continuation: AsyncStream<[CutoffReminder]>.Continuation) async {
        let scheduled = await source.scheduled()
        // A schedule that finished while the data source was being read is newer than what it read.
        let reminders = current ?? scheduled
        current = reminders
        subscribers[id] = continuation
        continuation.yield(reminders)
    }

    private func removeSubscriber(_ id: UUID) {
        subscribers[id] = nil
    }

    /// Publishes `reminders` to every subscriber, if they differ from the current ones.
    private func publish(_ reminders: [CutoffReminder]) {
        guard reminders != current else { return }
        current = reminders
        for subscriber in subscribers.values {
            subscriber.yield(reminders)
        }
    }
}
