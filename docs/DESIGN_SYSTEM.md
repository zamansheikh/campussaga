# VarsityKotha — Design System

Lives in `packages/campus_ui`. Every screen in every app uses it; no screen
writes its own colors, sizes or fonts.

**Personality:** trustworthy, calm, hopeful. A tool that gets things fixed,
not a gossip app. Clear over clever.

---

## 1. Token layers (the key to future-proofing)

```
Primitive tokens      teal600 = #0F766E, space4 = 16 ...    raw values, never used in widgets
        ▼
Semantic tokens       color.primary, color.statusSolved,     meaning, used by components
                      space.screenPadding ...
        ▼
Components            CsButton, CsIssueCard, CsStatusChip    used by screens
        ▼
Screens
```

A rebrand, dark mode or university-specific theme only changes the mapping
from primitive to semantic. Components and screens stay the same.

In Flutter:
- Material 3 `ThemeData` built from our tokens (`ColorScheme`, `TextTheme`).
- Extra tokens that Material has no slot for (status colors, category colors, spacing, radius) live in a `ThemeExtension<CsTokens>`, accessed as `context.cs.statusSolved`, `context.cs.space.md`.

---

## 2. Color

### Brand

| Token | Light | Dark | Use |
|---|---|---|---|
| `primary` | `#0F766E` teal 700 | `#5EEAD4` teal 300 | Main actions, links, active tab |
| `onPrimary` | `#FFFFFF` | `#042F2E` | Text on primary |
| `primaryContainer` | `#CCFBF1` | `#134E4A` | Selected chips, highlights |
| `accent` | `#B45309` amber 700 | `#FBBF24` amber 400 | "Me too" button, trending |
| `background` | `#F8FAFC` | `#0B1220` | Screen background |
| `surface` | `#FFFFFF` | `#111A2B` | Cards, sheets |
| `surfaceVariant` | `#F1F5F9` | `#1E293B` | Inputs, subtle areas |
| `textPrimary` | `#0F172A` | `#F1F5F9` | Body text |
| `textSecondary` | `#475569` | `#94A3B8` | Meta text, captions |
| `border` | `#E2E8F0` | `#273449` | Dividers, card borders |
| `error` | `#DC2626` | `#F87171` | Errors, destructive |

Teal reads as trust and calm, and stays clear of red (alarm) and of Facebook blue.
The palette is chosen for the product's context, **not taken from the logo**:
the name and logo are placeholders and will change (see section 9).

### Issue status (always icon + text + color, never color alone)

| Status | Text color (light) | Icon |
|---|---|---|
| Open | `#1D4ED8` blue | `radio_button_unchecked` |
| Acknowledged | `#6D28D9` violet | `visibility` |
| In progress | `#B45309` amber | `autorenew` |
| Solved | `#15803D` green | `check_circle` |
| Rejected | `#475569` slate | `block` |
| Removed | `#475569` slate | `delete` |

Exact light and dark values live in
`packages/campus_ui/lib/src/tokens/color_tokens.dart`.

Each status has `fg`, `bg` (≈10% tint) and `border` variants for light and
dark mode, so chips are readable in both themes.

### Categories

Academic, Hostel, Transport, Facilities, Safety, Administration, Food,
IT / Wi-Fi, Other. Each has one icon and one muted tint color. **Safety** is
the only category that uses red, and it opens the private reporting flow.

**Contrast rule:** text must reach WCAG AA (4.5:1 normal text, 3:1 large text
and icons). `packages/campus_ui/test/color_contrast_test.dart` checks every
pair in light and dark mode. Add new pairs there; CI fails if one is too low.

---

## 3. Typography

- **Latin:** the platform font (Roboto on Android, SF on iOS). Inter is not bundled, to keep the app small.
- **Bangla:** Noto Sans Bengali (set as `fontFamilyFallback`, so mixed Bangla/English text renders correctly)
- Fonts are **bundled in the app**, not downloaded at runtime, so they work offline and send no requests to Google.
- *Status:* Noto Sans Bengali 400/500/600/700 (hinted, about 585 KB) is bundled in `packages/campus_ui/fonts/NotoSansBengali/` with its OFL license, and set as the fallback in `tokens/typography.dart` and the theme.

