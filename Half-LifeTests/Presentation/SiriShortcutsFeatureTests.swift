//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests SiriShortcutsFeatureTests
//

import ComposableArchitecture
import Testing

@testable import Half_Life

/// ONB-SIRI-1 in the Onboarding article: the "Use Siri and Shortcuts" step asks for nothing, and moves on.
@MainActor
struct SiriShortcutsFeatureTests {

    @Test func continueMovesOnWithoutAskingForAnything() async {
        let store = TestStore(initialState: SiriShortcutsFeature.State()) {
            SiriShortcutsFeature()
        }

        await store.send(.continueTapped)
        await store.receive(\.delegate.continued)
    }
}
