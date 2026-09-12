//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life CaffeineStatusRule
//

import Foundation

/// The business rule behind the decay card: it turns intakes, their ``CaffeineKinetics``, and a bedtime into the
/// current level and the two tips.
///
/// It sums levels with ``CaffeineDecayRule``, and asks that rule which intakes count and when the last one is half
/// gone, so the figure, the tips, and the curve always agree. Like that rule, it holds no state and reads no clock,
/// so the current time is an input. Repositories execute it. See the Today Screen article, STATUS-1 to STATUS-6.
nonisolated struct CaffeineStatusRule: Sendable {
    private let decay = CaffeineDecayRule()

    /// Returns the status at `now`.
    ///
    /// - Parameters:
    ///   - intakes: The intakes to sum.
    ///   - kinetics: The elimination half-life and the absorption rate.
    ///   - bedtime: The bedtime to report the level at.
    ///   - now: The current time.
    ///   - calendar: The calendar, and so the time zone, the bedtime is a time of day in.
    func status(
        from intakes: [CaffeineIntake], kinetics: CaffeineKinetics, bedtime: Bedtime, now: Date, calendar: Calendar
    ) -> CaffeineStatus {
        let active = intakes.filter { decay.isCounting($0, at: now, kinetics: kinetics) }
        let lastHalfGone = active.max { $0.consumedAt < $1.consumedAt }.map {
            decay.halfGoneDate(of: $0, kinetics: kinetics)
        }
        let bedtimeLevel = nextBedtime(bedtime, atOrAfter: now, calendar: calendar).map {
            decay.level(at: $0, from: intakes, kinetics: kinetics)
        }
        return CaffeineStatus(
            level: decay.level(at: now, from: intakes, kinetics: kinetics),
            activeIntakes: active,
            lastIntakeHalfGoneAt: lastHalfGone.flatMap { $0 > now ? $0 : nil },
            levelAtBedtime: bedtimeLevel)
    }

    /// The first time `bedtime` comes round at or after `now`: tonight's, or tomorrow's once tonight's has passed.
    private func nextBedtime(_ bedtime: Bedtime, atOrAfter now: Date, calendar: Calendar) -> Date? {
        guard let tonight = calendar.date(bySettingHour: bedtime.hour, minute: bedtime.minute, second: 0, of: now)
        else { return nil }
        return tonight >= now ? tonight : calendar.date(byAdding: .day, value: 1, to: tonight)
    }
}
