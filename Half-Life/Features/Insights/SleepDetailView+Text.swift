//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life SleepDetailView+Text
//

import SwiftUI

/// What the Sleep screen says: the analysis card's headline and sentence, the notes, and each chart's spoken value.
/// They're static, so tests can read them without a store. See the Insights article, SLEEPSCREEN-4.
extension SleepDetailView {
    /// What the time to fall asleep card still needs: enough nights on each side of the threshold with time in bed.
    ///
    /// - Parameter amount: The threshold, formatted, such as "40 mg".
    static func needsNightsInBed(_ amount: String) -> LocalizedStringResource {
        """
        This needs at least \(SleepToleranceRule.minimumNightsEachSide) nights on each side of \(amount) with the \
        time you got into bed recorded.
        """
    }

    /// What the nights show about time asleep, in a few words.
    static func headline(_ finding: SleepDetailFeature.Finding) -> LocalizedStringResource {
        switch finding {
        case let .tolerance(tolerance):
            "Your sleep holds up to about \(SleepWindowChart.amount(tolerance.milligrams))"
        case .noDrop:
            "Your sleep hasn't dropped with caffeine so far"
        case .tooFewNights:
            "Not enough nights to say yet"
        }
    }

    /// What the nights show across both charts, hedged, or what the screen still needs. It never mentions the
    /// cutoff, which the Today screen shows (SLEEPSCREEN-4).
    ///
    /// - Parameters:
    ///   - finding: What the nights show about time asleep.
    ///   - fallingAsleep: How the time to fall asleep compares over the threshold, against at or under it.
    static func explanation(
        _ finding: SleepDetailFeature.Finding, fallingAsleep: SleepDetailFeature.FallingAsleep
    ) -> LocalizedStringResource {
        let standard = SleepWindowChart.amount(SleepThreshold.standard.milligrams)
        switch finding {
        case let .tolerance(tolerance):
            return trend(over: SleepWindowChart.amount(tolerance.milligrams), fallingAsleep: fallingAsleep)
        case .noDrop:
            return noDrop(over: standard, fallingAsleep: fallingAsleep)
        case let .tooFewNights(under, over):
            return tooFewNights(under: under, over: over, standard: standard)
        }
    }

    /// The hedged trend with a tolerance: less sleep over `amount`, and how the time to fall asleep compares.
    private static func trend(
        over amount: String, fallingAsleep: SleepDetailFeature.FallingAsleep
    ) -> LocalizedStringResource {
        switch fallingAsleep {
        case .longer:
            return """
                Sleep is shaped by many things, but the trend in your nights is that with more than \(amount) in you \
                at sleep onset, you sleep less and take longer to fall asleep.
                """
        case .shorter:
            return """
                Sleep is shaped by many things, but the trend in your nights is that with more than \(amount) in you \
                at sleep onset, you sleep less, though you fall asleep sooner.
                """
        case .aboutTheSame:
            return """
                Sleep is shaped by many things, but the trend in your nights is that with more than \(amount) in you \
                at sleep onset, you sleep less, though you fall asleep about as quickly.
                """
        case .unknown:
            return """
                Sleep is shaped by many things, but the trend in your nights is that with more than \(amount) in you \
                at sleep onset, you sleep less. There aren't yet enough nights with the time you got into bed to \
                compare how quickly you fall asleep.
                """
        }
    }

    /// No drop in time asleep, and how the time to fall asleep compares over the standard threshold, `standard`.
    private static func noDrop(
        over standard: String, fallingAsleep: SleepDetailFeature.FallingAsleep
    ) -> LocalizedStringResource {
        switch fallingAsleep {
        case .longer:
            return """
                Sleep is shaped by many things, but the trend in your nights is that with more than \(standard) in \
                you at sleep onset, you take longer to fall asleep, though you don't sleep less.
                """
        case .shorter:
            return """
                More caffeine at sleep onset hasn't gone with less sleep in your nights so far, and on nights with \
                more than \(standard) in you, you fall asleep sooner.
                """
        case .aboutTheSame:
            return """
                More caffeine at sleep onset hasn't gone with less sleep, or with taking longer to fall asleep, in \
                your nights so far.
                """
        case .unknown:
            return """
                More caffeine at sleep onset hasn't gone with less sleep in your nights so far. There aren't yet \
                enough nights with the time you got into bed to compare how quickly you fall asleep.
                """
        }
    }

    /// What the screen still needs before it can compare either chart.
    private static func tooFewNights(under: Int, over: Int, standard: String) -> LocalizedStringResource {
        return """
            This needs at least \(SleepToleranceRule.minimumNightsEachSide) nights on each side of \(standard) \
            to compare your time asleep and how quickly you fall asleep. So far, \(under) at or under it and \
            \(over) over it.
            """
    }

    /// The chart's spoken value: the averages either side of the threshold, or how many nights it shows.
    static func summary(
        of comparison: SleepComparison?, count: Int, threshold: SleepThreshold,
        units: Set<Duration.UnitsFormatStyle.Unit>
    ) -> LocalizedStringResource {
        guard let comparison else { return "\(count) nights" }
        let style = Duration.UnitsFormatStyle(allowedUnits: units, width: .wide)
        let under = Duration.seconds(comparison.underSeconds).formatted(style)
        let over = Duration.seconds(comparison.overSeconds).formatted(style)
        return "On average, \(under) at or under \(SleepWindowChart.amount(threshold.milligrams)), and \(over) over it."
    }
}
