//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests SettingsFeatureTests
//

import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// Checks Settings' root and its navigation, and that the app's root runs Settings (SET-1 to SET-4 in the Settings
/// article).
@MainActor
struct SettingsFeatureTests {

    // MARK: - SET-1: the root runs the sections its rows summarize

    @Test func theRootRunsTheSectionsItsRowsSummarize() async {
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }

        await store.send(.profile(.profileUpdated(UserProfile(name: "Alex")))) {
            $0.profile.savedProfile = UserProfile(name: "Alex")
            $0.profile.name = "Alex"
        }
        await store.send(.demoHistory(.demoHistoryUpdated(true))) {
            $0.demoHistory.hasDemoHistory = true
        }
    }

    // MARK: - SET-2: the root runs Settings, for its tab

    @Test func theRootRunsSettings() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }

        await store.send(.settings(.demoHistory(.demoHistoryUpdated(false)))) {
            $0.settings.demoHistory.hasDemoHistory = false
        }
    }

    // MARK: - SET-3: each row pushes its own screen

    @Test func eachRowPushesItsOwnScreen() async {
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }

        await store.send(.rowTapped(.aboutYou)) {
            $0.path.append(.aboutYou(ProfileSettingsFeature.State()))
        }
        await store.send(.rowTapped(.halfLifeFactors)) {
            $0.path.append(.halfLifeFactors(ProfileSettingsFeature.State()))
        }
        await store.send(.rowTapped(.bedtime)) {
            $0.path.append(.bedtime(ProfileSettingsFeature.State()))
        }
        await store.send(.rowTapped(.permissions)) {
            $0.path.append(.permissions(PermissionsFeature.State()))
        }
        await store.send(.rowTapped(.appLock)) {
            $0.path.append(.appLock(AppLockSettingsFeature.State()))
        }
        await store.send(.rowTapped(.demoData)) {
            $0.path.append(.demoData(DemoDataFeature.State()))
        }
    }

    // MARK: - SET-4: a pushed screen runs its feature

    @Test func aPushedScreenRunsItsFeature() async {
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }

        await store.send(.rowTapped(.demoData)) {
            $0.path.append(.demoData(DemoDataFeature.State()))
        }
        await store.send(.path(.element(id: 0, action: .demoData(.history(.demoHistoryUpdated(true)))))) {
            $0.path[id: 0, case: \.demoData]?.history.hasDemoHistory = true
        }
    }

    // MARK: - SET-5: the root shows the app's version and build, from the repository

    @Test func theRootShowsTheAppsVersionFromTheRepository() async {
        let version = AppVersion(version: "1.2", build: "34")
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        } withDependencies: {
            $0.observeAppVersion = ObserveAppVersionUseCase(repository: FakeAppVersionRepository(versions: [version]))
        }

        await store.send(.task)
        await store.receive(\.appVersionUpdated) {
            $0.appVersion = version
        }
        await store.finish()
    }
}
