//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life DrinkComposerView
//

import ComposableArchitecture
import SwiftUI

/// The drink composer's screen: a header, the one-tap row, a separator, a row of drink tiles that scrolls sideways,
/// and the chosen drink's panel.
///
/// A drink is always chosen, so the panel always shows. The sheet is only as tall as its content. When the content
/// is taller than the screen, at the largest text sizes, the sheet reaches full height and scrolls, so none of it is
/// cut off (constitution Article VI.2).
@MainActor
struct DrinkComposerView: View {
    /// The composer's store.
    let store: StoreOf<DrinkComposerFeature>

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var contentHeight: CGFloat = 560
    @State private var bottomInset: CGFloat = 0

    /// The screen's content.
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.sectionGap) {
                // The separator has a card gap on each side rather than a section gap, which keeps the sheet compact.
                if dynamicTypeSize.isAccessibilitySize {
                    header
                        .padding(.horizontal, Spacing.screenMargin)
                    drinkTiles
                    VStack(alignment: .leading, spacing: Spacing.cardGap) {
                        panel
                        oneTapSeparator
                        oneTapRow
                    }
                    .padding(.horizontal, Spacing.screenMargin)
                } else {
                    VStack(alignment: .leading, spacing: Spacing.cardGap) {
                        VStack(alignment: .leading, spacing: Spacing.itemGap) {
                            header
                            oneTapRow
                        }
                        .padding(.horizontal, Spacing.screenMargin)
                        oneTapSeparator
                            .padding(.horizontal, Spacing.screenMargin)
                        drinkTiles
                    }
                    panel
                        .padding(.horizontal, Spacing.screenMargin)
                }
            }
            .padding(.vertical, Spacing.itemGap)
            .onGeometryChange(for: CGFloat.self) {
                $0.size.height
            } action: {
                contentHeight = $0
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .onGeometryChange(for: CGFloat.self) {
            $0.safeAreaInsets.bottom
        } action: {
            bottomInset = $0
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(DrinkComposerViewAccessibilityID.screen)
        .background(Color.backgroundCanvasTop)
        .presentationBackground(Color.backgroundCanvasTop)
        .presentationDetents([.height(contentHeight + bottomInset)])
        .task { await store.send(.task).finish() }
    }

    /// The composer's own header. The system navigation bar's Close button doesn't scale with Dynamic Type, which fails
    /// the accessibility audit.
    private var header: some View {
        HStack(alignment: .center) {
            Text("Log a drink")
                .font(.headline)
                .foregroundStyle(Color.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: Spacing.itemGap)
            Button {
                store.send(.closeTapped)
            } label: {
                Text("Close")
                    .font(.body)
                    .foregroundStyle(Color.textPrimary)
                    .frame(minWidth: Sizing.minimumHitTarget, minHeight: Sizing.minimumHitTarget)
                    // Without a content shape, the hit area is only the text, which is smaller than 44 pt.
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(DrinkComposerViewAccessibilityID.closeButton)
        }
    }

    /// The one-tap row, in its slim style, so the sheet stays compact. It sits under the header. At accessibility text
    /// sizes it moves under the panel, because its stacked favourites would push the panel off screen.
    private var oneTapRow: some View {
        OneTapLogView(store: store.scope(state: \.oneTapLog, action: \.oneTapLog), style: .slim)
    }

    /// The line between the one-tap row and the rest of the composer, so the favourites read as their own group. It
    /// moves with the row, so it always sits between the row and the panel. It's decorative.
    private var oneTapSeparator: some View {
        Divider()
            .overlay(Color.separatorOnCard)
            .accessibilityHidden(true)
    }

    /// How many tiles fit the row's width: three, two from the xLarge text size, and one at accessibility sizes.
    private var tilesPerRow: Int {
        if dynamicTypeSize.isAccessibilitySize { return 1 }
        return dynamicTypeSize >= .xLarge ? 2 : 3
    }

    /// The row of tiles. It spans the screen, with the screen margins as content margins. Each tile is an exact
    /// fraction of the space between the margins, and the row snaps to tile edges.
    ///
    /// The next tile's name starts beyond the screen: the accessibility audit checks any text that touches the screen,
    /// even clipped, and a sliver of a name fails its contrast check. With the sheet's side inset of about 8 pt, the
    /// name starts at the margin's edge plus the gap plus the tile's padding. The card gap of 16 pt puts it 4 pt past
    /// the screen's edge at any width.
    private var drinkTiles: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: Spacing.cardGap) {
                ForEach(DrinkType.allCases, id: \.self) { drink in
                    DrinkTile(drink: drink, isSelected: store.selectedDrink == drink) {
                        store.send(.drinkSelected(drink))
                    }
                    .containerRelativeFrame(.horizontal, count: tilesPerRow, spacing: Spacing.cardGap)
                }
            }
            .scrollTargetLayout()
        }
        .contentMargins(.horizontal, Spacing.screenMargin, for: .scrollContent)
        .scrollTargetBehavior(.viewAligned)
        .accessibilityIdentifier(DrinkComposerViewAccessibilityID.drinkTiles)
    }

    private var panel: some View {
        VStack(alignment: .leading, spacing: Spacing.itemGap) {
            HStack(alignment: .firstTextBaseline) {
                Text(store.selectedDrink.displayName)
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)
                Spacer(minLength: Spacing.itemGap)
                Text(CaffeineFormat.milligrams(store.estimatedMilligrams))
                    .font(.title2)
                    .foregroundStyle(Color.textPrimary)
                    .accessibilityIdentifier(DrinkComposerViewAccessibilityID.estimate)
            }
            quantityRow
            whenChoices
            if store.saveFailed {
                saveError
            }
            addButton
        }
        .padding(Spacing.cardPadding)
        .background {
            // The shadow is on the card only. On the whole panel it would shadow every glyph, which fails the
            // accessibility audit's contrast check.
            RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                .fill(Color.surfaceCard)
                .shadow(
                    color: Color.textPrimary.opacity(Elevation.card.opacity), radius: Elevation.card.radius,
                    y: Elevation.card.yOffset)
        }
    }

    private var quantityRow: some View {
        HStack(spacing: Spacing.itemGap) {
            Text(store.selectedDrink.unit.quantityText(store.quantity))
                .font(.title3)
                .foregroundStyle(Color.textPrimary)
                .accessibilityIdentifier(DrinkComposerViewAccessibilityID.quantity)
            Spacer(minLength: 0)
            StepButton(
                symbolName: "minus", label: "Decrease quantity",
                identifier: DrinkComposerViewAccessibilityID.decreaseButton
            ) {
                store.send(.quantityDecremented)
            }
            StepButton(
                symbolName: "plus", label: "Increase quantity",
                identifier: DrinkComposerViewAccessibilityID.increaseButton
            ) {
                store.send(.quantityIncremented)
            }
        }
    }

    /// The "When" choices: a row, or a column from the xxLarge text size up. The layout switches on the text size
    /// rather than through `ViewThatFits`, whose chips fail the accessibility audit's Dynamic Type check.
    private var whenChoices: some View {
        let layout =
            dynamicTypeSize >= .xxLarge
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.itemGap))
            : AnyLayout(HStackLayout(spacing: Spacing.itemGap))
        return VStack(alignment: .leading, spacing: Spacing.sectionHeaderGap) {
            Text("When")
                .font(.footnote)
                .foregroundStyle(Color.textSecondary)
            layout {
                ForEach(DrinkComposerFeature.ConsumedWhen.allCases, id: \.self) { when in
                    WhenChoice(when: when, isSelected: store.consumedWhen == when) {
                        store.send(.consumedWhenSelected(when))
                    }
                }
            }
        }
    }

    private var saveError: some View {
        Label {
            Text("The drink couldn't be saved. Try again.")
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
                .accessibilityHidden(true)
        }
        .font(.footnote)
        .foregroundStyle(Color.feedbackCaution)
        .padding(Spacing.itemGap)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.feedbackCautionBackground, in: RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
        )
        .accessibilityIdentifier(DrinkComposerViewAccessibilityID.errorMessage)
    }

    private var addButton: some View {
        Button {
            store.send(.addTapped)
        } label: {
            Text("Add \(CaffeineFormat.milligrams(store.estimatedMilligrams))")
                .font(.headline)
                .foregroundStyle(Color.textOnEmphasis)
                .padding(.horizontal, Spacing.itemGap)
                .frame(maxWidth: .infinity, minHeight: Sizing.buttonHeight)
                .background(
                    Color.actionPrimary, in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(store.isLogging)
        .accessibilityIdentifier(DrinkComposerViewAccessibilityID.addButton)
    }
}

/// One drink in the composer's row: its icon above its name, with a checkmark when it's chosen.
@MainActor
private struct DrinkTile: View {
    let drink: DrinkType
    let isSelected: Bool
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            VStack(alignment: .leading, spacing: Spacing.itemGap) {
                HStack {
                    Image(systemName: drink.symbolName)
                        .font(.title3)
                        .foregroundStyle(isSelected ? Color.accentOnEmphasis : Color.accentColor)
                        .accessibilityHidden(true)
                    Spacer(minLength: 0)
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color.textOnEmphasis)
                            .accessibilityHidden(true)
                    }
                }
                Text(drink.displayName)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(isSelected ? Color.textOnEmphasis : Color.textPrimary)
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.leading)
            }
            .padding(Spacing.cardPaddingCompact)
            .frame(maxWidth: .infinity, minHeight: Sizing.minimumHitTarget, alignment: .leading)
            .background(
                isSelected ? Color.surfaceSelected : Color.surfaceCard,
                in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
        }
        .buttonStyle(.plain)
        // The tile switches to light text and a dark background at once. An animated switch would briefly show light
        // text on a light background, which fails the accessibility audit's contrast check.
        .transaction { transaction in
            transaction.animation = nil
            transaction.disablesAnimations = true
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier(drink.accessibilityTileIdentifier)
    }
}

