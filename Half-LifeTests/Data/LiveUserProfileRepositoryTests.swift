//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests LiveUserProfileRepositoryTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the live user profile repository against a fake data source (PROF-1 and PROF-2 in the Today Screen
/// article, PROF-3 to PROF-7 in the Onboarding article).
@Suite(.timeLimit(.minutes(1)))
struct LiveUserProfileRepositoryTests {

    static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()

    /// Midsummer 2026, in UTC.
    static let now = utc.date(from: DateComponents(year: 2026, month: 6, day: 15, hour: 12)) ?? .distantPast

    static func repository(_ source: FakeUserProfileDataSource) -> LiveUserProfileRepository {
        LiveUserProfileRepository(dataSource: source, clock: FakeClockDataSource(date: now, minuteDates: []))
    }

    // MARK: - PROF-1: a new subscriber immediately gets the stored profile

    @Test func publishesTheStoredProfile() async {
        let repository = Self.repository(FakeUserProfileDataSource(stored: UserProfile(name: "Alex")))

        var profiles = repository.profile().makeAsyncIterator()

        #expect(await profiles.next() == UserProfile(name: "Alex"))
    }

    // MARK: - PROF-2: with nothing stored, a profile with nothing given

    @Test func publishesAProfileWithNoNameWhenNothingIsStored() async {
        let repository = Self.repository(FakeUserProfileDataSource(stored: nil))

        var profiles = repository.profile().makeAsyncIterator()

        #expect(await profiles.next() == UserProfile(name: nil))
    }

    @Test func aProfileThatCantBeReadPublishesAProfileWithNothingGiven() async {
        let source = FakeUserProfileDataSource(stored: UserProfile(name: "Alex"), readError: FakeDataSourceError())
        let repository = Self.repository(source)

        var profiles = repository.profile().makeAsyncIterator()

        #expect(await profiles.next() == UserProfile())
    }

    // MARK: - PROF-3: every change, and the stream doesn't finish

    @Test func publishesEveryChangeTheDataSourceSignals() async {
        let source = FakeUserProfileDataSource(stored: UserProfile(name: "Alex"))
        let repository = Self.repository(source)

        var profiles = repository.profile().makeAsyncIterator()
        _ = await profiles.next()
        await source.replace(with: UserProfile(name: "Sam"))
        await source.signalChange()

        #expect(await profiles.next() == UserProfile(name: "Sam"))
    }

    // MARK: - PROF-4: saving the factors stores them with the half-life the rule gives

    @Test func savingTheFactorsStoresThemWithTheirHalfLife() async throws {
        let source = FakeUserProfileDataSource(stored: UserProfile(name: "Alex"))
        let repository = Self.repository(source)

        try await repository.saveHalfLifeFactors([.estrogen, .smokes])

        #expect(
            await source.stored
                == UserProfile(
                    name: "Alex", halfLifeFactors: [.estrogen, .smokes],
                    halfLife: HalfLifePriorRule().halfLife(for: [.estrogen, .smokes])))
    }

    @Test func clearingTheFactorsRestoresTheStandardHalfLife() async throws {
        let source = FakeUserProfileDataSource(
            stored: UserProfile(
                halfLifeFactors: [.fluvoxamine], halfLife: HalfLifePriorRule().halfLife(for: [.fluvoxamine])))
        let repository = Self.repository(source)

        try await repository.saveHalfLifeFactors([])

        #expect(await source.stored == UserProfile())
    }

    // MARK: - PROF-5: saving the name and birth year

    @Test func savingAboutYouKeepsEverythingElse() async throws {
        let source = FakeUserProfileDataSource(stored: UserProfile(name: "Alex", halfLifeFactors: [.smokes]))
        let repository = Self.repository(source)

        try await repository.saveAboutYou(name: "Sam", birthYear: 1990)

        #expect(await source.stored == UserProfile(name: "Sam", birthYear: 1990, halfLifeFactors: [.smokes]))
    }

    @Test func savingWithNothingStoredStartsFromTheDefaults() async throws {
        let source = FakeUserProfileDataSource(stored: nil)
        let repository = Self.repository(source)

        try await repository.saveAboutYou(name: nil, birthYear: 2000)

        #expect(await source.stored == UserProfile(birthYear: 2000))
    }

    // MARK: - PROF-6: saving the bedtime

    @Test func savingTheBedtimeStoresIt() async throws {
        let bedtime = try #require(Bedtime(hour: 23, minute: 15))
        let source = FakeUserProfileDataSource(stored: UserProfile(name: "Alex"))
        let repository = Self.repository(source)

        try await repository.saveBedtime(bedtime)

        #expect(await source.stored == UserProfile(name: "Alex", bedtime: bedtime))
    }

    // MARK: - PROF-7: completing onboarding, and the stream publishes it

    @Test func completingOnboardingStoresItAndPublishesIt() async throws {
        let source = FakeUserProfileDataSource(stored: UserProfile(name: "Alex"))
        let repository = Self.repository(source)

        var profiles = repository.profile().makeAsyncIterator()
        _ = await profiles.next()
        try await repository.completeOnboarding()

        #expect(await profiles.next() == UserProfile(name: "Alex", hasCompletedOnboarding: true))
        #expect(await source.stored == UserProfile(name: "Alex", hasCompletedOnboarding: true))
    }

    @Test func aSaveBuildsOnAChangeFromAnotherWriter() async throws {
        let source = FakeUserProfileDataSource(stored: UserProfile(name: "Alex"))
        let repository = Self.repository(source)

        var profiles = repository.profile().makeAsyncIterator()
        _ = await profiles.next()
        await source.replace(with: UserProfile(name: "Sam"))
        await source.signalChange()
        _ = await profiles.next()
        try await repository.completeOnboarding()

        #expect(await source.stored == UserProfile(name: "Sam", hasCompletedOnboarding: true))
    }

    @Test func aFailedSaveThrows() async {
        let source = FakeUserProfileDataSource(stored: nil, storeError: FakeDataSourceError())
        let repository = Self.repository(source)

        await #expect(throws: FakeDataSourceError.self) {
            try await repository.completeOnboarding()
        }
    }

    // MARK: - SLEEPNEED: the recommended sleep for the stored birth year, then each change

    @Test func publishesTheRecommendedSleepForTheStoredAgeThenEachChange() async {
        let source = FakeUserProfileDataSource(stored: UserProfile(birthYear: 1950))
        let repository = Self.repository(source)

        var ranges = repository.recommendedSleep(in: Self.utc).makeAsyncIterator()
        #expect(await ranges.next() == .olderAdult)
        await source.replace(with: UserProfile(birthYear: 2000))
        await source.signalChange()

        #expect(await ranges.next() == .adult)
    }
}
