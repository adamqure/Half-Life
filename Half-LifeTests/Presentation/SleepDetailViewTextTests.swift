//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests SleepDetailViewTextTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks what the Sleep screen's analysis card says (SLEEPSCREEN-4 in the Insights article). The owner chose on
/// 2026-09-13 that it describes both charts, hedged, and leaves the cutoff to the Today screen.
@MainActor
struct SleepDetailViewTextTests {

    static let tolerance = SleepDetailFeature.Finding.tolerance(
        SleepTolerance(milligrams: 35, nightsUnder: 9, nightsOver: 6))

    func sentence(
        _ finding: SleepDetailFeature.Finding, _ fallingAsleep: SleepDetailFeature.FallingAsleep
    ) -> String {
        String(localized: SleepDetailView.explanation(finding, fallingAsleep: fallingAsleep))
    }

    // MARK: - SLEEPSCREEN-4: the analysis describes both charts, hedged, and doesn't mention the cutoff

    @Test func withAToleranceAndLongerToFallAsleepItDescribesBoth() {
        let expected = """
            Sleep is shaped by many things, but the trend in your nights is that with more than 35 mg in you at sleep \
            onset, you sleep less and take longer to fall asleep.
            """

        #expect(sentence(Self.tolerance, .longer) == expected)
    }

    @Test func withAToleranceAndNoTimeInBedItSaysFallingAsleepCantBeComparedYet() {
        let expected = """
            Sleep is shaped by many things, but the trend in your nights is that with more than 35 mg in you at sleep \
            onset, you sleep less. There aren't yet enough nights with the time you got into bed to compare how \
            quickly you fall asleep.
            """

        #expect(sentence(Self.tolerance, .unknown) == expected)
    }

    @Test func withNoDropAndTheSameTimeToFallAsleepItSaysNeitherChanged() {
        let expected = """
            More caffeine at sleep onset hasn't gone with less sleep, or with taking longer to fall asleep, in your \
            nights so far.
            """

        #expect(sentence(.noDrop, .aboutTheSame) == expected)
    }

    @Test func withNoDropAndNoTimeInBedItBeginsWithTheOwnersSentence() {
        #expect(
            sentence(.noDrop, .unknown)
                .hasPrefix("More caffeine at sleep onset hasn't gone with less sleep in your nights so far."))
    }

    @Test func withTooFewNightsItNamesBothMeasures() {
        let text = sentence(.tooFewNights(under: 12, over: 3), .unknown)

        #expect(text.contains("time asleep"))
        #expect(text.contains("fall asleep"))
        #expect(text.contains("So far, 12 at or under it and 3 over it."))
    }

    @Test(arguments: [SleepDetailFeature.FallingAsleep.longer, .shorter, .aboutTheSame, .unknown])
    func noSentenceMentionsTheCutoff(fallingAsleep: SleepDetailFeature.FallingAsleep) {
        for finding in [Self.tolerance, .noDrop, .tooFewNights(under: 1, over: 2)] {
            #expect(!sentence(finding, fallingAsleep).contains("cutoff"))
        }
    }
}
