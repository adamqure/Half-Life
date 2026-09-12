//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeUITests DrinkComposerRobot
//

import XCTest

/// Drives `DrinkComposerView`, the sheet that logs a drink.
struct DrinkComposerRobot: Robot {
    /// A drink in the composer's row of tiles.
    enum Drink: CaseIterable {
        case espresso, americano, latte, cappuccino, flatWhite, dripCoffee, coldBrew, instantCoffee
        case blackTea, greenTea, matcha, cola, energyDrink

        fileprivate var tileIdentifier: String {
            switch self {
            case .espresso: DrinkComposerViewAccessibilityID.espressoTile
            case .americano: DrinkComposerViewAccessibilityID.americanoTile
            case .latte: DrinkComposerViewAccessibilityID.latteTile
            case .cappuccino: DrinkComposerViewAccessibilityID.cappuccinoTile
            case .flatWhite: DrinkComposerViewAccessibilityID.flatWhiteTile
            case .dripCoffee: DrinkComposerViewAccessibilityID.dripCoffeeTile
            case .coldBrew: DrinkComposerViewAccessibilityID.coldBrewTile
            case .instantCoffee: DrinkComposerViewAccessibilityID.instantCoffeeTile
            case .blackTea: DrinkComposerViewAccessibilityID.blackTeaTile
            case .greenTea: DrinkComposerViewAccessibilityID.greenTeaTile
            case .matcha: DrinkComposerViewAccessibilityID.matchaTile
            case .cola: DrinkComposerViewAccessibilityID.colaTile
            case .energyDrink: DrinkComposerViewAccessibilityID.energyDrinkTile
            }
        }
    }

    /// When the drink was consumed, as the composer offers it.
    enum When {
        case now, oneHourAgo, twoHoursAgo, fourHoursAgo

        fileprivate var identifier: String {
            switch self {
            case .now: DrinkComposerViewAccessibilityID.whenNow
            case .oneHourAgo: DrinkComposerViewAccessibilityID.whenOneHourAgo
            case .twoHoursAgo: DrinkComposerViewAccessibilityID.whenTwoHoursAgo
            case .fourHoursAgo: DrinkComposerViewAccessibilityID.whenFourHoursAgo
            }
        }
    }

    /// The composer's identifier.
    static let screenIdentifier = DrinkComposerViewAccessibilityID.screen

    /// The app the robot drives.
    let app: XCUIApplication

    private var screen: XCUIElement { app.descendants(matching: .any)[Self.screenIdentifier] }
    private var tiles: XCUIElement { app.scrollViews[DrinkComposerViewAccessibilityID.drinkTiles] }
    private var closeButton: XCUIElement { app.buttons[DrinkComposerViewAccessibilityID.closeButton] }
    private var increaseButton: XCUIElement { app.buttons[DrinkComposerViewAccessibilityID.increaseButton] }
    private var decreaseButton: XCUIElement { app.buttons[DrinkComposerViewAccessibilityID.decreaseButton] }
    private var quantity: XCUIElement { app.staticTexts[DrinkComposerViewAccessibilityID.quantity] }
    private var estimate: XCUIElement { app.staticTexts[DrinkComposerViewAccessibilityID.estimate] }
    private var addButton: XCUIElement { app.buttons[DrinkComposerViewAccessibilityID.addButton] }

    private func tile(_ drink: Drink) -> XCUIElement { app.buttons[drink.tileIdentifier] }
    private func choice(_ when: When) -> XCUIElement { app.buttons[when.identifier] }
    /// Looked for only in the composer, because the Today screen shows the one-tap row too.
    private func favouriteButton(_ favourite: OneTapFavourite) -> XCUIElement {
        screen.buttons[favourite.identifier]
    }

    /// Chooses a drink, scrolling the row of tiles until its tile is fully on screen.
    func selectDrink(_ drink: Drink, file: StaticString = #filePath, line: UInt = #line) {
        let tile = tile(drink)
        XCTAssertTrue(tile.waitForExistence(timeout: 5), "The drink's tile isn't there.", file: file, line: line)
        var drags = 0
        while !isOnScreen(tile) && drags < Drink.allCases.count {
            scrollTiles(toward: tile)
            drags += 1
        }
        XCTAssertTrue(isOnScreen(tile), "The drink's tile never came on screen.", file: file, line: line)
        tile.tap()
    }

    /// Adds one unit of the chosen drink.
    func addOneUnit(file: StaticString = #filePath, line: UInt = #line) {
        tap(increaseButton, named: "The increase button", file: file, line: line)
    }

    /// Removes one unit of the chosen drink.
    func removeOneUnit(file: StaticString = #filePath, line: UInt = #line) {
        tap(decreaseButton, named: "The decrease button", file: file, line: line)
    }

    /// Says when the drink was consumed.
    func choose(_ when: When, file: StaticString = #filePath, line: UInt = #line) {
        tap(choice(when), named: "The \"When\" choice", file: file, line: line)
    }

