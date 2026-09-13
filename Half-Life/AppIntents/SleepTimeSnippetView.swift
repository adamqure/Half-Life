//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life SleepTimeSnippetView
//

import SwiftUI

/// Siri's snippet for "When should I go to sleep?": tonight's caffeine against the sleep threshold, with the window
/// shaded, drawn by the Insights card's ``SleepWindowChart``.
///
/// Siri shows it under the dialog's sentence, and may not show it at all, so it adds nothing the sentence doesn't say.
/// It appears in Siri, outside the app that UI tests launch, so it has no robot. Its previews, at the default and the
/// largest text size, and an Accessibility Inspector check before release, cover it instead (constitution Article
/// I.20). See the App Intents article.
@MainActor
struct SleepTimeSnippetView: View {
    /// Tonight's window.
    let window: SleepWindow

    /// Creates the snippet. It's `nonisolated`, so ``GetSleepTimeIntent`` can build it off the main actor.
    ///
    /// - Parameter window: Tonight's window.
    nonisolated init(window: SleepWindow) {
        self.window = window
    }

    /// The chart, with the card's padding.
    var body: some View {
        SleepWindowChart(window: window)
            .padding(Spacing.cardPadding)
    }
}

#if DEBUG
    extension SleepWindow {
        /// A night for the previews: a 10:30pm bedtime, with caffeine clearing at about 11:20pm.
        fileprivate static let preview: SleepWindow = {
            let evening = Date(timeIntervalSinceReferenceDate: 810_496_800)
            let minute: TimeInterval = 60
            let levels = stride(from: 0, through: 600, by: 10).map { offset in
                CaffeineLevel(
                    date: evening.addingTimeInterval(Double(offset) * minute),
                    milligrams: 120 * pow(0.5, Double(offset) / 200))
            }
            let clearsAt = evening.addingTimeInterval(320 * minute)
            return SleepWindow(
                evening: evening,
                bedtime: evening.addingTimeInterval(270 * minute),
                clearsAt: clearsAt,
                window: DateInterval(start: clearsAt, duration: 90 * minute),
                chartEnd: evening.addingTimeInterval(600 * minute),
                threshold: .standard,
                levels: levels)
        }()
    }

    #Preview("After bedtime") {
        SleepTimeSnippetView(window: .preview)
    }

    #Preview("Largest text") {
        SleepTimeSnippetView(window: .preview)
            .environment(\.dynamicTypeSize, .accessibility5)
    }
#endif
