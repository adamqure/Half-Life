//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life AppView
//

import ComposableArchitecture
import SwiftUI

/// The app's root screen: the Today screen, with the log button that opens the drink composer pinned below it.
@MainActor
struct AppView: View {
    /// The root store.
    @Bindable var store: StoreOf<AppFeature>

    /// The screen's content.
    var body: some View {
        TodayView(store: store.scope(state: \.today, action: \.today))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom) {
                logButton
                    .padding(.bottom, Spacing.itemGap)
            }
            .background {
                LinearGradient(
                    colors: [Color.backgroundCanvasTop, Color.backgroundCanvasBottom], startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(AppViewAccessibilityID.screen)
            .sheet(item: $store.scope(state: \.composer, action: \.composer)) { composerStore in
                DrinkComposerView(store: composerStore)
            }
    }

    private var logButton: some View {
        Button {
            store.send(.logButtonTapped)
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.textOnEmphasis)
                .frame(width: Sizing.fabDiameter, height: Sizing.fabDiameter)
                .background(Color.actionPrimary, in: Circle())
                .shadow(
                    color: Color.textPrimary.opacity(Elevation.floating.opacity), radius: Elevation.floating.radius,
                    y: Elevation.floating.yOffset)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Log a drink"))
        .accessibilityIdentifier(AppViewAccessibilityID.logButton)
    }
}

#Preview {
    AppView(store: Store(initialState: AppFeature.State()) { AppFeature() })
}
