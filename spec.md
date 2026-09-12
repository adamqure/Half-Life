# Half-Life Case Study Brief

> **Source:** "femmli Case Study [09.11.26]", received 2026-09-11. The original PDF is committed as `spec/brief.pdf`. Everything above [Prototype screenshots](#prototype-screenshots) is a verbatim transcription of it. Only the formatting was converted to Markdown, and no wording was changed. If the two ever disagree, `spec/brief.pdf` is authoritative.
>
> **Due:** 5pm ET, Friday 2026-09-18.

**Link to artifact:** <https://claude.ai/code/artifact/57285549-6c49-44d8-8567-de3569166d7e>

## The context

Most caffeine apps are calorie-counters wearing a different hat: log a drink, watch a number go up, feel vaguely bad. They answer *how much*.

“Half-life” answers a different question: *when*. **As you are building, assume the following: 200 mg of caffeine has a half-life of roughly 5–6 hours, so a 4pm cold brew still has 80 mg circulating in your bloodstream at 11pm.** The interesting insight isn't your daily total; it's the decay curve and where your bedtime falls on it.

You're building that app. The attached prototype is a working directional reference, not a spec. Treat it as the strongest existing articulation of the idea, and improve on it where you can defend the change.

## Your core task

Ship a working version of the Half-life app.

At **minimum** it must:

1. Log a drink in one tap
2. Pull sleep, steps, etc. from Apple Health.
3. Display the correlations between the two cleanly, and beautifully.
4. Build a profile for a user of their longitudinal caffeine drinking habits and how they might be affecting sleep, heart rate, etc.

Design decisions matter as much as the build. If you cut something from the prototype, say why. If you add something, defend it.

**Bonus: text the app.** Include text-message logging. A user should be able to text a number and have the drink logged on the app, or ask the text message when the optimal time to sleep would be. The user should be able to ask questions about their data and get answers that feel more thoughtful than a correlation coefficient

## Scope and constraints

- **The platform is yours to choose.** Native iOS is the obvious fit given the Health integration and the visual language. React Native, or a web app with a documented Health stand-in, is acceptable if you tell us what you traded away.
- **One user, one device.** No accounts infrastructure, no sync, no social features.
- **Fake data is fine and encouraged.** Seed 2-4 weeks of plausible history so the Patterns surface has something to say. Say clearly what's seeded vs. live.
- **Don't build:** notifications infrastructure beyond a demo, a drink database beyond ~15 common items, settings screens for their own sake, or anything resembling a streak.
- **AI assistance is allowed.** Use whatever tools you'd use on a real job. We care about the result and your reasoning, not your keystrokes.

## What to submit

1. **The working thing**: repo link plus a TestFlight build. Include setup instructions that work on a clean machine.
2. **A short write-up, max 2 pages.** We want:
   - The one or two decisions you're proudest of, and what you rejected to get there
   - What you cut, and why it didn't earn its place
   - How you handled the half-life math and what you'd fix given another week
   - If you attempted the bonus: your parsing strategy and its failure modes
   - If you had more time, how you would have handled data privacy
3. **Anything you made along the way** that shows the thinking; sketches, dead ends, notes. Unpolished is fine.
4. If you used AI, **share the time-stamped scripts of your AI interactions**.

**Send everything to team@femmli.com by 5pm ET on Friday, September 18.** If something's blocking you before then, email us; asking a good question is not a mark against you.

## How we'll evaluate

| | What we're looking for |
|---|---|
| **Judgment** | Did you protect the single question, or did the app sprawl? Are the cuts principled? |
| **Craft** | Does the decay curve feel alive? Do the numbers land with the weight the type gives them? Does one-tap logging actually take one tap? Is the design beautiful? |
| **Honesty** | Does the app overstate what it knows about your sleep? Confidence language matters here more than the correlation itself. |
| **Communication** | Can we understand your reasoning without you in the room? |
| **Bonus** | Attempted thoughtfully (even partially) counts for more than skipped. Attempted badly at the expense of the core does not. |

## A note on effort

One week means one week of *part-time* work. We're assuming 10-15 hours, not 60. If you find yourself grinding, cut the scope and tell us what you cut. Knowing when to stop is part of what we're evaluating.

## Prototype screenshots

> **Added on import. This section is not part of the brief.** These screenshots show the prototype that the brief links to above and calls "a working directional reference, not a spec." The owner captured them on 2026-09-11 between 6:53 and 6:56pm, and they're numbered in capture order. The descriptions below were written on import. Copy in quotes is exactly as it appears on screen. A few shots carry a "User-generated artifact content" badge (03, 04, 05, 12), which is part of the artifact viewer, not the prototype.

| # | Screen | What it shows |
|---|--------|---------------|
| [01](spec/prototype/01.png) | Welcome | A decay-curve logo and the "Half-life" wordmark. "Log your coffee in one tap. We'll borrow your sleep and steps from Apple Health and tell you what your caffeine is actually doing." Buttons: "Continue with Apple" and "Continue with email." Footer: "Your caffeine and health data stays on your device. No account required to look around." |
| [02](spec/prototype/02.png) | Name | "Nice to meet you." A first-name field ("What should we call you?") and Continue. |
| [03](spec/prototype/03.png) | Onboarding: goals | "What are you hoping for?" A multi-select: Sleep better, Fewer jitters, Cut back gradually, Just curious. A daily ceiling stepper defaults to 400 mg ("The usual healthy-adult ceiling. About four espressos or two cold brews."). |
| [04](spec/prototype/04.png) | Onboarding: bedtime | "When do you want to be asleep?" Bedtime chips from 9:30pm to 12:00am. A "Your cutoff" card derives 2:30pm for a 10:30pm bedtime ("A normal cup drunk at 2:30pm is down to about 25 mg by 10:30pm — quiet enough to sleep through. We'll warn you when you log past it."). "Roughly how much a day?" chips: 1–2, 3–4, 5–6, 7+. |
| [05](spec/prototype/05.png) | Onboarding: Apple Health | "Connect Apple Health." "We only read. Nothing is written back, and nothing leaves your phone." Toggles: Sleep (duration, stages, time to fall asleep), Steps & activity (daily step count, active energy), and Resting heart rate ("Optional — sharpens the jitter signal"). Buttons: "Allow access" and "Not now — I'll log manually." |
| [06](spec/prototype/06.png) | Onboarding: summary | "You're set, Test." "Give it about ten days of logging — that's when the sleep pattern gets honest." Summarizes goals, daily ceiling, bedtime, cutoff, and Health types. Buttons: "Log my first cup" and "Take me to Today." |
| [07](spec/prototype/07.png) | Today | A large "In your system now" figure (85 mg) with "Down to about 34 mg by 11pm — half of your last cup is gone by 4:27pm." A decay curve with stepped jumps at each drink and a "now" marker. Tiles show today's total (192 mg, with a bar) and the last cup ("10:45am, before your 2:30pm cutoff"). "One tap" favourites: Double espresso 128 mg, Oat flat white 64 mg, Cold brew 205 mg, plus "All drinks." Tab bar: Today, a central + button, Patterns. |
| [08](spec/prototype/08.png) | Today: scrubbing | The same screen while scrubbing the curve. A second marker reads "36 mg at 10:36pm." |
| [09](spec/prototype/09.png) | Today: scrolled | "Logged today" lists each drink with its time, mg, and a × to delete. A card shows last night's sleep (6h 42m) and steps (8,420) "from Apple Health." |
| [10](spec/prototype/10.png) | Log a drink: warning | "Log a drink. Tap a favourite, or build it below." One-tap favourites across the top. "Build it" offers Espresso, Drip coffee, Latte, Cold brew, Matcha, and Black tea, each with a ring icon. A Latte at 2 shots is 128 mg. "When" chips: Now, 1h ago, 2h ago, 4h ago. With Now selected, a warning reads "This lands after your 2:30pm cutoff — about 51 mg will still be in you at bedtime." Button: "Add 128 mg." |
| [11](spec/prototype/11.png) | Log a drink: backdated | The same drink logged 4h ago: "Good timing — nearly all of this clears before you sleep." Button: "Add 128 mg at 11:24am." |
| [12](spec/prototype/12.png) | Patterns | A 7D / 30D / 90D range picker. A "What we noticed" card: "Caffeine after 2:30pm costs you 41 min of deep sleep. Same total mg, different timing. Your late-cup days (3 of the last 7) end with shorter, lighter sleep." It asks "Feel right?" with Yes and Not really. A "Best time to sleep tonight" card: "2:33am – 4:33am. Caffeine only drops under 55 mg at 2:33am — later than you wanted. Sleep in this window and expect a lighter first cycle." A 6:00pm–5:33am bar marks the best window, above a day-by-day caffeine and sleep bar chart. |
| [13](spec/prototype/13.png) | Patterns: scrolled | The chart with Thursday selected (caffeine 405 mg, slept 5h 54m, last cup 4:40p). "Against your caffeine" lists Deep sleep −41 min ("Strong link"), Time to fall asleep +18 min ("Moderate link"), and Daily steps +1.2k ("Weak link"). |