| Token | Size / line height | Weight | Use |
|---|---|---|---|
| `displaySm` | 32 / 40 | 700 | Onboarding headlines |
| `headline` | 24 / 32 | 700 | Screen titles |
| `title` | 18 / 26 | 600 | Card titles, issue title |
| `body` | 16 / 24 | 400 | Issue text, comments |
| `bodySm` | 14 / 20 | 400 | Secondary text |
| `label` | 14 / 20 | 600 | Buttons, chips, tabs |
| `caption` | 12 / 16 | 500 | Timestamps, counts |

Bangla glyphs are taller, so line heights are generous (≥1.45). Test every
screen in Bangla. Respect the system text-size setting up to 1.3× without
breaking layouts.

---

## 4. Spacing, radius, elevation, motion

**Spacing (4-point scale)**

| `xxs` | `xs` | `sm` | `md` | `lg` | `xl` | `xxl` |
|---|---|---|---|---|---|---|
| 2 | 4 | 8 | 16 | 24 | 32 | 48 |

Screen side padding = `md` (16). Gap between cards = `sm`–`md`.

**Radius:** `sm` 8 (inputs, chips) · `md` 12 (buttons) · `lg` 16 (cards, sheets) · `full` (avatars, pills)

**Elevation:** cards are flat with a 1px `border`. Shadow only for floating
things (FAB, bottom sheet, dialog). This stays clean on cheap screens.

**Motion:** 150 ms (press, toggle) · 250 ms (page, sheet) · `easeOutCubic`.
Respect the system "reduce motion" setting. Celebrate "Solved" with a small
check animation, the only playful moment.

**Touch targets:** at least 48×48 dp.

---

## 5. Components (`Cs` prefix)

### Built so far (`packages/campus_ui/lib/src/components/`)
- `CsPage` — scrollable page body with screen padding and the 480 px max width
- `CsSection` + `CsRow` — titled group of rows on one card (settings style): icon tile, title, subtitle, value, chevron, destructive variant
- `CsAvatar` — initials on a colour picked from the name
- `CsBadge` — pill label; tones primary, success, neutral, accent
- `CsBrandMark` — placeholder logo tile; the one widget to replace with the final logo
- `CsCodeField` — 6-box one-time code; one hidden field underneath, so paste and code autofill work
- `CsDots` — page indicator
- `CsOptionSheet` — bottom sheet with a single-choice list (theme, language)
- `CsEmptyState` — icon + title + message + action

Buttons, inputs, sheets, dialogs and snackbars are styled in
`cs_theme.dart`, so plain Material widgets already match.

**Screenshot review:** `apps/mobile/tool/screenshots/screens_test.dart`
renders every screen with real fonts in light, dark and Bangla and writes
contact sheets:
`flutter test tool/screenshots/screens_test.dart --dart-define=SHOTS_DIR=/abs/dir`
(run in `apps/mobile`). Look at them before calling a screen done.

### Foundations (planned)
- `CsButton` — variants: primary, secondary, tonal, text, destructive; sizes: md, lg; states: loading, disabled
- `CsIconButton`
- `CsTextField` — label, helper, error, character counter
- `CsChip` — filter and choice
- `CsAvatar` — photo, initials, or **anonymous mask icon**
- `CsBadge` — "Verified student", "Official", counts
- `CsCard`
- `CsBottomSheet`, `CsDialog`, `CsSnackbar`
- `CsSkeleton` — loading placeholders (instead of spinners in lists)
- `CsEmptyState`, `CsErrorState` — illustration + message + action

### My Class (R1)
- `CsNextClassCard` — hero card on Today: course, time, countdown, room, teacher
- `CsClassTile` — one class in a day list; course color stripe; theory/lab tag
- `CsChangeBadge` — Cancelled (strikethrough + red tag), Room changed, Rescheduled, Extra class
- `CsDayStrip` — horizontal Sat–Thu day picker (Bangladesh week starts Saturday; configurable per university)
- `CsWeekGrid` — whole-week routine view
- `CsAnnouncementCard` — CR message, pinned state
- `CsJoinCode` — 6-letter code + QR + share link
- `CsTimePicker` / `CsWeekdayPicker` — fast routine entry for CRs

