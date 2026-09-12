//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeUITests OnboardingUITests
//

import XCTest

/// Onboarding's scenarios (UI-ONB-1 to UI-ONB-6 in the Onboarding article). Each launch starts with nothing saved and
/// simulated permissions.
final class OnboardingUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// UI-ONB-1: a fresh launch shows Welcome, and skipping every step reaches the Today screen.
    @MainActor
    func testSkippingEveryStepReachesToday() throws {
        let app = XCUIApplication()
        app.launchAtOnboarding()

        try app.resolve(WelcomeRobot.self).getStarted()
        try app.resolve(AboutYouRobot.self).continueToNextStep()
        try app.resolve(HalfLifeFactorsRobot.self).continueToNextStep()
        try app.resolve(BedtimeRobot.self).continueToNextStep()
        try app.resolve(PermissionsRobot.self).continueToNextStep()
        try app.resolve(OnboardingSummaryRobot.self).takeMeToToday()

        try app.resolve(TodayRobot.self).verifyGreetingForTheTimeOfDay()
    }

    /// UI-ONB-2: a name entered in About you appears on the summary and in the Today screen's greeting.
    @MainActor
    func testTheNameAppearsOnTheSummaryAndInTheGreeting() throws {
        let app = XCUIApplication()
        app.launchAtOnboarding()

        try app.resolve(WelcomeRobot.self).getStarted()
        let aboutYou = try app.resolve(AboutYouRobot.self)
        aboutYou.enterName("Alex")
        aboutYou.chooseAge(30)
        aboutYou.continueToNextStep()
        try app.resolve(HalfLifeFactorsRobot.self).continueToNextStep()
        try app.resolve(BedtimeRobot.self).continueToNextStep()
        try app.resolve(PermissionsRobot.self).continueToNextStep()
        let summary = try app.resolve(OnboardingSummaryRobot.self)
        summary.verifyTitle(names: "Alex")
        summary.takeMeToToday()

        try app.resolve(TodayRobot.self).verifyGreeting(names: "Alex")
    }

    /// UI-ONB-5: a factor sets the starting half-life, on its step and on the summary.
    @MainActor
    func testEstrogenGivesAStartingHalfLifeOfAboutEightHours() throws {
        let app = XCUIApplication()
        app.launchAtOnboarding()

        try app.resolve(WelcomeRobot.self).getStarted()
        try app.resolve(AboutYouRobot.self).continueToNextStep()
        let factors = try app.resolve(HalfLifeFactorsRobot.self)
        factors.verifyStartingHalfLife("5.5")
        factors.choose(.estrogen)
        factors.verifyChosen(.estrogen)
        factors.verifyStartingHalfLife("8.3")
        factors.continueToNextStep()
        try app.resolve(BedtimeRobot.self).continueToNextStep()
        try app.resolve(PermissionsRobot.self).continueToNextStep()

        try app.resolve(OnboardingSummaryRobot.self).verifyStartingHalfLife("8.3")
    }

    /// UI-ONB-5: pregnancy takes its trimester.
    @MainActor
    func testPregnancyInTheThirdTrimesterLengthensTheHalfLife() throws {
        let app = XCUIApplication()
        app.launchAtOnboarding()

        try app.resolve(WelcomeRobot.self).getStarted()
        try app.resolve(AboutYouRobot.self).continueToNextStep()
        let factors = try app.resolve(HalfLifeFactorsRobot.self)
        factors.choosePregnancy(trimester: .third)

        factors.verifyPregnancy(trimester: .third)
        factors.verifyStartingHalfLife("14.9")
    }

    /// UI-ONB-6: each permission shows the outcome of asking for it.
    @MainActor
    func testEachPermissionShowsItsOutcome() throws {
        let app = XCUIApplication()
        app.launchAtOnboarding()

        try app.resolve(WelcomeRobot.self).getStarted()
        try app.resolve(AboutYouRobot.self).continueToNextStep()
        try app.resolve(HalfLifeFactorsRobot.self).continueToNextStep()
        try app.resolve(BedtimeRobot.self).continueToNextStep()
        let permissions = try app.resolve(PermissionsRobot.self)
        permissions.allowHealth()
        permissions.verifyHealthAsked()
        permissions.allowNotifications()
        permissions.verifyNotificationsOn()
        permissions.allowBiometrics()
        permissions.verifyBiometricsOn()
    }

    /// ONB-3: "Log my first cup" finishes onboarding and opens the drink composer.
    @MainActor
    func testLogMyFirstCupOpensTheComposer() throws {
        let app = XCUIApplication()
        app.launchAtOnboarding()

        try app.resolve(WelcomeRobot.self).getStarted()
        try app.resolve(AboutYouRobot.self).continueToNextStep()
        try app.resolve(HalfLifeFactorsRobot.self).continueToNextStep()
        try app.resolve(BedtimeRobot.self).continueToNextStep()
        try app.resolve(PermissionsRobot.self).continueToNextStep()
        try app.resolve(OnboardingSummaryRobot.self).logFirstCup()

        _ = try app.resolve(DrinkComposerRobot.self)
    }

    /// UI-ONB-8: every screen scrolls only vertically. A sideways swipe leaves its content inside the screen's width.
    @MainActor
    func testEveryStepScrollsOnlyVertically() throws {
        let app = XCUIApplication()
        app.launchAtOnboarding()

        try verifyEveryStepScrollsOnlyVertically(in: app)
    }

    /// UI-ONB-8: every screen scrolls only vertically at the largest accessibility text size too.
    @MainActor
    func testEveryStepScrollsOnlyVerticallyWithTheLargestText() throws {
        let app = XCUIApplication()
        app.launchAtOnboardingWithTheLargestText()

        try verifyEveryStepScrollsOnlyVertically(in: app)
    }

    /// Walks from Welcome to the summary, checking on each screen that a sideways swipe doesn't move the content.
    @MainActor
    private func verifyEveryStepScrollsOnlyVertically(in app: XCUIApplication) throws {
        let welcome = try app.resolve(WelcomeRobot.self)
        welcome.verifyScrollsOnlyVertically()
        welcome.getStarted()
        let aboutYou = try app.resolve(AboutYouRobot.self)
        aboutYou.verifyScrollsOnlyVertically()
        aboutYou.continueToNextStep()
        let factors = try app.resolve(HalfLifeFactorsRobot.self)
        factors.choosePregnancy(trimester: .second)
        factors.verifyPregnancy(trimester: .second)
        factors.verifyScrollsOnlyVertically()
        factors.continueToNextStep()
        let bedtime = try app.resolve(BedtimeRobot.self)
        bedtime.verifyScrollsOnlyVertically()
        bedtime.continueToNextStep()
        let permissions = try app.resolve(PermissionsRobot.self)
        permissions.verifyScrollsOnlyVertically()
        permissions.continueToNextStep()
        try app.resolve(OnboardingSummaryRobot.self).verifyScrollsOnlyVertically()
    }

    /// UI-ONB-3: every step passes the system accessibility audit (constitution Article VI.4).
    @MainActor
    func testEveryStepPassesTheAccessibilityAudit() throws {
        let app = XCUIApplication()
        app.launchAtOnboarding()

        let welcome = try app.resolve(WelcomeRobot.self)
        try welcome.auditAccessibility()
        welcome.getStarted()
        let aboutYou = try app.resolve(AboutYouRobot.self)
        try aboutYou.auditAccessibility()
        aboutYou.continueToNextStep()
        let factors = try app.resolve(HalfLifeFactorsRobot.self)
        factors.choosePregnancy(trimester: .second)
        factors.verifyPregnancy(trimester: .second)
        try factors.auditAccessibility()
        factors.continueToNextStep()
        let bedtime = try app.resolve(BedtimeRobot.self)
        bedtime.verifyBedtimePicker()
        try bedtime.auditAccessibility()
        bedtime.continueToNextStep()
        let permissions = try app.resolve(PermissionsRobot.self)
        try permissions.auditAccessibility()
        permissions.continueToNextStep()
        try app.resolve(OnboardingSummaryRobot.self).auditAccessibility()
    }
}
