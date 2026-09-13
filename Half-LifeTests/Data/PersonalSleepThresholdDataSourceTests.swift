//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests PersonalSleepThresholdDataSourceTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the threshold data source that serves the user's tolerance to the decay model (TOLSRC-1 to TOLSRC-3 in the
/// Insights article), and that the standard one never changes (THRESH-4 in the Caffeine Cutoff article).
@Suite(.timeLimit(.minutes(1)))
struct PersonalSleepThresholdDataSourceTests {

    static let tolerance = SleepTolerance(milligrams: 55, nightsUnder: 17, nightsOver: 9)

    // MARK: - TOLSRC-1: a stored tolerance is the threshold

    @Test func aStoredToleranceIsTheThreshold() async throws {
        let source = PersonalSleepThresholdDataSource(tolerances: FakeSleepToleranceDataSource(stored: Self.tolerance))

        #expect(try await source.threshold().milligrams == 55)
    }

    // MARK: - TOLSRC-2: without one, or when it can't be read, the threshold is the standard one

    @Test func withNoToleranceTheThresholdIsTheStandardOne() async throws {
        let source = PersonalSleepThresholdDataSource(tolerances: FakeSleepToleranceDataSource())

        #expect(try await source.threshold() == .standard)
    }

    @Test func aToleranceThatCantBeReadGivesTheStandardThreshold() async throws {
        let tolerances = FakeSleepToleranceDataSource(stored: Self.tolerance, readError: FakeDataSourceError())

        #expect(try await PersonalSleepThresholdDataSource(tolerances: tolerances).threshold() == .standard)
    }

    // MARK: - TOLSRC-3: it signals when a tolerance is stored

    @Test func storingAToleranceSignalsAChange() async throws {
        let tolerances = FakeSleepToleranceDataSource()
        var changes = await PersonalSleepThresholdDataSource(tolerances: tolerances).changes().makeAsyncIterator()

        try await tolerances.store(Self.tolerance)

        #expect(await changes.next() != nil)
    }

    // MARK: - THRESH-4: the standard threshold never changes

    @Test func theStandardThresholdsChangesFinishAtOnce() async {
        var changes = await StandardSleepThresholdDataSource().changes().makeAsyncIterator()

        #expect(await changes.next() == nil)
    }
}
