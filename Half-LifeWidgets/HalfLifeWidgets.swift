//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeWidgets HalfLifeWidgets
//

import SwiftUI
import WidgetKit

/// The widget extension's entry point: the One tap and In your system widgets, on the Home Screen.
///
/// The widgets only read what the app stored for them, and a One tap button's intent runs in the app's process, so the
/// app stays the only process that writes user data. See the Widgets article.
@main
@MainActor
struct HalfLifeWidgets: WidgetBundle {
    /// Both widgets.
    var body: some Widget {
        OneTapWidget()
        CaffeineLevelWidget()
    }
}
