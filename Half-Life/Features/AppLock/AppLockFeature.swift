//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life AppLockFeature
//

import ComposableArchitecture
import Foundation
import OSLog

/// The lock screen, which hides the app while it's locked and asks the user to unlock it.
///
/// It asks by itself once when the app becomes active while locked, and again whenever its Unlock button is tapped. It
/// learns that the app unlocked from the lock the root observes, which then removes it (constitution Article I.5).
/// Dismissing the system's prompt makes the app active again, so the screen asks by itself only once until the app has
/// been in the background. See the App Lock article, LOCKSCREEN-1 and LOCKSCREEN-2.
@Reducer nonisolated struct AppLockFeature {
    private static let logger = Logger(for: AppLockFeature.self)

    /// The lock screen's state.
    @ObservableState
    struct State: Equatable {
        /// Whether the screen has asked by itself since it appeared or the app last came back from the background.
        var hasPrompted = false
        /// Whether the system's prompt is showing.
        var isUnlocking = false
    }

    /// What can happen on the lock screen.
    enum Action {
        /// The app became active while the screen was showing, so it asks by itself if it hasn't yet.
        case becameActive
        /// The app went to the background, so the screen will ask by itself when the app comes back.
        case enteredBackground
        /// The user tapped Unlock.
        case unlockTapped
        /// The prompt ended, whether or not the user passed.
        case unlockFinished
    }

    @Dependency(\.unlockApp) var unlockApp

    /// Asks to unlock at most once at a time, and by itself at most once per return from the background.
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .becameActive:
                guard !state.hasPrompted else { return .none }
                state.hasPrompted = true
                return unlock(&state)
            case .enteredBackground:
                state.hasPrompted = false
                return .none
            case .unlockTapped:
                return unlock(&state)
            case .unlockFinished:
                state.isUnlocking = false
                return .none
            }
        }
    }

    /// Shows the prompt, unless it's already showing. A failure is logged, and the button can ask again.
    private func unlock(_ state: inout State) -> Effect<Action> {
        guard !state.isUnlocking else { return .none }
        state.isUnlocking = true
        return .run { [unlockApp] send in
            try await unlockApp.execute(())
            await send(.unlockFinished)
        } catch: { error, send in
            let domain = (error as NSError).domain
            let code = (error as NSError).code
            Self.logger.error("Couldn't unlock the app: \(domain, privacy: .public) \(code, privacy: .public)")
            await send(.unlockFinished)
        }
    }
}
