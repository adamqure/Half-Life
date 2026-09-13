//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests CutoffReminderFeatureTests
//

import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// Checks the cutoff reminder's reducer against REMINDER-1 to REMINDER-5 in the Cutoff Reminder article, with its use
/// cases overridden. The calendar is UTC and the locale is US English, so the reminder's text is known.
@MainActor
struct CutoffReminderFeatureTests {

    struct ScheduleFailed: Error {}

    static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()
    static let latte = FavouriteDrink(type: .latte, quantity: 2)
    static let tonight = CaffeineCutoff(drink: latte, latestCup: date(13), bedtime: date(22.5), threshold: .standard)
    static let tomorrow = CaffeineCutoff(drink: latte, latestCup: date(37), bedtime: date(46.5), threshold: .standard)
    static let noRoomTonight = CaffeineCutoff(drink: latte, latestCup: nil, bedtime: date(22.5), threshold: .standard)
    /// The approved wording, for a 10:30pm bedtime. iOS separates the time from "PM" with a narrow no-break space.
    static let body =
        "A Latte, 2 shots, now still clears by your 10:30\u{202F}PM bedtime. After this, caffeine will still be in "
        + "you when you go to bed."
    static let allowed = Permissions(health: .notRequested, notifications: .allowed, biometrics: .unavailable)
    static let denied = Permissions(health: .notRequested, notifications: .denied, biometrics: .unavailable)

    static func date(_ hours: Double) -> Date {
        Date(timeIntervalSinceReferenceDate: hours * 3_600)
    }

    static func reminder(at latestCup: Date) -> CutoffReminder {
        CutoffReminder(date: latestCup, title: "Last cup", body: body)
    }

    func makeStore(
        _ state: CutoffReminderFeature.State = CutoffReminderFeature.State(), upcoming: [[CaffeineCutoff]] = [],
        permissions: [Permissions] = [], reminders: FakeCutoffReminderRepository
    ) -> TestStoreOf<CutoffReminderFeature> {
        TestStore(initialState: state) {
            CutoffReminderFeature()
        } withDependencies: {
            $0.calendar = Self.utc
            $0.locale = Locale(identifier: "en_US")
            $0.observeUpcomingCutoffs = ObserveUpcomingCutoffsUseCase(
                repository: FakeCaffeineDecayRepository(upcoming: { nights, calendar in
                    nights == 7 && calendar == Self.utc ? upcoming : []
                }))
            $0.observePermissions = ObservePermissionsUseCase(
                repository: FakePermissionsRepository(streamed: permissions))
            $0.scheduleCutoffReminders = ScheduleCutoffRemindersUseCase(repository: reminders)
        }
    }

    // MARK: - REMINDER-1 and REMINDER-2: a reminder at each of the next seven nights' cutoffs

    @Test func taskSchedulesAReminderAtEachUpcomingCutoff() async {
        let reminders = FakeCutoffReminderRepository()
        let store = makeStore(upcoming: [[Self.tonight, Self.tomorrow]], reminders: reminders)

        await store.send(.task)
        await store.receive(\.upcomingCutoffsUpdated) {
            $0.cutoffs = [Self.tonight, Self.tomorrow]
        }
        await store.finish()

        #expect(await reminders.scheduled == [[Self.reminder(at: Self.date(13)), Self.reminder(at: Self.date(37))]])
    }

    @Test func taskReducesEachNotificationPermissionIntoState() async {
        let reminders = FakeCutoffReminderRepository()
        let store = makeStore(permissions: [Self.denied, Self.allowed], reminders: reminders)

        await store.send(.task)
        await store.receive(\.permissionsUpdated) {
            $0.notifications = .denied
        }
        await store.receive(\.permissionsUpdated) {
            $0.notifications = .allowed
        }
        await store.finish()

        // No cutoffs have arrived, so there's nothing to schedule.
        #expect(await reminders.scheduled.isEmpty)
    }

    // MARK: - REMINDER-3: a night with no room left gets no reminder

    @Test func aNightWithNoRoomLeftGetsNoReminder() async {
        let reminders = FakeCutoffReminderRepository()
        let store = makeStore(reminders: reminders)

        await store.send(.upcomingCutoffsUpdated([Self.noRoomTonight, Self.tomorrow])) {
            $0.cutoffs = [Self.noRoomTonight, Self.tomorrow]
        }
        await store.finish()

        #expect(await reminders.scheduled == [[Self.reminder(at: Self.date(37))]])
    }

    // MARK: - REMINDER-4: a change of notification permission schedules the last cutoffs again

    @Test func aChangedNotificationPermissionSchedulesTheLastCutoffsAgain() async {
        let reminders = FakeCutoffReminderRepository()
        let state = CutoffReminderFeature.State(cutoffs: [Self.tonight], notifications: .denied)
        let store = makeStore(state, reminders: reminders)

        await store.send(.permissionsUpdated(Self.allowed)) {
            $0.notifications = .allowed
        }
        await store.finish()

        #expect(await reminders.scheduled == [[Self.reminder(at: Self.date(13))]])
    }

    /// The first permission to arrive, and one that hasn't changed, schedule nothing. The cutoffs were scheduled with
    /// the permission the repository read itself.
    @Test func theFirstPermissionAndAnUnchangedOneScheduleNothing() async {
        let reminders = FakeCutoffReminderRepository()
        let store = makeStore(CutoffReminderFeature.State(cutoffs: [Self.tonight]), reminders: reminders)

        await store.send(.permissionsUpdated(Self.allowed)) {
            $0.notifications = .allowed
        }
        await store.send(
            .permissionsUpdated(Permissions(health: .requested, notifications: .allowed, biometrics: .unavailable)))
        await store.finish()

        #expect(await reminders.scheduled.isEmpty)
    }

    @Test func aPermissionChangeBeforeAnyCutoffsSchedulesNothing() async {
        let reminders = FakeCutoffReminderRepository()
        let store = makeStore(CutoffReminderFeature.State(notifications: .denied), reminders: reminders)

        await store.send(.permissionsUpdated(Self.allowed)) {
            $0.notifications = .allowed
        }
        await store.finish()

        #expect(await reminders.scheduled.isEmpty)
    }

    // MARK: - REMINDER-5: a failure to schedule is logged, and changes nothing

    @Test func aFailedScheduleChangesNothing() async {
        let reminders = FakeCutoffReminderRepository(scheduleError: ScheduleFailed())
        let store = makeStore(reminders: reminders)

        await store.send(.upcomingCutoffsUpdated([Self.tonight])) {
            $0.cutoffs = [Self.tonight]
        }
        await store.finish()

        #expect(await reminders.scheduled == [[Self.reminder(at: Self.date(13))]])
    }
}
