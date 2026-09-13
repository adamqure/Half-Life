# Half-Life Roadmap

> **Source:** the owner's priority map (`half-life-priority.jsx`), 2026-09-11. **Owner:** Adam Ure.

This is the order in which Half-Life's features are built. Work from the top down and stop whenever time runs out. Wherever you stop, the items above that point deliver the most value available for the effort spent.

## How the order was set

- **Effort** and **value** are relative points on a Fibonacci-style scale.
- Items are ordered by **value ÷ effort (V/E)**, except where a dependency requires an item to come earlier.
- **ID** is the item's number on the priority map. **Rank** is its place in the delivery order.
- **Quadrants** split at effort 6 and value 13:

| Quadrant | Value | Effort | Meaning |
|----------|-------|--------|---------|
| Quick Win | ≥ 13 | ≤ 6 | High value, low effort |
| Big Bet | ≥ 13 | > 6 | High value, high effort |
| Fill-in | < 13 | ≤ 6 | Low value, low effort |
| Time Sink | < 13 | > 6 | Low value, high effort (none on the board) |

- **Totals:** 27 items, 174 effort points, 747 value points.

## Where to stop

| Stop after | Effort spent | Value delivered | What you have |
|------------|-------------:|----------------:|---------------|
| 4 · Today screen | 26 (15%) | 191 (26%) | A working app: the decay model, logging (composer and one-tap favourites), and the Today screen. |
| 9 · Personal half-life estimator | 80 (46%) | 486 (65%) | The thesis: the absorption model, onboarding survey, HealthKit read, demo seed data, and the personal half-life estimator. |
| 13 · Pre-log cutoff warning | 100 (57%) | 604 (81%) | The priority map's default cut line. Adds tests, the Foundation Models layer, insight cards, and the pre-log warning. |
| 15 · Insights tab | 116 (67%) | 672 (90%) | Adds App Intents and the Insights tab. |
| 21 · Settings | 136 (78%) | 717 (96%) | Every item with V/E ≥ 1.5. The six items that remain cost 38 points (22% of effort) for 30 points (4% of value), and none of them returns more than 1 value point per effort point. |
| 27 · Biometric lock | 174 (100%) | 747 (100%) | Everything. |

## Delivery order

