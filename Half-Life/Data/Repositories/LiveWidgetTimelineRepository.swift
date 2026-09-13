//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life LiveWidgetTimelineRepository
//

import Foundation
import OSLog

/// The widget extension's timeline repository: it reads the snapshot the app wrote and executes
/// ``WidgetTimelineRule``.
///
/// It lives for one timeline, not for the app, so its stream publishes a single timeline and then finishes
/// (constitution Article I.19). With no snapshot yet, or a failed read, it publishes the setup timeline. It's an actor,
/// off the main actor (Article I.13). The Widgets article lists its requirements, WTLREPO-1 and WTLREPO-2.
actor LiveWidgetTimelineRepository: WidgetTimelineRepository {
    private static let logger = Logger(for: LiveWidgetTimelineRepository.self)

    private let snapshots: any WidgetSnapshotDataSource
    private let clock: any ClockDataSource
    private let rule = WidgetTimelineRule()

    /// Creates the repository.
    ///
    /// - Parameters:
    ///   - snapshots: Where the app stores the snapshot.
    ///   - clock: The current time, when the timeline starts.
    init(snapshots: any WidgetSnapshotDataSource, clock: any ClockDataSource) {
        self.snapshots = snapshots
        self.clock = clock
    }

    /// Streams one timeline, starting now, then finishes.
    ///
    /// - Parameter calendar: The calendar, and so the time zone, the bedtime is a time of day in.
    nonisolated func timeline(in calendar: Calendar) -> AsyncStream<WidgetTimeline> {
        AsyncStream { continuation in
            let task = Task {
                continuation.yield(await calculate(in: calendar))
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func calculate(in calendar: Calendar) async -> WidgetTimeline {
        let snapshot: WidgetSnapshot?
        do {
            snapshot = try await snapshots.storedSnapshot()
        } catch {
            let error = error as NSError
            Self.logger.error(
                "Couldn't read the widget snapshot: \(error.domain, privacy: .public) \(error.code, privacy: .public)")
            snapshot = nil
        }
        return rule.timeline(for: snapshot, startingAt: clock.now(), in: calendar)
    }
}