    /// Closes the composer without logging.
    func close(file: StaticString = #filePath, line: UInt = #line) {
        tap(closeButton, named: "The close button", file: file, line: line)
    }

    /// Logs the chosen drink, with its quantity and when it was consumed. The composer closes once it's logged.
    func logDrink(file: StaticString = #filePath, line: UInt = #line) {
        tap(addButton, named: "The Add button", file: file, line: line)
    }

    /// Logs a one-tap favourite as consumed now, in one tap. The composer closes once it's logged.
    func logFavourite(_ favourite: OneTapFavourite, file: StaticString = #filePath, line: UInt = #line) {
        tap(favouriteButton(favourite), named: "The \(favourite) one-tap drink", file: file, line: line)
    }

    /// Checks that exactly one drink is chosen, and that its quantity and estimate are showing.
    func verifyADrinkIsChosen(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(estimate.waitForExistence(timeout: 5), "No estimate is showing.", file: file, line: line)
        XCTAssertTrue(quantity.exists, "No quantity is showing.", file: file, line: line)
        let chosen = Drink.allCases.filter { tile($0).isSelected }
        XCTAssertEqual(chosen.count, 1, "Expected exactly one chosen drink.", file: file, line: line)
    }

    /// Checks the chosen drink's quantity, such as "2 shots".
    func verifyQuantity(_ text: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(quantity.waitForExistence(timeout: 5), "No quantity is showing.", file: file, line: line)
        XCTAssertEqual(quantity.label, text, file: file, line: line)
    }

    /// Checks the chosen drink's estimated caffeine, such as "125 mg".
    func verifyEstimate(_ text: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(estimate.waitForExistence(timeout: 5), "No estimate is showing.", file: file, line: line)
        XCTAssertEqual(estimate.label, text, file: file, line: line)
    }

    /// Checks which "When" choice is selected.
    func verifyChosen(_ when: When, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(choice(when).waitForExistence(timeout: 5), "The choice isn't showing.", file: file, line: line)
        XCTAssertTrue(choice(when).isSelected, "The choice isn't selected.", file: file, line: line)
    }

    /// Runs the system accessibility audit on the composer, skipping the given checks.
    ///
    /// Every skip needs the owner's approval, and a comment at the call site explaining why (constitution Article
    /// II.4).
    func auditAccessibility(except skipped: XCUIAccessibilityAuditType) throws {
        try app.performAccessibilityAudit(for: XCUIAccessibilityAuditType.all.subtracting(skipped))
    }

    /// Checks that every control and value in the panel, and the close button, is fully on screen.
    func verifyEveryControlIsOnScreen(file: StaticString = #filePath, line: UInt = #line) {
        let elements: [(String, XCUIElement)] = [
            ("close button", closeButton), ("estimate", estimate), ("quantity", quantity),
            ("decrease button", decreaseButton), ("increase button", increaseButton),
            ("Now", choice(.now)), ("1h ago", choice(.oneHourAgo)), ("2h ago", choice(.twoHoursAgo)),
            ("4h ago", choice(.fourHoursAgo)), ("Add button", addButton),
        ]
        for (name, element) in elements {
            XCTAssertTrue(element.waitForExistence(timeout: 5), "The \(name) isn't showing.", file: file, line: line)
            XCTAssertTrue(isOnScreen(element), "The \(name) isn't fully on screen.", file: file, line: line)
        }
    }

    /// Checks that the composer is a compact sheet, well short of the screen's height.
    func verifyIsCompact(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(screen.waitForExistence(timeout: 5), "The composer isn't showing.", file: file, line: line)
        let window = app.windows.firstMatch.frame
        XCTAssertLessThan(
            screen.frame.height, window.height * 0.75, "The composer isn't compact.", file: file, line: line)
    }

    /// Checks that the composer has closed.
    func verifyClosed(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(screen.waitForNonExistence(timeout: 5), "The composer is still open.", file: file, line: line)
    }

    /// Whether all of `element` is inside the app's window. XCUITest can't judge hittability for a tile scrolled off
    /// screen, so the frame is checked instead.
    private func isOnScreen(_ element: XCUIElement) -> Bool {
        let window = app.windows.firstMatch.frame
        return !element.frame.isEmpty && window.contains(element.frame)
    }

    /// Drags the row of tiles a short way toward `tile`, so no tile is skipped over.
    private func scrollTiles(toward tile: XCUIElement) {
        let isToTheRight = tile.frame.midX > app.windows.firstMatch.frame.midX
        let start = tiles.coordinate(withNormalizedOffset: CGVector(dx: isToTheRight ? 0.8 : 0.2, dy: 0.5))
        let end = tiles.coordinate(withNormalizedOffset: CGVector(dx: isToTheRight ? 0.4 : 0.6, dy: 0.5))
        start.press(forDuration: 0.05, thenDragTo: end)
    }

    private func tap(_ element: XCUIElement, named name: String, file: StaticString, line: UInt) {
        XCTAssertTrue(element.waitForExistence(timeout: 5), "\(name) isn't showing.", file: file, line: line)
        element.tap()
    }
}
