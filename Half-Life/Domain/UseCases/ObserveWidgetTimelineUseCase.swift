//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life ObserveWidgetTimelineUseCase
//

import Foundation

/// Streams the widgets' timeline, for the widget extension's timeline providers.
///
/// A provider takes the first timeline for each timeline WidgetKit asks for (constitution Article I.18). See WUSE-2 in
/// the Widgets article.
struct ObserveWidgetTimelineUseCase: UseCase {
    /// The repository that reads the snapshot.
    let repository: any WidgetTimelineRepository

    /// Streams the timeline, starting now.
    ///
    /// - Parameter calendar: The calendar, and so the time zone, the bedtime is a time of day in.
    /// - Returns: The repository's timeline stream.
    func execute(_ calendar: Calendar) -> AsyncStream<WidgetTimeline> {
        repository.timeline(in: calendar)
    }
}
