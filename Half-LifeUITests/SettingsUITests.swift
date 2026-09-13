//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeUITests SettingsUITests
//

import XCTest

/// Drives the Settings tab against UI-SET-1 to UI-SET-8 in the Settings article.
///
/// Each test launches past onboarding, with a new profile that has nothing else saved, an empty drink log, and
/// simulated permissions, then opens the tab, and opens a row's screen where it needs one.
final class SettingsUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Launches past onboarding and opens the Settings tab.
    @MainActor
    private func launchIntoSettings() throws -> (XCUIApplication, SettingsRobot) {
        let app = XCUIApplication()
        app.launchPastOnboarding()
        try app.resolve(AppRobot.self).openSettings()
        return (app, try app.resolve(SettingsRobot.self))
    }

    /// UI-SET-1: Settings opens from its tab, and its rows show the saved answers. Today opens from its own tab.
    @MainActor
    func testSettingsOpensFromItsTabAndTodayFromItsOwn() throws {
        let (app, settings) = try launchIntoSettings()
        settings.verifyRow(.bedtime, shows: "10:30")

        try app.resolve(AppRobot.self).openToday()
        try app.resolve(TodayRobot.self).verifyGreetingForTheTimeOfDay()
    }

    /// UI-SET-2: a name saved on the About you screen greets the user on the Today screen.
    @MainActor
    func testANameSavedInSettingsGreetsTheUserOnToday() throws {
        let (app, settings) = try launchIntoSettings()
        settings.open(.aboutYou)
        try app.resolve(AboutYouSettingsRobot.self).enterName("Alex")

        try app.resolve(AppRobot.self).openToday()
        try app.resolve(TodayRobot.self).verifyGreeting(names: "Alex")
    }

    /// UI-SET-3: a factor chosen in Settings shows as chosen once it's saved.
    @MainActor
    func testAFactorChosenInSettingsShowsAsChosen() throws {
        let (app, settings) = try launchIntoSettings()
        settings.open(.halfLifeFactors)
        let factors = try app.resolve(FactorsSettingsRobot.self)

        factors.chooseFactor(.estrogen)

        factors.verifyChosen(.estrogen)
    }

    /// UI-SET-4: each permission shows the outcome of asking for it, from the simulated data sources.
    @MainActor
    func testPermissionsCanBeAskedForInSettings() throws {
        let (app, settings) = try launchIntoSettings()
        settings.open(.permissions)
        let permissions = try app.resolve(PermissionSettingsRobot.self)

        permissions.allowHealth()
        permissions.verifyHealthAsked()
        permissions.allowNotifications()
        permissions.verifyNotificationsOn()
    }

    /// UI-SET-5: the demo drinks fill the log, labeled as demo drinks, and can be removed. Yesterday always has demo
    /// drinks, whatever time the test runs. The Settings tab keeps its screen while Today shows.
    @MainActor
    func testDemoDrinksFillTheLogAndCanBeRemoved() throws {
        let (app, settings) = try launchIntoSettings()
        settings.open(.demoData)
        let demo = try app.resolve(DemoHistorySettingsRobot.self)
        demo.addDemoDrinks()
        demo.verifyHasDemoDrinks(true)

        try app.resolve(AppRobot.self).openToday()
        let today = try app.resolve(TodayRobot.self)
        today.showHistory()
        today.showPreviousDay()
        today.verifyHistoryShows(.yesterday)
        today.verifyListsADemoDrink()
        try today.auditAccessibilityAboveTheTabBar()

        try app.resolve(AppRobot.self).openSettings()
        let demoAgain = try app.resolve(DemoHistorySettingsRobot.self)
        demoAgain.removeDemoDrinks()
        demoAgain.verifyHasDemoDrinks(false)
    }

    /// UI-SET-7: the root's last line shows the app's version and build.
    @MainActor
    func testTheRootShowsTheAppVersion() throws {
        let (_, settings) = try launchIntoSettings()

        settings.verifyShowsTheAppVersion()
    }

    /// UI-SET-8: the root links to the privacy policy, under the app's version.
    @MainActor
    func testTheRootLinksToThePrivacyPolicy() throws {
        let (_, settings) = try launchIntoSettings()

        settings.verifyLinksToThePrivacyPolicy()
    }

    // MARK: - UI-SET-6: every Settings screen passes the system accessibility audit (constitution Article VI.4)

    /// UI-SET-6: the root.
    @MainActor
    func testTheRootPassesTheAccessibilityAudit() throws {
        let (_, settings) = try launchIntoSettings()

        try settings.auditAccessibilityAboveTheTabBar()
    }

    /// UI-SET-6: About you.
    @MainActor
    func testAboutYouPassesTheAccessibilityAudit() throws {
        try auditScreen(.aboutYou, AboutYouSettingsRobot.self)
    }

    /// UI-SET-6: Caffeine and your body.
    @MainActor
    func testCaffeineAndYourBodyPassesTheAccessibilityAudit() throws {
        try auditScreen(.halfLifeFactors, FactorsSettingsRobot.self)
    }

    /// UI-SET-6: Bedtime, whose time picker shows.
    @MainActor
    func testBedtimePassesTheAccessibilityAudit() throws {
        let (app, settings) = try launchIntoSettings()
        settings.open(.bedtime)
        let bedtime = try app.resolve(BedtimeSettingsRobot.self)

        bedtime.verifyShowsTheBedtime()
        try bedtime.auditAccessibilityAboveTheTabBar()
    }

    /// UI-SET-6: Permissions.
    @MainActor
    func testPermissionsPassesTheAccessibilityAudit() throws {
        try auditScreen(.permissions, PermissionSettingsRobot.self)
    }

    /// UI-SET-6: App lock.
    @MainActor
    func testAppLockPassesTheAccessibilityAudit() throws {
        try auditScreen(.appLock, AppLockSettingsRobot.self)
    }

    /// UI-SET-6: Demo data.
    @MainActor
    func testDemoDataPassesTheAccessibilityAudit() throws {
        try auditScreen(.demoData, DemoHistorySettingsRobot.self)
    }

    /// Opens `destination` and audits the screen `robot` drives.
    @MainActor
    private func auditScreen<R: Robot>(_ destination: SettingsRobot.Screen, _ robot: R.Type) throws {
        let (app, settings) = try launchIntoSettings()
        settings.open(destination)

        try app.resolve(robot).auditAccessibilityAboveTheTabBar()
    }
}
