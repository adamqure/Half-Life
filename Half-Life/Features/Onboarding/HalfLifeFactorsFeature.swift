//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life HalfLifeFactorsFeature
//

import ComposableArchitecture
import Foundation
import OSLog

/// Onboarding's step that asks what changes how fast the user clears caffeine, and shows the starting half-life.
///
/// A choice is saved as soon as it's made. The factors and the half-life in `State` come only from the profile the
/// repository publishes, so the half-life shown is always the one the rule gave for what's saved (constitution Article
/// I.5). Choosing pregnancy asks for the trimester before anything is saved. See the Onboarding article, ONB-6.
@Reducer nonisolated struct HalfLifeFactorsFeature {
    private static let logger = Logger(for: HalfLifeFactorsFeature.self)

    /// The step's state.
    @ObservableState
    struct State: Equatable {
        /// The saved factors.
        var factors: Set<HalfLifeFactor> = []
        /// The saved starting half-life, or `nil` until the profile arrives.
        var halfLife: CaffeineHalfLife?
        /// Whether the user tapped "I'm pregnant" and hasn't chosen a trimester yet.
        var isChoosingTrimester = false

        /// The trimester of the saved pregnancy, or `nil` if none is saved.
        var trimester: Trimester? {
            for factor in factors {
                if case .pregnant(let trimester) = factor { return trimester }
            }
            return nil
        }
    }

    /// What can happen in the step.
    enum Action {
        /// The step appeared, so it starts observing the profile.
        case task
        /// The repository published the profile.
        case profileUpdated(UserProfile)
        /// The user chose "None of these".
        case noneTapped
        /// The user tapped "I'm pregnant".
        case pregnantTapped
        /// The user chose a trimester.
        case trimesterTapped(Trimester)
        /// The user tapped a factor other than pregnancy.
        case factorTapped(HalfLifeFactor)
        /// The user tapped Continue.
        case continueTapped
        /// What the step tells onboarding.
        case delegate(Delegate)
    }

    /// What the step tells ``OnboardingFeature``.
    @CasePathable
    enum Delegate {
        /// The user continued to the next step.
        case continued
    }

    @Dependency(\.observeUserProfile) var observeUserProfile
    @Dependency(\.saveHalfLifeFactors) var saveHalfLifeFactors

    /// Saves each choice, and reduces the saved factors and half-life into `State`.
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                return .run { [observeUserProfile] send in
                    for await profile in observeUserProfile.execute(()) {
                        await send(.profileUpdated(profile))
                    }
                }
            case let .profileUpdated(profile):
                state.factors = profile.halfLifeFactors
                state.halfLife = profile.halfLife
                return .none
            case .noneTapped:
                state.isChoosingTrimester = false
                return save([])
            case .pregnantTapped:
                if state.trimester != nil {
                    return save(Self.withoutPregnancy(state.factors))
                }
                state.isChoosingTrimester.toggle()
                return .none
            case let .trimesterTapped(trimester):
                state.isChoosingTrimester = false
                return save(Self.withoutPregnancy(state.factors).union([.pregnant(trimester)]))
            case let .factorTapped(factor):
                return save(state.factors.symmetricDifference([factor]))
            case .continueTapped:
                return .send(.delegate(.continued))
            case .delegate:
                return .none
            }
        }
    }

    /// Saves `factors`. The step's state follows when the repository publishes them.
    private func save(_ factors: Set<HalfLifeFactor>) -> Effect<Action> {
        .run { [saveHalfLifeFactors] _ in
            try await saveHalfLifeFactors.execute(factors)
        } catch: { error, _ in
            let error = error as NSError
            Self.logger.error(
                "Couldn't save the half-life factors: \(error.domain, privacy: .public) \(error.code, privacy: .public)"
            )
        }
    }

    private static func withoutPregnancy(_ factors: Set<HalfLifeFactor>) -> Set<HalfLifeFactor> {
        factors.filter {
            if case .pregnant = $0 { return false }
            return true
        }
    }
}
