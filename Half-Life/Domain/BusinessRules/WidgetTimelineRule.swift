//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life WidgetTimelineRule
//

import Foundation

/// The business rule that turns a ``WidgetSnapshot`` into the widgets' ``WidgetTimeline``.
///
/// It reads levels from the snapshot's forecast by date, and never evaluates the decay function itself (VIEW-1 in the
/// Caffeine Decay Model article). A level after the forecast ends is 0, because the forecast runs until no intake
/// still counts. It holds no state and reads no clock. The widget extension's ``WidgetTimelineRepository`` executes
/// it. See the Widgets article.
nonisolated struct WidgetTimelineRule: Sendable {
    /// The time between entries, in seconds.
    static let spacing: TimeInterval = 5 * 60
    /// How long a timeline lasts before WidgetKit asks for a new one, in seconds.
    static let length: TimeInterval = 12 * 60 * 60
    /// How far each entry's curve reaches either side of the entry, in seconds.
    static let curveRadius: TimeInterval = 6 * 60 * 60

    /// Returns the timeline starting at `start`.
    ///
    /// With no snapshot, or before onboarding is complete, it's a single entry with no content.
    ///
    /// - Parameters:
    ///   - snapshot: The snapshot the app last wrote, or `nil` if it hasn't written one.
    ///   - start: When the timeline starts: the current time.
    ///   - calendar: The calendar, and so the time zone, the bedtime is a time of day in.
    func timeline(for snapshot: WidgetSnapshot?, startingAt start: Date, in calendar: Calendar) -> WidgetTimeline {
        let reloadDate = start.addingTimeInterval(Self.length)
        guard let snapshot, snapshot.isOnboardingComplete else {
            return WidgetTimeline(entries: [WidgetTimelineEntry(date: start, content: nil)], reloadDate: reloadDate)
        }
        let entries = (0..<Int(Self.length / Self.spacing)).map { index in
            let date = start.addingTimeInterval(Double(index) * Self.spacing)
            return WidgetTimelineEntry(date: date, content: content(at: date, from: snapshot, in: calendar))
        }
        return WidgetTimeline(entries: entries, reloadDate: reloadDate)
    }

    private func content(at date: Date, from snapshot: WidgetSnapshot, in calendar: Calendar) -> WidgetContent {
        let forecast = snapshot.forecast
        let levelAtBedtime = snapshot.bedtime.next(atOrAfter: date, in: calendar).map { bedtime in
            CaffeineLevel(date: bedtime, milligrams: milligrams(at: bedtime, in: forecast))
        }
        return WidgetContent(
            level: CaffeineLevel(date: date, milligrams: milligrams(at: date, in: forecast)),
            curve: curve(around: date, in: forecast), levelAtBedtime: levelAtBedtime,
            favourites: snapshot.favourites, latestDrinkAt: snapshot.latestDrinkAt)
    }

    /// The forecast's level at or before `date`, or 0 outside the forecast.
    private func milligrams(at date: Date, in forecast: [CaffeineLevel]) -> Double {
        guard let last = forecast.last, date <= last.date else { return 0 }
        let index = Self.firstIndex(in: forecast) { $0.date > date } - 1
        return index >= 0 ? forecast[index].milligrams : 0
    }

    /// The forecast's levels within ``curveRadius`` of `date`, with 0 at each mark after the forecast ends.
    private func curve(around date: Date, in forecast: [CaffeineLevel]) -> [CaffeineLevel] {
        guard let last = forecast.last else { return [] }
        let lower = date.addingTimeInterval(-Self.curveRadius)
        let upper = date.addingTimeInterval(Self.curveRadius)
        let first = Self.firstIndex(in: forecast) { $0.date >= lower }
        var curve = Array(forecast[first...].prefix { $0.date <= upper })
        let marksPastTheEnd = max(1, (lower.timeIntervalSince(last.date) / Self.spacing).rounded(.up))
        var padding = last.date.addingTimeInterval(marksPastTheEnd * Self.spacing)
        while padding <= upper {
            curve.append(CaffeineLevel(date: padding, milligrams: 0))
            padding = padding.addingTimeInterval(Self.spacing)
        }
        return curve
    }

    /// The index of the first level for which `isPast` is true, or the count if there's none. The levels are in date
    /// order, and `isPast` is false for every level before the first it's true for.
    private static func firstIndex(in levels: [CaffeineLevel], where isPast: (CaffeineLevel) -> Bool) -> Int {
        var low = 0
        var high = levels.count
        while low < high {
            let middle = (low + high) / 2
            if isPast(levels[middle]) {
                high = middle
            } else {
                low = middle + 1
            }
        }
        return low
    }
}
