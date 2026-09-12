//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests ProfileSaveUseCaseTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks onboarding's use cases against the fake profile repository.
struct ProfileSaveUseCaseTests {

    static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()

    /// Midsummer 2026, in UTC.
    static let now = utc.date(from: DateComponents(year: 2026, month: 6, day: 15, hour: 12)) ?? .distantPast

    // MARK: - SaveAboutYouUseCase

    static func saveAboutYou(_ repository: FakeUserProfileRepository) -> SaveAboutYouUseCase {
        SaveAboutYouUseCase(currentTime: FakeCurrentTimeRepository(date: now), profile: repository)
    }

    @Test func savesTheNameAndTheBirthYearTheAgeImplies() async throws {
        let repository = FakeUserProfileRepository()

        try await executeThroughProtocol(
            Self.saveAboutYou(repository), SaveAboutYouUseCase.Input(name: "Alex", age: 30, calendar: Self.utc))

        #expect(await repository.savedAboutYou == [.init(name: "Alex", birthYear: 1996)])
    }

    @Test func trimsTheNameAndSavesABlankOneAsNone() async throws {
        let repository = FakeUserProfileRepository()
        let save = Self.saveAboutYou(repository)

        try await executeThroughProtocol(
            save, SaveAboutYouUseCase.Input(name: "  Sam \n", age: nil, calendar: Self.utc))
        try await executeThroughProtocol(save, SaveAboutYouUseCase.Input(name: "   ", age: nil, calendar: Self.utc))
        try await executeThroughProtocol(save, SaveAboutYouUseCase.Input(name: nil, age: nil, calendar: Self.utc))

        #expect(
            await repository.savedAboutYou == [
                .init(name: "Sam", birthYear: nil), .init(name: nil, birthYear: nil), .init(name: nil, birthYear: nil),
            ])
    }

    @Test func countsTheAgeInTheGivenCalendarsYear() async throws {
        // 2:00am UTC on New Year's Day 2026 is still 2025 in New York.
        let newYear = try #require(Self.utc.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 2)))
        var newYork = Calendar(identifier: .gregorian)
        newYork.timeZone = try #require(TimeZone(identifier: "America/New_York"))
        let repository = FakeUserProfileRepository()
        let save = SaveAboutYouUseCase(currentTime: FakeCurrentTimeRepository(date: newYear), profile: repository)

        try await executeThroughProtocol(save, SaveAboutYouUseCase.Input(name: nil, age: 20, calendar: newYork))

        #expect(await repository.savedAboutYou == [.init(name: nil, birthYear: 2005)])
    }

    @Test func aFailedSaveAboutYouThrows() async {
        let repository = FakeUserProfileRepository(error: FakeDataSourceError())

        await #expect(throws: FakeDataSourceError.self) {
            try await executeThroughProtocol(
                Self.saveAboutYou(repository), SaveAboutYouUseCase.Input(name: "Alex", age: 30, calendar: Self.utc))
        }
    }

    // MARK: - SaveHalfLifeFactorsUseCase

    @Test func savesTheFactors() async throws {
        let repository = FakeUserProfileRepository()

        try await executeThroughProtocol(
            SaveHalfLifeFactorsUseCase(repository: repository), [.pregnant(.third), .smokes])

        #expect(await repository.savedFactors == [[.pregnant(.third), .smokes]])
    }

    // MARK: - SaveBedtimeUseCase

    @Test func savesTheBedtime() async throws {
        let repository = FakeUserProfileRepository()
        let bedtime = try #require(Bedtime(hour: 1, minute: 30))

        try await executeThroughProtocol(SaveBedtimeUseCase(repository: repository), bedtime)

        #expect(await repository.savedBedtimes == [bedtime])
    }

    // MARK: - CompleteOnboardingUseCase

    @Test func completesOnboarding() async throws {
        let repository = FakeUserProfileRepository()

        try await executeThroughProtocol(CompleteOnboardingUseCase(repository: repository), ())

        #expect(await repository.completeCount == 1)
    }

    // MARK: - ObserveRecommendedSleepUseCase

    @Test func streamsTheRecommendedSleepInTheGivenCalendar() async throws {
        let repository = FakeUserProfileRepository(recommendedSleeps: [.adult, .olderAdult], sleepCalendar: Self.utc)

        var received: [RecommendedSleep] = []
        for await range in try await executeThroughProtocol(
            ObserveRecommendedSleepUseCase(repository: repository), Self.utc)
        {
            received.append(range)
        }

        #expect(received == [.adult, .olderAdult])
    }
}
