//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life WidgetKitReloadDataSource
//

import WidgetKit

/// Reloads the Home Screen widgets through WidgetKit's `WidgetCenter`.
///
/// It's the only code in the app that touches WidgetKit (constitution Article I.14). A reload the app asks for while
/// it's in the foreground doesn't count against the widgets' daily budget. See the Widgets article.
struct WidgetKitReloadDataSource: WidgetReloadDataSource {
    /// Asks WidgetKit for a new timeline for every one of Half-Life's widgets.
    func reloadAllTimelines() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
