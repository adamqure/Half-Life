//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life AboutYouFeature
//

import ComposableArchitecture
import Foundation
import OSLog

/// Onboarding's About you step: the user's first name and age, both optional.
///
/// The fields are the step's own editing state until Continue saves them (constitution Article I.2). They fill in
/// from the saved profile once, when the user returns to onboarding, unless the user has already typed. See the
/// Onboarding article, ONB-5.
@Reducer nonisolated struct AboutYouFeature {
    /// The ages the picker offers. Younger children aren't the app's audience.
    static let ages = 13...100

    private static let logger = Logger(for: AboutYouFeature.self)

    /// The step's state.
    @ObservableState
    struct State: Equatable {
        /// The name as typed.
        var name = ""
        /// The chosen age, or `nil` for "Prefer not to say".
        var age: Int?
        /// The profile the repository last published, or `nil` until it arrives.
        var savedProfile: UserProfile?
        /// The current year in the user's calendar, or `nil` until the time of day arrives.
        var currentYear: Int?
        /// Whether the fields hold the user's answers, filled in from the saved profile or changed by the user. Once
        /// they do, the saved profile no longer replaces them.
        var hasFilledFields = false
        /// Whether Continue is saving.
        var isSaving = false
    }

    /// What can happen in the step.
    enum Action: BindableAction {
        /// A change to the name or the age.
        case binding(BindingAction<State>)
        /// The step appeared, so it starts observing the profile and the time of day.
        case task
        /// The repository published the profile.
        case profileUpdated(UserProfile)
        /// A new minute arrived, which carries the current year.
        case timeOfDayUpdated(TimeOfDay)
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

    @Dependency(\.calendar) var calendar
    @Dependency(\.observeUserProfile) var observeUserProfile
    @Dependency(\.observeTimeOfDay) var observeTimeOfDay
    @Dependency(\.saveAboutYou) var saveAboutYou

    /// Keeps the fields, fills them from the saved profile once, and saves them on Continue.
    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding(\.name), .binding(\.age):
                state.hasFilledFields = true
                return .none
            case .binding:
                return .none
            case .task:
                return .merge(
                    .run { [observeUserProfile] send in
                        for await profile in observeUserProfile.execute(()) {
                            await send(.profileUpdated(profile))
                        }
                    },
                    .run { [observeTimeOfDay, calendar] send in
                        for await timeOfDay in observeTimeOfDay.execute(calendar) {
                            await send(.timeOfDayUpdated(timeOfDay))
                        }
                    }
                )
            case let .profileUpdated(profile):
                state.savedProfile = profile
                Self.fillFields(&state)
                return .none
            case let .timeOfDayUpdated(timeOfDay):
                state.currentYear = calendar.component(.year, from: timeOfDay.date)
                Self.fillFields(&state)
                return .none
            case .continueTapped:
                state.isSaving = true
                let input = SaveAboutYouUseCase.Input(name: state.name, age: state.age, calendar: calendar)
                return .run { [saveAboutYou] send in
                    do {
                        try await saveAboutYou.execute(input)
                    } catch {
                        // Onboarding never blocks, so the user continues. The answers can be given again later.
                        let error = error as NSError
                        Self.logger.error(
                            "Couldn't save About you: \(error.domain, privacy: .public) \(error.code, privacy: .public)"
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

    /// Fills the fields from the saved profile, once both it and the current year are known, unless they already
    /// hold the user's answers. A saved age outside the picker's range is left empty.
    private static func fillFields(_ state: inout State) {
        guard !state.hasFilledFields, let profile = state.savedProfile, let year = state.currentYear else { return }
        state.name = profile.name ?? ""
        state.age = profile.birthYear.map { year - $0 }.flatMap { ages.contains($0) ? $0 : nil }
        state.hasFilledFields = true
    }
}
