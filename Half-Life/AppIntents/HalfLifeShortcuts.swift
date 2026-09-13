//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life HalfLifeShortcuts
//

import AppIntents

/// The App Shortcuts that Siri, Shortcuts, and Spotlight offer without setup: one for each intent.
///
/// Every phrase names the app, as App Shortcuts require. The phrases are localized in `AppShortcuts.xcstrings`
/// (constitution Article VII.1.3). See INTENT-SHORTCUTS-1 in the App Intents article.
struct HalfLifeShortcuts: AppShortcutsProvider {
    /// The shortcuts, with their phrases, titles, and symbols.
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogDrinkIntent(),
            phrases: [
                "Log \(\.$drink) in \(.applicationName)",
                "Log a \(\.$drink) in \(.applicationName)",
                "Log a drink in \(.applicationName)",
            ],
            shortTitle: "Log a Drink",
            systemImageName: "cup.and.saucer.fill")
        AppShortcut(
            intent: GetCaffeineStatusIntent(),
            phrases: [
                "How much caffeine is in me in \(.applicationName)",
                "What's my caffeine level in \(.applicationName)",
            ],
            shortTitle: "Caffeine Level",
            systemImageName: "chart.line.downtrend.xyaxis")
        AppShortcut(
            intent: GetLastCupIntent(),
            phrases: [
                "When's my last cup in \(.applicationName)",
                "When should I stop drinking coffee in \(.applicationName)",
            ],
            shortTitle: "Last Cup",
            systemImageName: "clock")
        AppShortcut(
            intent: GetCaffeineIntakeIntent(),
            phrases: [
                "How much caffeine have I had in \(.applicationName)",
                "What did I drink today in \(.applicationName)",
            ],
            shortTitle: "Caffeine Intake",
            systemImageName: "list.bullet")
        AppShortcut(
            intent: GetSleepTimeIntent(),
            phrases: [
                "When should I go to sleep in \(.applicationName)",
                "When can I sleep in \(.applicationName)",
            ],
            shortTitle: "Sleep Time",
            systemImageName: "bed.double.fill")
        AppShortcut(
            intent: AskHalfLifeIntent(),
            phrases: [
                "Ask \(.applicationName) a question",
                "Ask \(.applicationName)",
            ],
            shortTitle: "Ask Half-Life",
            systemImageName: "text.bubble")
    }
}
