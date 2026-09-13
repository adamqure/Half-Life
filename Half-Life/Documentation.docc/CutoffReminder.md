# Cutoff Reminder

A local notification at the user's caffeine cutoff: the last moment their usual drink still fits before bedtime.

## Overview

The "Last cup" tile answers *when* while the app is open (<doc:CaffeineCutoff>). The cutoff reminder delivers the same answer when it's needed, with the app closed: "Last cup. A Latte, 2 shots, now still clears by your 10:30 PM bedtime."

It's roadmap rank 19, built early at the owner's request on 2026-09-12. The brief rules out "notifications infrastructure beyond a demo". The roadmap defends this one reminder as the delivery of the thesis, and it's the only notification the app sends. There's no scheduling screen, and no other kind of notification.

The owner set its shape on 2026-09-12:

- **23:01: it fires at the cutoff, and moves when the user drinks.** The time is the "Last cup" tile's cutoff, which counts every drink already logged. It's sized for the user's most-logged drink, or the first starter favourite when nothing has been logged.
- **23:04: it's scheduled for the next seven nights.** iOS delivers only what's already scheduled. A later night's cutoff assumes nothing more is drunk until then, which is the cutoff with no caffeine in the body (CUTOFF-9 in <doc:CaffeineCutoff>). Opening the app, or logging a drink, recalculates all seven. If the user stops opening the app, the reminders stop after a week.
- **23:04: it names the drink and the bedtime, and no caffeine amount.** The notification shows on the lock screen, so it carries no health value (below).
- **23:10: a feature drives it, and a data source schedules it.** A view-less feature under the root observes the upcoming cutoffs, and sends each set to a use case. Only a data source touches `UNUserNotificationCenter` (constitution Article I.14). The alternative, a repository that reschedules itself from the data sources' change signals, was offered and not chosen.

## How it's scheduled

```
CaffeineDecayRepository ── upcomingCutoffs(nights: 7) ──▶ ObserveUpcomingCutoffsUseCase ──▶ CutoffReminderFeature
PermissionsRepository ── permissions() ──▶ ObservePermissionsUseCase ──────────────────────────▶ CutoffReminderFeature
CutoffReminderFeature ── [CutoffReminder] ──▶ ScheduleCutoffRemindersUseCase ──▶ CutoffReminderRepository
CutoffReminderRepository ── replace(with:) ──▶ UserNotificationsReminderDataSource ──▶ UNUserNotificationCenter
```

- **``CutoffReminderFeature``** runs under ``AppFeature``, and ``AppView`` starts it from its own `.task`, so it runs for as long as the app's UI does, on every screen and during onboarding. For each new set of upcoming cutoffs, it writes a reminder for every night that has a cutoff, and schedules them all. A night with no room left, "No more today", gets no reminder.
- **It writes the text.** The drink's name and quantity come from Presentation (`DrinkPresentation`), so the reducer localizes the title and the body. It formats the bedtime in the calendar dependency's time zone and the locale dependency's format. The text is fixed when it's scheduled, so a change of language shows only after the next reschedule.
- **``LiveCutoffReminderRepository``** schedules only when notifications are allowed, and only the reminders its clock says are still to come. When notifications aren't allowed, it removes every reminder instead. It publishes the scheduled reminders, reading them back from the data source the first time.
- **``UserNotificationsReminderDataSource``** replaces every pending cutoff reminder with the new ones. Each reminder is a request with an identifier that starts with `cutoffReminder.`, delivered once at its date with the default sound, so other notifications are left alone. Its trigger is written in a fixed time zone, so it names the same moment wherever the user travels.

### When it reschedules

- **When the upcoming cutoffs change.** The decay repository sends them only when they change: after a drink is logged or deleted, or the bedtime or half-life changes, and at the minute tonight's cutoff passes.
- **When the notification permission changes.** The feature schedules the last cutoffs again, so allowing notifications takes effect at once. The first permission to arrive schedules nothing, because the repository reads the permission itself on every schedule.
- **Only while the app runs.** The reminders already scheduled stay put while the app is closed, which is why seven nights are scheduled. A permission changed in the Settings app is noticed when the permissions next refresh, or at the next reschedule, at the latest when tonight's cutoff passes.

### What iOS shows

iOS doesn't show a notification while its app is in the foreground unless the app asks, and Half-Life doesn't ask: the "Last cup" tile is already on screen.

## The wording

The owner approved this text on 2026-09-12 at 23:04:

| Part | Text |
|------|------|
| Title | "Last cup" |
| Body | "A Latte, 2 shots, now still clears by your 10:30 PM bedtime. After this, caffeine will still be in you when you go to bed." |

