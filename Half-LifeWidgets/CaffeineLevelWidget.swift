//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeWidgets CaffeineLevelWidget
//

import Charts
import SwiftUI
import WidgetKit

/// The In your system widget: the caffeine in your system now, and its curve. A tap opens the app.
///
/// The medium widget adds the decay card's sentence about bedtime. See the Widgets article.
@MainActor
struct CaffeineLevelWidget: Widget {
    /// The widget's kind, which identifies it to WidgetKit.
    static let kind = "com.quillanq.Half-Life.caffeineLevel"

    /// The widget's configuration: small and medium, on the Home Screen.
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: HalfLifeTimelineProvider()) { entry in
            CaffeineLevelWidgetView(entry: entry)
                .containerBackground(Color.surfaceCard, for: .widget)
        }
        .configurationDisplayName("In your system")
        .description("The caffeine in your system now, and how much is left by bedtime.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

/// The In your system widget's content: the level, the sentence, and the curve, or the setup message.
@MainActor
struct CaffeineLevelWidgetView: View {
    /// The timeline entry to show.
    let entry: HalfLifeWidgetEntry

    @Environment(\.widgetFamily) private var family
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private static let wholeNumber = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(0))
    private static let spokenAmount = Measurement<UnitMass>.FormatStyle(
        width: .wide, usage: .asProvided, numberFormatStyle: wholeNumber)
    private static let clockTime = Date.FormatStyle.dateTime.hour().minute()

    /// The level, the sentence on the medium widget, and the curve.
    var body: some View {
        if let content = entry.content {
            VStack(alignment: .leading, spacing: 4) {
                Text("In your system now")
                    .font(.eyebrow)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(2)
                figure(content.level.milligrams)
                if family == .systemMedium {
                    Text(sentence(content))
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .privacySensitive()
                }
                // At accessibility text sizes, the figure and the sentence take the room, and the curve goes.
                if !dynamicTypeSize.isAccessibilitySize {
                    curve(content)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        } else {
            WidgetSetUpView()
        }
    }

    /// The level in the accent color, such as "85 mg". VoiceOver reads it in full, after the heading.
    private func figure(_ milligrams: Double) -> some View {
        Text(CaffeineFormat.milligrams(milligrams))
            .font(.system(.largeTitle, weight: .light).monospacedDigit())
            .foregroundStyle(Color.accent)
            .minimumScaleFactor(0.6)
            .lineLimit(1)
            .privacySensitive()
            .accessibilityLabel(
                Text(Measurement(value: milligrams, unit: UnitMass.milligrams).formatted(Self.spokenAmount)))
    }

    /// The decay card's first sentence: nothing in your system, or how much is left by bedtime.
    private func sentence(_ content: WidgetContent) -> LocalizedStringResource {
        // The figure rounds to whole milligrams, so below half a milligram it reads 0 mg.
        guard content.level.milligrams >= 0.5, let atBedtime = content.levelAtBedtime else {
            return "Nothing in your system right now."
        }
        let amount = CaffeineFormat.milligrams(atBedtime.milligrams)
        let bedtime = atBedtime.date.formatted(Self.clockTime)
        return "Down to about \(amount) by \(bedtime)."
    }

    /// The curve from 6 hours ago to 6 hours ahead, with a dashed rule and a dot at the current level.
    private func curve(_ content: WidgetContent) -> some View {
        Chart {
            ForEach(content.curve, id: \.date) { level in
                AreaMark(x: .value("Time", level.date), y: .value("Caffeine", level.milligrams))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.dataCaffeine.opacity(0.25), Color.dataCaffeine.opacity(0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                LineMark(x: .value("Time", level.date), y: .value("Caffeine", level.milligrams))
                    .foregroundStyle(Color.dataCaffeine)
                    .lineStyle(StrokeStyle(lineWidth: 2))
            }
            RuleMark(x: .value("Current time", content.level.date))
                .foregroundStyle(Color.controlBorder)
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
            PointMark(x: .value("Current time", content.level.date), y: .value("Caffeine", content.level.milligrams))
                .foregroundStyle(Color.accent)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .privacySensitive()
        .accessibilityLabel(Text("Caffeine over the day"))
    }
}

#Preview("Small", as: .systemSmall) {
    CaffeineLevelWidget()
} timeline: {
    HalfLifeWidgetEntry.sample(at: .now)
    HalfLifeWidgetEntry.nothingLogged(at: .now)
    HalfLifeWidgetEntry(date: .now, content: nil)
}

#Preview("Medium", as: .systemMedium) {
    CaffeineLevelWidget()
} timeline: {
    HalfLifeWidgetEntry.sample(at: .now)
    HalfLifeWidgetEntry.nothingLogged(at: .now)
    HalfLifeWidgetEntry(date: .now, content: nil)
}
