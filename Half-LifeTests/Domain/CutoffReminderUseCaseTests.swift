//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests CutoffReminderUseCaseTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the cutoff reminder's use cases: OBSUPCOMING-1 and SCHEDREMIND-1 in the Cutoff Reminder article.
struct CutoffReminderUseCaseTests {

    struct ScheduleFailed: Error {}

    static let bedtime = Date(timeIntervalSinceReferenceDate: 22.5 * 3_600)
    static let latte = FavouriteDrink(type: .latte, quantity: 2)
    static let tonight = CaffeineCutoff(
        drink: latte, latestCup: Date(timeIntervalSinceReferenceDate: 13 * 3_600), bedtime: bedtime,
        threshold: .standard)
    static let tomorrow = CaffeineCutoff(
        drink: latte, latestCup: Date(timeIntervalSinceReferenceDate: 37 * 3_600),
        bedtime: bedtime.addingTimeInterval(86_400), threshold: .standard)
    static let reminder = CutoffReminder(
        date: Date(timeIntervalSinceReferenceDate: 13 * 3_600), title: "Last cup", body: "A latte now still fits.")

    // MARK: - OBSUPCOMING-1: the upcoming cutoffs the repository publishes for the nights and the calendar

    @Test func observeUpcomingCutoffsStreamsWhatTheRepositoryPublishesForTheNightsAndCalendar() async throws {
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let tokyoTimeZone = tokyo.timeZone
        let repository = FakeCaffeineDecayRepository(upcoming: { nights, calendar in
            nights == 7 && calendar.timeZone == tokyoTimeZone ? [[Self.tonight], [Self.tonight, Self.tomorrow]] : []
        })
        let observe = ObserveUpcomingCutoffsUseCase(repository: repository)

        var received: [[CaffeineCutoff]] = []
        for await cutoffs in try await executeThroughProtocol(observe, .init(nights: 7, calendar: tokyo)) {
            received.append(cutoffs)
        }

        #expect(received == [[Self.tonight], [Self.tonight, Self.tomorrow]])
    }

    // MARK: - SCHEDREMIND-1: scheduling hands the reminders to the repository

    @Test func scheduleCutoffRemindersHandsTheRemindersToTheRepository() async throws {
        let repository = FakeCutoffReminderRepository()

        try await executeThroughProtocol(ScheduleCutoffRemindersUseCase(repository: repository), [Self.reminder])

        #expect(await repository.scheduled == [[Self.reminder]])
    }

    @Test func scheduleCutoffRemindersThrowsTheRepositorysError() async {
        let repository = FakeCutoffReminderRepository(scheduleError: ScheduleFailed())

        await #expect(throws: ScheduleFailed.self) {
            try await ScheduleCutoffRemindersUseCase(repository: repository).execute([Self.reminder])
        }
    }
}
