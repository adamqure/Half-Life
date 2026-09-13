# Language Model

How Half-Life asks Apple's on-device language model for text, the tools the model can call, and when the features that use it are hidden.

## Overview

The Foundation Models layer (roadmap rank 11) gives other features one way to ask Apple's on-device language model for text. Three roadmap items build on it: insight cards (rank 12), App Intents (rank 14), which carry the brief's "text the app" bonus, and the Insights tab (rank 15). None of them is built yet, so nothing on screen shows the model's text yet.

**The rules calculate, and the model only phrases.** The model never works out a number. Every amount, time, and drink it mentions comes from a tool, and each tool reads it from the same repository the screens read. An answer can't disagree with the Today screen.

### Decisions

The owner settled these on 2026-09-12.

| Decision | Why |
|----------|-----|
| Tools read repositories, never data sources. | Constitution Article V.3.5 lets only repositories reach HealthKit data sources, and Article I.10 has repositories execute the business rules. A tool that read a data source would have to re-run the rules, and could disagree with the screen. |
| Tools only read, except `logDrink`, which logs a drink through ``LogDrinkUseCase``. | Logging goes through the same use case as the composer, one-tap favourites, and App Intents, so it gets the same checks. |
| Only instructions from App Intents get `logDrink`. | The model can log a drink only when the user asked for one, in their own words. Text the app writes, such as a request for an insight, can never log a drink. |
| Each session handles a single instruction. | Half-Life isn't a chatbot. Each instruction gets a new session and new tools, which are discarded with its response. Nothing carries from one instruction to the next, and nothing is persisted. |
| Features that use the model are hidden while it's unavailable. | The app works fully without Apple Intelligence, as it does without Health (Article V.3.3). |
| An insight's facts come with its request, rather than from a repository. The owner decided this on 2026-09-13. | The card's feature already holds the finding, for "Feel right?", so the model can't describe newer data than the card shows, and this layer doesn't reach the Sleep screen's repository. |
| An insight's session has no tools. Its facts are in the prompt, and its answer is capped at 150 tokens. The owner decided this on 2026-09-13, at 15:43, replacing the `compareCaffeineTiming` tool. | A context audit measured a normal insight at 18% of the model's 4,096-token window, so only a loop inside the session could overflow it: the model calling `compareCaffeineTiming` again and again (about 25 calls fill the window), or a sentence that never ends. With no tool, there's nothing to call again, and the cap stops a runaway answer. The facts still come from the request, so the model's words still can't disagree with the card. |
| The data source is `LanguageModelDataSource`, implemented by `FoundationModelLanguageModelDataSource`. | The owner chose the singular, although the framework is `FoundationModels`. The files live in `Data/DataSources/FoundationModels/`, named for the framework. |

## How an instruction runs

```
Feature or App Intent ─▶ RespondToInstructionUseCase ─▶ LanguageModelRepository.respond(to:)
  ─▶ LanguageModelDataSource.respond(to:)
       ─▶ a new LanguageModelSession(tools:instructions:) ─▶ one response, then discarded
               │
               ├─▶ read-only tools ─▶ CaffeineDecayRepository, DrinkLogRepository, CurrentTimeRepository
               └─▶ logDrink (App Intents only) ─▶ LogDrinkUseCase ─▶ DrinkLogRepository
```

- **The response is returned, not published.** The repository doesn't keep it, so it isn't repository-owned data, and returning it isn't an exception to constitution Article I.5's one-way flow. A drink that `logDrink` stores does flow the usual way: the drink log data source signals the change, and the Today screen, the curve, and the favourites follow.
- **The tools are part of the data source, and they read repositories.** A tool conforms to the framework's `Tool` protocol, and only data sources import `FoundationModels` (Article I.14). Tools read the Domain repository protocols, never another data source. This is the only data source that reads repositories.
- **Each instruction builds its own tools**, so the ``LogDrinkUseCase`` that `logDrink` holds lives for a single instruction (Article I.8).

```
Half-Life/Data/DataSources/FoundationModels/
├── LanguageModelDataSource.swift                  The protocol. It doesn't import FoundationModels, so fakes don't need it.
├── FoundationModelLanguageModelDataSource.swift   Availability, the tools for each instruction, and the session
├── LanguageModelInstructions.swift                The session's instructions
├── LanguageModelFormat.swift                      Amounts, times, and days, formatted for the user's locale
├── InsightFacts.swift                             An insight's facts, for its prompt and the number check
├── GeneratedDrinkType.swift                       A @Generable mirror of DrinkType
├── GeneratedInsight.swift                         A @Generable mirror of Insight
└── Tools/                                         One file per tool
```

