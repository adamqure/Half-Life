//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests LiveWidgetTimelineRepositoryTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the widget extension's timeline repository against WTLREPO-1 and WTLREPO-2 in the Widgets article, with a
/// fake snapshot data source.
@Suite(.timeLimit(.minutes(1)))
struct LiveWidgetTimelineRepositoryTests {

    struct DataSourceFailed: Error {}

    static let now = Date(timeIntervalSinceReferenceDate: 800_001_130)

    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }

    static func timelines(_ snapshots: FakeWidgetSnapshotDataSource) async -> [WidgetTimeline] {
        let repository = LiveWidgetTimelineRepository(
            snapshots: snapshots, clock: FakeClockDataSource(date: now, minuteDates: []))
        var timelines: [WidgetTimeline] = []
        for await timeline in repository.timeline(in: calendar) {
            timelines.append(timeline)
        }
        return timelines
    }

    // MARK: - WTLREPO-1: one timeline for the stored snapshot, then the stream finishes

    @Test func itPublishesOneTimelineForTheStoredSnapshotThenFinishes() async {
        let snapshot = WidgetSnapshotRule().snapshot(
            drinks: [], intakes: [], kinetics: .standard, profile: UserProfile(hasCompletedOnboarding: true),
            now: Self.now)

        let timelines = await Self.timelines(FakeWidgetSnapshotDataSource(stored: snapshot))

        #expect(timelines == [WidgetTimelineRule().timeline(for: snapshot, startingAt: Self.now, in: Self.calendar)])
    }

    // MARK: - WTLREPO-2: with no snapshot, or a failed read, the setup timeline

    @Test func withNoSnapshotItPublishesTheSetupTimeline() async {
        let timelines = await Self.timelines(FakeWidgetSnapshotDataSource(stored: nil))

        #expect(timelines == [WidgetTimelineRule().timeline(for: nil, startingAt: Self.now, in: Self.calendar)])
    }

    @Test func aFailedReadPublishesTheSetupTimeline() async {
        let timelines = await Self.timelines(FakeWidgetSnapshotDataSource(readError: DataSourceFailed()))

        #expect(timelines == [WidgetTimelineRule().timeline(for: nil, startingAt: Self.now, in: Self.calendar)])
    }
}