### Campus Voice (R2)
- `CsIssueCard` — category, title, 2-line preview, status chip, me-too count, comment count, time, anonymity indicator
- `CsStatusChip` — status → icon + label + color
- `CsMeTooButton` — toggle with count and a light haptic on tap
- `CsStatusTimeline` — vertical steps with dates and official notes
- `CsOfficialReply` — highlighted comment from a verified authority
- `CsAnonToggle` — "Post anonymously" with a one-line explanation
- `CsCategoryPicker` — grid of category icons
- `CsImageGrid` — 1–4 images, tap to view
- `CsUniversityHeader` — logo, name, scorecard summary

Each component has:
1. a **Widgetbook** entry with every variant, in light/dark and Bangla/English
2. **golden tests** so a visual change is never an accident
3. a `Semantics` label for screen readers

---

## 6. Patterns

- **Navigation:** bottom bar with 4 tabs: Feed · Search · Notifications · Profile. A floating "Raise issue" button sits on the Feed.
- **Post flow:** 3 steps max: category → title + details + photos → review (anonymous toggle, similar issues) → post.
- **Loading:** skeletons for lists; optimistic updates for votes (update right away, roll back on error).
- **Errors:** human language with a next step ("No internet. Your draft is saved."), never raw error codes.
- **Empty states:** always suggest an action.
- **Confirmations:** only for destructive actions (delete, report). Never for votes.
- **Privacy cues:** the anonymous mask icon appears wherever anonymity applies, so the user always knows how they appear.

---

## 7. Voice and copy

- Short, calm, respectful. Talk to students like a helpful senior.
- Say "issue", not "complaint". Say "me too", not "like".
- Bangla copy is written in Bangla, not machine-translated from English.
- Never blame: "This post was removed because it names a person", not "You broke the rules".

---

## 8. Package structure

```
packages/campus_ui/lib/
  campus_ui.dart              # single export
  src/
    tokens/
      brand.dart              # app name + brand hues (the only brand file)
      color_tokens.dart       # semantic light + dark, status colors
      typography.dart
      dimensions.dart         # spacing, radius, motion, touch size
    theme/
      cs_theme.dart           # builds ThemeData light/dark
      cs_tokens.dart          # ThemeExtension + context.cs
    components/
      button/  card/  chip/  issue_card/  status_chip/  ...
    icons/
      cs_icons.dart           # category + status icon mapping
packages/campus_ui/widgetbook/  # component catalog app
packages/campus_ui/test/goldens/
```

**Rules**
- No `Color(0x...)`, `EdgeInsets.all(13)` or `TextStyle(fontSize: ...)` outside `campus_ui`. Add a lint check in CI.
- New component → design it in Figma, add it to Widgetbook, add a golden test, then use it.
- Figma library mirrors the same token names, so designers and code speak the same language.

---

## 9. Rebranding checklist

The product name and logo are placeholders. Brand values live in a few known
places so a rename takes an hour, not a refactor:

| What | Where |
|---|---|
| Brand colors | `packages/campus_ui/lib/src/tokens/brand.dart` (then run the contrast test) |
| In-app name | `brand.dart` → `CsBrand.appName`, and `appName` in `packages/campus_l10n/lib/src/arb/app_en.arb` + `app_bn.arb` |
| Android app name | `apps/mobile/android/app/src/main/AndroidManifest.xml` → `android:label` |
| iOS app name | `apps/mobile/ios/Runner/Info.plist` → `CFBundleDisplayName` |
| In-app logo | `CsBrandMark` in `packages/campus_ui/lib/src/components/cs_brand_mark.dart` (splash, sign-in, onboarding, profile footer) |
| Launcher icon | replace files in `apps/mobile/assets/launcher/`, run `dart run flutter_launcher_icons` in `apps/mobile` |
| README / docs | `README.md`, `assets/icon/` |
| Website + policy links | `site/` pages (name, contact), and `siteUrl` in `apps/mobile/lib/app/env.dart` once the domain changes |

**Do not change** the app ID `com.silifton.campussaga` after the first store
release: stores treat a new ID as a different app. The package names
(`campus_*`) and the `Cs` component prefix are generic and can stay.
