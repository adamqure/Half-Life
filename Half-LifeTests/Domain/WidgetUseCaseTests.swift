//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests WidgetUseCaseTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the widgets' use cases against WUSE-1 and WUSE-2 in the Widgets article, with fake repositories.
struct WidgetUseCaseTests {

    static let now = Date(timeIntervalSinceReferenceDate: 800_001_130)

    static let snapshot = WidgetSnapshotRule().snapshot(
        drinks: [], intakes: [], kinetics: .standard, profile: UserProfile(hasCompletedOnboarding: true), now: now)

    // MARK: - WUSE-1: keeping the widgets current subscribes to the snapshots for as long as they come

    @Test func keepingTheWidgetsCurrentSubscribesToTheSnapshotsUntilTheyEnd() async throws {
        let repository = FakeWidgetSnapshotRepository(snapshots: [Self.snapshot, Self.snapshot])

        try await executeThroughProtocol(KeepWidgetsCurrentUseCase(repository: repository), ())

        #expect(repository.subscriptions.value == 1)
    }

    // MARK: - WUSE-2: observing the timeline streams the repository's timeline, in the given calendar

    @Test func observingTheTimelineStreamsTheRepositorysTimelineInTheCalendar() async throws {
        let timeline = WidgetTimelineRule().timeline(for: Self.snapshot, startingAt: Self.now, in: .current)
        let repository = FakeWidgetTimelineRepository(timelines: [timeline])
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt

        let observe = ObserveWidgetTimelineUseCase(repository: repository)

        var received: [WidgetTimeline] = []
        for await value in try await executeThroughProtocol(observe, calendar) {
            received.append(value)
        }

        #expect(received == [timeline])
        #expect(repository.calendars.value == [calendar])
    }
}
