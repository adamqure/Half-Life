//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life CaffeineDecayRule
//

import Foundation

/// The decay model's business rule: it turns caffeine intakes and their ``CaffeineKinetics``, a half-life and an
/// absorption rate, into caffeine levels.
///
/// Each intake follows the Bateman function. Its caffeine passes from the stomach into the body at the absorption
/// rate, and the body clears the caffeine that has arrived at the elimination rate (first-order absorption and
/// elimination). The level at any moment is the sum of the intakes that still count (superposition). An intake stops
/// counting once it's past its peak and below ``negligibleMilligrams``.
///
/// The rule holds no state and reads no clock, so the current time is always an input. Repositories execute it.
/// See the Caffeine Decay Model article for the math and the requirements it meets.
nonisolated struct CaffeineDecayRule: Sendable {
    /// The amount below which an intake past its peak stops counting, in milligrams.
    static let negligibleMilligrams = 0.5
    /// The time between the curve's samples, in seconds.
    static let sampleSpacing: TimeInterval = 60
    /// How far the curve reaches either side of the current minute, in seconds.
    static let windowRadius: TimeInterval = 12 * 60 * 60
    /// The number of levels in a curve: 1,440 for a 24-hour window at one-minute spacing.
    static let sampleCount = Int(2 * windowRadius / sampleSpacing)
    /// How close ``halfGoneDate(of:kinetics:)`` gets to the exact moment, in seconds.
    private static let halfGonePrecision: TimeInterval = 0.001

    /// Returns the caffeine in the body at `date`: the sum of every intake that still counts at that moment.
    ///
    /// - Parameters:
    ///   - date: The moment to evaluate.
    ///   - intakes: The intakes to sum. Intakes consumed after `date` add nothing.
    ///   - kinetics: The elimination half-life and the absorption rate.
    func level(at date: Date, from intakes: [CaffeineIntake], kinetics: CaffeineKinetics) -> CaffeineLevel {
        let curve = BatemanCurve(kinetics)
        let milligrams = intakes.reduce(0.0) { total, intake in
            let elapsed = date.timeIntervalSince(intake.consumedAt)
            guard curve.counts(intake.milligrams, after: elapsed) else { return total }
            return total + curve.amount(of: intake.milligrams, after: elapsed)
        }
        return CaffeineLevel(date: date, milligrams: milligrams)
    }

    /// Returns whether `intake` counts at `date`: from the moment it's consumed until it's past its peak and below
    /// ``negligibleMilligrams``.
    ///
    /// A drink consumed at exactly `date` counts, although none of its caffeine has reached the body yet.
    ///
    /// - Parameters:
    ///   - intake: The intake to check.
    ///   - date: The moment to check it at.
    ///   - kinetics: The elimination half-life and the absorption rate.
    func isCounting(_ intake: CaffeineIntake, at date: Date, kinetics: CaffeineKinetics) -> Bool {
        BatemanCurve(kinetics).counts(intake.milligrams, after: date.timeIntervalSince(intake.consumedAt))
    }

    /// Returns the curve for `now`: ``sampleCount`` levels, one per ``sampleSpacing``, from ``windowRadius`` before
    /// the current minute to ``windowRadius`` after it.
    ///
    /// The level at index `sampleCount / 2` is for the current minute.
    ///
    /// - Parameters:
    ///   - intakes: The intakes to sum.
    ///   - kinetics: The elimination half-life and the absorption rate.
    ///   - now: The current time.
    func curve(from intakes: [CaffeineIntake], kinetics: CaffeineKinetics, now: Date) -> [CaffeineLevel] {
        let start = windowStart(for: now)
        return (0..<Self.sampleCount).map { index in
            let date = start.addingTimeInterval(Double(index) * Self.sampleSpacing)
            return level(at: date, from: intakes, kinetics: kinetics)
        }
    }

    /// Returns the intakes that are negligible at the window's first sample, so a repository can mark them.
    ///
    /// An intake is negligible once it's past its peak and below ``negligibleMilligrams``. After its peak, its level
    /// only falls, so a negligible intake adds nothing anywhere in the curve for `now`.
    ///
    /// - Parameters:
    ///   - intakes: The intakes to check.
    ///   - kinetics: The elimination half-life and the absorption rate.
    ///   - now: The current time.
    func negligibleIntakes(
        from intakes: [CaffeineIntake], kinetics: CaffeineKinetics, now: Date
    ) -> [CaffeineIntake] {
        let curve = BatemanCurve(kinetics)
        let start = windowStart(for: now)
        return intakes.filter { intake in
            curve.isNegligible(intake.milligrams, after: start.timeIntervalSince(intake.consumedAt))
        }
    }

    /// Returns when `intake` is half gone: the first moment, at or after its peak, when its own level is down to half
    /// its dose.
    ///
    /// The level is proportional to the dose, so every dose takes the same time. The Bateman function has no
    /// closed-form inverse, so the rule finds the moment by bisection, to within a millisecond. If the intake never
    /// reaches half its dose, it's half gone at its peak.
    ///
    /// - Parameters:
    ///   - intake: The intake to check.
    ///   - kinetics: The elimination half-life and the absorption rate.
    func halfGoneDate(of intake: CaffeineIntake, kinetics: CaffeineKinetics) -> Date {
        let curve = BatemanCurve(kinetics)
        var low = curve.peakDelay
        guard curve.fraction(after: low) > 0.5 else { return intake.consumedAt.addingTimeInterval(low) }
        var high = 2 * low
        while curve.fraction(after: high) > 0.5 {
            high *= 2
        }
        while high - low > Self.halfGonePrecision {
            let middle = (low + high) / 2
            if curve.fraction(after: middle) > 0.5 {
                low = middle
            } else {
                high = middle
            }
        }
        return intake.consumedAt.addingTimeInterval(high)
    }

    /// The window's first sample: the current minute, minus ``windowRadius``.
    private func windowStart(for now: Date) -> Date {
        let spacing = Self.sampleSpacing
        let currentMinute = (now.timeIntervalSinceReferenceDate / spacing).rounded(.down) * spacing
        return Date(timeIntervalSinceReferenceDate: currentMinute - Self.windowRadius)
    }
}

