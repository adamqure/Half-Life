//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests LiveCurrentTimeRepositoryTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the current time repository against the Drink Composer article: requirements TIME-1 and TIME-2.
struct LiveCurrentTimeRepositoryTests {

    let start = Date(timeIntervalSinceReferenceDate: 0)

    // MARK: - TIME-1: now() is the data source's time

    @Test func nowIsTheDataSourcesTime() {
        let repository = LiveCurrentTimeRepository(dataSource: FakeClockDataSource(date: start, minuteDates: []))

        #expect(repository.now() == start)
    }

    // MARK: - TIME-2: currentTime() streams the data source's minutes, in order

    @Test func streamsTheDataSourcesMinutesInOrder() async {
        let minutes = [start, start.addingTimeInterval(60), start.addingTimeInterval(120)]
        let repository = LiveCurrentTimeRepository(dataSource: FakeClockDataSource(date: start, minuteDates: minutes))

        var received: [Date] = []
        for await date in repository.currentTime() {
            received.append(date)
        }

        #expect(received == minutes)
    }
}
