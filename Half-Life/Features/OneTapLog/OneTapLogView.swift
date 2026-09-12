//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life OneTapLogView
//

import ComposableArchitecture
import SwiftUI

/// The one-tap row: a "One tap" heading, and a button for each favourite that logs it as consumed now.
///
/// The Today screen shows it under its tiles, and the drink composer above its drink tiles. Each button shows the
/// drink's icon, name, quantity, and caffeine. Just after a tap, the button shows "Logged" with a checkmark, the device
/// plays the success haptic, and VoiceOver announces it. The buttons sit in a row, and stack from the xxLarge text size
/// so none of them is cut off (constitution Article VI.2). See the One-Tap Log article.
@MainActor
struct OneTapLogView: View {
    /// How much each favourite shows.
    enum Style {
        /// The "One tap" heading, and each drink's icon, name, quantity, and caffeine. The Today screen's style.
        case cards
        /// Each drink's name, quantity, and caffeine only, so the drink composer's sheet stays compact.
        case slim
    }

    /// The row's store.
    let store: StoreOf<OneTapLogFeature>
    /// How much each favourite shows.
    var style = Style.cards

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// The heading, the favourites, and a message if a favourite couldn't be saved.
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sectionHeaderGap) {
            if style == .cards {
                Text("One tap")
                    .font(.eyebrow)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.textSecondary)
                    .accessibilityAddTraits(.isHeader)
            }
            favourites
            if store.saveFailed {
                saveError
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sensoryFeedback(.success, trigger: store.justLogged) { _, logged in logged != nil }
        .onChange(of: store.justLogged) { _, logged in
            guard let logged else { return }
            AccessibilityNotification.Announcement(String(localized: "Logged \(FavouriteButton.name(of: logged))"))
                .post()
        }
        .task { await store.send(.task).finish() }
    }

    /// The buttons, in a row of equal heights, or a column from the xxLarge text size. The layout switches on the text
    /// size rather than through `ViewThatFits`, which fails the accessibility audit's Dynamic Type check.
    private var favourites: some View {
        let layout =
            dynamicTypeSize >= .xxLarge
            ? AnyLayout(VStackLayout(spacing: Spacing.itemGap))
            : AnyLayout(HStackLayout(alignment: .top, spacing: Spacing.itemGap))
        let buttons = Array(zip(store.favourites, OneTapLogViewAccessibilityID.favourites))
        return layout {
            ForEach(buttons, id: \.0) { favourite, identifier in
                FavouriteButton(
                    favourite: favourite, isLogged: store.justLogged == favourite, showsIcon: style == .cards,
                    identifier: identifier
                ) {
                    store.send(.favouriteTapped(favourite))
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
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
    }
}

/// One favourite: its icon, name, quantity, and caffeine, or a checkmark and "Logged" just after it's logged.
@MainActor
private struct FavouriteButton: View {
    let favourite: FavouriteDrink
    let isLogged: Bool
    let showsIcon: Bool
    let identifier: String
    let log: () -> Void

    @ScaledMetric(relativeTo: .footnote) private var iconTileSide = Sizing.iconTileCompact

    private static let spokenAmount = Measurement<UnitMass>.FormatStyle(
        width: .wide, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(0)))

    var body: some View {
        Button(action: log) {
            VStack(alignment: .leading, spacing: Spacing.itemGap / 2) {
                if showsIcon {
                    Image(systemName: isLogged ? "checkmark" : favourite.type.symbolName)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.textAccent)
                        .frame(width: iconTileSide, height: iconTileSide)
                        .background(
                            Color.dataCaffeineSubtle,
                            in: RoundedRectangle(cornerRadius: CornerRadius.extraSmall, style: .continuous)
                        )
                        .accessibilityHidden(true)
                }
                Text(favourite.type.displayName)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                detail
                    .font(.footnote)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(Spacing.itemGap)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color.surfaceCard, in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                    .strokeBorder(Color.borderCard, lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(Self.name(of: favourite)))
        .accessibilityValue(isLogged ? Text("Logged") : Text(Self.spoken(favourite)))
        .accessibilityHint(Text("Logs this drink now."))
        .accessibilityIdentifier(identifier)
    }

    /// The quantity and caffeine, such as "2 shots · 125 mg", or "Logged" just after it's logged.
    private var detail: Text {
        if isLogged {
            return Text("Logged").fontWeight(.semibold).foregroundStyle(Color.textAccent)
        }
        let quantity = String(localized: favourite.type.unit.quantityText(favourite.quantity))
        let amount = CaffeineFormat.milligrams(favourite.type.estimatedMilligrams(quantity: favourite.quantity))
        return Text("\(quantity) · \(amount)").foregroundStyle(Color.textSecondary)
    }

    /// The drink and its quantity, such as "Espresso, 2 shots": the button's label, and the heart of its announcement.
    static func name(of favourite: FavouriteDrink) -> String {
        let name = String(localized: favourite.type.displayName)
        let quantity = String(localized: favourite.type.unit.quantityText(favourite.quantity))
        return String(localized: "\(name), \(quantity)")
    }

    /// The caffeine in full, rounded to whole milligrams, such as "125 milligrams", for VoiceOver.
    private static func spoken(_ favourite: FavouriteDrink) -> String {
        Measurement(value: favourite.type.estimatedMilligrams(quantity: favourite.quantity), unit: UnitMass.milligrams)
            .formatted(spokenAmount)
    }
}

#Preview {
    OneTapLogView(
        store: Store(initialState: OneTapLogFeature.State(favourites: FavouriteDrinksRule.starters)) {
            OneTapLogFeature()
        }
    )
    .padding()
}
