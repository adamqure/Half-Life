//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests AboutYouFeatureTests
//

import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// Checks the About you step (ONB-5 in the Onboarding article).
@MainActor
struct AboutYouFeatureTests {

    static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()

    /// Midsummer 2026, in UTC.
    static let now = utc.date(from: DateComponents(year: 2026, month: 6, day: 15, hour: 15)) ?? .distantPast
    static let timeOfDay = TimeOfDay(date: now, period: .afternoon)

    // MARK: - The step reads the saved profile and the current year

    @Test func taskReducesTheSavedProfileIntoState() async {
        let profile = UserProfile(name: "Alex", birthYear: 1990)
        let store = TestStore(initialState: AboutYouFeature.State()) {
            AboutYouFeature()
        } withDependencies: {
            $0.calendar = Self.utc
            $0.observeUserProfile = ObserveUserProfileUseCase(
                repository: FakeUserProfileRepository(profiles: [profile]))
            $0.observeTimeOfDay = ObserveTimeOfDayUseCase(currentTime: SilentCurrentTimeRepository())
        }

        await store.send(.task)
        await store.receive(\.profileUpdated) {
            $0.savedProfile = profile
        }
        await store.finish()
    }

    @Test func taskReducesTheCurrentYearIntoState() async {
        let store = TestStore(initialState: AboutYouFeature.State()) {
            AboutYouFeature()
        } withDependencies: {
            $0.calendar = Self.utc
            $0.observeUserProfile = ObserveUserProfileUseCase(repository: FakeUserProfileRepository(profiles: []))
            $0.observeTimeOfDay = ObserveTimeOfDayUseCase(currentTime: FakeCurrentTimeRepository(date: Self.now))
        }

        await store.send(.task)
        await store.receive(\.timeOfDayUpdated) {
            $0.currentYear = 2026
        }
        await store.finish()
    }

    // MARK: - The fields fill in from the saved profile once, unless the user has typed

    @Test func theFieldsFillInOnceTheProfileAndYearAreKnown() async {
        let store = TestStore(initialState: AboutYouFeature.State()) {
            AboutYouFeature()
        } withDependencies: {
            $0.calendar = Self.utc
        }

        await store.send(.profileUpdated(UserProfile(name: "Alex", birthYear: 1990))) {
            $0.savedProfile = UserProfile(name: "Alex", birthYear: 1990)
        }
        await store.send(.timeOfDayUpdated(Self.timeOfDay)) {
            $0.currentYear = 2026
            $0.name = "Alex"
            $0.age = 36
            $0.hasFilledFields = true
        }
        await store.send(.profileUpdated(UserProfile(name: "Sam", birthYear: 1990))) {
            $0.savedProfile = UserProfile(name: "Sam", birthYear: 1990)
        }
    }

    @Test func aSavedAgeOutsideThePickerIsLeftEmpty() async {
        let store = TestStore(initialState: AboutYouFeature.State()) {
            AboutYouFeature()
        } withDependencies: {
            $0.calendar = Self.utc
        }

        await store.send(.timeOfDayUpdated(Self.timeOfDay)) {
            $0.currentYear = 2026
        }
        await store.send(.profileUpdated(UserProfile(birthYear: 2020))) {
            $0.savedProfile = UserProfile(birthYear: 2020)
            $0.hasFilledFields = true
        }
    }

    @Test func typingBeforeTheProfileArrivesKeepsWhatWasTyped() async {
        let store = TestStore(initialState: AboutYouFeature.State()) {
            AboutYouFeature()
        } withDependencies: {
            $0.calendar = Self.utc
        }

        await store.send(.binding(.set(\.name, "Sam"))) {
            $0.name = "Sam"
            $0.hasFilledFields = true
        }
        await store.send(.timeOfDayUpdated(Self.timeOfDay)) {
            $0.currentYear = 2026
        }
        await store.send(.profileUpdated(UserProfile(name: "Alex", birthYear: 1990))) {
            $0.savedProfile = UserProfile(name: "Alex", birthYear: 1990)
        }
    }

    @Test func choosingAnAgeKeepsIt() async {
        let store = TestStore(initialState: AboutYouFeature.State()) {
            AboutYouFeature()
        }

        await store.send(.binding(.set(\.age, 42))) {
            $0.age = 42
            $0.hasFilledFields = true
        }
    }

    // MARK: - ONB-5: Continue saves the name and age, then moves on

    @Test func continueSavesTheNameAndAgeThenContinues() async {
        let repository = FakeUserProfileRepository()
        let store = TestStore(initialState: AboutYouFeature.State(name: "Alex", age: 30)) {
            AboutYouFeature()
        } withDependencies: {
            $0.calendar = Self.utc
            $0.saveAboutYou = SaveAboutYouUseCase(
                currentTime: FakeCurrentTimeRepository(date: Self.now), profile: repository)
        }

        await store.send(.continueTapped) {
            $0.isSaving = true
        }
        await store.receive(\.saveFinished) {
            $0.isSaving = false
        }
        await store.receive(\.delegate.continued)

        #expect(await repository.savedAboutYou == [.init(name: "Alex", birthYear: 1996)])
    }

    @Test func emptyFieldsSaveNothing() async {
        let repository = FakeUserProfileRepository()
        let store = TestStore(initialState: AboutYouFeature.State()) {
            AboutYouFeature()
        } withDependencies: {
            $0.calendar = Self.utc
            $0.saveAboutYou = SaveAboutYouUseCase(
                currentTime: FakeCurrentTimeRepository(date: Self.now), profile: repository)
        }

        await store.send(.continueTapped) {
            $0.isSaving = true
        }
        await store.receive(\.saveFinished) {
            $0.isSaving = false
        }
        await store.receive(\.delegate.continued)

        #expect(await repository.savedAboutYou == [.init(name: nil, birthYear: nil)])
    }

    @Test func aFailedSaveStillContinues() async {
        let store = TestStore(initialState: AboutYouFeature.State(name: "Alex")) {
            AboutYouFeature()
        } withDependencies: {
            $0.calendar = Self.utc
            $0.saveAboutYou = SaveAboutYouUseCase(
                currentTime: FakeCurrentTimeRepository(date: Self.now),
                profile: FakeUserProfileRepository(error: FakeDataSourceError()))
        }

        await store.send(.continueTapped) {
            $0.isSaving = true
        }
        await store.receive(\.saveFinished) {
            $0.isSaving = false
        }
        await store.receive(\.delegate.continued)
    }

    @Test func theAgePickerOffersThirteenToOneHundred() {
        #expect(AboutYouFeature.ages == 13...100)
    }
}
