//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests LanguageModelUseCaseTests
//

import Testing

@testable import Half_Life

/// Checks the language model's use cases against a fake repository (OBSLM-1 and RESPOND-1 in the Language Model
/// article).
struct LanguageModelUseCaseTests {

    struct ModelFailed: Error {}

    static let instruction = LanguageModelInstruction(prompt: "How much caffeine is in me?", origin: .appIntent)

    /// OBSLM-1: it streams every availability the repository publishes, in order.
    @Test func observingTheAvailabilityStreamsWhatTheRepositoryPublishes() async throws {
        let repository = FakeLanguageModelRepository(availabilities: [.unavailable, .available, .unavailable])
        let observe = ObserveLanguageModelAvailabilityUseCase(repository: repository)

        var received: [LanguageModelAvailability] = []
        for await availability in try await executeThroughProtocol(observe, ()) {
            received.append(availability)
        }

        #expect(received == [.unavailable, .available, .unavailable])
    }

    /// RESPOND-1: it returns the repository's response to the instruction.
    @Test func respondingReturnsTheRepositorysResponse() async throws {
        let repository = FakeLanguageModelRepository(response: { "Answer to \($0.prompt)" })
        let respond = RespondToInstructionUseCase(repository: repository)

        let response = try await executeThroughProtocol(respond, Self.instruction)

        #expect(response == "Answer to How much caffeine is in me?")
        #expect(await repository.instructions == [Self.instruction])
    }

    /// RESPOND-1: it throws the repository's error.
    @Test func respondingThrowsTheRepositorysError() async {
        let repository = FakeLanguageModelRepository(response: { _ in throw LanguageModelError.unavailable })
        let respond = RespondToInstructionUseCase(repository: repository)

        await #expect(throws: LanguageModelError.unavailable) {
            try await executeThroughProtocol(respond, Self.instruction)
        }
    }
}
