//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life CaffeineCutoffRule
//

import Foundation

/// The business rule behind the "Last cup" tile: the latest time the user's usual drink can be drunk and still leave
/// no more than the sleep threshold in the body at bedtime.
///
/// It counts every intake already logged, and asks ``CaffeineDecayRule`` for the levels, so the tile and the curve
/// always agree. Only cups that peak by bedtime are considered, because a cup still being absorbed at bedtime adds
/// little *at* bedtime but keeps rising after it. Within that window, the later the cup, the more is left at bedtime,
/// so the rule finds the exact moment by bisection. It then rounds it down to the half hour in the user's calendar, so
/// the tile reads as a friendly time, and there's no cutoff once that half hour has passed. It holds no state and reads
/// no clock. ``CaffeineDecayRepository`` executes it. See the Caffeine Cutoff article, CUTOFF-1 to CUTOFF-8.
struct CaffeineCutoffRule: Sendable {
    /// What a cutoff is calculated from, apart from the current time and the calendar.
    struct Inputs: Sendable, Equatable {
        /// The usual drink, sized with its catalog estimate.
        let drink: FavouriteDrink
        /// Every intake already logged.
        let intakes: [CaffeineIntake]
        /// The elimination half-life and the absorption rate.
        let kinetics: CaffeineKinetics
        /// The most caffeine allowed in the body at bedtime.
        let threshold: SleepThreshold
        /// The user's bedtime.
        let bedtime: Bedtime
    }

    /// How close the bisection gets to the exact moment before it's rounded down, in seconds.
    private static let precision: TimeInterval = 1
    /// The cutoff rounds down to a multiple of this many minutes past the hour: :00 or :30.
    private static let roundingMinutes = 30
    private let decay = CaffeineDecayRule()

    /// Returns the cutoff at `now`.
    ///
    /// - Parameters:
    ///   - inputs: The usual drink, the intakes already logged, the kinetics, the threshold, and the bedtime.
    ///   - now: The current time.
    ///   - calendar: The calendar, and so the time zone, the bedtime is a time of day in, and whose half hours the
    ///     cutoff rounds to.
    /// - Returns: The cutoff, or `nil` if the calendar can't find the next bedtime.
    func cutoff(_ inputs: Inputs, now: Date, calendar: Calendar) -> CaffeineCutoff? {
        guard let night = inputs.bedtime.next(atOrAfter: now, in: calendar) else { return nil }
        let cup = inputs.drink.type.estimatedMilligrams(quantity: inputs.drink.quantity)
        let fits: (Date) -> Bool = { cupAt in
            let withCup = inputs.intakes + [CaffeineIntake(id: UUID(), milligrams: cup, consumedAt: cupAt)]
            let level = decay.level(at: night, from: withCup, kinetics: inputs.kinetics)
            return level.milligrams <= inputs.threshold.milligrams
        }
        let latestPeakingCup = night.addingTimeInterval(-decay.peakDelay(for: inputs.kinetics))
        let latestCup = latestMoment(from: now, to: latestPeakingCup, fits: fits)
            .flatMap { halfHour(atOrBefore: $0, in: calendar) }
            .flatMap { $0 >= wholeMinute(now) ? $0 : nil }
        return CaffeineCutoff(drink: inputs.drink, latestCup: latestCup, bedtime: night, threshold: inputs.threshold)
    }

    /// The last moment from `start` to `end` that `fits`, which holds for an unbroken stretch from `start`, or `nil`
    /// if `start` doesn't fit or comes after `end`.
    private func latestMoment(from start: Date, to end: Date, fits: (Date) -> Bool) -> Date? {
        guard start <= end, fits(start) else { return nil }
        guard !fits(end) else { return end }
        var low = start
        var high = end
        while high.timeIntervalSince(low) > Self.precision {
            let middle = low.addingTimeInterval(high.timeIntervalSince(low) / 2)
            if fits(middle) {
                low = middle
            } else {
                high = middle
            }
        }
        return low
    }

    /// `date` rounded down to the last half hour, :00 or :30, on `calendar`'s clock, or `nil` if the calendar can't
    /// find the hour it's in.
    private func halfHour(atOrBefore date: Date, in calendar: Calendar) -> Date? {
        guard let hour = calendar.dateInterval(of: .hour, for: date) else { return nil }
        let minute = calendar.component(.minute, from: date)
        return hour.start.addingTimeInterval(TimeInterval(minute - minute % Self.roundingMinutes) * 60)
    }

    /// `date` rounded down to its whole clock minute.
    private func wholeMinute(_ date: Date) -> Date {
        Date(timeIntervalSinceReferenceDate: (date.timeIntervalSinceReferenceDate / 60).rounded(.down) * 60)
    }
}
