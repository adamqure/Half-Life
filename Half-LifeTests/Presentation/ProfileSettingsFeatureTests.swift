//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests ProfileSettingsFeatureTests
//

import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// Checks Settings' profile sections, the onboarding answers, against SETPROF-1 to SETPROF-7 in the Settings article.
@MainActor
struct ProfileSettingsFeatureTests {

    struct SaveFailed: Error {}

    static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()

    /// Midsummer 2026, in UTC.
    static let now = utc.date(from: DateComponents(year: 2026, month: 6, day: 15, hour: 15)) ?? .distantPast
    static let timeOfDay = TimeOfDay(date: now, period: .afternoon)
    static let elevenPM = Bedtime(hour: 23, minute: 0) ?? .standard
    static let midnight = Bedtime(hour: 0, minute: 0) ?? .standard

    static func store(
        _ state: ProfileSettingsFeature.State, repository: FakeUserProfileRepository = FakeUserProfileRepository()
    ) -> TestStoreOf<ProfileSettingsFeature> {
        TestStore(initialState: state) {
            ProfileSettingsFeature()
        } withDependencies: {
            $0.calendar = Self.utc
            $0.saveAboutYou = SaveAboutYouUseCase(
                currentTime: FakeCurrentTimeRepository(date: Self.now), profile: repository)
            $0.saveBedtime = SaveBedtimeUseCase(repository: repository)
            $0.saveHalfLifeFactors = SaveHalfLifeFactorsUseCase(repository: repository)
        }
    }

    // MARK: - SETPROF-1: the sections show the saved profile, refilled from every profile the repository publishes

    @Test func taskReducesTheSavedProfileIntoState() async {
        let halfLife = HalfLifePriorRule().halfLife(for: [.smokes])
        let profile = UserProfile(
            name: "Alex", birthYear: 1990, halfLifeFactors: [.smokes], bedtime: Self.elevenPM, halfLife: halfLife)
        let store = TestStore(initialState: ProfileSettingsFeature.State()) {
            ProfileSettingsFeature()
        } withDependencies: {
            $0.calendar = Self.utc
            $0.observeUserProfile = ObserveUserProfileUseCase(
                repository: FakeUserProfileRepository(profiles: [profile]))
            $0.observeTimeOfDay = ObserveTimeOfDayUseCase(currentTime: SilentCurrentTimeRepository())
        }

        await store.send(.task)
        await store.receive(\.profileUpdated) {
            $0.savedProfile = profile
            $0.name = "Alex"
            $0.factors = [.smokes]
            $0.bedtime = Self.elevenPM
        }
        await store.finish()
    }

