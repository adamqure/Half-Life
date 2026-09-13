//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life AppLockSettingsView
//

import ComposableArchitecture
import SwiftUI

/// Settings' App lock screen: ``AppLockSettingsSection``, pushed from the root's App lock row.
///
/// See the Settings and App Lock articles.
@MainActor
struct AppLockSettingsView: View {
    /// The screen's store.
    let store: StoreOf<AppLockSettingsFeature>

    /// The app lock's section, on its own screen.
    var body: some View {
        SettingsScreen(title: Text("App lock"), screenIdentifier: AppLockSettingsViewAccessibilityID.screen) {
            AppLockSettingsSection(store: store)
        }
        .task { await store.send(.task).finish() }
    }
}
