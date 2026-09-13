//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests HealthDataAvailabilityRuleTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks which kinds of Health data are available, against AVAIL-1 to AVAIL-3 in the Insights article. The rule is
/// pure, so its tests need no fakes.
struct HealthDataAvailabilityRuleTests {

    let rule = HealthDataAvailabilityRule()

    static let start = Date(timeIntervalSinceReferenceDate: 0)

    static func interval(_ stage: SleepStageInterval.Stage) -> SleepStageInterval {
        SleepStageInterval(stage: stage, start: start, end: start.addingTimeInterval(7 * 3_600))
    }

    // MARK: - AVAIL-1: sleep is available when Health recorded sleep, and time in bed alone doesn't count

    @Test(arguments: [SleepStageInterval.Stage.core, .deep, .rem, .asleepUnspecified])
    func anyStretchOfSleepMakesSleepAvailable(stage: SleepStageInterval.Stage) {
        #expect(rule.kinds(sleep: [Self.interval(stage)], steps: [], restingHeartRates: []) == [.sleep])
    }

    @Test func timeInBedOrAwakeAloneDoesntMakeSleepAvailable() {
        #expect(
            rule.kinds(sleep: [Self.interval(.inBed), Self.interval(.awake)], steps: [], restingHeartRates: []).isEmpty)
    }

    // MARK: - AVAIL-2: steps and resting heart rate are available when any day has a value, 0 included

    @Test func anyValueMakesStepsAndRestingHeartRateAvailable() {
        #expect(rule.kinds(sleep: [], steps: [nil, 0], restingHeartRates: [nil, 58]) == [.steps, .restingHeartRate])
        #expect(rule.kinds(sleep: [], steps: [nil, nil], restingHeartRates: [nil]).isEmpty)
    }

    // MARK: - AVAIL-3: the kinds show in a fixed order: sleep, steps, then resting heart rate

    @Test func theKindsShowInAFixedOrder() {
        #expect(HealthDataKind.allCases == [.sleep, .steps, .restingHeartRate])
    }
}
