//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests SleepDetailFeatureTests
//

import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// Checks the Sleep screen against SLEEPSCREEN-1 to SLEEPSCREEN-3 in the Insights article.
@MainActor
struct SleepDetailFeatureTests {

    static func night(_ milligrams: Double, minutesToFallAsleep: Double? = nil) -> SleepCaffeineNight {
        SleepCaffeineNight(
            sleepOnset: Date(timeIntervalSinceReferenceDate: 0), asleepSeconds: 7 * 3_600,
            secondsToFallAsleep: minutesToFallAsleep.map { $0 * 60 }, caffeineAtOnset: milligrams)
    }

    static func analysis(
        _ nights: [SleepCaffeineNight], tolerance: SleepTolerance? = nil
    ) -> SleepCaffeineAnalysis {
        let empty = SleepCaffeineAnalysis.empty()
        return SleepCaffeineAnalysis(
            nights: nights, tolerance: tolerance, timeAsleep: nil, timeToFallAsleep: nil, period: empty.period,
            days: empty.days, isDemo: false)
    }

    // MARK: - SLEEPSCREEN-1: `task` subscribes to the analysis, and each is reduced into State

    @Test func taskReducesEachAnalysisIntoState() async {
        let first = SleepCaffeineAnalysis.empty()
        let second = SleepCaffeineAnalysis.empty(isDemo: true)
        let store = TestStore(initialState: SleepDetailFeature.State()) {
            SleepDetailFeature()
        } withDependencies: {
            $0.observeSleepCaffeineAnalysis = ObserveSleepCaffeineAnalysisUseCase(
                repository: FakeSleepToleranceRepository(analyses: [first, second]))
        }

        await store.send(.task)
        await store.receive(\.analysisUpdated) {
            $0.analysis = first
        }
        await store.receive(\.analysisUpdated) {
            $0.analysis = second
        }
        await store.finish()
    }

    // MARK: - SLEEPSCREEN-2: the finding is the tolerance, no drop, or too few nights either side of the threshold

    @Test func beforeTheFirstAnalysisThereIsNoFinding() {
        #expect(SleepDetailFeature.State().finding == nil)
    }

    @Test func withAToleranceTheFindingIsTheTolerance() {
        let tolerance = SleepTolerance(milligrams: 55, nightsUnder: 5, nightsOver: 5)
        let nights = (0..<5).map { _ in Self.night(10) } + (0..<5).map { _ in Self.night(90) }

        let state = SleepDetailFeature.State(analysis: Self.analysis(nights, tolerance: tolerance))

        #expect(state.finding == .tolerance(tolerance))
    }

    @Test func withFiveNightsEitherSideAndNoToleranceTheFindingIsNoDrop() {
        let nights = (0..<5).map { _ in Self.night(40) } + (0..<5).map { _ in Self.night(41) }

        #expect(SleepDetailFeature.State(analysis: Self.analysis(nights)).finding == .noDrop)
    }

    @Test func withFewerThanFiveNightsOnASideTheFindingCountsBothSides() {
        let nights = (0..<7).map { _ in Self.night(10) } + (0..<4).map { _ in Self.night(60) }

        #expect(
            SleepDetailFeature.State(analysis: Self.analysis(nights)).finding == .tooFewNights(under: 7, over: 4))
    }

    // MARK: - SLEEPSCREEN-3: the time to fall asleep needs time in bed

    @Test func theTimeToFallAsleepCountsOnlyNightsWithTimeInBed() {
        let nights = [Self.night(10, minutesToFallAsleep: 12), Self.night(60), Self.night(60, minutesToFallAsleep: 30)]

        let state = SleepDetailFeature.State(analysis: Self.analysis(nights))

        #expect(state.nightsWithTimeInBed == 2)
        #expect(SleepDetailFeature.State(analysis: Self.analysis([Self.night(10)])).nightsWithTimeInBed == 0)
    }
}
