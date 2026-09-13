//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests LiveLanguageModelRepositoryTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the live language model repository against LMREPO-1 to LMREPO-5 in the Language Model article, with a
/// fake data source and a fake clock.
struct LiveLanguageModelRepositoryTests {

    struct ModelFailed: Error {}

    static let instruction = LanguageModelInstruction(prompt: "Write tonight's summary.", origin: .app)
    static let start = Date(timeIntervalSinceReferenceDate: 0)

    /// A clock stopped at `start` that streams the given number of minutes after it, then finishes.
    static func clock(minutes: Int) -> FakeClockDataSource {
        FakeClockDataSource(date: start, minuteDates: (0..<minutes).map { start.addingTimeInterval(Double($0) * 60) })
    }

    /// Collects every availability the repository streams until the clock finishes.
    static func availabilities(of repository: LiveLanguageModelRepository) async -> [LanguageModelAvailability] {
        var received: [LanguageModelAvailability] = []
        for await availability in repository.availability() {
            received.append(availability)
        }
        return received
    }

    /// LMREPO-1: a new subscriber immediately receives the current availability.
    @Test func aNewSubscriberReceivesTheCurrentAvailability() async {
        let repository = LiveLanguageModelRepository(
            dataSource: FakeLanguageModelDataSource(availabilities: [.available]), clock: Self.clock(minutes: 0))

        #expect(await Self.availabilities(of: repository) == [.available])
    }

    /// LMREPO-2: at each minute, the availability is re-read, and sent only when it changed.
    @Test func eachMinuteSendsTheAvailabilityOnlyWhenItChanged() async {
        let dataSource = FakeLanguageModelDataSource(
            availabilities: [.unavailable, .unavailable, .available, .available, .unavailable])
        let repository = LiveLanguageModelRepository(dataSource: dataSource, clock: Self.clock(minutes: 4))

        #expect(await Self.availabilities(of: repository) == [.unavailable, .available, .unavailable])
    }

    /// LMREPO-3: while the model is available, the instruction reaches the data source, and its response comes back.
    @Test func respondingWhileAvailableReturnsTheDataSourcesResponse() async throws {
        let dataSource = FakeLanguageModelDataSource(availabilities: [.available], response: { _ in "Sleep by 11." })
        let repository = LiveLanguageModelRepository(dataSource: dataSource, clock: Self.clock(minutes: 0))

        let response = try await repository.respond(to: Self.instruction)

        #expect(response == "Sleep by 11.")
        #expect(dataSource.received.value == [Self.instruction])
    }

    /// LMREPO-4: while the model is unavailable, responding throws and never reaches the data source.
    @Test func respondingWhileUnavailableThrowsWithoutReachingTheDataSource() async {
        let dataSource = FakeLanguageModelDataSource(availabilities: [.unavailable], response: { _ in "Sleep by 11." })
        let repository = LiveLanguageModelRepository(dataSource: dataSource, clock: Self.clock(minutes: 0))

        await #expect(throws: LanguageModelError.unavailable) {
            try await repository.respond(to: Self.instruction)
        }
        #expect(dataSource.received.value.isEmpty)
    }

    /// LMREPO-5: the data source's error is thrown on to the caller.
    @Test func respondingThrowsTheDataSourcesError() async {
        let dataSource = FakeLanguageModelDataSource(
            availabilities: [.available], response: { _ in throw ModelFailed() })
        let repository = LiveLanguageModelRepository(dataSource: dataSource, clock: Self.clock(minutes: 0))

        await #expect(throws: ModelFailed.self) {
            try await repository.respond(to: Self.instruction)
        }
    }
}
