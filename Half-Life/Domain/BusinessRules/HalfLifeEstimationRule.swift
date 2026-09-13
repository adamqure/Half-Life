//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life HalfLifeEstimationRule
//

import Foundation

/// The personal half-life estimator: it updates the survey's starting half-life with the user's own nights.
///
/// Health data can't measure a half-life. What it can show is how the user's sleep went against the caffeine left in
/// them when they fell asleep, and that amount depends on the half-life. So the rule asks, for each of 121 candidate
/// half-lives from 1 to 100 hours, how well the caffeine at sleep onset under that half-life explains which nights
/// were disrupted, and weighs the answer against the survey's prior (a Bayesian update):
///
/// 1. **The prior** is a log-normal centred on the survey's half-life, with a spread of ``priorSpread`` on the log
///    scale, which matches how widely healthy adults vary.
/// 2. **Each night's disruption score** is its time awake minus its deep sleep, each measured against the user's own
///    average and spread, then standardized.
/// 3. **For each candidate,** ``CaffeineDecayRule`` gives the caffeine at each night's sleep onset. A Bayesian
///    linear regression of the scores on it, standardized, with the weekend, the day's steps, and the day's resting
///    heart rate beside it, gives the evidence for the candidate, with the coefficients integrated out. Caffeine is
///    only allowed to disturb sleep, never to improve it.
/// 4. **The estimate** is the posterior's median, with its 10th and 90th percentiles as the range, clamped to the 3 to
///    40 hours of ``HalfLifePriorRule``.
///
/// Standardizing the caffeine means only the pattern of which nights had more caffeine counts, never its amount. How
/// strongly a given amount disturbs sleep varies from person to person, separately from the half-life, so an amount
/// can't tell the two apart. Only variety in when the user drinks can: without it, every candidate gives the same
/// pattern, and the estimate stays the prior.
///
/// A night counts once drinks have been logged for ``warmUp`` before it, so drinks from before the user started
/// logging don't go missing from its caffeine. With fewer than ``minimumNights`` such nights, the estimate is the
/// prior. The rule holds no state and reads no clock. ``HalfLifeEstimateRepository`` executes it. The Half-Life
/// Estimator article gives the math and its requirements, EST-1 to EST-8.
struct HalfLifeEstimationRule {
    /// One night to fit, with the day before it.
    struct Night: Sendable, Equatable {
        /// The night's sleep.
        let sleep: SleepNight
        /// The steps on the day before the night, or `nil` if Health has none.
        let steps: Int?
        /// The resting heart rate on the day before the night, in beats per minute, or `nil` if Health has none.
        let restingHeartRate: Double?
    }

    /// What an estimate is made from.
    struct Inputs: Sendable, Equatable {
        /// The survey's starting half-life, from ``HalfLifePriorRule``.
        let prior: CaffeineHalfLife
        /// The nights Health recorded, in any order.
        let nights: [Night]
        /// Every intake the user logged, in any order.
        let intakes: [CaffeineIntake]
        /// The absorption rate the decay model uses.
        let absorption: CaffeineAbsorptionRate
    }

    /// The fewest usable nights that can move the estimate away from the prior: 14.
    static let minimumNights = 14
    /// How long drinks must have been logged before a night counts: 2 days. After 48 hours, less than 0.3% of a drink
    /// is left at the standard half-life.
    static let warmUp: TimeInterval = 2 * 24 * 3_600
    /// How far before a night its drinks are summed: 7 days. After a week, less than 6% of a drink is left even at 40
    /// hours.
    static let lookback: TimeInterval = 7 * 24 * 3_600
    /// The spread of the prior: the standard deviation of the half-life's natural log.
    ///
    /// Healthy adults ranged from 2.3 to 9.9 hours (Blanchard 1983, 16 men), about 3.6 standard deviations of 0.4.
    static let priorSpread = 0.4
    /// The least spread, across nights, in the caffeine a candidate leaves at sleep onset for it to explain anything:
    /// 1 mg. A candidate below it, such as a very short half-life with only morning drinks, says nothing.
    static let minimumCaffeineSpread = 1.0

    /// The number of steps between the shortest and longest candidate.
    private static let candidateSteps = 120
    /// The candidates, in seconds: evenly spaced on a log scale from 1 hour to 100 hours.
    private static let candidates: [TimeInterval] = (0...candidateSteps).map { step in
        3_600 * pow(100, Double(step) / Double(candidateSteps))
    }
    /// The distance between neighbouring candidates, as a natural log.
    private static let candidateSpacing = log(100.0) / Double(candidateSteps)
    /// The distance, in standard deviations, from the median to the range's ends, the 10th and 90th percentiles.
    private static let rangeDeviations = 1.281_551_565_545
    /// The noise prior: an inverse gamma with shape 2 and scale 1, whose mean is 1, the variance of a standardized
    /// score.
    private static let noiseShape = 2.0
    private static let noiseScale = 1.0

    private let decayRule = CaffeineDecayRule()