| Rank | ID | Feature | Effort | Value | V/E | Quadrant | Cumulative effort | Cumulative value | Why |
|-----:|---:|---------|-------:|------:|----:|----------|------------------:|-----------------:|-----|
| 1 | 1 | Decay + superposition | 13 | 89 | 6.85 | Big Bet | 13 (7%) | 89 (12%) | Every other number in the app is read off this. Nothing ships before it. |
| 2 | 7 | Drink composer | 3 | 8 | 2.67 | Fill-in | 16 (9%) | 97 (13%) | You need a way to create an intake before anything downstream has input. |
| 3 | 6 | One-tap favourites | 2 | 5 | 2.50 | Fill-in | 18 (10%) | 102 (14%) | Named in the brief as a minimum requirement, and nearly free once the composer exists. |
| 4 | 11 | Today screen | 8 | 89 | 11.13 | Big Bet | 26 (15%) | 191 (26%) | Best ratio on the board. The only thing a reviewer opens the app and sees. |
| 5 | 2 | Bateman absorption | 13 | 55 | 4.23 | Big Bet | 39 (22%) | 246 (33%) | Half the write-up. Refines the curve the Today screen already draws. |
| 6 | 5 | Onboarding survey | 5 | 13 | 2.60 | Quick Win | 44 (25%) | 259 (35%) | Produces the informed prior and the cutoff time. Day-one accuracy before any data exists. |
| 7 | 20 | HealthKit read | 13 | 89 | 6.85 | Big Bet | 57 (33%) | 348 (47%) | Biggest dependency in the graph — both estimators and Insights are dead without it. |
| 8 | 24 | Demo seed generator | 2 | 5 | 2.50 | Fill-in | 59 (34%) | 353 (47%) | Needed before the estimator so recovery can be validated against known ground truth. |
| 9 | 3 | Personal half-life estimator | 21 | 133 | 6.33 | Big Bet | 80 (46%) | 486 (65%) | The thesis. The correction to the brief and the reason this isn't a calculator. |
| 10 | 25 | Test suite | 5 | 8 | 1.60 | Fill-in | 85 (49%) | 494 (66%) | How AI-written code gets reviewed at speed. Estimator recovery is the key assertion. |
| 11 | 19 | Foundation Models layer | 5 | 34 | 6.80 | Quick Win | 90 (52%) | 528 (71%) | Three items depend on this. Underpriced by ratio alone — build it early. |
| 12 | 14 | Insight cards | 5 | 55 | 11.00 | Quick Win | 95 (55%) | 583 (78%) | Second-best ratio. Where the honesty posture becomes visible to the user. |
| 13 | 9 | Pre-log cutoff warning | 5 | 21 | 4.20 | Quick Win | 100 (57%) | 604 (81%) | The app intervening before the mistake. Strongest moment in the prototype. |
| 14 | 18 | App Intents | 8 | 34 | 4.25 | Big Bet | 108 (62%) | 638 (85%) | The bonus, on a better substrate. Also lights up Shortcuts and the Action Button. |
| 15 | 13 | Insights tab (formerly Patterns screen) | 8 | 34 | 4.25 | Big Bet | 116 (67%) | 672 (90%) | Satisfies the brief's correlation requirement, reframed as timing comparison. |
| 16 | 12 | Uncertainty rendering | 5 | 8 | 1.60 | Fill-in | 121 (70%) | 680 (91%) | Cross-cutting. Touches curve, hero number, insights, FM copy and settings. |
| 17 | 8 | Retroactive timing | 5 | 13 | 2.60 | Quick Win | 126 (72%) | 693 (93%) | People log after they drink. First capture item that forces recomputation. |
| 18 | 27 | Documentation | 3 | 13 | 4.33 | Quick Win | 129 (74%) | 706 (95%) | Graded directly. Mostly transcription — the reasoning already exists. |
| 19 | 16 | Cutoff notification | 3 | 5 | 1.67 | Fill-in | 132 (76%) | 711 (95%) | Deviates from the brief's exclusion list; defended as the delivery of the thesis. |
| 20 | 10 | Delete + undo | 2 | 3 | 1.50 | Fill-in | 134 (77%) | 714 (96%) | Required by one-tap logging having no confirmation step. |
| 21 | 23 | Settings | 2 | 3 | 1.50 | Fill-in | 136 (78%) | 717 (96%) | HealthKit status, bedtime, and the half-life override. |
| 22 | 4 | Personal sensitivity threshold | 21 | 21 | 1.00 | Big Bet | 157 (90%) | 738 (99%) | Worst ratio in the top band at 1.0. First candidate to cut if time runs short. |
| 23 | 21 | CloudKit backup | 5 | 3 | 0.60 | Fill-in | 162 (93%) | 741 (99%) | Prevents silent data loss on device upgrade without adding accounts or servers. |
| 24 | 26 | Accessibility | 3 | 1 | 0.33 | Fill-in | 165 (95%) | 742 (99%) | Low scored value, but cheap and the right default. Chart needs a text summary. |
| 25 | 17 | Widgets / Action Button | 5 | 2 | 0.40 | Fill-in | 170 (98%) | 744 (100%) | App Intents already covers logging without opening the app. |
| 26 | 15 | "Feel right?" feedback | 2 | 2 | 1.00 | Fill-in | 172 (99%) | 746 (100%) | Captured as a stored flag; feeding it into the fit is a next-week item. |
| 27 | 22 | Biometric lock | 2 | 1 | 0.50 | Fill-in | 174 (100%) | 747 (100%) | Access control on local data. Nice to have, graded by nothing. |

Percentages are rounded to the nearest whole number, so the value column reaches 100% at rank 25 even though three points remain.

## Backlog

These items come after rank 27. They have no effort or value scores, so they're outside the delivery order and its totals.

| Item | Added | Why it's here |
|------|-------|---------------|
| Dark mode | 2026-09-11 | An intentional decision by the owner: important, but not important enough for this build. Until then, the app is locked to the light appearance. The AI made that decision and the owner disagrees with it, so this item also removes the lock. The app's colors are named semantically, so adding dark mode means adding a dark value to each color set, with no view changes. See the DocC catalog's Design System article. |
| Crash report prompt | 2026-09-11 | On the launch after a crash, the app offers to send the crash report. One tap opens the Mail draft from Settings' log export, with the crash report and the current log attached, and the user taps Send. The owner asked for crash reports to be sent automatically on the next launch. Sending with no user action would need a server or a third-party service, which constitution Articles V.1, V.6, and XI.8 rule out, so the owner chose the prompt. It depends on Settings' log export (rank 21), which already attaches unsent crash reports to every send. See the DocC catalog's Logging article. |
| User's name | 2026-09-11 | Personalizes the Today screen's greeting ("Good afternoon, Alex."). The greeting already works without a name, so the owner made this a low-priority item, and the onboarding survey (rank 6) doesn't ask for one. iOS gives an app no way to read the user's name without the user's involvement. The recommended design is a name field with `.textContentType(.givenName)`: AutoFill offers the first name from the user's contact card in one tap, with no permission or entitlement. Sign in with Apple was rejected. It returns the name only on the first authorization, so it needs the same field as a fallback. It also adds an entitlement and an Apple ID credential the app doesn't use, and it resembles the accounts infrastructure the brief rules out. Where the field appears is still open. See the DocC catalog's Today Screen article. |

## Changing the order

Re-score or reorder items only at the owner's request. When the order changes, recompute the V/E, cumulative, and "Where to stop" figures in the same edit.
