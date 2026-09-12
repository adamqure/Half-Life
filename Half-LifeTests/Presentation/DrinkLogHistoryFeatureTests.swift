//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests DrinkLogHistoryFeatureTests
//

import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// Checks the history card's reducer against HIST-1 to HIST-10 in the Today Screen article, with an exhaustive
/// `TestStore` and every use case built on fakes.
@MainActor
struct DrinkLogHistoryFeatureTests {

    struct DeleteFailed: Error {}

    // Immutable Sendable values, so the default arguments and the fake's closure can read them off the main actor.
    nonisolated static let midnight = Date(timeIntervalSinceReferenceDate: 0)
    nonisolated static let yesterdayMidnight = midnight.addingTimeInterval(-86_400)
    nonisolated static let tomorrowMidnight = midnight.addingTimeInterval(86_400)
    /// 4:00pm today.
    nonisolated static let now = midnight.addingTimeInterval(16 * 3_600)
    nonisolated static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()

    nonisolated static func drink(_ milligrams: Double, hours: Double) -> LoggedDrink {
        let consumedAt = midnight.addingTimeInterval(hours * 3_600)
        return LoggedDrink(type: .espresso, quantity: 1, milligrams: milligrams, consumedAt: consumedAt)
    }

    nonisolated static let yesterday = drink(95, hours: -2)
    nonisolated static let morning = drink(128, hours: 8)
    nonisolated static let lateMorning = drink(64, hours: 10.75)
    nonisolated static let today = DrinkLogDay(
        intake: DailyCaffeineIntake(day: midnight, milligrams: 192), drinks: [morning, lateMorning])
    nonisolated static let yesterdaysDay = DrinkLogDay(
        intake: DailyCaffeineIntake(day: yesterdayMidnight, milligrams: 95), drinks: [yesterday])

    /// Today's and yesterday's days, by their midnight. Any other day publishes nothing.
    nonisolated static func days(_ date: Date, _ calendar: Calendar) -> [DrinkLogDay] {
        switch date {
        case midnight: [today]
        case yesterdayMidnight: [yesterdaysDay]
        default: []
        }
    }

    /// The state once today and its drinks have arrived.
    static let showingToday = DrinkLogHistoryFeature.State(today: midnight, selectedDay: midnight, day: today)

    static func store(
        _ initialState: DrinkLogHistoryFeature.State = DrinkLogHistoryFeature.State(),
        repository: FakeDrinkLogRepository = FakeDrinkLogRepository(days: days),
        time: any CurrentTimeRepository = SilentCurrentTimeRepository()
    ) -> TestStoreOf<DrinkLogHistoryFeature> {
        TestStore(initialState: initialState) {
            DrinkLogHistoryFeature()
        } withDependencies: {
            $0.calendar = utc
            $0.observeTimeOfDay = ObserveTimeOfDayUseCase(currentTime: time)
            $0.observeDrinkLogDay = ObserveDrinkLogDayUseCase(repository: repository)
            $0.deleteDrink = DeleteDrinkUseCase(drinkLog: repository)
        }
    }

    // MARK: - HIST-1: the card opens on today, and shows its drinks and total

    @Test func taskShowsTodayAndItsDrinks() async {
        let store = Self.store(time: FakeCurrentTimeRepository(date: Self.now))

        await store.send(.task)
        await store.receive(\.timeOfDayUpdated) {
            $0.today = Self.midnight
            $0.selectedDay = Self.midnight
        }
        await store.receive(\.dayUpdated) {
            $0.day = Self.today
        }
        await store.finish()
    }

    /// When the view comes back, `task` observes the day it was showing again.
    @Test func taskObservesTheSelectedDayAgain() async {
        let store = Self.store(DrinkLogHistoryFeature.State(today: Self.midnight, selectedDay: Self.midnight))

        await store.send(.task)
        await store.receive(\.dayUpdated) {
            $0.day = Self.today
        }
        await store.finish()
    }

    @Test func leavingTheScreenStopsObservingTheDay() async {
        let store = Self.store(Self.showingToday)

        await store.send(.disappeared)
    }

