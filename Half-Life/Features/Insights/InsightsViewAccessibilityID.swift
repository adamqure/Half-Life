//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life InsightsViewAccessibilityID
//

/// Accessibility identifiers for ``InsightsView`` and its cards (constitution Article II.7).
///
/// This file belongs to both the `Half-Life` and `Half-LifeUITests` targets, so the views and `InsightsRobot` share
/// one definition.
enum InsightsViewAccessibilityID {
    /// The Insights tab's root element, which robots use to detect the screen.
    static let screen = "insightsView.screen"
    /// The scrolling content under the title.
    static let content = "insightsView.content"
    /// Tonight's sleep window card.
    static let sleepWindowCard = "insightsView.sleepWindowCard"
    /// The window's start and end times, or that there's no window tonight.
    static let sleepWindowTimes = "insightsView.sleepWindowTimes"
    /// The sentence that says why the window is where it is.
    static let sleepWindowSummary = "insightsView.sleepWindowSummary"
    /// The chart of tonight's caffeine, with the threshold and the window.
    static let sleepWindowChart = "insightsView.sleepWindowChart"
    /// The sentence that says where the sleep window's threshold comes from.
    static let sleepWindowFootnote = "insightsView.sleepWindowFootnote"
    /// The last 7 days card.
    static let weekCard = "insightsView.weekCard"
    /// The last 7 days card's column for yesterday.
    static let weekColumn1DayAgo = "insightsView.weekColumn1DayAgo"
    /// The last 7 days card's column for 2 days ago.
    static let weekColumn2DaysAgo = "insightsView.weekColumn2DaysAgo"
    /// The last 7 days card's column for 3 days ago.
    static let weekColumn3DaysAgo = "insightsView.weekColumn3DaysAgo"
    /// The last 7 days card's column for 4 days ago.
    static let weekColumn4DaysAgo = "insightsView.weekColumn4DaysAgo"
    /// The last 7 days card's column for 5 days ago.
    static let weekColumn5DaysAgo = "insightsView.weekColumn5DaysAgo"
    /// The last 7 days card's column for 6 days ago.
    static let weekColumn6DaysAgo = "insightsView.weekColumn6DaysAgo"
    /// The last 7 days card's column for 7 days ago.
    static let weekColumn7DaysAgo = "insightsView.weekColumn7DaysAgo"
    /// The columns, oldest first, so the last is yesterday's.
    static let weekColumns = [
        weekColumn7DaysAgo, weekColumn6DaysAgo, weekColumn5DaysAgo, weekColumn4DaysAgo, weekColumn3DaysAgo,
        weekColumn2DaysAgo, weekColumn1DayAgo,
    ]
    /// The chosen day's name: "Yesterday", or its weekday.
    static let weekDetailTitle = "insightsView.weekDetailTitle"
    /// The chosen day's caffeine.
    static let weekDetailCaffeine = "insightsView.weekDetailCaffeine"
    /// The chosen day's sleep: the time asleep, the time in bed, or "Not recorded".
    static let weekDetailSleep = "insightsView.weekDetailSleep"
    /// Where the sleep comes from: Apple Health, or the demo.
    static let weekSleepSource = "insightsView.weekSleepSource"
    /// The chosen day's last cup, or "None".
    static let weekDetailLastCup = "insightsView.weekDetailLastCup"
    /// The Health data card: a button for each kind of Health data with any data.
    static let healthDataCard = "insightsView.healthDataCard"
    /// The Health data card's sleep button.
    static let healthDataSleepButton = "insightsView.healthDataSleepButton"
    /// The Health data card's steps button.
    static let healthDataStepsButton = "insightsView.healthDataStepsButton"
    /// The Health data card's resting heart rate button.
    static let healthDataRestingHeartRateButton = "insightsView.healthDataRestingHeartRateButton"
    /// The note that sleep appears when Apple Health has it.
    static let weekSleepNote = "insightsView.weekSleepNote"
    /// The "What we noticed" card.
    static let noticedCard = "insightsView.noticedCard"
    /// The finding's headline, in the model's words.
    static let noticedHeadline = "insightsView.noticedHeadline"
    /// The finding's sentence, in the model's words.
    static let noticedSentence = "insightsView.noticedSentence"
    /// The label that says the finding comes from the demo Health data.
    static let noticedDemo = "insightsView.noticedDemo"
    /// The "Yes" answer to "Feel right?".
    static let feelRightYes = "insightsView.feelRightYes"
    /// The "Not really" answer to "Feel right?".
    static let feelRightNotReally = "insightsView.feelRightNotReally"
}
