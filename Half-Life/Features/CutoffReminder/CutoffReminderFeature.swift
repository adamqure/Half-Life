//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life CutoffReminderFeature
//

import ComposableArchitecture
import Foundation
import OSLog

/// The cutoff reminder: a local notification at each of the next seven nights' cutoffs. It has no screen.
///
/// It observes the upcoming cutoffs and the permissions, and reduces each into `State`. For each new set of cutoffs,
/// it writes a reminder for every night with a cutoff, and schedules them through ``ScheduleCutoffRemindersUseCase``.
/// When the notification permission changes, it schedules the last cutoffs again. ``AppFeature`` runs it, and
/// ``AppView`` starts it. The bedtime is formatted in the calendar and locale dependencies. See the Cutoff Reminder
/// article.
@Reducer nonisolated struct CutoffReminderFeature {
    /// How many nights the reminders are scheduled for: tonight and the six after it.
    static let nights = 7

    private static let logger = Logger(for: CutoffReminderFeature.self)

    private enum CancelID {
        case schedule
    }

    /// What the reminder knows.
    @ObservableState
    struct State: Equatable {
        /// The upcoming cutoffs, tonight's first, or `nil` until the first arrive.
        var cutoffs: [CaffeineCutoff]?
        /// Whether notifications are allowed, or `nil` until the permissions first arrive.
        var notifications: NotificationPermission?
    }

    /// What can happen to the reminder.
    enum Action {
        /// Subscribes to the upcoming cutoffs and the permissions, for as long as the app's UI runs.
        case task
        /// The decay repository published the upcoming cutoffs.
        case upcomingCutoffsUpdated([CaffeineCutoff])
        /// The permissions repository published the permissions.
        case permissionsUpdated(Permissions)
    }

    @Dependency(\.calendar) private var calendar
    @Dependency(\.locale) private var locale
    @Dependency(\.observeUpcomingCutoffs) private var observeUpcomingCutoffs
    @Dependency(\.observePermissions) private var observePermissions
    @Dependency(\.scheduleCutoffReminders) private var scheduleCutoffReminders

    /// Starts both observations, and schedules the reminders for each set of cutoffs, and again when the notification
    /// permission changes.
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                let input = ObserveUpcomingCutoffsUseCase.Input(nights: Self.nights, calendar: calendar)
                return .merge(
                    .run { [observeUpcomingCutoffs] send in
                        for await cutoffs in observeUpcomingCutoffs.execute(input) {
                            await send(.upcomingCutoffsUpdated(cutoffs))
                        }
                    },
                    .run { [observePermissions] send in
                        for await permissions in observePermissions.execute(()) {
                            await send(.permissionsUpdated(permissions))
                        }
                    }
                )
            case let .upcomingCutoffsUpdated(cutoffs):
                state.cutoffs = cutoffs
                return schedule(cutoffs)
            case let .permissionsUpdated(permissions):
                let previous = state.notifications
                state.notifications = permissions.notifications
                // The repository reads the permission itself on every schedule, so only a change matters.
                guard let previous, previous != permissions.notifications, let cutoffs = state.cutoffs else {
                    return .none
                }
                return schedule(cutoffs)
            }
        }
    }

    /// Schedules a reminder at each of `cutoffs` that has one, replacing any schedule still in flight.
    private func schedule(_ cutoffs: [CaffeineCutoff]) -> Effect<Action> {
        let reminders = cutoffs.compactMap(reminder(for:))
        return .run { [scheduleCutoffReminders] _ in
            try await scheduleCutoffReminders.execute(reminders)
        } catch: { error, _ in
            let domain = (error as NSError).domain
            let code = (error as NSError).code
            Self.logger.error(
                "Couldn't schedule the cutoff reminders: \(domain, privacy: .public) \(code, privacy: .public)")
        }
        .cancellable(id: CancelID.schedule, cancelInFlight: true)
    }

    /// The reminder at `cutoff`'s latest cup, or `nil` when there's none, in the wording the owner approved.
    private func reminder(for cutoff: CaffeineCutoff) -> CutoffReminder? {
        guard let latestCup = cutoff.latestCup else { return nil }
        var name = cutoff.drink.type.displayName
        name.locale = locale
        var quantity = cutoff.drink.type.unit.quantityText(cutoff.drink.quantity)
        quantity.locale = locale
        let drink = String(localized: name)
        let amount = String(localized: quantity)
        let bedtime = cutoff.bedtime.formatted(
            Date.FormatStyle(date: .omitted, time: .shortened, locale: locale, calendar: calendar,
                timeZone: calendar.timeZone))
        return CutoffReminder(
            date: latestCup,
            title: String(localized: "Last cup", locale: locale),
            body: String(
                localized: """
                    A \(drink), \(amount), now still clears by your \(bedtime) bedtime. After this, caffeine will \
                    still be in you when you go to bed.
                    """,
                locale: locale,
                comment: """
                    The cutoff reminder's notification, at the latest time the usual drink still fits before bedtime. \
                    The arguments are the drink's name, such as "Latte", its quantity, such as "2 shots", and the \
                    bedtime, such as "10:30 PM".
                    """))
    }
}
