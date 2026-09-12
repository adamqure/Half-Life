//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests CaffeineIntakeTodayFeatureTests
//

import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// Checks that the "Today" tile reduces the intakes it observes (TILE-1 in the Today Screen article).
@MainActor
struct CaffeineIntakeTodayFeatureTests {

    /// TILE-1: `task` subscribes to today's intake in the calendar dependency, and each intake is reduced into
    /// `State`.
    @Test func taskReducesEachIntakeInTheCalendarIntoState() async throws {
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let tokyoTimeZone = tokyo.timeZone
        let morning = DailyCaffeineIntake(day: Date(timeIntervalSinceReferenceDate: 0), milligrams: 128)
        let afternoon = DailyCaffeineIntake(day: Date(timeIntervalSinceReferenceDate: 0), milligrams: 192)
        let repository = FakeDrinkLogRepository(intakes: { $0.timeZone == tokyoTimeZone ? [morning, afternoon] : [] })
        let store = TestStore(initialState: CaffeineIntakeTodayFeature.State()) {
            CaffeineIntakeTodayFeature()
        } withDependencies: {
            $0.calendar = tokyo
            $0.observeCaffeineIntakeToday = ObserveCaffeineIntakeTodayUseCase(repository: repository)
        }

        await store.send(.task)
        await store.receive(\.intakeUpdated) {
            $0.intake = morning
        }
        await store.receive(\.intakeUpdated) {
            $0.intake = afternoon
        }
        await store.finish()
    }
}
