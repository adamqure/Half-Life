//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests AppFeatureCutoffReminderTests
//

import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// Checks that the root runs the cutoff reminder (APP-REMINDER in the Cutoff Reminder article).
@MainActor
struct AppFeatureCutoffReminderTests {

    /// APP-REMINDER: the reminder's actions reach ``CutoffReminderFeature``, and its state appears under
    /// `AppFeature.State.cutoffReminder`.
    @Test func theReminderActionsReachTheCutoffReminderFeature() async {
        let allowed = Permissions(health: .notRequested, notifications: .allowed, biometrics: .unavailable)
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }

        await store.send(.cutoffReminder(.permissionsUpdated(allowed))) {
            $0.cutoffReminder.notifications = .allowed
        }
    }
}
