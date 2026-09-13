//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests InsightNumberRuleTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the number check on the model's finding, against NUMCHECK-1 to NUMCHECK-4 in the Insights article. The rule
/// is pure, so its tests need no fakes.
struct InsightNumberRuleTests {

    let rule = InsightNumberRule()

    static let facts = """
        Period: the last 30 days, Aug 14 to Sep 12.
        Caffeine when you fell asleep: over 40 mg on 6 nights, 40 mg or under on 17 nights.
        Time asleep: shorter on the nights over 40 mg than on the others.
        Confidence: an early sign.
        7 nights had no sleep recorded, and aren't counted.
        """

    // MARK: - NUMCHECK-1: a finding whose every number is in the facts passes

    @Test func aFindingWhoseNumbersAreAllInTheFactsPasses() {
        #expect(rule.isGrounded("On 6 nights over 40 mg you slept less than on the other 17", in: Self.facts))
    }

    // MARK: - NUMCHECK-2: a number the facts don't hold fails the finding

    @Test func aNumberTheFactsDontHoldFails() {
        #expect(!rule.isGrounded("Late caffeine cost you 53 minutes of sleep", in: Self.facts))
        #expect(!rule.isGrounded("Over 6 nights, you slept 1.5 hours less", in: Self.facts))
    }

    // MARK: - NUMCHECK-3: a finding with no numbers passes

    @Test func aFindingWithNoNumbersPasses() {
        #expect(rule.isGrounded("Late caffeine, shorter nights: an early sign", in: Self.facts))
    }

    // MARK: - NUMCHECK-4: digits in any script are the same numbers

    @Test func digitsInAnyScriptAreTheSameNumbers() {
        #expect(rule.isGrounded("٦ ليالٍ", in: Self.facts))
        #expect(!rule.isGrounded("٥٣ دقيقة", in: Self.facts))
    }
}