    @Test func taskReducesTheCurrentYearIntoState() async {
        let store = TestStore(initialState: ProfileSettingsFeature.State()) {
            ProfileSettingsFeature()
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

    @Test func theAgeFillsInOnceTheYearIsKnownAndEachProfileRefillsTheFields() async {
        let store = Self.store(ProfileSettingsFeature.State())

        await store.send(.profileUpdated(UserProfile(name: "Alex", birthYear: 1990))) {
            $0.savedProfile = UserProfile(name: "Alex", birthYear: 1990)
            $0.name = "Alex"
        }
        await store.send(.timeOfDayUpdated(Self.timeOfDay)) {
            $0.currentYear = 2026
            $0.age = 36
        }
        await store.send(.profileUpdated(UserProfile(name: "Sam", birthYear: 1980, bedtime: Self.elevenPM))) {
            $0.savedProfile = UserProfile(name: "Sam", birthYear: 1980, bedtime: Self.elevenPM)
            $0.name = "Sam"
            $0.age = 46
            $0.bedtime = Self.elevenPM
        }
    }

    @Test func aSavedAgeOutsideThePickerIsLeftEmpty() async {
        let store = Self.store(ProfileSettingsFeature.State(currentYear: 2026, age: 30))

        await store.send(.profileUpdated(UserProfile(birthYear: 2020))) {
            $0.savedProfile = UserProfile(birthYear: 2020)
            $0.age = nil
        }
    }

    // MARK: - SETPROF-2: the name saves when it's committed, and a name being typed isn't replaced

    @Test func aNameBeingTypedIsntReplacedByAPublishedProfile() async {
        let store = Self.store(ProfileSettingsFeature.State())

        await store.send(.binding(.set(\.name, "Sa"))) {
            $0.name = "Sa"
            $0.isEditingName = true
        }
        await store.send(.profileUpdated(UserProfile(name: "Alex"))) {
            $0.savedProfile = UserProfile(name: "Alex")
        }
    }

    @Test func committingTheNameSavesItWithTheAge() async {
        let repository = FakeUserProfileRepository()
        let store = Self.store(
            ProfileSettingsFeature.State(currentYear: 2026, name: " Sam ", age: 36, isEditingName: true),
            repository: repository)

        await store.send(.nameCommitted) {
            $0.isEditingName = false
            $0.savesInFlight = 1
        }
        await store.receive(\.saveFinished) {
            $0.savesInFlight = 0
        }

        #expect(await repository.savedAboutYou == [.init(name: "Sam", birthYear: 1990)])
    }

    /// The name field wraps, so Return types a newline instead of submitting. The newline commits the name instead.
    @Test func typingANewlineCommitsTheNameWithoutIt() async {
        let repository = FakeUserProfileRepository()
        let store = Self.store(ProfileSettingsFeature.State(currentYear: 2026, name: "Sam"), repository: repository)

        await store.send(.binding(.set(\.name, "Sam\n"))) {
            $0.name = "Sam"
            $0.savesInFlight = 1
        }
        await store.receive(\.saveFinished) {
            $0.savesInFlight = 0
        }

        #expect(await repository.savedAboutYou == [.init(name: "Sam", birthYear: nil)])
    }

    @Test func committingANameThatWasntChangedSavesNothing() async {
        let repository = FakeUserProfileRepository()
        let store = Self.store(ProfileSettingsFeature.State(name: "Alex"), repository: repository)

        await store.send(.nameCommitted)

        #expect(await repository.savedAboutYou.isEmpty)
    }

    // MARK: - SETPROF-3: the age and the bedtime save as soon as they're chosen

    @Test func choosingAnAgeSavesItWithTheName() async {
        let repository = FakeUserProfileRepository()
        let store = Self.store(
            ProfileSettingsFeature.State(currentYear: 2026, name: "Alex", isEditingName: true), repository: repository)

        await store.send(.binding(.set(\.age, 40))) {
            $0.age = 40
            $0.isEditingName = false
            $0.savesInFlight = 1
        }
        await store.receive(\.saveFinished) {
            $0.savesInFlight = 0
        }

        #expect(await repository.savedAboutYou == [.init(name: "Alex", birthYear: 1986)])
    }

    @Test func choosingABedtimeSavesIt() async {
        let repository = FakeUserProfileRepository()
        let store = Self.store(ProfileSettingsFeature.State(), repository: repository)

        await store.send(.binding(.set(\.bedtime, Self.midnight))) {
            $0.bedtime = Self.midnight
            $0.savesInFlight = 1
        }
        await store.receive(\.saveFinished) {
            $0.savesInFlight = 0
        }

        #expect(await repository.savedBedtimes == [Self.midnight])
    }

    // MARK: - SETPROF-4: a profile published while a save is under way doesn't move the fields

    @Test func aProfilePublishedDuringASaveLeavesTheFields() async {
        let store = Self.store(ProfileSettingsFeature.State(bedtime: Self.midnight, savesInFlight: 1))

        await store.send(.profileUpdated(UserProfile(name: "Alex", halfLifeFactors: [.smokes]))) {
            $0.savedProfile = UserProfile(name: "Alex", halfLifeFactors: [.smokes])
            $0.factors = [.smokes]
        }
    }

    // MARK: - SETPROF-5: a failed save puts the fields back to what's saved

    @Test func aFailedSavePutsTheFieldsBackToWhatsSaved() async {
        let store = Self.store(
            ProfileSettingsFeature.State(savedProfile: UserProfile(name: "Alex", bedtime: Self.elevenPM)),
            repository: FakeUserProfileRepository(error: SaveFailed()))

        await store.send(.binding(.set(\.bedtime, Self.midnight))) {
            $0.bedtime = Self.midnight
            $0.savesInFlight = 1
        }
        await store.receive(\.saveFinished) {
            $0.savesInFlight = 0
            $0.name = "Alex"
            $0.bedtime = Self.elevenPM
        }
    }

    // MARK: - SETPROF-6: a factor saves as soon as it's switched, and the sections follow the repository

    @Test func switchingAFactorOnSavesItWithTheOthers() async {
        let repository = FakeUserProfileRepository()
        let store = Self.store(ProfileSettingsFeature.State(factors: [.smokes]), repository: repository)

        await store.send(.factorToggled(.estrogen, isOn: true))
        await store.finish()

        #expect(await repository.savedFactors == [[.smokes, .estrogen]])
    }

    @Test func switchingAFactorOffRemovesIt() async {
        let repository = FakeUserProfileRepository()
        let store = Self.store(ProfileSettingsFeature.State(factors: [.smokes, .cirrhosis]), repository: repository)

        await store.send(.factorToggled(.smokes, isOn: false))
        await store.finish()

        #expect(await repository.savedFactors == [[.cirrhosis]])
    }

    @Test func aFailedFactorSaveChangesNothing() async {
        let store = Self.store(
            ProfileSettingsFeature.State(), repository: FakeUserProfileRepository(error: SaveFailed()))

        await store.send(.factorToggled(.smokes, isOn: true))
        await store.finish()
    }

    // MARK: - SETPROF-7: pregnancy asks for the trimester before anything is saved

    @Test func switchingPregnancyOnAsksForTheTrimesterBeforeSaving() async {
        let repository = FakeUserProfileRepository()
        let store = Self.store(ProfileSettingsFeature.State(factors: [.smokes]), repository: repository)

        await store.send(.pregnancyToggled(true)) {
            $0.isChoosingTrimester = true
        }
        #expect(await repository.savedFactors.isEmpty)
        await store.send(.trimesterChosen(.second)) {
            $0.isChoosingTrimester = false
        }
        await store.finish()

        #expect(await repository.savedFactors == [[.smokes, .pregnant(.second)]])
    }

    @Test func switchingPregnancyOffRemovesIt() async {
        let repository = FakeUserProfileRepository()
        let store = Self.store(
            ProfileSettingsFeature.State(factors: [.pregnant(.first), .estrogen]), repository: repository)

        await store.send(.pregnancyToggled(false))
        await store.finish()

        #expect(await repository.savedFactors == [[.estrogen]])
    }

    @Test func switchingPregnancyOffWhileChoosingATrimesterSavesNothing() async {
        let repository = FakeUserProfileRepository()
        let store = Self.store(ProfileSettingsFeature.State(isChoosingTrimester: true), repository: repository)

        await store.send(.pregnancyToggled(false)) {
            $0.isChoosingTrimester = false
        }

        #expect(await repository.savedFactors.isEmpty)
    }

    @Test func pregnancyIsOnWhileATrimesterIsSavedOrBeingChosen() {
        #expect(ProfileSettingsFeature.State(factors: [.pregnant(.third)]).isPregnant)
        #expect(ProfileSettingsFeature.State(factors: [.pregnant(.third)]).trimester == .third)
        #expect(ProfileSettingsFeature.State(isChoosingTrimester: true).isPregnant)
        #expect(!ProfileSettingsFeature.State(factors: [.smokes]).isPregnant)
    }
}
