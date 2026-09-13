//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life SleepNightRule
//

import Foundation

/// Turns the sleep intervals Apple Health recorded into nights: the night rule the Sleep Data article left open.
///
/// Stretches of sleep, and of time awake that a tracker recorded during sleep, belong to one session while each starts
/// no more than ``sessionGap`` after the session so far ends. Time awake holds a session together, so a long awakening
/// doesn't split a night in two and hide it. A session is a night when it holds at least ``minimumAsleepSeconds`` of
/// sleep and at least one stretch recorded with a stage (core, deep, or REM). Shorter sessions are naps, and a night
/// without stages has no deep sleep to score. The night runs from its first sleep to its last. Time in bed doesn't
/// count as sleep, and time awake counts only between the night's first and last sleep. Where trackers overlap, the
/// overlap counts once.
///
/// It's stateless, and ``HalfLifeEstimateRepository`` executes it. ``LastNightSleepRule`` shares its sessions and its
/// union, so the Apple Health card and the estimator agree on what a night is. The Half-Life Estimator article lists
/// its requirements, NIGHT-1 to NIGHT-6.
struct SleepNightRule {
    /// The longest gap between stretches in one session: 1 hour.
    static let sessionGap: TimeInterval = 3_600
    /// The least sleep a session needs to be a night rather than a nap: 3 hours.
    static let minimumAsleepSeconds: TimeInterval = 3 * 3_600

    /// Returns the nights in `intervals`, in order of onset.
    ///
    /// - Parameter intervals: The intervals Health recorded, from any trackers, in any order.
    /// - Returns: One night for each session that has enough sleep and at least one stage.
    func nights(from intervals: [SleepStageInterval]) -> [SleepNight] {
        Self.sessions(of: intervals.filter { $0.stage.isAsleep || $0.stage == .awake }).compactMap(night(in:))
    }

    /// Groups intervals into sessions, in order of start: each interval joins the session so far if it starts no more
    /// than ``sessionGap`` after that session ends. ``LastNightSleepRule`` groups sleep, and time in bed, the same way.
    ///
    /// - Parameter stretches: The intervals to group, in any order.
    /// - Returns: The sessions, each with its intervals in order of start.
    static func sessions(of stretches: [SleepStageInterval]) -> [[SleepStageInterval]] {
        var sessions: [[SleepStageInterval]] = []
        var sessionEnd = Date.distantPast
        for interval in stretches.sorted(by: { $0.start < $1.start }) {
            if let last = sessions.indices.last, interval.start <= sessionEnd.addingTimeInterval(Self.sessionGap) {
                sessions[last].append(interval)
                sessionEnd = max(sessionEnd, interval.end)
            } else {
                sessions.append([interval])
                sessionEnd = interval.end
            }
        }
        return sessions
    }

    /// The night a session makes, or `nil` if it's a nap, has no stages, or has no sleep at all.
    private func night(in session: [SleepStageInterval]) -> SleepNight? {
        let asleep = session.filter(\.stage.isAsleep)
        guard asleep.contains(where: \.stage.isStaged),
            let onset = asleep.map(\.start).min(),
            let wake = asleep.map(\.end).max()
        else { return nil }
        let bounds = DateInterval(start: onset, end: wake)
        guard Self.unionLength(of: asleep, within: bounds) >= Self.minimumAsleepSeconds else { return nil }
        return SleepNight(
            sleepOnset: onset, wake: wake,
            deepSeconds: Self.unionLength(of: asleep.filter { $0.stage == .deep }, within: bounds),
            awakeSeconds: Self.unionLength(of: session.filter { $0.stage == .awake }, within: bounds))
    }

    /// The time `intervals` cover within `bounds`, counting any overlap once.
    ///
    /// - Parameters:
    ///   - intervals: The intervals to measure, in any order.
    ///   - bounds: The time to measure within. Anything outside it is clipped off.
    static func unionLength(of intervals: [SleepStageInterval], within bounds: DateInterval) -> TimeInterval {
        let pieces =
            intervals
            .map { (start: max($0.start, bounds.start), end: min($0.end, bounds.end)) }
            .filter { $0.start < $0.end }
            .sorted { $0.start < $1.start }
        var total: TimeInterval = 0
        var open: (start: Date, end: Date)?
        for piece in pieces {
            if let current = open, piece.start <= current.end {
                open = (current.start, max(current.end, piece.end))
            } else {
                if let current = open {
                    total += current.end.timeIntervalSince(current.start)
                }
                open = piece
            }
        }
        if let current = open {
            total += current.end.timeIntervalSince(current.start)
        }
        return total
    }
}

extension SleepStageInterval.Stage {
    /// Whether the stage is sleep, with or without a stage.
    var isAsleep: Bool {
        switch self {
        case .asleepUnspecified, .core, .deep, .rem: true
        case .inBed, .awake: false
        }
    }

    /// Whether the stage is sleep recorded with a stage.
    fileprivate var isStaged: Bool {
        switch self {
        case .core, .deep, .rem: true
        case .inBed, .awake, .asleepUnspecified: false
        }
    }
}
