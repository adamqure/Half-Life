//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life ProfileSettingsFeature
//

import ComposableArchitecture
import Foundation
import OSLog

/// Settings' sections for the onboarding answers: About you, Caffeine and your body, and Bedtime.
///
/// The factors come only from the profile the repository publishes, and an option saves at once (constitution Article
/// I.5). The name, age, and bedtime are the sections' own editing state (Article I.2).
/// They're refilled from every published profile, except a name being typed, and except while a save is under way, so
/// a wheel being turned never jumps back. The name saves when it's committed, and a newline typed in it commits it,
/// because the field wraps and Return types one. The age and the bedtime save as soon as they're chosen. A failed save
/// puts the fields back to what was last published. See the Settings article, SETPROF-1 to SETPROF-7.
@Reducer nonisolated struct ProfileSettingsFeature {
    private static let logger = Logger(for: ProfileSettingsFeature.self)

    /// The sections' state.
    @ObservableState
    struct State: Equatable {
        /// The profile the repository last published, or `nil` until it arrives.
        var savedProfile: UserProfile?
        /// The current year in the user's calendar, or `nil` until the time of day arrives.
        var currentYear: Int?
        /// The name as the field shows it.
        var name = ""
        /// The age the picker shows, or `nil` for "Prefer not to say".
        var age: Int?
        /// The bedtime the picker shows.
        var bedtime: Bedtime = .standard
        /// The saved factors.
        var factors: Set<HalfLifeFactor> = []
        /// Whether the user switched pregnancy on and hasn't chosen a trimester yet.
        var isChoosingTrimester = false
        /// Whether the name has been typed since it was last filled in or committed. Until it's committed, a published
        /// profile doesn't replace it.
        var isEditingName = false
        /// How many saves of the name, age, or bedtime are under way. While any is, a published profile doesn't move
        /// the fields.
        var savesInFlight = 0

        /// The trimester of the saved pregnancy, or `nil` if none is saved.
        var trimester: Trimester? {
            for factor in factors {
                if case .pregnant(let trimester) = factor { return trimester }
            }
            return nil
        }

        /// Whether the pregnancy switch is on: a pregnancy is saved, or its trimester is being chosen.
        var isPregnant: Bool {
            trimester != nil || isChoosingTrimester
        }
    }

    /// What can happen in the sections.
    enum Action: BindableAction {
        /// A change to the name, the age, or the bedtime.
        case binding(BindingAction<State>)
        /// The sections appeared, so they start observing the profile and the time of day.
        case task
        /// The repository published the profile.
        case profileUpdated(UserProfile)
        /// A new minute arrived, which carries the current year.
        case timeOfDayUpdated(TimeOfDay)
        /// The user pressed Return in the name field, or left it.
        case nameCommitted
        /// The user switched a factor other than pregnancy on or off.
        case factorToggled(HalfLifeFactor, isOn: Bool)
        /// The user switched pregnancy on or off.
        case pregnancyToggled(Bool)
        /// The user chose a trimester.
        case trimesterChosen(Trimester)
        /// A save of the name, age, or bedtime finished. `succeeded` is whether it was stored.
        case saveFinished(succeeded: Bool)
    }

    @Dependency(\.calendar) var calendar
    @Dependency(\.observeUserProfile) var observeUserProfile
    @Dependency(\.observeTimeOfDay) var observeTimeOfDay
    @Dependency(\.saveAboutYou) var saveAboutYou
    @Dependency(\.saveHalfLifeFactors) var saveHalfLifeFactors
    @Dependency(\.saveBedtime) var saveBedtime

    /// Fills the fields from the saved profile, and saves each change.
    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding(\.name):
                // The name field wraps, so Return types a newline rather than submitting. The newline commits.
                if state.name.contains(where: \.isNewline) {
                    state.name.removeAll(where: \.isNewline)
                    return saveAboutYou(&state)
                }
                state.isEditingName = true
                return .none
            case .binding(\.age):
                return saveAboutYou(&state)
            case .binding(\.bedtime):
                state.savesInFlight += 1
                let bedtime = state.bedtime
                return save("the bedtime") { [saveBedtime] in try await saveBedtime.execute(bedtime) }
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
                state.factors = profile.halfLifeFactors
                Self.fillFields(&state)
                return .none
            case let .timeOfDayUpdated(timeOfDay):
                state.currentYear = calendar.component(.year, from: timeOfDay.date)
                Self.fillFields(&state)
                return .none
            case .nameCommitted:
                guard state.isEditingName else { return .none }
                return saveAboutYou(&state)
            case let .factorToggled(factor, isOn):
                return saveFactors(isOn ? state.factors.union([factor]) : state.factors.subtracting([factor]))
            case let .pregnancyToggled(isOn):
                if isOn {
                    state.isChoosingTrimester = state.trimester == nil
                    return .none
                }
                state.isChoosingTrimester = false
                guard state.trimester != nil else { return .none }
                return saveFactors(Self.withoutPregnancy(state.factors))
            case let .trimesterChosen(trimester):
                state.isChoosingTrimester = false
                return saveFactors(Self.withoutPregnancy(state.factors).union([.pregnant(trimester)]))
            case let .saveFinished(succeeded):
                state.savesInFlight -= 1
                if !succeeded {
                    Self.fillFields(&state)
                }
                return .none
            }
        }
    }

    /// Saves the name as the field shows it, and the age, together.
    private func saveAboutYou(_ state: inout State) -> Effect<Action> {
        state.isEditingName = false
        state.savesInFlight += 1
        let input = SaveAboutYouUseCase.Input(name: state.name, age: state.age, calendar: calendar)
        return save("About you") { [saveAboutYou] in try await saveAboutYou.execute(input) }
    }

    /// Runs a save of the name, age, or bedtime, and reports whether it was stored. A failure is logged with its
    /// domain and code only.
    private func save(_ what: String, _ operation: @escaping @Sendable () async throws -> Void) -> Effect<Action> {
        .run { send in
            do {
                try await operation()
                await send(.saveFinished(succeeded: true))
            } catch {
                let error = error as NSError
                Self.logger.error(
                    """
                    Couldn't save \(what, privacy: .public): \
                    \(error.domain, privacy: .public) \(error.code, privacy: .public)
                    """
                )
                await send(.saveFinished(succeeded: false))
            }
        }
    }

    /// Saves `factors`. The sections follow when the repository publishes them.
    private func saveFactors(_ factors: Set<HalfLifeFactor>) -> Effect<Action> {
        .run { [saveHalfLifeFactors] _ in
            try await saveHalfLifeFactors.execute(factors)
        } catch: { error, _ in
            let error = error as NSError
            Self.logger.error(
                "Couldn't save the half-life factors: \(error.domain, privacy: .public) \(error.code, privacy: .public)"
            )
        }
    }

    /// Fills the name, age, and bedtime from the saved profile, unless a save is under way. A name being typed is kept,
    /// and a saved age outside the picker's range is left empty.
    private static func fillFields(_ state: inout State) {
        guard state.savesInFlight == 0, let profile = state.savedProfile else { return }
        if !state.isEditingName {
            state.name = profile.name ?? ""
        }
        state.bedtime = profile.bedtime
        if let year = state.currentYear {
            state.age = profile.birthYear.map { year - $0 }.flatMap { AboutYouFeature.ages.contains($0) ? $0 : nil }
        }
    }

    private static func withoutPregnancy(_ factors: Set<HalfLifeFactor>) -> Set<HalfLifeFactor> {
        factors.filter {
            if case .pregnant = $0 { return false }
            return true
        }
    }
}
