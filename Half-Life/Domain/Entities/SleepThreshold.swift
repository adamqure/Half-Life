//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life SleepThreshold
//

import Foundation

/// The most caffeine the cutoff allows in the body at bedtime.
///
/// It's always positive and finite. Until the personal sensitivity threshold learns the user's own, it's
/// ``standard``, 40 mg, the value the research in the Caffeine Cutoff article supports. Its ``source`` says which, so
/// the app can say where the number comes from. See THRESH-1, THRESH-2, and THRESH-5.
struct SleepThreshold: Sendable, Equatable {
    /// Where a threshold comes from.
    enum Source: Sendable, Equatable {
        /// Clinical sleep studies, for the average person: ``SleepThreshold/standard``.
        case sleepStudies
        /// The trend in the user's own time asleep: their caffeine tolerance.
        case learned
    }

    /// 40 mg: about what sleep studies leave in the body at bedtime when they stop finding an effect on total sleep
    /// time. It applies until the threshold is personalised.
    static let standard = SleepThreshold(validMilligrams: 40, source: .sleepStudies)

    /// The amount, in milligrams. Always positive and finite.
    let milligrams: Double
    /// Where the amount comes from.
    let source: Source

    /// Creates a threshold learned from the user's nights, or returns `nil` if `milligrams` isn't positive and finite.
    ///
    /// Only ``standard`` comes from sleep studies, so every other threshold is the user's own.
    ///
    /// - Parameter milligrams: The amount, in milligrams.
    init?(milligrams: Double) {
        guard milligrams > 0, milligrams.isFinite else { return nil }
        self.milligrams = milligrams
        source = .learned
    }

    private init(validMilligrams: Double, source: Source) {
        milligrams = validMilligrams
        self.source = source
    }
}
