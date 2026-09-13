//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests SleepWindowFeatureTests
//

import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// Checks that the sleep window card reduces the windows it observes (SWCARD-1 in the Insights article).
@MainActor
struct SleepWindowFeatureTests {

    /// SWCARD-1: `task` subscribes to the window in the calendar dependency, and each window is reduced into `State`.
    @Test func taskReducesEachWindowInTheCalendarIntoState() async throws {
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let tokyoTimeZone = tokyo.timeZone
        let tonight = SleepWindow(
            evening: Date(timeIntervalSinceReferenceDate: 18 * 3_600),
            bedtime: Date(timeIntervalSinceReferenceDate: 22.5 * 3_600),
            clearsAt: Date(timeIntervalSinceReferenceDate: 24.4 * 3_600),
            window: DateInterval(start: Date(timeIntervalSinceReferenceDate: 24.4 * 3_600), duration: 5_400),
            chartEnd: Date(timeIntervalSinceReferenceDate: 28 * 3_600), threshold: .standard, levels: [])
        let later = SleepWindow(
            evening: tonight.evening, bedtime: tonight.bedtime, clearsAt: nil, window: nil,
            chartEnd: Date(timeIntervalSinceReferenceDate: 36 * 3_600), threshold: .standard, levels: [])
        let repository = FakeCaffeineDecayRepository(sleepWindows: {
            $0.timeZone == tokyoTimeZone ? [tonight, later] : []
        })
        let store = TestStore(initialState: SleepWindowFeature.State()) {
            SleepWindowFeature()
        } withDependencies: {
            $0.calendar = tokyo
            $0.observeSleepWindow = ObserveSleepWindowUseCase(repository: repository)
        }

        await store.send(.task)
        await store.receive(\.windowUpdated) {
            $0.window = tonight
        }
        await store.receive(\.windowUpdated) {
            $0.window = later
        }
        await store.finish()
    }
}