    /// Returns the estimate for the user's nights and drinks.
    ///
    /// - Parameters:
    ///   - inputs: The prior, the nights, the intakes, and the absorption rate.
    ///   - calendar: The calendar that decides which nights end on a weekend.
    ///   - now: When the estimate is made.
    /// - Returns: The estimate. With fewer than ``minimumNights`` usable nights, it's the prior.
    func estimate(_ inputs: Inputs, calendar: Calendar, now: Date) -> HalfLifeEstimate {
        let prior = inputs.prior
        let intakes = inputs.intakes
        guard let firstDrink = intakes.map(\.consumedAt).min() else { return priorEstimate(prior, now: now) }
        let used =
            inputs.nights
            .filter { $0.sleep.sleepOnset >= firstDrink.addingTimeInterval(Self.warmUp) }
            .sorted { $0.sleep.sleepOnset < $1.sleep.sleepOnset }
        guard used.count >= Self.minimumNights else { return priorEstimate(prior, now: now) }

        let scores = Self.standardized(Self.disruption(of: used).map(Optional.some))
        let covariates = [
            Self.standardized(used.map { calendar.isDateInWeekend($0.sleep.wake) ? 1 : 0 }),
            Self.standardized(used.map { $0.steps.map(Double.init) }),
            Self.standardized(used.map(\.restingHeartRate)),
        ]
        let drinks = used.map { night in
            let onset = night.sleep.sleepOnset
            return intakes.filter { $0.consumedAt <= onset && $0.consumedAt > onset.addingTimeInterval(-Self.lookback) }
        }
        let logWeights = Self.candidates.map { candidate in
            let deviation = log(candidate / prior.seconds) / Self.priorSpread
            let caffeine = caffeineAtOnset(
                of: used, drinks: drinks, halfLife: candidate, absorption: inputs.absorption)
            return -deviation * deviation / 2 + Self.logEvidence(for: scores, columns: [caffeine] + covariates)
        }
        guard let largest = logWeights.max(), largest.isFinite else { return priorEstimate(prior, now: now) }
        let weights = logWeights.map { exp($0 - largest) }
        let total = weights.reduce(0, +)
        let posterior = weights.map { $0 / total }
        return HalfLifeEstimate(
            halfLife: Self.clamped(Self.quantile(0.5, of: posterior), fallback: prior),
            lowerBound: Self.clamped(Self.quantile(0.1, of: posterior), fallback: prior),
            upperBound: Self.clamped(Self.quantile(0.9, of: posterior), fallback: prior), prior: prior,
            nightsUsed: used.count, calculatedAt: now)
    }

    /// The estimate when the nights can't say anything: the prior, with the prior's range.
    private func priorEstimate(_ prior: CaffeineHalfLife, now: Date) -> HalfLifeEstimate {
        let spread = Self.rangeDeviations * Self.priorSpread
        return HalfLifeEstimate(
            halfLife: prior, lowerBound: Self.clamped(prior.seconds * exp(-spread), fallback: prior),
            upperBound: Self.clamped(prior.seconds * exp(spread), fallback: prior), prior: prior, nightsUsed: 0,
            calculatedAt: now)
    }

    /// The caffeine at each night's sleep onset under a candidate half-life, standardized, or all zeros if it varies
    /// by less than ``minimumCaffeineSpread`` across the nights.
    private func caffeineAtOnset(
        of nights: [Night], drinks: [[CaffeineIntake]], halfLife seconds: TimeInterval,
        absorption: CaffeineAbsorptionRate
    ) -> [Double] {
        let none = [Double](repeating: 0, count: nights.count)
        guard let halfLife = CaffeineHalfLife(seconds: seconds) else { return none }
        let kinetics = CaffeineKinetics(halfLife: halfLife, absorption: absorption)
        let levels = zip(nights, drinks).map { night, drinks in
            decayRule.level(at: night.sleep.sleepOnset, from: drinks, kinetics: kinetics).milligrams
        }
        guard Self.standardDeviation(of: levels) >= Self.minimumCaffeineSpread else { return none }
        return Self.standardized(levels.map(Optional.some))
    }

    /// Each night's disruption: its time awake minus its deep sleep, each standardized across the nights.
    private static func disruption(of nights: [Night]) -> [Double] {
        let deep = standardized(nights.map { $0.sleep.deepSeconds })
        let awake = standardized(nights.map { $0.sleep.awakeSeconds })
        return zip(awake, deep).map { $0 - $1 }
    }

