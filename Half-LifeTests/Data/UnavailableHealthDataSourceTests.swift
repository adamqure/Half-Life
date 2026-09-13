//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests UnavailableHealthDataSourceTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the stand-in for Apple Health that previews and UI tests use (NOHEALTH-1 in the Half-Life Estimator
/// article).
struct UnavailableHealthDataSourceTests {

    let source = UnavailableHealthDataSource()
    let today = Date(timeIntervalSinceReferenceDate: 802_137_600)

    // MARK: - NOHEALTH-1: it has no data and never changes

    @Test func hasNoSleep() async throws {
        let range = DateInterval(start: today.addingTimeInterval(-90 * 86_400), end: today)

        #expect(try await source.sleepIntervals(in: range).isEmpty)
    }

    @Test func hasNoSteps() async throws {
        #expect(try await source.stepCount(on: today) == nil)
    }

    @Test func hasNoRestingHeartRate() async throws {
        #expect(try await source.averageRestingHeartRate(on: today) == nil)
    }

    @Test func itsSleepNeverChanges() async {
        var changes = source.changes().makeAsyncIterator()

        #expect(await changes.next() == nil)
    }
}