/// A round button that adds or removes one unit.
@MainActor
private struct StepButton: View {
    let symbolName: String
    let label: LocalizedStringKey
    let identifier: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbolName)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.textPrimary)
                .frame(width: Sizing.minimumHitTarget, height: Sizing.minimumHitTarget)
                .background(Color.surfaceControl, in: Circle())
                .overlay(Circle().strokeBorder(Color.controlBorder))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label))
        .accessibilityIdentifier(identifier)
    }
}

/// One "When" choice, drawn as a chip.
@MainActor
private struct WhenChoice: View {
    let when: DrinkComposerFeature.ConsumedWhen
    let isSelected: Bool
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            title
                .font(.callout.weight(.semibold))
                .foregroundStyle(isSelected ? Color.textOnEmphasis : Color.textPrimary)
                .padding(.horizontal, Spacing.itemGap)
                .frame(minWidth: Sizing.minimumHitTarget, minHeight: Sizing.chipHeight)
                .background(isSelected ? Color.controlSelected : Color.surfaceControl, in: Capsule())
                .overlay(Capsule().strokeBorder(isSelected ? Color.controlSelected : Color.controlBorder))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier(identifier)
    }

    private var title: Text {
        switch when {
        case .now:
            Text("Now")
        case .oneHourAgo, .twoHoursAgo, .fourHoursAgo:
            Text("\(Duration.seconds(when.secondsAgo).formatted(.units(allowed: [.hours], width: .narrow))) ago")
        }
    }

    private var identifier: String {
        switch when {
        case .now: DrinkComposerViewAccessibilityID.whenNow
        case .oneHourAgo: DrinkComposerViewAccessibilityID.whenOneHourAgo
        case .twoHoursAgo: DrinkComposerViewAccessibilityID.whenTwoHoursAgo
        case .fourHoursAgo: DrinkComposerViewAccessibilityID.whenFourHoursAgo
        }
    }
}

#Preview {
    DrinkComposerView(
        store: Store(initialState: DrinkComposerFeature.State()) {
            DrinkComposerFeature()
        })
}