### Writing an insight

```
Insights card ─▶ WriteInsightUseCase ─▶ LanguageModelRepository.writeInsight(_:)
  ─▶ LanguageModelDataSource.writeInsight(_:)
       ─▶ a new LanguageModelSession(instructions:), with no tools
            ─▶ a prompt with the request's facts
            ─▶ one GeneratedInsight, through guided generation, at most 150 tokens, then discarded
  ─▶ InsightNumberRule: the insight is kept only if every number in it is in the facts
```

- **The facts are in the prompt.** ``InsightRequest`` carries the ``SleepPattern`` the card holds, and `InsightFacts` writes it as a few lines of text, with every number already formatted. The prompt gives the model those lines, so its words can't disagree with the card. The session has no tools, so the model has nothing to call again and again.
- **Guided generation.** The model answers into `GeneratedInsight`, a `@Generable` mirror of ``Insight``, whose guides ask for the facts' headline, in the user's language, and one sentence of at most 25 words that says how the nights support it. The guides are only descriptions, so the answer is also capped at **150 tokens**, twice the longest valid answer measured (74 tokens, in French). A runaway answer fails at the cap instead of filling the context window, and the card stays hidden.
- **Refusals.** The model can refuse to write an insight. Its log line then names `refusal`, and the card stays hidden. On 2026-09-13 it refused twice while it was asked to say what the finding meant for the user's sleep, so the rules write the headline, and the model writes only the sentence on how the nights support it (<doc:Insights>). The refusal's explanation can quote the prompt, so it's never logged.
- **The number check.** The data source returns the insight with the facts it gave the model, and the repository executes ``InsightNumberRule``. An insight with any other number throws ``LanguageModelError/ungrounded``, and the card stays hidden. Numbers written as words aren't caught.

## Availability

``LanguageModelAvailability`` has two cases. It's `available` only when `SystemLanguageModel.default` reports `.available` and supports the user's current locale. Every other state is `unavailable`: the device isn't eligible, Apple Intelligence is off, the model is still downloading, or the model doesn't support the user's language. Features don't need the reason, because they hide either way.

The framework doesn't announce changes: `SystemLanguageModel` isn't `Observable`. So the repository re-reads the availability at each whole minute from the clock data source, and sends a subscriber a new value only when it changes. When the model finishes downloading, or the user turns Apple Intelligence on, features appear within a minute.

A feature that uses the model observes the availability through ``ObserveLanguageModelAvailabilityUseCase``, and hides itself while it's `unavailable`. ``LanguageModelRepository/respond(to:)`` checks it too, and throws ``LanguageModelError/unavailable`` without reaching the model.

## Instructions

A ``LanguageModelInstruction`` is a prompt and where it came from:

- **`appIntent`:** the words the user sent through an App Intent, such as a text to the app. Only these get `logDrink`.
- **`app`:** text the app writes, such as a request for the Insights tab's analysis.

Every session starts with the same instructions, the model's standing rules:

- Get every number, time, and drink from a tool. Never calculate, estimate, or invent one.
- Repeat amounts and times exactly as the tools give them.
- Say plainly when a tool reports that something isn't available.
- Don't diagnose, and don't give medical advice.
- Be brief.
- Answer in the user's language, named from the current locale.

An `appIntent` session adds one more rule: log a drink only when the user says they drank it.

An insight's session, for the Insights tab's first card, has no tools, so its standing rules take every number from the facts in the prompt instead: "Get every number from the facts", "Repeat amounts and days exactly as the facts give them", and "If the facts say something isn't available, say so plainly". The other standing rules are the same. Then it adds the insight rules the owner approved on 2026-09-13 (<doc:Insights>). Its prompt asks for today's finding: the facts' headline, and a sentence that says how the data supports it. Then it gives the facts. After a "Not really", it adds the headline and sentence the user disagreed with, and asks for a different approach from them.

## Tools

