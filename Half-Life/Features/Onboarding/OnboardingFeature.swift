//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life OnboardingFeature
//

import ComposableArchitecture

/// Onboarding's flow: Welcome at the root of a navigation stack, and each later step pushed onto its path.
///
/// Each step tells the flow when the user continues, and the flow pushes the next one: About you, what changes the
/// half-life, bedtime, permissions, then the summary. The summary's delegate action reaches ``AppFeature``, which
/// completes onboarding. See the Onboarding article, ONB-4.
@Reducer nonisolated struct OnboardingFeature {
    /// A step pushed onto onboarding's navigation stack.
    @Reducer nonisolated enum Path {
        /// Step 2: the name and age.
        case aboutYou(AboutYouFeature)
        /// Step 3: what changes how fast the user clears caffeine.
        case halfLifeFactors(HalfLifeFactorsFeature)
        /// Step 4: the bedtime.
        case bedtime(BedtimeFeature)
        /// Step 5: the permissions.
        case permissions(PermissionsFeature)
        /// Step 6: the summary.
        case summary(OnboardingSummaryFeature)
    }

    /// Onboarding's state.
    @ObservableState
    struct State: Equatable {
        /// The steps pushed after Welcome, in order.
        var path = StackState<Path.State>()
    }

    /// What can happen in onboarding.
    enum Action {
        /// The user tapped Get started on the Welcome screen.
        case getStartedTapped
        /// An action for a pushed step, or a change to the stack.
        case path(StackActionOf<Path>)
        /// What onboarding tells its parent.
        case delegate(Delegate)
    }

    /// What onboarding tells ``AppFeature``.
    @CasePathable
    enum Delegate {
        /// The user left the summary. `logFirstCup` is whether they asked to log their first cup.
        case finished(logFirstCup: Bool)
    }

    /// Pushes each step when the one before it continues, and runs the pushed steps.
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .getStartedTapped:
                state.path.append(.aboutYou(AboutYouFeature.State()))
                return .none
            case .path(.element(_, .aboutYou(.delegate(.continued)))):
                state.path.append(.halfLifeFactors(HalfLifeFactorsFeature.State()))
                return .none
            case .path(.element(_, .halfLifeFactors(.delegate(.continued)))):
                state.path.append(.bedtime(BedtimeFeature.State()))
                return .none
            case .path(.element(_, .bedtime(.delegate(.continued)))):
                state.path.append(.permissions(PermissionsFeature.State()))
                return .none
            case .path(.element(_, .permissions(.delegate(.continued)))):
                state.path.append(.summary(OnboardingSummaryFeature.State()))
                return .none
            case let .path(.element(_, .summary(.delegate(.finished(logFirstCup))))):
                return .send(.delegate(.finished(logFirstCup: logFirstCup)))
            case .path, .delegate:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}

/// Lets onboarding's `State`, which holds the pushed steps, be `Equatable`.
///
/// It's declared here rather than with `@Reducer(state: .equatable)`, which is deprecated.
extension OnboardingFeature.Path.State: Equatable {}
