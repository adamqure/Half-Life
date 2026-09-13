//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life CutoffWarningBanner
//

import SwiftUI

/// The drink composer's cutoff warning: the heading, and why the chosen drink, at the time chosen, is past its caffeine
/// cutoff, in the wording the owner approved.
///
/// It sits above Add, which it never disables. VoiceOver reads it as one element. Its symbol is decorative, so the text
/// carries the meaning (constitution Article VI.1 and VI.3). See the Drink Composer and Caffeine Cutoff articles.
@MainActor
struct CutoffWarningBanner: View {
    /// Why the drink is past its cutoff.
    let warning: CutoffWarning

    /// The heading and the reason, in the caution colors, with a warning symbol.
    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: Spacing.sectionHeaderGap) {
                Text("After your cutoff")
                    .font(.footnote.weight(.semibold))
                reason
                    .font(.footnote)
            }
            .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
                .accessibilityHidden(true)
        }
        .foregroundStyle(Color.feedbackCaution)
        .padding(Spacing.itemGap)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.feedbackCautionBackground, in: RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
        )
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(DrinkComposerViewAccessibilityID.cutoffWarning)
    }

    /// Why the drink is past its cutoff. The amount rounds up to the whole milligram, so it never shows at or under the
    /// threshold it's compared with.
    private var reason: Text {
        switch warning {
        case let .tooMuchAtBedtime(level, threshold):
            let amount = CaffeineFormat.milligrams(level.milligrams.rounded(.up))
            let bedtime = level.date.formatted(date: .omitted, time: .shortened)
            let limit = CaffeineFormat.milligrams(threshold.milligrams)
            switch threshold.source {
            case .learned:
                return Text(
                    """
                    About \(amount) would still be in you at your \(bedtime) bedtime. Your time asleep starts to \
                    drop above \(limit).
                    """)
            case .sleepStudies:
                return Text(
                    """
                    About \(amount) would still be in you at your \(bedtime) bedtime. Clinical sleep studies \
                    support under \(limit) for the average person.
                    """)
            }
        case let .stillRisingAtBedtime(bedtime):
            let time = bedtime.formatted(date: .omitted, time: .shortened)
            return Text("This would still be rising at your \(time) bedtime.")
        }
    }
}