The drink's name and quantity are the composer's, and the bedtime is formatted for the locale. The approved preview wrote the drink in lower case ("a latte"). The catalog's names are capitalised, and lower-casing them isn't correct in every language, so the body shows the catalog's name as it is.

### Honesty

The body says "still clears" and "caffeine will still be in you", as approved. Strictly, a cup at the cutoff leaves up to the threshold, 40 mg, at bedtime, and some caffeine is always left after any cup. The Caffeine Cutoff article's "How the app talks about it" avoids overstating what the app knows. This wording is less precise than that guidance, and the AI raised it with the owner for a final decision.

## Privacy

- **No health value on the lock screen.** The notification names the usual drink and the bedtime, never a caffeine amount (constitution Article V).
- **Nothing leaves the device.** Local notifications are scheduled and delivered by iOS on the device.
- **The logs carry no health data.** ``LiveCutoffReminderRepository`` logs each reschedule at `debug` only, because a reschedule follows a logged drink, so its time is health data (Article XI.7). A failure is logged at `error`, with the error's domain and code only.

## Entities

### CutoffReminder

| Property | Type | Meaning |
|----------|------|---------|
| `date` | `Date` | When it's delivered: the cutoff |
| `title` | `String` | Its title, already localized |
| `body` | `String` | Its body, already localized |

## Testable requirements

The cutoffs for several nights are CUTOFF-9 and CUTREPO-5 in <doc:CaffeineCutoff>.

### UserNotificationsReminderDataSource

Tested through stand-ins for the notification center, so no test schedules a real notification.

| ID | Requirement |
|----|-------------|
| REMINDSRC-1 | Each reminder becomes a request, with its own identifier, delivered once at its date with its title, its body, and a sound. |
| REMINDSRC-2 | Replacing removes every pending cutoff reminder, and no other request. |
| REMINDSRC-3 | The scheduled reminders are the pending cutoff reminders, soonest first. |
| REMINDSRC-4 | A request the notification center refuses throws its error. |

### LiveCutoffReminderRepository

Tested against a fake reminder data source, notification permission, and clock.

| ID | Requirement |
|----|-------------|
| REMINDREPO-1 | A new subscriber gets the reminders already scheduled. |
| REMINDREPO-2 | Scheduling replaces every reminder with those after the current time, and publishes them. |
| REMINDREPO-3 | Without notification permission, scheduling removes every reminder. |
| REMINDREPO-4 | A failed replacement throws, and publishes nothing. |
| REMINDREPO-5 | Scheduling the same reminders again publishes nothing. |

### Use cases

| ID | Requirement |
|----|-------------|
| OBSUPCOMING-1 | ``ObserveUpcomingCutoffsUseCase`` streams every set of cutoffs the repository publishes for the nights and the calendar it's given, in order. |
| SCHEDREMIND-1 | ``ScheduleCutoffRemindersUseCase`` hands the reminders to the repository, and throws its error. |

### CutoffReminderFeature

Tested with an exhaustive `TestStore`, with the use cases overridden.

| ID | Requirement |
|----|-------------|
| REMINDER-1 | `task` observes the upcoming cutoffs for seven nights in the calendar dependency, and the permissions, and reduces each into `State`. |
| REMINDER-2 | Each set of upcoming cutoffs schedules a reminder at each night's cutoff, titled "Last cup", with the approved body. |
| REMINDER-3 | A night with no cutoff gets no reminder. |
| REMINDER-4 | When the notification permission changes, the last cutoffs are scheduled again. The first permission, an unchanged one, or a change before any cutoffs have arrived schedules nothing. |
| REMINDER-5 | A failure to schedule is logged, and changes nothing. |
| APP-REMINDER | The reminder's actions reach ``CutoffReminderFeature`` through ``AppFeature``, and its state appears under `AppFeature.State.cutoffReminder`. |

### Registration

| ID | Requirement |
|----|-------------|
| DEP-REMINDER | `\.scheduleCutoffReminders` holds the app-scoped `\.cutoffReminderRepository`, and `\.observeUpcomingCutoffs` the app-scoped `\.caffeineDecayRepository`. In tests, using either repository or use case without overriding it reports an issue. Under UI tests and in previews, the repository schedules through ``SimulatedCutoffReminderDataSource``, which holds the reminders in memory, with the simulated notification permission. |

### Not tested automatically

A UI test can't read the pending notifications, and the reminder has no screen of its own. That a reminder appears on the lock screen at the cutoff is a manual check on a device.

## Still to decide

- **The honesty of the wording** (above).
- **Tapping the notification** opens the app on whatever screen was last showing. Opening the drink composer instead would need a notification delegate, which isn't built.
