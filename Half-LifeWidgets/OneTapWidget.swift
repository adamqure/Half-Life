//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeWidgets OneTapWidget
//

import AppIntents
import SwiftUI
import WidgetKit

/// The One tap widget: favourite drinks, each logged in one tap without opening the app.
///
/// The small widget logs the top favourite, and the medium widget shows all three, like the Today screen's row. Each
/// button performs ``LogDrinkIntent``, which runs in the app's process (constitution Article I.18). See the Widgets
/// article.
@MainActor
struct OneTapWidget: Widget {
    /// The widget's kind, which identifies it to WidgetKit.
    static let kind = "com.quillanq.Half-Life.oneTap"

    /// The widget's configuration: small and medium, on the Home Screen.
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: HalfLifeTimelineProvider()) { entry in
            OneTapWidgetView(entry: entry)
                .containerBackground(Color.surfaceCard, for: .widget)
        }
        .configurationDisplayName("One tap")
        .description("Log a favourite drink without opening Half-Life.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

/// The One tap widget's content: the favourites, or the setup message until Half-Life is set up.
@MainActor
struct OneTapWidgetView: View {
    /// The timeline entry to show.
    let entry: HalfLifeWidgetEntry

    @Environment(\.widgetFamily) private var family

    /// The favourites for the widget's size, and when the latest drink was consumed.
    var body: some View {
        if let content = entry.content {
            VStack(alignment: .leading, spacing: 6) {
                if family == .systemMedium {
                    Text("One tap")
                        .font(.eyebrow)
                        .textCase(.uppercase)
                        .foregroundStyle(Color.textSecondary)
                        .accessibilityAddTraits(.isHeader)
                    HStack(spacing: 8) {
                        ForEach(content.favourites, id: \.self) { favourite in
                            OneTapWidgetButton(favourite: favourite)
                        }
                    }
                } else if let favourite = content.favourites.first {
                    OneTapWidgetButton(favourite: favourite)
                }
                if let latestDrinkAt = content.latestDrinkAt {
                    LatestDrinkText(date: latestDrinkAt)
                }
            }
        } else {
            WidgetSetUpView()
        }
    }
}

/// A favourite's button: its icon, name, quantity, and caffeine. A tap logs it, consumed now.
@MainActor
struct OneTapWidgetButton: View {
    /// The favourite the button logs.
    let favourite: FavouriteDrink

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private static let spokenAmount = Measurement<UnitMass>.FormatStyle(
        width: .wide, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(0)))

    /// The button, which performs ``LogDrinkIntent`` for the favourite.
    var body: some View {
        Button(intent: LogDrinkIntent(drink: DrinkTypeAppEnum(favourite.type), quantity: favourite.quantity)) {
            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: favourite.type.symbolName)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.textAccent)
                    .frame(width: Sizing.iconTileCompact, height: Sizing.iconTileCompact)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.extraSmall, style: .continuous)
                            .fill(Color.dataCaffeineSubtle)
                    )
                    .accessibilityHidden(true)
                Spacer(minLength: 0)
                Text(favourite.type.displayName)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                // At accessibility text sizes, the name takes the room, and the quantity line goes.
                if !dynamicTypeSize.isAccessibilitySize {
                    Text(detail)
                        .font(.caption2)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                    .fill(Color.surfaceMuted)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(name))
        .accessibilityValue(Text(spoken))
        .accessibilityHint(Text("Logs this drink now."))
    }

    /// The drink and its quantity, such as "Espresso, 2 shots", under the Today screen's String Catalog key.
    private var name: String {
        let name = String(localized: favourite.type.displayName)
        let quantity = String(localized: favourite.type.unit.quantityText(favourite.quantity))
        return String(localized: "\(name), \(quantity)")
    }

    /// The quantity and caffeine, such as "2 shots · 125 mg".
    private var detail: String {
        let quantity = String(localized: favourite.type.unit.quantityText(favourite.quantity))
        let amount = CaffeineFormat.milligrams(favourite.type.estimatedMilligrams(quantity: favourite.quantity))
        return String(localized: "\(quantity) · \(amount)")
    }

    /// The caffeine in full, such as "125 milligrams", for VoiceOver.
    private var spoken: String {
        Measurement(value: favourite.type.estimatedMilligrams(quantity: favourite.quantity), unit: UnitMass.milligrams)
            .formatted(Self.spokenAmount)
    }
}

/// When the latest drink was consumed, such as "Latest drink 3:04 PM". It dims while the widget reloads after a tap,
/// and iOS hides it while the phone is locked.
@MainActor
struct LatestDrinkText: View {
    /// When the latest drink was consumed.
    let date: Date

    /// The line.
    var body: some View {
        Text("Latest drink \(date.formatted(.dateTime.hour().minute()))")
            .font(.caption2)
            .foregroundStyle(Color.textSecondary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .privacySensitive()
            .invalidatableContent()
    }
}

#Preview("Small", as: .systemSmall) {
    OneTapWidget()
} timeline: {
    HalfLifeWidgetEntry.sample(at: .now)
    HalfLifeWidgetEntry.nothingLogged(at: .now)
    HalfLifeWidgetEntry(date: .now, content: nil)
}

#Preview("Medium", as: .systemMedium) {
    OneTapWidget()
} timeline: {
    HalfLifeWidgetEntry.sample(at: .now)
    HalfLifeWidgetEntry.nothingLogged(at: .now)
    HalfLifeWidgetEntry(date: .now, content: nil)
}
