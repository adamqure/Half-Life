//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests WidgetTimelineRuleTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the widget timeline rule against WTL-1 to WTL-6 in the Widgets article.
struct WidgetTimelineRuleTests {

    /// A whole 5-minute mark: 06:30 GMT.
    static let mark = Date(timeIntervalSinceReferenceDate: 800_001_000)
    /// When the timeline starts, 100 seconds after the mark.
    static let start = mark.addingTimeInterval(100)
    static let hour: TimeInterval = 60 * 60
    static let rule = WidgetTimelineRule()
    static let favourites = [FavouriteDrink(type: .matcha, quantity: 1), FavouriteDrink(type: .cola, quantity: 1)]

    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }

    /// A forecast whose level at each mark is its index, in milligrams, from 12 hours before the mark.
    static func forecast(samples: Int) -> [CaffeineLevel] {
        (0..<samples).map { index in
            CaffeineLevel(
                date: mark.addingTimeInterval(-12 * hour + Double(index) * 5 * 60), milligrams: Double(index))
        }
    }

    static func snapshot(
        samples: Int = 24 * 12 + 1, bedtime: Bedtime = .standard, isOnboardingComplete: Bool = true
    ) -> WidgetSnapshot {
        WidgetSnapshot(
            forecast: forecast(samples: samples), bedtime: bedtime, favourites: favourites,
            latestDrinkAt: mark.addingTimeInterval(-hour), isOnboardingComplete: isOnboardingComplete,
            writtenAt: mark)
    }

    static func timeline(_ snapshot: WidgetSnapshot?) -> WidgetTimeline {
        rule.timeline(for: snapshot, startingAt: start, in: calendar)
    }

    static func content(_ entry: WidgetTimelineEntry?) throws -> WidgetContent {
        let entry = try #require(entry)
        return try #require(entry.content)
    }

    // MARK: - WTL-1: an entry every 5 minutes for 12 hours, then a new timeline

    @Test func thereIsAnEntryAtTheStartAndEveryFiveMinutesForTwelveHours() {
        let entries = Self.timeline(Self.snapshot()).entries

        #expect(entries.count == 12 * 12)
        #expect(entries.first?.date == Self.start)
        #expect(zip(entries, entries.dropFirst()).allSatisfy { $1.date.timeIntervalSince($0.date) == 5 * 60 })
    }

    @Test func itAsksForANewTimelineTwelveHoursAfterItsStart() {
        #expect(Self.timeline(Self.snapshot()).reloadDate == Self.start.addingTimeInterval(12 * Self.hour))
    }

    // MARK: - WTL-2: the level is the forecast's sample at or before the entry, or 0 after the forecast ends

    @Test func theLevelIsTheSampleAtOrBeforeTheEntry() throws {
        let entries = Self.timeline(Self.snapshot()).entries

        // The first entry is 100 seconds after the mark, whose sample is number 144: 12 hours after the forecast's
        // start.
        #expect(try Self.content(entries.first).level == CaffeineLevel(date: Self.start, milligrams: 144))
        #expect(try Self.content(entries[1]).level.milligrams == 145)
    }

    @Test func theLevelIsZeroAfterTheForecastEnds() throws {
        let entries = Self.timeline(Self.snapshot(samples: 12 * 12 + 1 + 6)).entries

        // The forecast's last sample, number 150, is 30 minutes after the mark. The sixth entry after the first is 31
        // minutes 40 seconds after it, so it's past the forecast.
        #expect(try Self.content(entries[5]).level.milligrams == 149)
        #expect(try Self.content(entries[6]).level.milligrams == 0)
    }

    // MARK: - WTL-3: the curve spans 6 hours either side of the entry, and is 0 after the forecast ends

    @Test func theCurveHoldsTheSamplesFromSixHoursBeforeTheEntryToSixHoursAfter() throws {
        let curve = try Self.content(Self.timeline(Self.snapshot()).entries.first).curve

        #expect(curve.first?.date == Self.mark.addingTimeInterval(-6 * Self.hour + 5 * 60))
        #expect(curve.last?.date == Self.mark.addingTimeInterval(6 * Self.hour))
        #expect(curve.map(\.milligrams) == (73...216).map(Double.init))
    }

    @Test func theCurveIsZeroAfterTheForecastEnds() throws {
        let curve = try Self.content(Self.timeline(Self.snapshot(samples: 12 * 12 + 1)).entries.first).curve

        #expect(curve.last?.date == Self.mark.addingTimeInterval(6 * Self.hour))
        #expect(zip(curve, curve.dropFirst()).allSatisfy { $1.date.timeIntervalSince($0.date) == 5 * 60 })
        #expect(curve.filter { $0.date > Self.mark }.allSatisfy { $0.milligrams == 0 })
    }

    // MARK: - WTL-4: the level at the next bedtime, in the given calendar

    @Test func theBedtimeLevelIsTheForecastsLevelAtTheNextBedtime() throws {
        let bedtime = try #require(Bedtime(hour: 11, minute: 0))

        let content = try Self.content(Self.timeline(Self.snapshot(bedtime: bedtime)).entries.first)

        // 11:00 GMT is 4 hours 30 minutes after the mark: sample 144 + 54.
        let atBedtime = Self.mark.addingTimeInterval(4.5 * Self.hour)
        #expect(content.levelAtBedtime == CaffeineLevel(date: atBedtime, milligrams: 198))
    }

    @Test func theBedtimeLevelIsZeroWhenTheBedtimeIsPastTheForecast() throws {
        let content = try Self.content(Self.timeline(Self.snapshot()).entries.first)

        // 22:30 GMT is 16 hours after the mark, and the forecast ends 12 hours after it.
        let bedtime = Self.mark.addingTimeInterval(16 * Self.hour)
        #expect(content.levelAtBedtime == CaffeineLevel(date: bedtime, milligrams: 0))
    }

    // MARK: - WTL-5: until onboarding is complete, or before any snapshot, one setup entry

    @Test func beforeOnboardingIsCompleteThereIsOneSetupEntry() {
        let timeline = Self.timeline(Self.snapshot(isOnboardingComplete: false))

        #expect(timeline.entries == [WidgetTimelineEntry(date: Self.start, content: nil)])
        #expect(timeline.reloadDate == Self.start.addingTimeInterval(12 * Self.hour))
    }

    @Test func withNoSnapshotThereIsOneSetupEntry() {
        #expect(Self.timeline(nil).entries == [WidgetTimelineEntry(date: Self.start, content: nil)])
    }

    // MARK: - WTL-6: the favourites and the last cup come from the snapshot

    @Test func theFavouritesAndTheLatestDrinkComeFromTheSnapshot() throws {
        let content = try Self.content(Self.timeline(Self.snapshot()).entries.last)

        #expect(content.favourites == Self.favourites)
        #expect(content.latestDrinkAt == Self.mark.addingTimeInterval(-Self.hour))
    }
}