| Tool | Arguments | Reads | Reports |
|------|-----------|-------|---------|
| `getCaffeineStatus` | None | ``CaffeineDecayRepository/status(in:)`` | The caffeine in the body now, the level at the next bedtime and when that is, and when the last drink is half gone |
| `getCaffeineCutoff` | None | ``CaffeineDecayRepository/cutoff(in:)`` | The usual drink, and the latest time to have it and still be at or under the sleep threshold at bedtime, or that there's no more today. It also gives the bedtime and the threshold. |
| `getCaffeineLevelAt` | An hour and a minute | ``CaffeineDecayRepository/curve()`` | The level the next time the clock shows that time, if that's within the 12 hours the curve covers ahead of now |
| `getDrinksOnDay` | Days ago, 0–90 | ``CurrentTimeRepository/now()``, ``DrinkLogRepository/day(containing:in:)`` | Each drink's time, name, quantity, and caffeine, marked when it's demo data, and the day's total |
| `logDrink`, for App Intents only | A drink, a quantity of 1–10, and minutes ago, 0–720 | ``LogDrinkUseCase`` | What was logged, or why it wasn't |

An insight's session gets no tools. Its prompt gives the facts instead: the period, the nights over and under the threshold and their total, whether time asleep was shorter, longer, or about the same on the nights over it, the confidence words, and the nights not counted. Never an average or an amount of sleep.

- **Short text, not samples.** Each tool returns a few lines of text. Amounts are whole milligrams. Times and days are formatted for the user's locale and time zone (Article VII.3). The model copies them, so it never formats or rounds a number itself.
- **Missing data is said, not thrown.** When a repository publishes nothing, the tool says the figure isn't available, so the model can say so too.
- **Demo drinks are marked.** The brief asks the app to say clearly what's seeded, so `getDrinksOnDay` marks every drink the demo history added.
- **`logDrink`'s drink** is a `GeneratedDrinkType`, a `@Generable` mirror of ``DrinkType``, because Domain can't import `FoundationModels`. Its ranges guide the model toward plausible values. The composer has no maximum quantity, so 10 servings and 12 hours are the tool's own limits. ``DrinkLogRule`` still checks every drink. A ``DrinkLogRule/Violation`` goes back to the model as the reason the drink wasn't logged, so it can tell the user. Any other error fails the instruction.
- **The context window is small.** `SystemLanguageModel.contextSize` is 4,096 tokens, for everything in the session: instructions, tool definitions, the prompt, tool calls and their output, and the answer. Measure new tools with `tokenCount(for:)` as they're added. It runs in the simulator without Apple Intelligence. An audit on 2026-09-13 measured, with the framework's own formatting:

  | Session | Tokens | Of 4,096 |
  |---------|--------|----------|
  | An insight, with a disagreement and its answer, with the headline the rules write (665 before the refinement, and 773 with the wording the model refused) | 703 | 17% |
  | A question, before any tool call. The five tools' definitions are 697 of it, and `logDrink`'s alone 251. | 931 | 22% |
  | A question that reads 7 days, at 12 drinks a day | 3,331 | 81% |
  | A question that reads 30 days, at 4 drinks a day | 5,273 | 128% |

  A question's tool calls and the question's length aren't limited yet, so a question about a long stretch of days can overflow the window. The audit's other proposals, a call budget, a cap on `getDrinksOnDay`'s lines, and a limit on the question's length, are still to decide.

### Tools still to come

| Tool | Waits for |
|------|-----------|
| `simulateDrink`: the level at bedtime if the user has a given drink at a given time | A "what if" query on ``CaffeineDecayRepository``. The pre-log cutoff warning (rank 13) needs the same query. |
| `getCaffeineLevelAt` more than 12 hours ahead | The same query |
| `getBestSleepTime` | Tonight's sleep window on ``CaffeineDecayRepository``, from the Insights design |
| `getHealthDay` and `getSleepTrend` | The Health data repository, from the Apple Health card design |
| `getDrinkingHabits` | A rule for longitudinal habits |
| `getHalfLifeEstimate` | The half-life estimate repository (<doc:HalfLifeEstimator>) |

## Privacy and logging

- **On device.** The Foundation Models framework runs the model on the device, and makes no network request, so constitution Article V.1 still holds.
- **Nothing is stored.** The instruction, its session, its tool calls, and its response live in memory for that one instruction.
- **Nothing the model reads or writes is logged.** Prompts, responses, tool arguments, and tool output all carry health data (Article XI.6), so they're never logged, at any level. The data source logs a failed response or insight at `error`, with the kind of error, its domain, and its code, all `.public`. The kind is the case of the framework's `GenerationError`, such as `exceededContextWindowSize` or `guardrailViolation`, or `toolCallError` when a tool threw, or `other`. The error's description, and the context the framework attaches to it, aren't logged, because they can hold the prompt. The repository logs an instruction it refuses because the model is unavailable at `notice`, without its text, and an insight it discards for its numbers the same way.
- **Only a finding from Health data reaches the model.** An insight's facts give it counts of nights, a direction, and a confidence, derived from sleep, and never an amount of sleep. They stay on the device, with the model.

