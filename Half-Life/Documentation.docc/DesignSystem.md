# Design System

The semantic color, type, spacing, and shape tokens every Half-Life screen is built from.

## Overview

The tokens were extracted from the prototype screenshots in `spec/prototype/` and then adjusted to meet constitution Article VI (accessibility). The screenshots were sampled by script: colors are exact sRGB values converted from the captures' Display P3 profile, and sizes are measured from browser captures at about 2x, accurate to about ±2 pt.

### In code

- **Colors** are color sets in `Assets.xcassets/Colors/`, one folder per category. The folders don't provide namespaces, so Xcode generates flat symbols such as `Color.textPrimary`. The accent is the catalog's `AccentColor`, which Xcode generates as `Color.accent` and uses as the app's tint.
- **Spacing, corner radii, sizes, and elevation** are constants in `Half-Life/DesignSystem/`: `Spacing`, `CornerRadius`, `Sizing`, and `Elevation`.
- **Typography** is in code for the styles a screen uses so far, in `DesignSystem/Typography.swift`:
  - `Font.eyebrow` and `Font.titleLarge`.
  - `Typography.metricHeroSize` (80) and `Typography.metricUnitScale` (0.45), for the decay card's figure.
  - The rest are added as screens use them.
- **Metric sizes scale with Dynamic Type** through `@ScaledMetric(relativeTo:)`, in the view that uses them, relative to the text style the Typography table gives. The decay card scales `metricHero` relative to `largeTitle`, and sets its "mg" at `metricUnitScale` of that size.
- `ColorTokenTests` checks every color set's value and every contrast pairing in this article. `LayoutTokenTests` checks the constants, the 4 pt grid, and the minimum hit target. `TypographyTests` checks the type styles in code. `AppearanceTests` checks the light-appearance lock.

### Naming rules

1. **Name a token for its role, never its appearance or location.** Use `textSecondary`, not `warmGrey` or `todayCaptionColor`.
2. **Follow the pattern category, role, then an optional variant or state**, in lower camel case: `surfaceEmphasis`, `actionPrimaryPressed`.
3. **Name content on a colored surface `…On<Surface>`,** as in `textOnEmphasis`.
4. **Express hierarchy with Apple's vocabulary:** primary, secondary, tertiary.
5. **Keep hue names and raw values out of views.** They appear only in the asset catalog and in this article.
6. **Use domain names only for data series** (`dataCaffeine`, `dataSleep`, and so on). In a health app the metric is the role, the same way Apple Health assigns each category a color.

### Decisions

| Decision | Choice | Why |
|----------|--------|-----|
| Typeface | SF Pro (the system font) throughout | The prototype's condensed serif, apparently Instrument Serif, would be a bundled third-party asset. SF Pro is first-party and supports Dynamic Type without extra work. |
| Text hierarchy | Two grey tiers, not three | The prototype's third grey fails WCAG AA. Darkened to 4.5:1, it lands on the same value as the second tier. Size, weight, and case carry the hierarchy instead. |
| Cards | Solid fills | The prototype's cards are translucent, so their color and contrast change down the page. Solid fills make contrast predictable and testable. The page background keeps its gradient. |
| Primary action color | One: `actionPrimary` | The prototype uses #1B1510 in onboarding and #3B2C1E in the app. |
| Data colors | One hue per metric, everywhere | The prototype reuses caffeine brown for heart rate and time-to-fall-asleep, its legend swatch doesn't match its bars, and it tints every toggle slate. |
| Heart rate | Muted rose, `dataHeart` | Heart rate needed its own hue, distinct from caffeine copper and from the rust of `feedbackCaution`. |
| Icons | SF Symbols | They replace the prototype's letter placeholders (S, A, H, …). |
| Dark mode | Deferred to the end of the backlog | Intentional: it matters, but less than the core app. See <doc:DesignSystem#Dark-mode>. |
| Light-appearance lock | `UIUserInterfaceStyle` set to `Light` | **Made by the AI, and the owner disagrees with it.** It keeps system controls from turning dark around color sets that only have light values. It will be reversed when the dark-mode backlog item is built. |

