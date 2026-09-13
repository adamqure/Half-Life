//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life HealthDataAvailabilityRule
//

import Foundation

/// Which kinds of Health data have any data: the business rule behind the Insights tab's Health data buttons.
///
/// Sleep is available when Health recorded any sleep, with or without a stage. Time in bed or awake on its own isn't
/// sleep, so it doesn't count. Steps and resting heart rate are available when any day has a value, and a step count of
/// 0 is a value. It holds no state and reads no clock. ``HealthDataRepository`` executes it. See the Insights article,
/// AVAIL-1 to AVAIL-3.
struct HealthDataAvailabilityRule {
    /// Returns the kinds of Health data that have any data.
    ///
    /// - Parameters:
    ///   - sleep: The sleep Health recorded, from any trackers.
    ///   - steps: Each day's step count that was read, `nil` for a day with none.
    ///   - restingHeartRates: Each day's resting heart rate that was read, `nil` for a day with none.
    func kinds(sleep: [SleepStageInterval], steps: [Int?], restingHeartRates: [Double?]) -> Set<HealthDataKind> {
        var kinds: Set<HealthDataKind> = []
        if sleep.contains(where: { Self.isSleep($0.stage) }) {
            kinds.insert(.sleep)
        }
        if steps.contains(where: { $0 != nil }) {
            kinds.insert(.steps)
        }
        if restingHeartRates.contains(where: { $0 != nil }) {
            kinds.insert(.restingHeartRate)
        }
        return kinds
    }

    /// Whether `stage` is sleep, with or without a stage.
    private static func isSleep(_ stage: SleepStageInterval.Stage) -> Bool {
        switch stage {
        case .asleepUnspecified, .core, .deep, .rem: true
        case .inBed, .awake: false
        }
    }
}
