//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life BedtimeFeature
//

import ComposableArchitecture
import Foundation
import OSLog

/// Onboarding's bedtime step: when the user wants to be asleep, chosen on a time picker.
///
/// It starts from the saved bedtime, which is 10:30pm until the user chooses one. The chosen time is the step's own
/// editing state until Continue saves it. See the Onboarding article, ONB-5.
@Reducer nonisolated struct BedtimeFeature {
    private static let logger = Logger(for: BedtimeFeature.self)

    /// The step's state.
    @ObservableState
    struct State: Equatable {
        /// The bedtime the picker shows.
        var bedtime: Bedtime = .standard
        /// Whether the user has moved the picker. Once they have, the saved bedtime no longer replaces their choice.
        var hasChosen = false
        /// Whether Continue is saving.
        var isSaving = false
    }

    /// What can happen in the step.
    enum Action {
        /// The step appeared, so it starts observing the profile.
        case task
        /// The repository published the profile.
        case profileUpdated(UserProfile)
        /// The user moved the picker.
        case bedtimeChanged(Bedtime)
        /// The user tapped Continue.
        case continueTapped
        /// The save finished, whether or not it succeeded.
        case saveFinished
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
    @Dependency(\.saveBedtime) var saveBedtime

    /// Starts from the saved bedtime, keeps the user's choice, and saves it on Continue.
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
                if !state.hasChosen {
                    state.bedtime = profile.bedtime
                }
                return .none
            case let .bedtimeChanged(bedtime):
                state.bedtime = bedtime
                state.hasChosen = true
                return .none
            case .continueTapped:
                state.isSaving = true
                let bedtime = state.bedtime
                return .run { [saveBedtime] send in
                    do {
                        try await saveBedtime.execute(bedtime)
                    } catch {
                        // Onboarding never blocks. The standard bedtime applies until one is saved.
                        let domain = (error as NSError).domain
                        let code = (error as NSError).code
                        Self.logger.error(
                            "Couldn't save the bedtime: \(domain, privacy: .public) \(code, privacy: .public)"
                        )
                    }
                    await send(.saveFinished)
                    await send(.delegate(.continued))
                }
            case .saveFinished:
                state.isSaving = false
                return .none
            case .delegate:
                return .none
            }
        }
    }
}