The owner made these decisions on 2026-09-11, with two exceptions. The owner delegated the heart-rate hue to the AI. The light-appearance lock was the AI's decision, not the owner's.

## Color

Contrast figures are WCAG ratios against the darkest surface the token appears on. Text needs 4.5:1, and graphics and large text need 3:1.

### Background and surfaces

| Token | Value | Used for |
|-------|-------|----------|
| `backgroundCanvasTop` | #F8F2E9 | Top of the page gradient |
| `backgroundCanvasBottom` | #E5DBC9 | Bottom of the page gradient |
| `backgroundCanvasGlow` | #FDFBF9 | Radial highlight at the top trailing corner |
| `surfaceCard` | #F9F7F1 | Cards, lists, tiles |
| `surfaceControl` | #FCFBF8 | Chips, text fields, stepper buttons, secondary buttons |
| `surfaceMuted` | #E1DBD3 | Apple Health summary card, note card |
| `surfaceEmphasis` | #3E2C1F | Cutoff card, insight card |
| `surfaceSelected` | #493B2D | Selected option card, selected drink tile |
| `surfaceHighlight` | #FBF9F6 | Selected chart column, active segment |

### Text

| Token | Value | Contrast | Used for |
|-------|-------|---------:|----------|
| `textPrimary` | #2E271F | > 10 | Titles, values, names |
| `textSecondary` | #666058 | 4.5 | Body copy, subtitles, labels, eyebrows, captions, placeholders |
| `textOnEmphasis` | #F6EFE3 | 9.4 | Text on `surfaceEmphasis`, `surfaceSelected`, and `actionPrimary` |
| `textOnEmphasisSecondary` | #BBB0A0 | 5.0 | Secondary text on the same surfaces |
| `textAccent` | #84572B | 4.5 | Links, logged caffeine amounts |

### Accent, actions, and lines

| Token | Value | Contrast | Used for |
|-------|-------|---------:|----------|
| `AccentColor` | #B87333 | 3.3 | The live caffeine figure, decay curve, progress fill, drink rings, and system control tint. Graphics and large text only, on card surfaces only. |
| `accentOnEmphasis` | #E6B173 | 6.1 | Highlights on `surfaceEmphasis` |
| `actionPrimary` | #3B2C1E | — | Primary buttons, the log button |
| `controlSelected` | #3B2C1E | — | Selected chip or segment, active tab, current progress dot |
| `controlBorder` | #827C72 | 3.8 | Outline of an unselected radio or checkbox |
| `controlTrack` | #DAD4CA | — | Progress track, upcoming progress dots |
| `separatorOnCard` | #E8E4DE | — | Row dividers on cards, and the line under the drink composer's one-tap row, on `backgroundCanvasTop` (decorative). Not named `separator`, which would clash with UIKit's `UIColor.separator` and SwiftUI's `.separator` style. |
| `separatorOnEmphasis` | #5A4C3D | — | Dividers on `surfaceEmphasis` |
| `borderOnEmphasis` | #6C5F51 | — | Outline buttons on `surfaceEmphasis` |
| `borderCard` | #FFFFFF at 70% | — | Hairline edge around cards |

`controlSelected` has the same value as `actionPrimary` but is a separate token, so the two can diverge.

### Feedback

| Token | Value | Contrast | Used for |
|-------|-------|---------:|----------|
| `feedbackCaution` | #8C3F1D | 5.6 | Text of a caution message, such as a drink logged after the cutoff |
| `feedbackCautionBackground` | #EEDDD4 | — | Background of a caution message |
| `feedbackPositive` | #4F5E38 | 5.4 | Text of a positive message, such as a drink logged before the cutoff |
| `feedbackPositiveBackground` | #E3E2D7 | — | Background of a positive message |

The message's wording always states its meaning, so color is never the only signal.

### Data series