    /// The evidence for a candidate, as a log, up to a constant every candidate shares.
    ///
    /// It's the marginal likelihood of `scores` under a Bayesian linear regression on `columns`, with a standard
    /// normal prior on each coefficient, in units of the noise, and ``noiseShape`` and ``noiseScale`` for the noise.
    /// The first column is the caffeine. Its coefficient is only allowed to be positive, so the evidence is also
    /// multiplied by twice the posterior probability that it is.
    private static func logEvidence(for scores: [Double], columns: [[Double]]) -> Double {
        let size = columns.count
        var precision = (0..<size).map { row in (0..<size).map { column in row == column ? 1.0 : 0 } }
        var projection = [Double](repeating: 0, count: size)
        for row in 0..<size {
            for column in 0..<size {
                precision[row][column] += dot(columns[row], columns[column])
            }
            projection[row] = dot(columns[row], scores)
        }
        guard let factor = CholeskyFactor(precision) else { return -.infinity }
        let coefficients = factor.solve(projection)
        let shape = noiseShape + Double(scores.count) / 2
        let scale = noiseScale + (dot(scores, scores) - dot(projection, coefficients)) / 2
        let caffeineVariance = scale / shape * factor.solve((0..<size).map { $0 == 0 ? 1 : 0 })[0]
        // A normal approximation to the posterior's Student t, which has more than 30 degrees of freedom here.
        let positive = erfc(-coefficients[0] / (2 * caffeineVariance).squareRoot()) / 2
        return -factor.logDeterminant / 2 - shape * log(scale) + log(2 * positive)
    }

    /// The half-life below which `probability` of the posterior lies, in seconds. Each candidate's weight is spread
    /// evenly over its step on the log scale.
    private static func quantile(_ probability: Double, of posterior: [Double]) -> TimeInterval {
        var cumulative = 0.0
        for (index, weight) in posterior.enumerated() where weight > 0 {
            if cumulative + weight >= probability {
                let fraction = (probability - cumulative) / weight
                return candidates[index] * exp((fraction - 0.5) * candidateSpacing)
            }
            cumulative += weight
        }
        return candidates[candidates.count - 1]
    }

    /// The half-life of `seconds`, clamped to the 3 to 40 hours of ``HalfLifePriorRule``.
    private static func clamped(_ seconds: TimeInterval, fallback: CaffeineHalfLife) -> CaffeineHalfLife {
        let seconds = min(max(seconds, HalfLifePriorRule.minimumSeconds), HalfLifePriorRule.maximumSeconds)
        // The clamp keeps `seconds` positive and finite, so the half-life always exists.
        return CaffeineHalfLife(seconds: seconds) ?? fallback
    }

    /// Centres `values` on their mean, and scales them to a standard deviation of 1. A missing value becomes 0, the
    /// mean. With fewer than two values, or none that differ, every value is 0, so the column says nothing.
    private static func standardized(_ values: [Double?]) -> [Double] {
        let present = values.compactMap { $0 }
        let none = [Double](repeating: 0, count: values.count)
        guard present.count > 1 else { return none }
        let mean = present.reduce(0, +) / Double(present.count)
        let deviation = standardDeviation(of: present)
        guard deviation > 0 else { return none }
        return values.map { value in value.map { ($0 - mean) / deviation } ?? 0 }
    }

    private static func standardized(_ values: [Double]) -> [Double] {
        standardized(values.map(Optional.some))
    }

    /// The population standard deviation of `values`.
    private static func standardDeviation(of values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        return (values.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(values.count)).squareRoot()
    }

    private static func dot(_ first: [Double], _ second: [Double]) -> Double {
        zip(first, second).reduce(0) { $0 + $1.0 * $1.1 }
    }
}

/// The Cholesky factor of a small symmetric positive-definite matrix, for solving linear systems with it.
private struct CholeskyFactor {
    /// The lower-triangular factor `L`, where the matrix is `L·Lᵀ`.
    private let lower: [[Double]]

    /// Factors `matrix`, or returns `nil` if it isn't positive definite.
    init?(_ matrix: [[Double]]) {
        let size = matrix.count
        var lower = [[Double]](repeating: [Double](repeating: 0, count: size), count: size)
        for row in 0..<size {
            for column in 0...row {
                var sum = matrix[row][column]
                for inner in 0..<column {
                    sum -= lower[row][inner] * lower[column][inner]
                }
                if row == column {
                    guard sum > 0 else { return nil }
                    lower[row][column] = sum.squareRoot()
                } else {
                    lower[row][column] = sum / lower[column][column]
                }
            }
        }
        self.lower = lower
    }

    /// The natural log of the matrix's determinant.
    var logDeterminant: Double {
        2 * lower.indices.reduce(0) { $0 + log(lower[$1][$1]) }
    }

    /// Solves `matrix · x = vector` for `x`.
    func solve(_ vector: [Double]) -> [Double] {
        let size = lower.count
        var forward = [Double](repeating: 0, count: size)
        for row in 0..<size {
            var sum = vector[row]
            for inner in 0..<row {
                sum -= lower[row][inner] * forward[inner]
            }
            forward[row] = sum / lower[row][row]
        }
        var solution = [Double](repeating: 0, count: size)
        for row in (0..<size).reversed() {
            var sum = forward[row]
            for inner in (row + 1)..<size {
                sum -= lower[inner][row] * solution[inner]
            }
            solution[row] = sum / lower[row][row]
        }
        return solution
    }
}
