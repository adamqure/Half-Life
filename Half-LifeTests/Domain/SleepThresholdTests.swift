//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests SleepThresholdTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the sleep threshold entity (THRESH-1, THRESH-2, and THRESH-5 in the Caffeine Cutoff article).
struct SleepThresholdTests {

    /// THRESH-1: until it's personalised, the threshold is 40 mg.
    @Test func standardThresholdIsFortyMilligrams() {
        #expect(SleepThreshold.standard.milligrams == 40)
    }

    /// THRESH-2: a threshold is a positive, finite amount.
    @Test(arguments: [0.5, 40, 250])
    func acceptsAPositiveAmount(milligrams: Double) throws {
        #expect(try #require(SleepThreshold(milligrams: milligrams)).milligrams == milligrams)
    }

    /// THRESH-2: anything else isn't a threshold.
    @Test(arguments: [0, -1, Double.infinity, Double.nan])
    func rejectsAnAmountThatIsNotPositiveAndFinite(milligrams: Double) {
        #expect(SleepThreshold(milligrams: milligrams) == nil)
    }

    /// THRESH-5: the standard threshold comes from clinical sleep studies, and any other is learned from the user's
    /// nights, so a learned 40 mg isn't the standard.
    @Test func theStandardComesFromSleepStudiesAndAnyOtherIsLearned() throws {
        #expect(SleepThreshold.standard.source == .sleepStudies)
        #expect(try #require(SleepThreshold(milligrams: 35)).source == .learned)
        #expect(try #require(SleepThreshold(milligrams: 40)) != .standard)
    }
}
