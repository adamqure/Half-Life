//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life InsightFacts
//

import Foundation

/// The facts of the Insights tab's first finding, with every number already formatted, for the insight's prompt and
/// the number check.
///
/// It writes the ``SleepPattern`` that came with the request, which is the one the card holds, so the model's words
/// can't disagree with the card. It gives the direction only, never the averages, so the model can't say how much sleep
/// was lost. It gives the total nights too, so the model copies the sum rather than calculating it, which the number
/// check would reject (LMFACT-1, LMFACT-2).
struct InsightFacts: Sendable {
    /// The finding the facts describe.
    let pattern: SleepPattern
    /// Formats the counts, amounts, and days, in the calendar the finding was made in.
    let format: LanguageModelFormat

    /// The finding, as the lines the prompt gives the model. The number check compares the model's answer with them.
    var text: String {
        let threshold = format.milligrams(pattern.threshold.milligrams)
        let firstDay = format.shortDay(pattern.period.start)
        let lastDay = format.shortDay(pattern.period.end.addingTimeInterval(-1))
        let over = nights(pattern.nightsOver)
        let under = nights(pattern.nightsUnder)
        var lines = [
            "Period: the last \(format.count(pattern.days)) days, \(firstDay) to \(lastDay).",
            "Caffeine when you fell asleep: over \(threshold) on \(over), \(threshold) or under on \(under).",
            "Nights counted: \(format.count(pattern.nightsOver + pattern.nightsUnder)).",
            "Time asleep: \(direction(over: threshold)).",
            "Headline: \(headline(for: threshold)).",
            "Confidence: \(confidence).",
        ]
        let uncounted = pattern.uncountedNights
        let reason = "no sleep was recorded, or no drinks were logged before"
        if uncounted == 1 {
            lines.append("\(format.count(uncounted)) night isn't counted: \(reason) it yet.")
        } else if uncounted > 1 {
            lines.append("\(format.count(uncounted)) nights aren't counted: \(reason) them yet.")
        }
        return lines.joined(separator: "\n")
    }

    private func nights(_ count: Int) -> String {
        "\(format.count(count)) \(count == 1 ? "night" : "nights")"
    }

    private func direction(over threshold: String) -> String {
        switch pattern.direction {
        case .shorter: "shorter on the nights over \(threshold) than on the others"
        case .longer: "longer on the nights over \(threshold) than on the others"
        case .aboutTheSame: "about the same on the nights over \(threshold) as on the others"
        }
    }

    /// The headline the rules write for the finding's direction, which the model uses in the user's language.
    ///
    /// The model refused twice on 2026-09-13 while it was asked what the finding meant for the user's sleep, so the
    /// rules write the claim, and the model only says how the nights support it. It says "more", not "the most",
    /// because the finding compares only two groups of nights, and "more sleep", not "better sleep", because it
    /// compares time asleep.
    private func headline(for threshold: String) -> String {
        switch pattern.direction {
        case .shorter: "You get more sleep at \(threshold) or less"
        case .longer: "You get more sleep above \(threshold)"
        case .aboutTheSame: "Your sleep is about the same either side of \(threshold)"
        }
    }

    private var confidence: String {
        switch pattern.confidence {
        case .tooFew: "too few nights to say anything yet"
        case .earlySign: "an early sign"
        case .consistent: "consistent so far"
        }
    }
}
