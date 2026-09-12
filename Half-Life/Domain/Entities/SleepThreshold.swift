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
/// ``standard``, 40 mg, the value the research in the Caffeine Cutoff article supports. See THRESH-1 and THRESH-2.
struct SleepThreshold: Sendable, Equatable {
    /// 40 mg: about what sleep studies leave in the body at bedtime when they stop finding an effect on total sleep
    /// time. It applies until the threshold is personalised.
    static let standard = SleepThreshold(validMilligrams: 40)

    /// The amount, in milligrams. Always positive and finite.
    let milligrams: Double

    /// Creates a threshold, or returns `nil` if `milligrams` isn't positive and finite.
    ///
    /// - Parameter milligrams: The amount, in milligrams.
    init?(milligrams: Double) {
        guard milligrams > 0, milligrams.isFinite else { return nil }
        self.milligrams = milligrams
    }

    private init(validMilligrams: Double) {
        milligrams = validMilligrams
    }
}
