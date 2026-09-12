//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life Half_LifeApp
//

import ComposableArchitecture
import SwiftUI

/// The Half-Life app's entry point.
@main
@MainActor
struct Half_LifeApp: App {
    /// The root store, created once for the app's lifetime.
    let store = Store(initialState: AppFeature.State()) {
        AppFeature()
    }

    /// The app's single window, hosting ``AppView``.
    var body: some Scene {
        WindowGroup {
            AppView(store: store)
        }
    }
}
