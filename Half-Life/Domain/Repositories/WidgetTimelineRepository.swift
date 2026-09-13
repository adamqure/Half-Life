//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life WidgetTimelineRepository
//

import Foundation

/// The widget extension's source of the widgets' ``WidgetTimeline``, read from the snapshot the app stored.
///
/// ``LiveWidgetTimelineRepository`` implements it. It lives for one timeline, not for the app (constitution Article
/// I.19). See the Widgets article.
protocol WidgetTimelineRepository: Sendable {
    /// Streams one timeline, starting now, then finishes.
    ///
    /// - Parameter calendar: The calendar, and so the time zone, the bedtime is a time of day in.
    func timeline(in calendar: Calendar) -> AsyncStream<WidgetTimeline>
}