## Localization

The instructions and the tools' descriptions and output are prompt text for the model, not text the user sees, so they're written in code in English, not in the String Catalog (Article VII.1). The model's answer is what the user sees. The instructions ask for the user's language, availability requires the model to support the current locale, and the tools format their amounts and times for that locale.

## Entities

- ``LanguageModelAvailability``: whether features that use the model can show.
- ``LanguageModelInstruction``: a prompt, and whether it came from an App Intent or from the app.
- ``LanguageModelError``: why an instruction couldn't be answered: `unavailable`, or `ungrounded` when an insight held a number its tools didn't give.
- ``InsightRequest``: the Insights tab's finding to put into words, and the one the user last disagreed with.
- ``Insight``: the finding in the model's words, a headline and a sentence.

## Testable requirements

### FoundationModelLanguageModelDataSource

Tested with the system model's availability replaced, so no test needs Apple Intelligence.

| ID | Requirement |
|----|-------------|
| LMSRC-1 | The availability is `available` only when the system model is available and supports the current locale. Each reason the system model gives for being unavailable, and an unsupported locale, give `unavailable`. |
| LMSRC-2 | An `appIntent` instruction gets every read-only tool and `logDrink`. An `app` instruction gets only the read-only tools. |
| LMSRC-3 | The instructions name the user's language. Only an `appIntent` instruction's instructions mention logging a drink. |
| LMSRC-4 | An insight's instructions are the standing rules, taking every number from the facts instead of a tool, then the insight rules the owner approved, in order. They never mention a tool. |
| LMSRC-5 | An insight's prompt asks for today's finding, the facts' headline and a sentence that says how the data supports it, and gives the facts. After a "Not really", it adds the headline and sentence the user disagreed with, and asks for a different approach from them. |
| LMSRC-6 | An insight's session has no tools and the insight's instructions, its facts are the request's finding, and `GeneratedInsight` mirrors ``Insight``. |
| LMSRC-7 | An insight's answer is capped at 150 tokens. |
| LMSRC-8 | A failure is logged with its kind: the `GenerationError` case's name, `toolCallError` for a tool's error, or `other`. |
| LMSRC-9 | `GeneratedInsight`'s guides ask for the facts' headline, in the user's language, and a sentence that says how the nights in the facts support it, with the confidence words. |

Responding, and writing an insight, with the real model aren't unit-tested. Its output isn't deterministic, and it needs Apple Intelligence on the machine that runs the tests. The code that responds is kept to building the session and asking it once.

### Tools

Tested by calling each tool directly, against fake repositories, in New York's time zone and the `en_US` locale.

| ID | Requirement |
|----|-------------|
| LMTOOL-1 | `getCaffeineStatus` reports the level now, the level at bedtime with the bedtime's time, and when the last drink is half gone, from the first status the repository publishes for the data source's calendar. It leaves out the parts the status doesn't have. |
| LMTOOL-2 | `getCaffeineCutoff` reports the usual drink, the latest time to have it, the bedtime, and the threshold, from the first cutoff the repository publishes. With no latest time, it reports that there's no more today. |
| LMTOOL-3 | `getCaffeineLevelAt` reports the level from the curve's sample for the next minute the clock shows the given hour and minute. When that minute is past the curve's last sample, it reports that the curve doesn't reach it. |
| LMTOOL-4 | `getDrinksOnDay` reports the day, each drink logged on the day that many days before today, with its time, name, quantity, and caffeine, marked when it's demo data, and the day's total. With no drinks, it reports that none were logged. |
| LMTOOL-5 | `logDrink` logs the drink through ``LogDrinkUseCase`` with its quantity, consumed the given number of minutes ago, and reports the drink, its caffeine, and the time it was consumed. |
| LMTOOL-6 | When ``DrinkLogRule`` refuses the drink, `logDrink` reports that it wasn't logged, and why. Any other error is thrown. |
| LMTOOL-7 | When a repository publishes nothing, the tool reports that the figure isn't available, instead of throwing. |
| LMTOOL-8 | Amounts are whole milligrams, and times and days are formatted in the data source's calendar, with its locale and time zone. |
| LMTOOL-9 | `GeneratedDrinkType` has one case for each ``DrinkType``, and each maps to its drink. |

