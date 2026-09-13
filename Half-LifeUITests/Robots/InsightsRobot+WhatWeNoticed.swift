//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeUITests InsightsRobot+WhatWeNoticed
//

import XCTest

extension InsightsRobot {
    /// An answer to "Feel right?" on the "What we noticed" card.
    enum FeelRight {
        case yes, notReally
    }

    /// How long the card may take to appear: the analysis reads 30 days of sleep and drinks, then the model writes.
    private static let noticedTimeout: TimeInterval = 20

    private var noticedCard: XCUIElement { app.descendants(matching: .any)[InsightsViewAccessibilityID.noticedCard] }
    private var noticedHeadline: XCUIElement {
        app.descendants(matching: .any)[InsightsViewAccessibilityID.noticedHeadline]
    }
    private var noticedSentence: XCUIElement {
        app.descendants(matching: .any)[InsightsViewAccessibilityID.noticedSentence]
    }
    private var noticedDemo: XCUIElement { app.descendants(matching: .any)[InsightsViewAccessibilityID.noticedDemo] }
    private var sleepWindowCard: XCUIElement {
        app.descendants(matching: .any)[InsightsViewAccessibilityID.sleepWindowCard]
    }

    private func button(_ answer: FeelRight) -> XCUIElement {
        switch answer {
        case .yes: app.buttons[InsightsViewAccessibilityID.feelRightYes]
        case .notReally: app.buttons[InsightsViewAccessibilityID.feelRightNotReally]
        }
    }

    /// Checks that "What we noticed" shows a finding, a headline and a sentence in the model's words, and asks "Feel
    /// right?".
    func verifyNoticedCardAsks(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(
            noticedCard.waitForExistence(timeout: Self.noticedTimeout), "\"What we noticed\" didn't appear.",
            file: file, line: line)
        require(noticedHeadline, "The finding's headline", file: file, line: line)
        require(noticedSentence, "The finding's sentence", file: file, line: line)
        require(button(.yes), "The \"Yes\" answer", file: file, line: line)
        require(button(.notReally), "The \"Not really\" answer", file: file, line: line)
    }

    /// Checks that the card says its finding comes from the demo Health data.
    func verifyNoticedCardSaysDemo(file: StaticString = #filePath, line: UInt = #line) {
        require(noticedDemo, "The demo Health data label", file: file, line: line)
    }

    /// Answers "Feel right?".
    func answerFeelRight(_ answer: FeelRight, file: StaticString = #filePath, line: UInt = #line) {
        require(button(answer), "The \(answer) answer", file: file, line: line)
        button(answer).tap()
    }

    /// Checks that the card still shows its finding, without asking "Feel right?".
    func verifyNoticedCardWithoutTheQuestion(file: StaticString = #filePath, line: UInt = #line) {
        require(noticedHeadline, "The finding's headline", file: file, line: line)
        XCTAssertTrue(waitForAbsence(of: button(.yes)), "The card still asks \"Feel right?\".", file: file, line: line)
    }

    /// Checks that there's no "What we noticed" card once tonight's sleep window has loaded. A card that's showing
    /// has 5 seconds to go.
    func verifyNoNoticedCard(file: StaticString = #filePath, line: UInt = #line) {
        require(sleepWindowCard, "Tonight's sleep window", file: file, line: line)
        XCTAssertTrue(waitForAbsence(of: noticedCard), "\"What we noticed\" shows.", file: file, line: line)
    }

    /// Waits up to 5 seconds for `element` to be gone, and returns whether it went.
    private func waitForAbsence(of element: XCUIElement) -> Bool {
        let gone = NSPredicate(format: "exists == false")
        return XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: gone, object: element)], timeout: 5)
            == .completed
    }
}