    // MARK: - HIST-2: the buttons move a day back and forward, never past today

    @Test func previousAndNextMoveADayAtATime() async {
        let store = Self.store(Self.showingToday)

        await store.send(.previousDayTapped) {
            $0.selectedDay = Self.yesterdayMidnight
            $0.daysAgo = 1
        }
        await store.receive(\.dayUpdated) {
            $0.day = Self.yesterdaysDay
        }
        await store.send(.nextDayTapped) {
            $0.selectedDay = Self.midnight
            $0.daysAgo = 0
        }
        await store.receive(\.dayUpdated) {
            $0.day = Self.today
        }
        await store.finish()
    }

    @Test func nextDoesNothingOnToday() async {
        let store = Self.store(Self.showingToday)

        await store.send(.nextDayTapped)
    }

    @Test func previousDoesNothingBeforeTheFirstDayArrives() async {
        let store = Self.store()

        await store.send(.previousDayTapped)
    }

    // MARK: - HIST-3: at midnight, today moves on, and a past day stays put

    @Test func atMidnightTodayMovesToTheNewDay() async {
        let store = Self.store(Self.showingToday)

        await store.send(.timeOfDayUpdated(TimeOfDay(date: Self.tomorrowMidnight, period: .evening))) {
            $0.today = Self.tomorrowMidnight
            $0.selectedDay = Self.tomorrowMidnight
        }
        await store.finish()
    }

    @Test func atMidnightAPastDayStaysAndIsADayFurtherBack() async {
        let store = Self.store(
            DrinkLogHistoryFeature.State(
                today: Self.midnight, selectedDay: Self.yesterdayMidnight, daysAgo: 1, day: Self.yesterdaysDay))

        await store.send(.timeOfDayUpdated(TimeOfDay(date: Self.tomorrowMidnight, period: .evening))) {
            $0.today = Self.tomorrowMidnight
            $0.daysAgo = 2
        }
    }

    @Test func aNewMinuteOnTheSameDayChangesNothing() async {
        let store = Self.store(Self.showingToday)

        await store.send(.timeOfDayUpdated(TimeOfDay(date: Self.now.addingTimeInterval(60), period: .afternoon)))
    }

    // MARK: - HIST-4: a day other than the one showing is ignored

    @Test func aDayOtherThanTheOneShowingIsIgnored() async {
        let store = Self.store(Self.showingToday)

        await store.send(.dayUpdated(Self.yesterdaysDay))
    }

    // MARK: - HIST-5: deleting asks first, and only a confirmed deletion reaches the use case

    @Test func confirmingADeletionDeletesTheDrink() async {
        let repository = FakeDrinkLogRepository(days: Self.days)
        let store = Self.store(Self.showingToday, repository: repository)

        await store.send(.deleteTapped(Self.morning.id)) {
            $0.pendingDeletion = Self.morning.id
        }
        await store.send(.deleteConfirmed) {
            $0.pendingDeletion = nil
        }
        await store.finish()

        #expect(await repository.deleted == [Self.morning.id])
    }

    @Test func cancellingADeletionKeepsTheDrink() async {
        let repository = FakeDrinkLogRepository(days: Self.days)
        let store = Self.store(Self.showingToday, repository: repository)

        await store.send(.deleteTapped(Self.morning.id)) {
            $0.pendingDeletion = Self.morning.id
        }
        await store.send(.deleteCancelled) {
            $0.pendingDeletion = nil
        }
        await store.finish()

        #expect(await repository.deleted.isEmpty)
    }

    @Test func confirmingWithNothingPendingDoesNothing() async {
        let repository = FakeDrinkLogRepository(days: Self.days)
        let store = Self.store(Self.showingToday, repository: repository)

        await store.send(.deleteConfirmed)
        await store.finish()

        #expect(await repository.deleted.isEmpty)
    }

    // MARK: - HIST-6: a failed deletion shows an error until the next attempt

