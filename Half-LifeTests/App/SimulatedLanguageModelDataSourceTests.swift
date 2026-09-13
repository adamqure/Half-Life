//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests SimulatedLanguageModelDataSourceTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the simulated language model that UI tests use, and its registration under a UI test, against SIMLM-1 to
/// SIMLM-3 and DEP-LM-UI in the Language Model article.
struct SimulatedLanguageModelDataSourceTests {

    static func calendar() throws -> Calendar {
        try LanguageModelFormatTests.calendar("America/New_York")
    }

    static func dataSource(isAvailable: Bool = true) throws -> SimulatedLanguageModelDataSource {
        SimulatedLanguageModelDataSource(isAvailable: isAvailable, calendar: try calendar())
    }

    /// SIMLM-1: it's available only when the UI test asked for it.
    @Test func itsAvailableOnlyWhenAskedFor() throws {
        #expect(try Self.dataSource(isAvailable: true).availability() == .available)
        #expect(try Self.dataSource(isAvailable: false).availability() == .unavailable)
    }

    /// SIMLM-2: it writes an insight from the facts an insight's prompt gives the model, with a number in it, which
    /// passes the number check.
    @Test func itWritesAnInsightFromTheFactsThatPassesTheNumberCheck() async throws {
        let written = try await Self.dataSource().writeInsight(.example)
        let facts = InsightFacts(
            pattern: InsightRequest.example.pattern, format: LanguageModelFormat(calendar: try Self.calendar())
        ).text
        let text = written.insight.headline + "\n" + written.insight.sentence

        #expect(written.facts == facts)
        #expect(!written.insight.headline.isEmpty)
        #expect(text.contains { $0.isNumber })
        #expect(InsightNumberRule().isGrounded(text, in: written.facts))
    }

    /// SIMLM-3: it answers every instruction.
    @Test func itAnswersEveryInstruction() async throws {
        let answer = try await Self.dataSource().respond(to: LanguageModelInstruction(prompt: "Hello", origin: .app))

        #expect(!answer.isEmpty)
    }

    /// DEP-LM-UI: under a UI test, the language model is the simulated one. It's unavailable, unless the launch asked
    /// for it.
    @Test func underAUITestTheModelIsTheSimulatedOne() throws {
        let completed = [LaunchEnvironmentKey.profile: LaunchEnvironmentKey.completed]
        let simulated = completed.merging(
            [LaunchEnvironmentKey.languageModel: LaunchEnvironmentKey.simulatedLanguageModel]) { $1 }
        let without = LanguageModelRepositoryKey.makeLiveValue(
            configuration: UITestLaunchConfiguration(environment: completed))
        let with = LanguageModelRepositoryKey.makeLiveValue(
            configuration: UITestLaunchConfiguration(environment: simulated))

        let withoutSource = try #require(
            (without as? LiveLanguageModelRepository)?.dataSource as? SimulatedLanguageModelDataSource)
        let withSource = try #require(
            (with as? LiveLanguageModelRepository)?.dataSource as? SimulatedLanguageModelDataSource)
        #expect(withoutSource.availability() == .unavailable)
        #expect(withSource.availability() == .available)
    }
}
