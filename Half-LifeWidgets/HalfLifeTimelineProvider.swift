//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeWidgets HalfLifeTimelineProvider
//

import Foundation
import WidgetKit

/// One entry of the widgets' timeline, in the form WidgetKit needs.
struct HalfLifeWidgetEntry: TimelineEntry {
    /// When the entry starts to show.
    let date: Date
    /// The caffeine and the favourites, or `nil` while Half-Life isn't set up.
    let content: WidgetContent?
}

/// Gives both widgets their timeline.
///
/// For each timeline WidgetKit asks for, it takes the first value of ``ObserveWidgetTimelineUseCase`` (constitution
/// Article I.18). The widget gallery and the placeholder show ``HalfLifeWidgetEntry/sample(at:)``, never the user's
/// data. See the Widgets article.
struct HalfLifeTimelineProvider: TimelineProvider {
    /// A sample entry, shown redacted while the widget loads.
    func placeholder(in context: Context) -> HalfLifeWidgetEntry {
        .sample(at: SystemClockDataSource().now())
    }

    /// The sample entry in the widget gallery, and the current entry anywhere else.
    func getSnapshot(in context: Context, completion: @escaping @Sendable (HalfLifeWidgetEntry) -> Void) {
        guard !context.isPreview else {
            completion(.sample(at: SystemClockDataSource().now()))
            return
        }
        Task {
            let timeline = await Self.timeline()
            completion(timeline.entries.first ?? .sample(at: SystemClockDataSource().now()))
        }
    }

    /// The timeline from now, which asks for a new one when it ends.
    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<HalfLifeWidgetEntry>) -> Void) {
        Task {
            completion(await Self.timeline())
        }
    }

    private static func timeline() async -> Timeline<HalfLifeWidgetEntry> {
        let observe = WidgetCompositionRoot.observeWidgetTimeline()
        for await timeline in observe.execute(.autoupdatingCurrent) {
            return Timeline(
                entries: timeline.entries.map { HalfLifeWidgetEntry(date: $0.date, content: $0.content) },
                policy: .after(timeline.reloadDate))
        }
        let setUp = HalfLifeWidgetEntry(date: SystemClockDataSource().now(), content: nil)
        return Timeline(entries: [setUp], policy: .atEnd)
    }
}

extension HalfLifeWidgetEntry {
    /// A sample entry for the widget gallery and the placeholder: the starter favourites and a made-up curve, the same
    /// for everyone, so the gallery never shows the user's data.
    ///
    /// - Parameter date: When the entry shows.
    static func sample(at date: Date) -> HalfLifeWidgetEntry {
        let hourly: [Double] = [0, 0, 118, 108, 176, 162, 148, 135, 122, 110, 99, 89, 80]
        let curve = hourly.enumerated().map { hour, milligrams in
            CaffeineLevel(date: date.addingTimeInterval(Double(hour - 6) * 60 * 60), milligrams: milligrams)
        }
        let content = WidgetContent(
            level: CaffeineLevel(date: date, milligrams: 148), curve: curve,
            levelAtBedtime: CaffeineLevel(date: date.addingTimeInterval(5 * 60 * 60), milligrams: 89),
            favourites: [
                FavouriteDrink(type: .espresso, quantity: 2), FavouriteDrink(type: .flatWhite, quantity: 2),
                FavouriteDrink(type: .coldBrew, quantity: 2),
            ],
            latestDrinkAt: date.addingTimeInterval(-2 * 60 * 60))
        return HalfLifeWidgetEntry(date: date, content: content)
    }

    /// A sample entry with nothing logged: the starter favourites and a flat curve at 0 mg, for previews.
    ///
    /// - Parameter date: When the entry shows.
    static func nothingLogged(at date: Date) -> HalfLifeWidgetEntry {
        let curve = (0...12).map { hour in
            CaffeineLevel(date: date.addingTimeInterval(Double(hour - 6) * 60 * 60), milligrams: 0)
        }
        let content = WidgetContent(
            level: CaffeineLevel(date: date, milligrams: 0), curve: curve,
            levelAtBedtime: CaffeineLevel(date: date.addingTimeInterval(5 * 60 * 60), milligrams: 0),
            favourites: [
                FavouriteDrink(type: .espresso, quantity: 2), FavouriteDrink(type: .flatWhite, quantity: 2),
                FavouriteDrink(type: .coldBrew, quantity: 2),
            ],
            latestDrinkAt: nil)
        return HalfLifeWidgetEntry(date: date, content: content)
    }
}