| Token | Value | Contrast | Used for |
|-------|-------|---------:|----------|
| `dataCaffeine` | #B87333 | 3.3 | Caffeine bars, curve, legend |
| `dataCaffeineSubtle` | #EDDFD1 | — | Drink icon tiles, the top of the curve's area fill |
| `dataSleep` | #6E7795 | 3.9 | Sleep bars, legend |
| `dataSleepText` | #5A6486 | 5.0 | Sleep figures set as text |
| `dataSleepSubtle` | #E2E0E2 | — | Sleep icon tiles |
| `dataActivity` | #63713F | 4.7 | Steps and activity, as both text and graphics |
| `dataActivitySubtle` | #E3E3D8 | — | Activity icon tiles |
| `dataHeart` | #9B4459 | 4.6 | Resting heart rate, as both text and graphics |
| `dataHeartSubtle` | #F1DFE1 | — | Heart rate icon tiles |

Caffeine figures set as text use `textAccent`.

## Typography

Every style uses SF Pro and scales with Dynamic Type. Most sizes the prototype used fall on the iOS text-style defaults, so they use those styles directly. The three large metrics are custom sizes that scale relative to a text style.

| Token | Size and weight | Scales with | Used for |
|-------|-----------------|-------------|----------|
| `metricHero` | 80 light | `largeTitle` | The caffeine-in-your-system figure |
| `metricLarge` | 48 light | `largeTitle` | The drink composer's caffeine figure |
| `metricMedium` | 40 regular | `title` | Cutoff time, sleep window |
| `titleLarge` | 34 bold | `largeTitle` | Screen titles, the Today screen's date |
| `titleMedium` | 28 semibold | `title` | Insight headlines |
| `metric` | 22 regular | `title2` | Stat-tile values |
| `metricSmall` | 20 regular | `title3` | Inline values, stepper counts |
| `labelLarge` | 17 semibold | `headline` | Buttons |
| `bodyLarge` | 17 regular | `body` | Onboarding lead copy |
| `label` | 16 semibold | `callout` | Row and option titles, chips |
| `body` | 15 regular | `subheadline` | Card copy |
| `bodySmall` | 13 regular | `footnote` | Subtitles, metadata, footers |
| `caption` | 12 regular | `caption` | Chart axes, day labels |
| `eyebrow` | 12 semibold, uppercase, no tracking | `caption` | Section labels, the Today screen's greeting |

- Figures that change while on screen, like the live caffeine figure and the chart's scrub label, use monospaced digits so they don't jitter.
- A unit beside a metric ("mg") uses the metric's weight at about 45% of its size, in `textSecondary`.
- The "Half-life" wordmark is a logo asset, not a text style.

## Spacing, shape, and elevation

Values are rounded to a 4 pt grid. Prototype measurements are in parentheses.

| Spacing token | Value | Used for |
|---------------|------:|----------|
| `screenMargin` | 20 (22) | Leading and trailing page inset |
| `cardPadding` | 20 (21) | Inset inside large cards |
| `cardPaddingCompact` | 16 (14) | Inset inside tiles |
| `cardGap` | 16 (15) | Between stacked cards |
| `itemGap` | 12 (9–10) | Between chips, tiles, and options |
| `sectionGap` | 28 (29) | Between sections |
| `sectionHeaderGap` | 12 (12) | Between a section label and its content |

| Shape and size token | Value | Used for |
|----------------------|------:|----------|
| `CornerRadius.large` | 20 (20–22) | Large cards |
| `CornerRadius.medium` | 16 | Buttons, tiles, option cards |
| `CornerRadius.small` | 12 | Chips |
| `CornerRadius.extraSmall` | 8 | Icon tiles |
| `Sizing.buttonHeight` | 52 | Primary and secondary buttons |
| `Sizing.chipHeight` | 44 | Chips |
| `Sizing.fabDiameter` | 64 | The prototype's round log button. No view uses it since the log button moved to the tab bar's bottom accessory (<doc:OneTapLog>). |
| `Sizing.iconTile` | 34 | Icon tiles in settings-style rows |
| `Sizing.iconTileCompact` | 26 | Icon tiles on drink favourites |
| `Sizing.curveHeight` | 160 | The decay curve on the Today screen |
| `Sizing.minimumHitTarget` | 44 | The smallest tappable area, in both directions |

