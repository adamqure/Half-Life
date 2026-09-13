//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FakeWidgetRepositories
//

import Foundation

@testable import Half_Life

/// A widget snapshot repository that streams fixed snapshots, then finishes, and counts its subscriptions.
final class FakeWidgetSnapshotRepository: WidgetSnapshotRepository, Sendable {
    /// The snapshots each subscription streams, in order.
    let sent: [WidgetSnapshot]
    /// How many times `snapshots()` was called.
    let subscriptions = Recorded(0)

    init(snapshots: [WidgetSnapshot] = []) {
        sent = snapshots
    }

    func snapshots() -> AsyncStream<WidgetSnapshot> {
        subscriptions.update { $0 += 1 }
        return AsyncStream { continuation in
            for snapshot in sent {
                continuation.yield(snapshot)
            }
            continuation.finish()
        }
    }
}

/// A widget timeline repository that streams fixed timelines, then finishes, and records the calendars it was asked
/// for.
final class FakeWidgetTimelineRepository: WidgetTimelineRepository, Sendable {
    /// The timelines each call streams, in order.
    let sent: [WidgetTimeline]
    /// The calendar of each call, in order.
    let calendars = Recorded<[Calendar]>([])

    init(timelines: [WidgetTimeline] = []) {
        sent = timelines
    }

    func timeline(in calendar: Calendar) -> AsyncStream<WidgetTimeline> {
        calendars.update { $0.append(calendar) }
        return AsyncStream { continuation in
            for timeline in sent {
                continuation.yield(timeline)
            }
            continuation.finish()
        }
    }
}
