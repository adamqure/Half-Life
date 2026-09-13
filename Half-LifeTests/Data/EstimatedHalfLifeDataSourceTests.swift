//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests EstimatedHalfLifeDataSourceTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the half-life the decay model reads: the stored estimate's, or the survey's (ESTSRC-1 to ESTSRC-3 in the
/// Half-Life Estimator article).
@Suite(.timeLimit(.minutes(1)))
struct EstimatedHalfLifeDataSourceTests {

    static func halfLife(hours: Double) throws -> CaffeineHalfLife {
        try #require(CaffeineHalfLife(seconds: hours * 3_600))
    }

    static func estimate(hours: Double, prior: CaffeineHalfLife = .standard) throws -> HalfLifeEstimate {
        HalfLifeEstimate(
            halfLife: try halfLife(hours: hours), lowerBound: try halfLife(hours: hours - 1),
            upperBound: try halfLife(hours: hours + 1), prior: prior, nightsUsed: 21,
            calculatedAt: Date(timeIntervalSinceReferenceDate: 0))
    }

    // MARK: - ESTSRC-1: the estimate's half-life, when it came from the current survey

    @Test func anEstimateFromTheCurrentSurveyGivesItsHalfLife() async throws {
        let source = EstimatedHalfLifeDataSource(
            estimates: FakeHalfLifeEstimateDataSource(stored: try Self.estimate(hours: 7)),
            prior: FakeHalfLifeDataSource(value: .standard))

        #expect(try await source.halfLife() == (try Self.halfLife(hours: 7)))
    }

    // MARK: - ESTSRC-2: otherwise the survey's half-life

    @Test func withNoEstimateItsTheSurveysHalfLife() async throws {
        let source = EstimatedHalfLifeDataSource(
            estimates: FakeHalfLifeEstimateDataSource(), prior: FakeHalfLifeDataSource(value: .standard))

        #expect(try await source.halfLife() == .standard)
    }

    @Test func anEstimateFromAnOlderSurveyIsIgnored() async throws {
        let lengthened = try Self.halfLife(hours: 8.25)
        let source = EstimatedHalfLifeDataSource(
            estimates: FakeHalfLifeEstimateDataSource(stored: try Self.estimate(hours: 7)),
            prior: FakeHalfLifeDataSource(value: lengthened))

        #expect(try await source.halfLife() == lengthened)
    }

    @Test func anEstimateThatCantBeReadGivesTheSurveysHalfLife() async throws {
        let source = EstimatedHalfLifeDataSource(
            estimates: FakeHalfLifeEstimateDataSource(readError: FakeDataSourceError()),
            prior: FakeHalfLifeDataSource(value: .standard))

        #expect(try await source.halfLife() == .standard)
    }

    // MARK: - ESTSRC-3: it signals when either the estimate or the survey changes

    @Test func signalsWhenTheEstimateChanges() async {
        let estimates = FakeHalfLifeEstimateDataSource()
        let source = EstimatedHalfLifeDataSource(estimates: estimates, prior: FakeHalfLifeDataSource(value: .standard))

        var changes = await source.changes().makeAsyncIterator()
        await estimates.signalChange()

        #expect(await changes.next() != nil)
    }

    @Test func signalsWhenTheSurveyChanges() async throws {
        let prior = FakeHalfLifeDataSource(value: .standard)
        let source = EstimatedHalfLifeDataSource(estimates: FakeHalfLifeEstimateDataSource(), prior: prior)

        var changes = await source.changes().makeAsyncIterator()
        await prior.change(to: try Self.halfLife(hours: 8.25))

        #expect(await changes.next() != nil)
    }
}
