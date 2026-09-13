# Half-Life Privacy Policy

**Effective:** September 13, 2026

Half-Life is an iPhone app, developed by Adam Ure, that shows how the caffeine you drink wears off, and how its timing lines up with your sleep, steps, and resting heart rate. This policy explains what the app stores, where it's stored, and how you control it.

**In short:** your data stays on your iPhone. Half-Life has no accounts, no server, no analytics, no advertising, and no tracking. The developer never receives your caffeine or health data.

## What Half-Life stores on your iPhone

Everything below is stored only on your device, inside the app's own storage. None of it is synced to iCloud, and none of it is sent to the developer or to anyone else.

| Data | Why |
|------|-----|
| The drinks you log: the kind of drink, its amount, its estimated caffeine, and when you drank it | To draw your caffeine curve, total your day, and suggest your one-tap favourites |
| What you tell the app about yourself, all of it optional: your first name, your age (stored as a birth year), what changes how fast you clear caffeine (such as smoking, pregnancy, or liver disease), and your bedtime | To greet you, compare your sleep with the recommended range for your age, and fit the caffeine curve to you |
| Two values worked out from your Apple Health data: your personal caffeine half-life, and the caffeine level your sleep starts to drop at | To fit the caffeine curve and your caffeine cutoff to you |
| Your answers to "Feel right?" on the Insights tab, with the finding you answered | To stop asking, or hide a finding you disagreed with, and to word the next one differently |
| A summary for the Home Screen widgets: your caffeine forecast, your favourite drinks, your bedtime, and when you last logged a drink | To show the widgets. It's kept in storage the app shares only with its own widgets. |
| Your settings: whether the app lock is on, whether Face ID has been requested, and whether demo Health data is on | To remember your choices |

Demo data that you add from Settings is stored the same way, marked as demo data, and deleted when you remove it. Demo Health data is generated inside the app, and is never written to Apple Health.

## Apple Health

With your permission, Half-Life **reads** three kinds of data from Apple Health: **sleep**, **step count**, and **resting heart rate**. It asks only when you tap "Allow Apple Health", during setup or in Settings, and never when the app launches. The app works fully if you say no.

- Half-Life **writes nothing** to Apple Health.
- Health data is read when a screen needs it, and held in memory. The app doesn't keep a copy. The only things it saves are the two values it works out from your sleep, listed above.
- Health data, and anything worked out from it, is never stored in iCloud, never sent anywhere, never shared with third parties, and never used for advertising or marketing.
- You can change or turn off Half-Life's access at any time in the Health app's privacy settings. Apple Health keeps its own data. Removing Half-Life's access doesn't delete anything from Health.

## What leaves your iPhone

Half-Life itself makes no network requests with your data. A few Apple features that the app works with can move data, under Apple's own privacy policy and your settings:

- **Device backups.** If you back up your iPhone to iCloud or a computer, the backup can include your drink log, your answers about yourself, your "Feel right?" answers, and your settings, like other apps' data. The values worked out from Apple Health, and the widget summary, are left out of backups.
- **Siri and Shortcuts.** When you ask Siri to log a drink or answer a question, Apple handles your request. Half-Life works out its answer on your iPhone.
- **Apple Intelligence.** The "What we noticed" card and "Ask Half-Life" use Apple's on-device language model. Your data and your questions aren't sent to any server, Apple's included, and nothing the model sees is saved.
- **Notifications.** If you allow them, the app schedules one reminder a day on your iPhone, at your caffeine cutoff. It names your usual drink and your bedtime, and no caffeine amounts, because it can appear on your Lock Screen.
- **Crash reports.** If you've chosen to share analytics with app developers in the Settings app (Privacy & Security, then Analytics & Improvements), Apple may send the developer crash reports and usage statistics. They don't include your caffeine or health data.
- **TestFlight.** If you test a beta version through TestFlight, Apple shares the following with the developer: your name and email address, if you were invited by email; your device model, iOS version, carrier, and time zone; crash reports; how often you used the build; and any feedback and screenshots you send. A screenshot shows whatever was on screen, so check it for health information before you send it.

## Logs

Like most apps, Half-Life writes diagnostic messages to your iPhone's system log, which helps fix bugs. Those messages never include caffeine amounts, health values, or anything worked out from them. Personal details are redacted by the system. The app has no way to send its log anywhere.

## Security

- Most of what Half-Life stores is encrypted by iOS, and can't be read while your iPhone is locked.
- Your drink log and the widget summary can be read after you first unlock your iPhone, so Siri and the widgets keep working while it's locked.
- An optional app lock, off by default, asks for Face ID, Touch ID, or your passcode each time you open the app.

## Keeping and deleting your data

Half-Life keeps your data until you delete it.

- **A drink:** delete it from the drink history on the Today tab.
- **Demo data:** remove it in Settings, under Demo data.
- **Your answers about yourself:** change or clear them in Settings.
- **Everything:** delete the app. That removes all of its data from your iPhone. A device backup keeps its copy until the backup is replaced or deleted.

## Your choices

- Turn Apple Health access, notifications, and Face ID on or off at any time in the Settings app. The app keeps working without them.
- Everything you tell the app about yourself is optional.

## Third parties

Half-Life shares no data with third parties. It contains no third-party analytics, advertising, or crash-reporting code. Its only third-party code is The Composable Architecture, an open-source library for building apps, and the open-source libraries it depends on. None of them collects data.

## Children

Half-Life isn't directed at children under 13, and it doesn't knowingly collect data from them. Nothing it stores leaves the device.

## Not medical advice

Half-Life estimates caffeine from typical amounts for each drink. Its findings are patterns in your own data, not medical advice, and not proof that caffeine caused anything.

## Changes to this policy

This policy lives in the app's public source repository. If it changes, the date at the top changes, and the repository's history shows every earlier version.

## Contact

Questions about privacy are welcome as an issue on the repository: <https://github.com/adamqure/Half-Life/issues>. Issues are public, so please don't include health information in one.
