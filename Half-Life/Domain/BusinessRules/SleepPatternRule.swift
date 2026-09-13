//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life SleepPatternRule
//

import Foundation

/// The business rule behind the Insights tab's first card: the step from the Sleep screen's analysis to the finding
/// about the user's own nights.
///
/// ``SleepToleranceRule`` finds the nights, measures each one's time asleep and the caffeine in the user when they fell
/// asleep, and compares time asleep on the nights over the threshold in use with the others. This rule turns that
/// comparison into a direction and a confidence, so the card and the Sleep screen share one definition and one source.
/// The averages less than ``aboutTheSameSeconds`` apart are about the same, and the smaller group's nights set the
/// confidence. It holds no state and reads no clock. See the Insights article, PATTERN-1 to PATTERN-6.
struct SleepPatternRule {
    /// How far apart the averages must be for a direction: 15 minutes. Closer than that, they're about the same.
    static let aboutTheSameSeconds: TimeInterval = 15 * 60
    /// The fewest nights in the smaller group for "an early sign": 5.
    static let earlySignNights = 5
    /// The fewest nights in the smaller group for "consistent so far": 10.
    static let consistentNights = 10

    /// Returns the finding in `analysis`.
    ///
    /// - Parameter analysis: The Sleep screen's analysis of the user's nights.
    /// - Returns: The finding. Without a comparison of time asleep, one group has fewer than 5 nights, so it counts the
    ///   nights by their caffeine at sleep onset, and they're too few to say anything.
    func pattern(from analysis: SleepCaffeineAnalysis) -> SleepPattern {
        let threshold = analysis.threshold
        guard let timeAsleep = analysis.timeAsleep else {
            let over = analysis.nights.filter { $0.caffeineAtOnset > threshold.milligrams }.count
            return SleepPattern(
                period: analysis.period, days: analysis.days, nightsOver: over,
                nightsUnder: analysis.nights.count - over, threshold: threshold, direction: .aboutTheSame,
                confidence: .tooFew)
        }
        return SleepPattern(
            period: analysis.period, days: analysis.days, nightsOver: timeAsleep.nightsOver,
            nightsUnder: timeAsleep.nightsUnder, threshold: threshold, direction: Self.direction(of: timeAsleep),
            confidence: Self.confidence(smallerGroup: min(timeAsleep.nightsOver, timeAsleep.nightsUnder)))
    }

    /// Shorter or longer when the averages are at least ``aboutTheSameSeconds`` apart, and about the same otherwise.
    private static func direction(of timeAsleep: SleepComparison) -> SleepPattern.Direction {
        let difference = timeAsleep.overSeconds - timeAsleep.underSeconds
        guard abs(difference) >= aboutTheSameSeconds else { return .aboutTheSame }
        return difference < 0 ? .shorter : .longer
    }

    /// The confidence the smaller group's nights allow.
    private static func confidence(smallerGroup nights: Int) -> SleepPattern.Confidence {
        if nights >= consistentNights { return .consistent }
        return nights >= earlySignNights ? .earlySign : .tooFew
    }
}
