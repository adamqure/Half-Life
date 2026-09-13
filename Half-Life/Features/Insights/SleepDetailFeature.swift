//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life SleepDetailFeature
//

import ComposableArchitecture
import Foundation

/// The Insights tab's Sleep screen: the user's time asleep, and the time they took to fall asleep, against the
/// caffeine in them at sleep onset, over the last 30 days, and the caffeine tolerance those nights show.
///
/// It observes the analysis, and reduces each one into `State`. ``Action/task`` starts the observation, for as long as
/// the screen is on the tab's navigation stack. See the Insights article.
@Reducer nonisolated struct SleepDetailFeature {
    /// What the screen says about the user's time asleep.
    enum Finding: Equatable {
        /// The nights show a tolerance, which the cutoff now uses.
        case tolerance(SleepTolerance)
        /// There are 5 nights on each side of the threshold, but time asleep doesn't drop with caffeine.
        case noDrop
        /// There are too few nights on one side of the threshold to say: how many are at or under it, and over it.
        case tooFewNights(under: Int, over: Int)
    }

    /// How the time to fall asleep compares on the nights over the threshold in use, against the nights at or under it.
    enum FallingAsleep: Equatable {
        /// Longer over the threshold, by more than ``SleepDetailFeature/fallingAsleepBand``.
        case longer
        /// Shorter over the threshold, by more than ``SleepDetailFeature/fallingAsleepBand``.
        case shorter
        /// Within ``SleepDetailFeature/fallingAsleepBand`` either way.
        case aboutTheSame
        /// Not comparable yet: fewer than 5 nights with time in bed on either side.
        case unknown
    }

    /// The least difference in the average time to fall asleep that the screen names as longer or shorter: 5 minutes.
    /// The owner chose it on 2026-09-13.
    static let fallingAsleepBand: TimeInterval = 5 * 60

    /// What the screen shows.
    @ObservableState
    struct State: Equatable {
        /// The analysis of the user's nights, or `nil` until the first one arrives.
        var analysis: SleepCaffeineAnalysis?

        /// What the screen says about the user's time asleep, or `nil` until the first analysis arrives.
        var finding: Finding? {
            guard let analysis else { return nil }
            if let tolerance = analysis.tolerance {
                return .tolerance(tolerance)
            }
            let threshold = analysis.threshold.milligrams
            let over = analysis.nights.filter { $0.caffeineAtOnset > threshold }.count
            let under = analysis.nights.count - over
            let minimum = SleepToleranceRule.minimumNightsEachSide
            return under >= minimum && over >= minimum ? .noDrop : .tooFewNights(under: under, over: over)
        }

        /// How many nights have the time the user got into bed, so their time to fall asleep is known.
        var nightsWithTimeInBed: Int {
            analysis?.nights.filter { $0.secondsToFallAsleep != nil }.count ?? 0
        }

        /// How the time to fall asleep compares over the threshold in use, against at or under it.
        var fallingAsleep: FallingAsleep {
            guard let comparison = analysis?.timeToFallAsleep else { return .unknown }
            let difference = comparison.overSeconds - comparison.underSeconds
            if difference > SleepDetailFeature.fallingAsleepBand { return .longer }
            if difference < -SleepDetailFeature.fallingAsleepBand { return .shorter }
            return .aboutTheSame
        }
    }

    /// What can happen on the screen.
    enum Action {
        /// Subscribes to the analysis, for as long as the screen is shown.
        case task
        /// The sleep tolerance repository published an analysis.
        case analysisUpdated(SleepCaffeineAnalysis)
    }

    @Dependency(\.observeSleepCaffeineAnalysis) private var observeSleepCaffeineAnalysis

    /// Starts the observation, and reduces each analysis it emits into `State`.
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                return .run { [observeSleepCaffeineAnalysis] send in
                    for await analysis in observeSleepCaffeineAnalysis.execute(()) {
                        await send(.analysisUpdated(analysis))
                    }
                }
            case let .analysisUpdated(analysis):
                state.analysis = analysis
                return .none
            }
        }
    }
}