    @Test func aFailedDeletionShowsAnErrorUntilTheNextAttempt() async {
        let store = Self.store(
            Self.showingToday, repository: FakeDrinkLogRepository(days: Self.days, deleteError: DeleteFailed()))

        await store.send(.deleteTapped(Self.morning.id)) {
            $0.pendingDeletion = Self.morning.id
        }
        await store.send(.deleteConfirmed) {
            $0.pendingDeletion = nil
        }
        await store.receive(\.deletionFailed) {
            $0.deletionFailed = true
        }
        await store.send(.deleteTapped(Self.morning.id)) {
            $0.pendingDeletion = Self.morning.id
            $0.deletionFailed = false
        }
    }

    // MARK: - HIST-7: a pending deletion ends when its drink leaves the day, or the day changes

    @Test func aDrinkLeavingTheDayEndsItsPendingDeletion() async {
        var state = Self.showingToday
        state.pendingDeletion = Self.morning.id
        let store = Self.store(state)
        let withoutMorning = DrinkLogDay(
            intake: DailyCaffeineIntake(day: Self.midnight, milligrams: 64), drinks: [Self.lateMorning])

        await store.send(.dayUpdated(withoutMorning)) {
            $0.day = withoutMorning
            $0.pendingDeletion = nil
        }
    }

    @Test func changingTheDayEndsAPendingDeletion() async {
        var state = Self.showingToday
        state.pendingDeletion = Self.morning.id
        let store = Self.store(state)

        await store.send(.previousDayTapped) {
            $0.selectedDay = Self.yesterdayMidnight
            $0.daysAgo = 1
            $0.pendingDeletion = nil
        }
        await store.receive(\.dayUpdated) {
            $0.day = Self.yesterdaysDay
        }
        await store.finish()
    }

    // MARK: - HIST-8: the title names today, yesterday, or the date, and Next shows only after today

    @Test func titleNamesTheDay() {
        var state = DrinkLogHistoryFeature.State()
        #expect(state.title == nil)

        state = Self.showingToday
        #expect(state.title == .today)
        #expect(!state.canShowNextDay)

        state.selectedDay = Self.yesterdayMidnight
        state.daysAgo = 1
        #expect(state.title == .yesterday)
        #expect(state.canShowNextDay)

        let twoDaysAgo = Self.midnight.addingTimeInterval(-2 * 86_400)
        state.selectedDay = twoDaysAgo
        state.daysAgo = 2
        #expect(state.title == .date(twoDaysAgo))
    }

    // MARK: - HIST-9: Today returns to today from an earlier day, and is offered only there

    @Test func todayReturnsToTodayFromAnEarlierDay() async {
        let twoDaysAgo = Self.midnight.addingTimeInterval(-2 * 86_400)
        let store = Self.store(DrinkLogHistoryFeature.State(today: Self.midnight, selectedDay: twoDaysAgo, daysAgo: 2))

        await store.send(.todayTapped) {
            $0.selectedDay = Self.midnight
            $0.daysAgo = 0
        }
        await store.receive(\.dayUpdated) {
            $0.day = Self.today
        }
        await store.finish()
    }

    @Test func todayDoesNothingOnToday() async {
        let store = Self.store(Self.showingToday)

        await store.send(.todayTapped)
    }

    @Test func todayIsOfferedOnlyOnAnEarlierDay() {
        var state = Self.showingToday
        #expect(!state.canShowToday)

        state.selectedDay = Self.yesterdayMidnight
        state.daysAgo = 1
        #expect(state.canShowToday)
    }

    // MARK: - HIST-10: changing the day keeps the day showing in place until the next one arrives

    @Test func changingTheDayKeepsTheLastDayUntilTheNextArrives() async {
        let store = Self.store(Self.showingToday)
        #expect(store.state.showsSelectedDay)

        await store.send(.previousDayTapped) {
            $0.selectedDay = Self.yesterdayMidnight
            $0.daysAgo = 1
        }
        #expect(store.state.day == Self.today)
        #expect(!store.state.showsSelectedDay)
        await store.receive(\.dayUpdated) {
            $0.day = Self.yesterdaysDay
        }
        #expect(store.state.showsSelectedDay)
        await store.finish()
    }
}
