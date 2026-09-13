//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests AskHalfLifeIntentTests
//

import AppIntents
import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// INTENT-ASK-1 to INTENT-ASK-3 in the App Intents article, with the language model faked.
struct AskHalfLifeIntentTests {

    /// Records whether the fallback asked to open the app.
    actor OpenedApp {
        private(set) var opens = 0

        func open() {
            opens += 1
        }
    }

    /// INTENT-ASK-1: the question goes to the model as the user's own words, and the model's answer comes back.
    @Test func itAsksTheModelInTheUsersWordsAndAnswersWithItsResponse() async throws {
        let model = FakeLanguageModelRepository(response: { _ in "About 85 mg." })
        let opened = OpenedApp()

        let answer = try await AskHalfLifeIntent.answer(
            "How much caffeine is in me?", respondToInstruction: RespondToInstructionUseCase(repository: model),
            format: try AppIntentTesting.format()
        ) { _ in await opened.open() }

        #expect(String(localized: answer) == "About 85 mg.")
        #expect(
            await model.instructions
                == [LanguageModelInstruction(prompt: "How much caffeine is in me?", origin: .appIntent)])
        #expect(await opened.opens == 0)
    }

    /// INTENT-ASK-1, through `perform()`: the intent's question reaches the model.
    @Test func performAsksTheModel() async throws {
        let model = FakeLanguageModelRepository(response: { _ in "About 85 mg." })
        let calendar = try AppIntentTesting.newYork()
        let intent = withDependencies {
            $0.calendar = calendar
            $0.respondToInstruction = RespondToInstructionUseCase(repository: model)
        } operation: {
            AskHalfLifeIntent()
        }
        intent.question = "How much caffeine is in me?"

        _ = try await intent.perform()

        #expect(await model.instructions.map(\.prompt) == ["How much caffeine is in me?"])
    }

    /// INTENT-ASK-2: without Apple Intelligence, it asks to open the app instead.
    @Test func withoutTheModelItAsksToOpenTheApp() async throws {
        let model = FakeLanguageModelRepository(response: { _ in throw LanguageModelError.unavailable })
        let opened = OpenedApp()
        let format = try AppIntentTesting.format()

        let answer = try await AskHalfLifeIntent.answer(
            "How much caffeine is in me?", respondToInstruction: RespondToInstructionUseCase(repository: model),
            format: format
        ) { _ in await opened.open() }

        #expect(await opened.opens == 1)
        #expect(String(localized: answer) == String(localized: format.openingApp))
    }

    /// INTENT-ASK-3: any other error fails with "couldn't answer", and doesn't open the app.
    @Test func anyOtherErrorFailsAsCouldntAnswer() async throws {
        let model = FakeLanguageModelRepository(response: { _ in throw AppIntentTesting.StoreFailed() })
        let opened = OpenedApp()

        await #expect(throws: IntentFailure.couldntAnswer) {
            _ = try await AskHalfLifeIntent.answer(
                "How much caffeine is in me?", respondToInstruction: RespondToInstructionUseCase(repository: model),
                format: try AppIntentTesting.format()
            ) { _ in await opened.open() }
        }
        #expect(await opened.opens == 0)
    }

    /// INTENT-ASK-2: the prompt to open the app, and what it says as it opens.
    @Test func theFallbackSaysAppleIntelligenceIsNeeded() throws {
        let format = try AppIntentTesting.format()

        #expect(
            String(localized: format.needsApp)
                == "Answers need Apple Intelligence. Open Half-Life to see your caffeine?")
        #expect(String(localized: format.openingApp) == "Opening Half-Life.")
    }
}