- Corners use the continuous (squircle) style. Toggles, segmented controls, chart bars, and the log button are capsules or circles.
- `Elevation.floating` is for floating controls, such as the prototype's log button and tab bar. No view uses it since those moved to the system tab bar. It's a soft shadow in `textPrimary` at 18% opacity, offset 8 pt, with a SwiftUI shadow radius of 12 (about a 24 pt blur in the prototype's CSS).
- `Elevation.card` is 5% opacity, offset 2 pt, radius 6, together with `borderCard`.
- Both elevation values were estimated by eye from the screenshots.

## Charts

- **Decay curve:** a 2.5 pt `dataCaffeine` stroke. Its area fill fades from `dataCaffeine` at 25% opacity to clear, over a `controlTrack` hairline baseline.
- **Now marker:** a 10 pt `AccentColor` dot with a 2 pt `surfaceCard` ring, on a 1 pt dashed rule.
- **Scrub marker:** a 1 pt solid rule and a `textPrimary` dot, with a `label` callout.
- **Bars:** 14 pt wide with rounded ends. Every bar keeps its full data color. The selected day is marked by a `surfaceHighlight` column and a bold day label, never by color alone. The prototype's faded unselected bars measured 1.5–1.7:1, below the 3:1 that graphics need.

## Accessibility rules

- Text meets 4.5:1 against its surface. Only `metricHero`, `metricLarge`, and `metricMedium` may rely on the 3:1 large-text threshold.
- `AccentColor` and the data colors appear only on card surfaces. They drop below 3:1 on `backgroundCanvasBottom`.
- Every tappable element is at least `minimumHitTarget` in both directions, because the required `performAccessibilityAudit()` UI tests check hit regions. The prototype falls short on the "When" chips (35 pt), the stepper buttons (35 pt), the avatar (40 pt), the 7D/30D segments (about 30 pt), and the delete buttons (about 20 pt).
- SF Symbols in icon tiles are hidden from VoiceOver. The row they sit in carries the label.
- Every text style passes the Dynamic Type check in `performAccessibilityAudit()`. Text set in `caption2` fails it ("Dynamic Type font sizes are partially unsupported"), with or without a weight, tracking, or uppercase, so no style scales with `caption2`. The eyebrow was designed as 11 pt `caption2`, and on 2026-09-11 the owner moved it to 12 pt `caption`. If a smaller size is ever needed, 11 pt semibold scaled along `footnote` with `@ScaledMetric(relativeTo: .footnote)` also passes.
- Text that can wrap has no tracking. The audit's "Text clipped" check flags tracked text once it wraps at large Dynamic Type sizes ("Text of this SwiftUI.AccessibilityNode may be clipped at larger Dynamic Type sizes"). The decay card's "IN YOUR SYSTEM NOW" heading failed it with the eyebrow's +2 pt tracking, and passed without it. Tracking that turns off at accessibility sizes fails the Dynamic Type check instead. On 2026-09-12 the owner removed the eyebrow's tracking everywhere, so every eyebrow matches, and a greeting long enough to wrap can't fail later.
- When the color sets are added, a unit test will assert every text-on-surface pairing in this article against its threshold, so a color change can't silently break contrast.

## Dark mode

Dark mode is deliberately deferred. It's the last item in the roadmap's backlog: important, but less important than the core app.

- The app is locked to the light appearance (`INFOPLIST_KEY_UIUserInterfaceStyle = Light` in the app target's build settings), so system controls never render dark around color sets that only have light values. `AppearanceTests` checks the lock.
- **The lock was the AI's decision, not the owner's, and the owner disagrees with it.** It's reversed as part of the dark-mode backlog item: remove the build setting and replace `AppearanceTests` with contrast tests for the dark values.
- Every color token is semantic, so adding dark mode means adding a dark value to each color set, re-running the contrast tests against the dark surfaces, and removing the lock. No view code changes.
