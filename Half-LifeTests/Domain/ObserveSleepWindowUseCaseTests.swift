//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests ObserveSleepWindowUseCaseTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks that observing the sleep window streams what the repository publishes for the given calendar (SWUSE-1 in
/// the Insights article).
struct ObserveSleepWindowUseCaseTests {

    @Test func streamsTheWindowsTheRepositoryPublishesForTheGivenCalendar() async throws {
        let tonight = SleepWindow(
            evening: Date(timeIntervalSinceReferenceDate: 18 * 3_600),
            bedtime: Date(timeIntervalSinceReferenceDate: 22.5 * 3_600),
            clearsAt: Date(timeIntervalSinceReferenceDate: 24.4 * 3_600),
            window: DateInterval(start: Date(timeIntervalSinceReferenceDate: 24.4 * 3_600), duration: 5_400),
            chartEnd: Date(timeIntervalSinceReferenceDate: 28 * 3_600), threshold: .standard, levels: [])
        let tomorrow = SleepWindow(
            evening: Date(timeIntervalSinceReferenceDate: 42 * 3_600),
            bedtime: Date(timeIntervalSinceReferenceDate: 46.5 * 3_600),
            clearsAt: Date(timeIntervalSinceReferenceDate: 42 * 3_600),
            window: DateInterval(start: Date(timeIntervalSinceReferenceDate: 46.5 * 3_600), duration: 5_400),
            chartEnd: Date(timeIntervalSinceReferenceDate: 52 * 3_600), threshold: .standard, levels: [])
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let tokyoTimeZone = tokyo.timeZone
        let repository = FakeCaffeineDecayRepository(sleepWindows: {
            $0.timeZone == tokyoTimeZone ? [tonight, tomorrow] : []
        })
        let observe = ObserveSleepWindowUseCase(repository: repository)

        var received: [SleepWindow] = []
        for await window in try await executeThroughProtocol(observe, tokyo) {
            received.append(window)
        }

        #expect(received == [tonight, tomorrow])
    }
}
