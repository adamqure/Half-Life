//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests LastSevenDaysFeatureTests
//

import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// Checks the last 7 days card against WEEKCARD-1 to WEEKCARD-4 in the Insights article.
///
/// The card observes two streams, the drinks and the sleep, whose values can arrive in either order. So each test of
/// `task` gives one of them values and the other none.
@MainActor
struct LastSevenDaysFeatureTests {

    static func day(_ index: Int, milligrams: Double = 0) -> DrinkLogDay {
        DrinkLogDay(
            intake: DailyCaffeineIntake(
                day: Date(timeIntervalSinceReferenceDate: Double(index) * 86_400), milligrams: milligrams),
            drinks: [])
    }

    /// Seven days ending today, day 6.
    static let week = (0..<7).map { day($0, milligrams: Double($0) * 10) }
    /// The same week a day later: day 0 has gone, and day 7 is today.
    static let nextWeek = (1..<8).map { day($0, milligrams: Double($0) * 10) }

    /// WEEKCARD-1: `task` subscribes to the week in the calendar dependency, and each week is reduced into `State`.
    @Test func taskReducesEachWeekInTheCalendarIntoState() async throws {
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let tokyoTimeZone = tokyo.timeZone
        // The repository's 8 days to today lose today, so the card gets the 7 before it.
        let (toToday, toTomorrow) = (Self.week + [Self.day(7)], Self.nextWeek + [Self.day(8)])
        let repository = FakeDrinkLogRepository(recentDays: { count, calendar in
            count == 8 && calendar.timeZone == tokyoTimeZone ? [toToday, toTomorrow] : []
        })
        let store = TestStore(initialState: LastSevenDaysFeature.State()) {
            LastSevenDaysFeature()
        } withDependencies: {
            $0.calendar = tokyo
            $0.observeDrinkLogWeek = ObserveDrinkLogWeekUseCase(repository: repository)
            $0.observeSleepWeek = ObserveSleepWeekUseCase(repository: FakeHealthDataRepository())
        }

        await store.send(.task)
        await store.receive(\.daysUpdated) {
            $0.days = Self.week
        }
        await store.receive(\.daysUpdated) {
            $0.days = Self.nextWeek
        }
        await store.finish()
    }

    /// WEEKCARD-4: `task` also subscribes to the sleep week in the calendar dependency, and each history is reduced
    /// into `State`.
    @Test func taskReducesEachSleepHistoryInTheCalendarIntoState() async throws {
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let tokyoTimeZone = tokyo.timeZone
        let nights = Self.week.map { SleepHistoryNight(day: $0.intake.day, sleep: .asleep(seconds: 7 * 3_600)) }
        let history = SleepHistory(nights: nights, isDemo: true)
        // The repository's nights to tonight lose tonight's, so the card gets the 7 before it.
        let tonight = SleepHistoryNight(day: Self.day(7).intake.day, sleep: nil)
        let toTonight = SleepHistory(nights: nights + [tonight], isDemo: true)
        let health = FakeHealthDataRepository(histories: { days, calendar in
            days == 8 && calendar.timeZone == tokyoTimeZone ? [toTonight] : []
        })
        let store = TestStore(initialState: LastSevenDaysFeature.State()) {
            LastSevenDaysFeature()
        } withDependencies: {
            $0.calendar = tokyo
            $0.observeDrinkLogWeek = ObserveDrinkLogWeekUseCase(repository: FakeDrinkLogRepository())
            $0.observeSleepWeek = ObserveSleepWeekUseCase(repository: health)
        }

        await store.send(.task)
        await store.receive(\.sleepUpdated) {
            $0.sleep = history
        }
        await store.finish()
    }

    /// WEEKCARD-4: a day's night is the one the history holds for it, and there's none before the history arrives.
    @Test func eachDaysNightIsTheHistorysNightForIt() {
        let nights = Self.week.map { SleepHistoryNight(day: $0.intake.day, sleep: .asleep(seconds: 6 * 3_600)) }
        var state = LastSevenDaysFeature.State(days: Self.week)
        #expect(state.night(after: Self.week[2]) == nil)

        state.sleep = SleepHistory(nights: nights, isDemo: false)

        #expect(state.night(after: Self.week[2]) == nights[2])
    }

    /// WEEKCARD-2: with no day chosen, the selected day is the last, yesterday.
    @Test func withNoDayChosenTheLastDayIsSelected() {
        let state = LastSevenDaysFeature.State(days: Self.week)

        #expect(state.selected == Self.week[6])
        #expect(LastSevenDaysFeature.State().selected == nil)
    }

    /// WEEKCARD-3: choosing a day selects it, and once it's no longer in the week, the last day is selected again.
    @Test func choosingADaySelectsItUntilItLeavesTheWeek() async {
        let store = TestStore(initialState: LastSevenDaysFeature.State(days: Self.week)) {
            LastSevenDaysFeature()
        }

        await store.send(.daySelected(Self.week[0].intake.day)) {
            $0.selectedDay = Self.week[0].intake.day
        }
        #expect(store.state.selected == Self.week[0])

        await store.send(.daysUpdated(Self.nextWeek)) {
            $0.days = Self.nextWeek
        }
        #expect(store.state.selected == Self.nextWeek[6])
    }
}
