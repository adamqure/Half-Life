//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life SettingsFeature
//

import ComposableArchitecture

/// The Settings tab: a root list of rows, each opening its own screen on a navigation stack.
///
/// The rows are About you, Caffeine and your body, Bedtime, Permissions, App lock, and Demo data. Tapping one pushes
/// its screen onto the `StackState` path with fresh state, and the screen observes its own data (constitution Article
/// I.6). The root also runs the profile, app lock, and demo sections, for the values its rows show, and observes the
/// app's version and build for the line under its rows. See the Settings article, SET-1 to SET-5, and the App Lock
/// article.
@Reducer nonisolated struct SettingsFeature {
    /// A screen pushed onto Settings' navigation stack.
    @Reducer nonisolated enum Path {
        /// About you: the name and age.
        case aboutYou(ProfileSettingsFeature)
        /// Caffeine and your body: the factors that change the half-life.
        case halfLifeFactors(ProfileSettingsFeature)
        /// Bedtime.
        case bedtime(ProfileSettingsFeature)
        /// Permissions: Apple Health, notifications, and Face ID or Touch ID.
        case permissions(PermissionsFeature)
        /// App lock.
        case appLock(AppLockSettingsFeature)
        /// Demo data: the demo drinks, and the demo Health data switch.
        case demoData(DemoDataFeature)
    }

    /// A row on Settings' root, one for each screen it opens.
    enum Row: CaseIterable, Sendable {
        /// About you.
        case aboutYou
        /// Caffeine and your body.
        case halfLifeFactors
        /// Bedtime.
        case bedtime
        /// Permissions.
        case permissions
        /// App lock.
        case appLock
        /// Demo data.
        case demoData
    }

    /// The tab's state.
    @ObservableState
    struct State: Equatable {
        /// The screens pushed after the root, in order.
        var path = StackState<Path.State>()
        /// The profile, for the About you, Caffeine and your body, and Bedtime rows' values.
        var profile = ProfileSettingsFeature.State()
        /// The app lock, for its row's value.
        var appLock = AppLockSettingsFeature.State()
        /// The demo drinks, for their row's value.
        var demoHistory = DemoHistoryFeature.State()
        /// The app's version and build, for the root's last line, or `nil` until the repository sends them.
        var appVersion: AppVersion?
    }

    /// What can happen in the tab.
    enum Action {
        /// The root appeared, so it starts observing the app's version.
        case task
        /// The repository sent the app's version and build.
        case appVersionUpdated(AppVersion)
        /// An action for a pushed screen, or a change to the stack.
        case path(StackActionOf<Path>)
        /// The user tapped a row on the root.
        case rowTapped(Row)
        /// An action for the root's profile section.
        case profile(ProfileSettingsFeature.Action)
        /// An action for the root's app lock section.
        case appLock(AppLockSettingsFeature.Action)
        /// An action for the root's demo section.
        case demoHistory(DemoHistoryFeature.Action)
    }

    @Dependency(\.observeAppVersion) var observeAppVersion

    /// Runs the root's sections, observes the app's version, pushes each row's screen, and runs the pushed screens.
    var body: some ReducerOf<Self> {
        Scope(state: \.profile, action: \.profile) {
            ProfileSettingsFeature()
        }
        Scope(state: \.appLock, action: \.appLock) {
            AppLockSettingsFeature()
        }
        Scope(state: \.demoHistory, action: \.demoHistory) {
            DemoHistoryFeature()
        }
        Reduce { state, action in
            switch action {
            case .task:
                return .run { [observeAppVersion] send in
                    for await appVersion in observeAppVersion.execute(()) {
                        await send(.appVersionUpdated(appVersion))
                    }
                }
            case let .appVersionUpdated(appVersion):
                state.appVersion = appVersion
                return .none
            case let .rowTapped(row):
                state.path.append(Self.screen(for: row))
                return .none
            case .path, .profile, .appLock, .demoHistory:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }

    /// The screen a row opens, with fresh state.
    private static func screen(for row: Row) -> Path.State {
        switch row {
        case .aboutYou: .aboutYou(ProfileSettingsFeature.State())
        case .halfLifeFactors: .halfLifeFactors(ProfileSettingsFeature.State())
        case .bedtime: .bedtime(ProfileSettingsFeature.State())
        case .permissions: .permissions(PermissionsFeature.State())
        case .appLock: .appLock(AppLockSettingsFeature.State())
        case .demoData: .demoData(DemoDataFeature.State())
        }
    }
}

/// Lets Settings' `State`, which holds the pushed screens, be `Equatable`.
///
/// It's declared here rather than with `@Reducer(state: .equatable)`, which is deprecated.
extension SettingsFeature.Path.State: Equatable {}
