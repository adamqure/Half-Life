//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests BedtimeFeatureTests
//

import ComposableArchitecture
import Testing

@testable import Half_Life

/// Checks the bedtime step, which saves on Continue (ONB-5 in the Onboarding article).
@MainActor
struct BedtimeFeatureTests {

    @Test func taskStartsFromTheSavedBedtime() async throws {
        let late = try #require(Bedtime(hour: 23, minute: 15))
        let store = TestStore(initialState: BedtimeFeature.State()) {
            BedtimeFeature()
        } withDependencies: {
            $0.observeUserProfile = ObserveUserProfileUseCase(
                repository: FakeUserProfileRepository(profiles: [UserProfile(bedtime: late)]))
        }

        await store.send(.task)
        await store.receive(\.profileUpdated) {
            $0.bedtime = late
        }
        await store.finish()
    }

    @Test func aChosenBedtimeIsntReplacedByTheSavedOne() async throws {
        let late = try #require(Bedtime(hour: 23, minute: 15))
        let early = try #require(Bedtime(hour: 21, minute: 0))
        let store = TestStore(initialState: BedtimeFeature.State()) {
            BedtimeFeature()
        }

        await store.send(.bedtimeChanged(early)) {
            $0.bedtime = early
            $0.hasChosen = true
        }
        await store.send(.profileUpdated(UserProfile(bedtime: late)))
    }

    @Test func continueSavesTheBedtimeThenContinues() async throws {
        let late = try #require(Bedtime(hour: 0, minute: 30))
        let repository = FakeUserProfileRepository()
        let store = TestStore(initialState: BedtimeFeature.State(bedtime: late)) {
            BedtimeFeature()
        } withDependencies: {
            $0.saveBedtime = SaveBedtimeUseCase(repository: repository)
        }

        await store.send(.continueTapped) {
            $0.isSaving = true
        }
        await store.receive(\.saveFinished) {
            $0.isSaving = false
        }
        await store.receive(\.delegate.continued)

        #expect(await repository.savedBedtimes == [late])
    }

    @Test func aFailedSaveStillContinues() async {
        let store = TestStore(initialState: BedtimeFeature.State()) {
            BedtimeFeature()
        } withDependencies: {
            $0.saveBedtime = SaveBedtimeUseCase(repository: FakeUserProfileRepository(error: FakeDataSourceError()))
        }

        await store.send(.continueTapped) {
            $0.isSaving = true
        }
        await store.receive(\.saveFinished) {
            $0.isSaving = false
        }
        await store.receive(\.delegate.continued)
    }
}