LMTOOL-10 and LMTOOL-11 belonged to `compareCaffeineTiming`, which was removed on 2026-09-13. They're now LMFACT-1 and LMFACT-2.

### Insight facts

Tested by reading `InsightFacts` directly, in New York's time zone and the `en_US` locale.

| ID | Requirement |
|----|-------------|
| LMFACT-1 | The facts give the finding's period, its nights over and under the threshold, their total, the direction of time asleep only, a headline that says it in plain words, its confidence words, and the nights not counted, with every number formatted. |
| LMFACT-2 | Each direction and confidence has its own words, including the headline, and a count of one is singular. With every night counted, that line is left out. |

### LanguageModelRepository

Tested against a fake data source and a fake clock.

| ID | Requirement |
|----|-------------|
| LMREPO-1 | A new subscriber immediately receives the current availability. |
| LMREPO-2 | At each minute the clock streams, the repository re-reads the availability, and a subscriber receives it only if it changed. |
| LMREPO-3 | While the model is available, `respond(to:)` passes the instruction to the data source, and returns its response. |
| LMREPO-4 | While the model is unavailable, `respond(to:)` throws ``LanguageModelError/unavailable`` and never reaches the data source. |
| LMREPO-5 | An error from the data source is thrown on to the caller. |
| LMREPO-6 | While the model is available, `writeInsight(_:)` passes the request to the data source, and returns its insight when every number in it is in the facts. |
| LMREPO-7 | An insight with a number the facts don't hold, in its headline or its sentence, throws ``LanguageModelError/ungrounded``. |
| LMREPO-8 | While the model is unavailable, `writeInsight(_:)` throws ``LanguageModelError/unavailable`` and never reaches the data source. |
| LMREPO-9 | An error from the data source's `writeInsight(_:)` is thrown on to the caller. |

### Use cases

| ID | Requirement |
|----|-------------|
| OBSLM-1 | ``ObserveLanguageModelAvailabilityUseCase`` streams every availability the repository publishes, in order. |
| RESPOND-1 | ``RespondToInstructionUseCase`` returns the repository's response to the instruction, and throws the repository's error. |
| WRITE-1 | ``WriteInsightUseCase`` returns the repository's insight for the request, and throws the repository's error. |

### Registration

| ID | Requirement |
|----|-------------|
| DEP-LM | `\.observeLanguageModelAvailability`, `\.respondToInstruction`, and `\.writeInsight` hold the app-scoped `\.languageModelRepository`. Its data source's tools read the app-scoped caffeine decay, drink log, and current time repositories. The preview repositories open an in-memory store, so this test runs inside the serialized `SwiftDataStoreTests`. In tests, using the repository or any of its use cases without overriding it reports an issue. |

### UI tests

Whether the simulator's model is available depends on the Mac that runs it, so under a UI test the language model is ``SimulatedLanguageModelDataSource``, as the owner decided on 2026-09-13. It's unavailable, so features that use the model are hidden, unless the test launches with `LaunchEnvironmentKey.languageModel` set to `simulatedLanguageModel`. Then it's available, answers every instruction with one fixed sentence, and writes an insight from the facts an insight's prompt gives, so the insight passes the number check. Its words stand in for the model's, and like the model's, they aren't in the String Catalog.

| ID | Requirement |
|----|-------------|
| LAUNCH-LM | The language model key asks for the simulated model, and any other value is ignored. Without it, there's none. |
| SIMLM-1 | ``SimulatedLanguageModelDataSource`` is available only when the UI test asked for it. |
| SIMLM-2 | It writes an insight from the facts an insight's prompt gives, with a number in it, which passes the number check. |
| SIMLM-3 | It answers every instruction. |
| DEP-LM-UI | Under a UI test, the language model repository is over the simulated model, which is unavailable unless the launch asked for it. |

## Still to decide

- **Each consumer's prompt.** The Insights tab's first card has its approved prompt (<doc:Insights>). App Intents pass the user's own words.
- **The context budget.** How many tools fit in one session, measured as tools are added, and how a question's tool calls and length are limited (see "Tools").