/// The Bateman function for one ``CaffeineKinetics``: the elimination half-life `Te` and the absorption half-life
/// `Ta`.
private nonisolated struct BatemanCurve {
    /// The elimination half-life `Te`, in seconds.
    let elimination: TimeInterval
    /// The absorption half-life `Ta`, in seconds.
    let absorption: TimeInterval
    /// How long after it's consumed an intake peaks, in seconds.
    let peakDelay: TimeInterval

    init(_ kinetics: CaffeineKinetics) {
        let elimination = kinetics.halfLife.seconds
        let absorption = kinetics.absorption.halfLifeSeconds
        self.elimination = elimination
        self.absorption = absorption
        if elimination == absorption {
            peakDelay = elimination / log(2)
        } else {
            peakDelay = elimination * absorption * log2(elimination / absorption) / (elimination - absorption)
        }
    }

    /// The fraction of a dose in the body `elapsed` seconds after it's consumed. It's zero until then, and at that
    /// moment.
    ///
    /// Uses the half-life form of the Bateman function, `Te / (Te − Ta) · (2^(−t / Te) − 2^(−t / Ta))`. When the two
    /// half-lives are equal, that divides by zero, so it uses the function's limit, `(ln 2 · t / T) · 2^(−t / T)`.
    func fraction(after elapsed: TimeInterval) -> Double {
        guard elapsed > 0 else { return 0 }
        guard elimination != absorption else {
            return log(2) * elapsed / elimination * exp2(-elapsed / elimination)
        }
        return elimination / (elimination - absorption) * (exp2(-elapsed / elimination) - exp2(-elapsed / absorption))
    }

    /// The caffeine in the body from an intake of `milligrams`, `elapsed` seconds after it's consumed, ignoring the
    /// negligible cutoff.
    func amount(of milligrams: Double, after elapsed: TimeInterval) -> Double {
        milligrams * fraction(after: elapsed)
    }

    /// Whether an intake of `milligrams` counts `elapsed` seconds after it's consumed: from that moment until it's
    /// negligible.
    func counts(_ milligrams: Double, after elapsed: TimeInterval) -> Bool {
        elapsed >= 0 && !isNegligible(milligrams, after: elapsed)
    }

    /// Whether an intake of `milligrams` is negligible `elapsed` seconds after it's consumed: at or past its peak,
    /// and below ``CaffeineDecayRule/negligibleMilligrams``. After its peak, its level only falls, so it never counts
    /// again.
    func isNegligible(_ milligrams: Double, after elapsed: TimeInterval) -> Bool {
        elapsed >= peakDelay && amount(of: milligrams, after: elapsed) < CaffeineDecayRule.negligibleMilligrams
    }
}
