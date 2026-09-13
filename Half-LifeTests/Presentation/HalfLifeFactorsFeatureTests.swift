//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests HalfLifeFactorsFeatureTests
//

import ComposableArchitecture
import Testing

@testable import Half_Life

/// Checks the step that asks what changes how fast the user clears caffeine (ONB-6 in the Onboarding article).
///
/// A choice is saved at once, and the step's state changes only when the repository publishes it.
@MainActor
struct HalfLifeFactorsFeatureTests {

    static func store(
        _ state: HalfLifeFactorsFeature.State, repository: FakeUserProfileRepository = FakeUserProfileRepository()
    ) -> TestStoreOf<HalfLifeFactorsFeature> {
        TestStore(initialState: state) {
            HalfLifeFactorsFeature()
        } withDependencies: {
            $0.saveHalfLifeFactors = SaveHalfLifeFactorsUseCase(repository: repository)
        }
    }

    @Test func taskReducesTheSavedFactorsButNotTheHalfLifeIntoState() async throws {
        let profile = UserProfile(halfLifeFactors: [.smokes], halfLife: HalfLifePriorRule().halfLife(for: [.smokes]))
        let store = TestStore(initialState: HalfLifeFactorsFeature.State()) {
            HalfLifeFactorsFeature()
        } withDependencies: {
            $0.observeUserProfile = ObserveUserProfileUseCase(
                repository: FakeUserProfileRepository(profiles: [profile]))
        }

        await store.send(.task)
        await store.receive(\.profileUpdated) {
            $0.factors = [.smokes]
        }
        await store.finish()
    }

    @Test func choosingAFactorSavesItWithTheOthers() async {
        let repository = FakeUserProfileRepository()
        let store = Self.store(HalfLifeFactorsFeature.State(factors: [.smokes]), repository: repository)

        await store.send(.factorTapped(.estrogen))
        await store.finish()

        #expect(await repository.savedFactors == [[.smokes, .estrogen]])
    }

    @Test func choosingAChosenFactorAgainRemovesIt() async {
        let repository = FakeUserProfileRepository()
        let store = Self.store(HalfLifeFactorsFeature.State(factors: [.smokes, .cirrhosis]), repository: repository)

        await store.send(.factorTapped(.smokes))
        await store.finish()

        #expect(await repository.savedFactors == [[.cirrhosis]])
    }

    @Test func noneOfTheseSavesNoFactors() async {
        let repository = FakeUserProfileRepository()
        let store = Self.store(
            HalfLifeFactorsFeature.State(factors: [.smokes], isChoosingTrimester: true), repository: repository)

        await store.send(.noneTapped) {
            $0.isChoosingTrimester = false
        }
        await store.finish()

        #expect(await repository.savedFactors == [[]])
    }

    @Test func pregnancyAsksForTheTrimesterBeforeSaving() async {
        let repository = FakeUserProfileRepository()
        let store = Self.store(HalfLifeFactorsFeature.State(factors: [.smokes]), repository: repository)

        await store.send(.pregnantTapped) {
            $0.isChoosingTrimester = true
        }
        await store.send(.trimesterTapped(.second)) {
            $0.isChoosingTrimester = false
        }
        await store.finish()

        #expect(await repository.savedFactors == [[.smokes, .pregnant(.second)]])
    }

    @Test func tappingPregnancyWhileChoosingATrimesterCancels() async {
        let repository = FakeUserProfileRepository()
        let store = Self.store(HalfLifeFactorsFeature.State(isChoosingTrimester: true), repository: repository)

        await store.send(.pregnantTapped) {
            $0.isChoosingTrimester = false
        }

        #expect(await repository.savedFactors.isEmpty)
    }

    @Test func anotherTrimesterReplacesTheSavedOne() async {
        let repository = FakeUserProfileRepository()
        let store = Self.store(HalfLifeFactorsFeature.State(factors: [.pregnant(.first)]), repository: repository)

        await store.send(.trimesterTapped(.third))
        await store.finish()

        #expect(await repository.savedFactors == [[.pregnant(.third)]])
    }

    @Test func tappingPregnancyWhenPregnantRemovesIt() async {
        let repository = FakeUserProfileRepository()
        let store = Self.store(
            HalfLifeFactorsFeature.State(factors: [.pregnant(.first), .estrogen]), repository: repository)

        await store.send(.pregnantTapped)
        await store.finish()

        #expect(await repository.savedFactors == [[.estrogen]])
    }

    @Test func aFailedSaveChangesNothing() async {
        let store = Self.store(
            HalfLifeFactorsFeature.State(), repository: FakeUserProfileRepository(error: FakeDataSourceError()))

        await store.send(.factorTapped(.smokes))
        await store.finish()
    }

    @Test func theTrimesterIsTheSavedPregnancysOne() {
        #expect(HalfLifeFactorsFeature.State(factors: [.smokes, .pregnant(.second)]).trimester == .second)
        #expect(HalfLifeFactorsFeature.State(factors: [.smokes]).trimester == nil)
    }

    @Test func continueMovesOn() async {
        let store = Self.store(HalfLifeFactorsFeature.State())

        await store.send(.continueTapped)
        await store.receive(\.delegate.continued)
    }
}
