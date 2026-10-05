# Bookly Design System

Social reading app. Friends read together in private circles, track progress, write chapter notes, talk to Gemini about the book.

Voice of the brand: considered literary imprint, modern premium app. Restraint over decoration. Paper, ink, one deep red.

Files in this package:

| File | Purpose |
|---|---|
| `DESIGN.md` | This document. Source of truth for rules. |
| `tokens.css` | CSS custom properties. Light, dark (system), dark (toggle). |
| `tokens.json` | Same tokens, W3C DTCG format. Feed to Style Dictionary, Figma Tokens, Flutter generator. |
| `flutter/` | Drop-in Dart design system, assets, launcher icon config. |
| `logos/` | Master logos: PNG (4096 / 8192 px) and SVG. |

If this doc and tokens disagree, tokens win. Fix doc.

---

## 1. Principles

1. **Paper first.** Warm neutrals, never pure white or pure black as page ground.
2. **One accent.** Oxblood carries brand and primary action. Everything else is ink and paper.
3. **Quiet UI, loud content.** Book covers, notes, friends' words are the color. Chrome stays muted.
4. **Both modes are first-class.** Dark is a designed theme, not an inversion.
5. **Type does the work.** Raleway weight and size build hierarchy. Few borders, few shadows.
6. **Shared by default, private by design.** Circle context always visible. Nothing leaks outside circle; UI never implies public.

---

## 2. Logo

### Mark

Two overlapping circles = private reading circle. Overlap lens = shared page. Spine line inside lens = open book.

Construction on 120 × 120 grid:

| Part | Spec |
|---|---|
| Circle A | center (46, 60), r 34, stroke 3, no fill |
| Circle B | center (74, 60), r 34, stroke 3, no fill |
| Lens | intersection of A and B, filled accent |
| Spine | vertical line x 60, y 38 to 82, stroke 2, color = page ground |

### Wordmark

"Bookly", Raleway 700, letter-spacing −0.02em, sentence case. Lockup: mark left, wordmark right, gap = 0.18 × mark width, wordmark cap-height centered on mark midline.

> Earlier concept board set the wordmark in Fraunces. Superseded. Raleway only.

### Colorways

| Context | Rings + wordmark | Lens | Spine |
|---|---|---|---|
| Light ground | `ink #1B1714` | `oxblood #7A1F2B` | `paper #F4EEE3` |
| Dark ground | `paper #F4EEE3` | `#C0525E` | `ink #1B1714` |
| App icon tile | `paper` | `paper` | `oxblood` on tile `#7A1F2B` |
| One-color | any single ink, lens filled, spine knocked out | | |

Dark lens `#C0525E` is graphic-only (3:1+). Never use it for text. Text accent in dark = `--text-link`.

### Clear space and size

- Clear space on all sides = lens width (⅓ of mark width).
- Full mark with spine: minimum 32 px.
- Under 32 px: drop the spine. Stroke scales to a ~1.6 px hairline: units = max(3, 192 / size) on the 120-unit grid (12 at 16 px, 8 at 24 px, 4.8 at 40 px). Flutter `BooklyMark` does this automatically.
- App icon tile radius 22.5%.
- Lockup minimum width 96 px. Below that, mark only.

### Never

- Recolor lens outside accent or paper.
- Add gradients, shadows, glow, or outlines.
- Rotate, skew, or separate the circles.
- Put lockup on busy photo without a scrim.
- Fill both circles.

---

## 3. Color

Semantic tokens only in product code. Never raw hex in components.

### 3.1 Brand

| Token | Hex |
|---|---|
| `brand.ink` | `#1B1714` |
| `brand.paper` | `#F4EEE3` |
| `brand.oxblood` | `#7A1F2B` |

### 3.2 Surfaces and text

| Token | Light | Dark | Use |
|---|---|---|---|
| `bg` | `#F4EEE3` | `#14110F` | Page ground |
| `surface` | `#FBF8F2` | `#1B1714` | Cards, sheets, nav |
| `surface-raised` | `#FFFFFF` | `#241F1B` | Popovers, menus, modals, inputs |
| `surface-sunken` | `#EBE3D5` | `#0F0D0B` | Wells, code, progress tracks |
| `text` | `#1B1714` | `#F4EEE3` | Body, headings |
| `text-secondary` | `#5C534A` | `#BDB2A3` | Supporting copy |
| `text-tertiary` | `#6B6258` | `#968B7D` | Captions, meta. Still AA. |
| `text-disabled` | `#A89D8D` | `#5E564C` | Disabled only. Exempt from contrast. |
| `text-on-accent` | `#FBF8F2` | `#F4EEE3` | Text on accent fill |
| `text-link` | `#7A1F2B` | `#DE7B85` | Links, text-style actions |
| `border` | `#D9CFBD` | `#2E2823` | Dividers, card edges |
| `border-strong` | `#B9AD98` | `#4A4239` | Input edges, emphasis |
| `focus-ring` | `#7A1F2B` | `#DE7B85` | Keyboard focus |
| `scrim` | ink @ 48% | black @ 64% | Behind modals |

### 3.3 Accent

| Token | Light | Dark | Use |
|---|---|---|---|
| `accent` | `#7A1F2B` | `#B8434F` | Primary button fill, active tab, progress fill |
| `accent-hover` | `#651823` | `#C5525E` | Hover |
| `accent-pressed` | `#52121C` | `#A63844` | Pressed |
| `accent-subtle` | `#EFDCD9` | `#3A1A1E` | Selected row, badge bg |
| `accent-subtle-text` | `#5A1520` | `#F0B4BA` | Text on accent-subtle |

Dark accent is lighter and slightly desaturated so red does not vibrate on near-black. Fill and text-link are different tokens on purpose in dark: fill `#B8434F` carries paper text at ~4.8:1; red as text needs the lighter `#DE7B85`.

### 3.4 Semantic

| Role | Light fg | Light bg | Dark fg | Dark bg |
|---|---|---|---|---|
| Success | `#2F6B4F` | `#DCEBE2` | `#6FBF98` | `#17291F` |
| Warning | `#8A5A00` | `#F3E5C6` | `#E0B04A` | `#2C2410` |
| Danger | `#C42B1C` | `#F6D9D4` | `#F0786C` | `#321815` |
| Info | `#2C5A7A` | `#D9E6EE` | `#7FB3D6` | `#132230` |

Danger is a brighter, orange-leaning red than oxblood on purpose. Destructive actions must never read as brand. Always pair color with icon or label.

### 3.5 Gemini (AI)

| Token | Light | Dark |
|---|---|---|
| `ai-surface` | `#EBE7F0` | `#221D2B` |
| `ai-border` | `#CFC7DA` | `#3A3149` |
| `ai-text` | `#3B2F4F` | `#D8CDEA` |

Muted violet, only for Gemini replies. Signals "not a friend" at a glance. Do not use elsewhere.

### 3.6 Circle members

Six identity colors. Assign per member inside a circle in join order. Used for avatar ring, progress marker, note tag, chapter-note edge.

| Token | Name | Light | Dark |
|---|---|---|---|
| `member-1` | Ochre | `#B4741C` | `#E0A04A` |
| `member-2` | Teal | `#1F7A74` | `#55C4BB` |
| `member-3` | Plum | `#7A3F7E` | `#C58AC9` |
| `member-4` | Moss | `#5B7A2A` | `#9CC25A` |
| `member-5` | Slate blue | `#3F5F9A` | `#8AA8E6` |
| `member-6` | Terracotta | `#B4533A` | `#E68A72` |

Rules: member color is never the only identifier. Always initials or avatar alongside. Circles larger than 6 wrap and add a 2px dashed ring to distinguish.

### 3.7 Contrast

Targets: body text 4.5:1, large text (≥24 px or ≥19 px bold) 3:1, UI boundaries and icons 3:1. Pairs above were chosen to meet these; confirm in your tooling (Stark, axe, Figma plugin) before shipping a new pairing.

---

## 4. Typography

Single family: **Raleway** (Google Fonts). Variable, weights 100–900. Load 400, 500, 600, 700, 800 and italic 500.

```
https://fonts.googleapis.com/css2?family=Raleway:ital,wght@0,400;0,500;0,600;0,700;0,800;1,500&display=swap
```

### 4.1 Raleway rules that bite

1. **Old-style figures by default.** Numbers dip below baseline. Bad for page counts, percentages, times. Always set `font-feature-settings: "lnum"`. For anything aligned in columns or counting up (page numbers, progress %), add `"tnum"`.
2. **Light feel at 400.** Raleway looks thin vs other sans. Use **500 for UI and short text**. Use 400 only for long reading blocks at ≥16 px.
3. **Wide letterforms.** Tighten display sizes (−0.02em). Never track out lowercase body.
4. **Overline caps** need generous tracking (+0.14em) at 600.
5. **Hierarchy through weight jumps** of 200+ (500 vs 700), not 100.

### 4.2 Scale

| Style | Size / line | Weight | Tracking | Use |
|---|---|---|---|---|
| Display | 56 / 60 | 700 | −0.02em | Marketing hero, empty-state heroes |
| H1 | 40 / 48 | 700 | −0.01em | Screen title (web) |
| H2 | 32 / 38 | 700 | −0.01em | Section |
| H3 | 24 / 29 | 600 | −0.01em | Card title, sheet title |
| H4 | 20 / 26 | 600 | 0 | Subsection, list header |
| Body L | 18 / 29 | 500 | 0 | Reading mode, chapter notes |
| Body | 16 / 26 | 500 | 0 | Default UI text |
| Body S | 14 / 20 | 500 | 0 | Secondary text, list meta |
| Caption | 12 / 17 | 500 | +0.01em | Timestamps, helper text |
| Overline | 12 / 16 | 600 | +0.14em, UPPERCASE | Section labels, circle names |
| Button | 15 / 20 | 600 | 0 | Buttons, tabs |

Mobile: Display 40, H1 32, H2 28, H3 22. Others unchanged. Minimum text size anywhere: 12.

### 4.3 Reading and notes

Chapter notes and Gemini answers are long-form. Use Body L, Raleway 400–500, line-height 1.7, max line length 62 characters (`container-reading` 640 px). Italic 500 for quoted book passages, with a 2px `border-strong` bar on the leading edge.

### 4.4 Do / don't

- Do sentence case everywhere. Titles of books keep their own case.
- Do truncate book titles at 2 lines, authors at 1.
- Don't use 300 or lighter in product UI.
- Don't underline except links in running text.
- Don't mix a second typeface. Mono only for code or IDs.

---

## 5. Spacing and layout

4 pt base. Scale: 0, 4, 8, 12, 16, 20, 24, 32, 40, 48, 64, 80, 96 (`space-0` … `space-24`).

| Context | Value |
|---|---|
| Screen horizontal padding, mobile | 20 |
| Screen horizontal padding, ≥768 | 32 |
| Card padding | 16 (compact) / 20 (default) / 24 (feature) |
| Stack gap, related items | 8 |
| Stack gap, groups | 24 |
| Section gap | 48 |
| Tap target minimum | 44 × 44 |

Breakpoints: sm 640, md 768, lg 1024, xl 1280. Containers: reading 640, app 1152.

Grid: 4 columns mobile (16 gutter), 8 columns md (24), 12 columns lg+ (24).

---

## 6. Shape, border, elevation

| Token | Value | Use |
|---|---|---|
| `radius-xs` | 4 | Tags, tiny chips |
| `radius-sm` | 8 | Inputs, buttons (compact) |
| `radius-md` | 12 | Buttons, cards (default) |
| `radius-lg` | 16 | Large cards, covers |
| `radius-xl` | 24 | Bottom sheets (top corners), modals |
| `radius-full` | pill | Avatars, chips, progress |
| Book cover | 4 left / 8 right | Spine-side tight, page-edge soft |

Border: 1 px `border` for structure. 2 px for focus and selection.

### Elevation

| Level | Use | Light | Dark |
|---|---|---|---|
| 0 | Flat content | none | none |
| 1 | Cards | soft 1 px shadow | 1 px border ring |
| 2 | Menus, popovers, sticky bars | 4 / 12 shadow | ring + shadow, surface-raised |
| 3 | Modals, sheets | 12 / 32 shadow | ring + heavier shadow |

**Dark mode depth comes from lighter surface plus border.** Shadows on near-black are invisible, so each step up the stack uses the next lighter surface token (`bg` → `surface` → `surface-raised`).

---

## 7. Motion

| Token | Value | Use |
|---|---|---|
| `dur-fast` | 120 ms | Hover, press, toggles |
| `dur-base` | 200 ms | Fades, chip select, tab change |
| `dur-slow` | 320 ms | Sheets, page transitions |
| `ease-standard` | cubic-bezier(0.2, 0, 0, 1) | Default |
| `ease-enter` | cubic-bezier(0, 0, 0, 1) | Elements arriving |
| `ease-exit` | cubic-bezier(0.3, 0, 1, 1) | Elements leaving |

Signature motion: when a friend's progress updates, their avatar ring animates around the book cover over `dur-slow`. Page-turn style transitions: forbidden; too skeuomorphic for this brand.

Reduced motion: all durations → 0, replace slides with fades under 100 ms.

---

## 8. Iconography

- 24 px grid, 1.75 px stroke, round caps and joins, no fills except active states.
- Active tab icons may fill with `accent`.
- Corner radius on icon geometry 2 px.
- Source: Lucide or Phosphor (regular). Pick one, never mix.
- Icon-only buttons need an accessible label.
- Core set: book, bookmark, circle (people), note, chat/Gemini, progress, bell, search, plus, share-in-circle, more.

---

## 9. Components

State rules for every interactive component: default, hover (web), pressed, focus-visible, disabled, loading. Focus = 2 px `focus-ring`, 2 px offset. Disabled = `text-disabled` on `surface-sunken`, no shadow.

### Button

| Variant | Fill | Text | Border |
|---|---|---|---|
| Primary | `accent` | `text-on-accent` | none |
| Secondary | transparent | `text` | 1 px `border-strong` |
| Tertiary | transparent | `text-link` | none |
| Destructive | `danger` | `bg` | none |

Height 48 (default), 40 (compact), 56 (hero). Radius `radius-md`. Horizontal padding 20. Icon gap 8. One primary per view.

### Input

Height 48, radius `radius-sm`, fill `surface-raised`, 1 px `border-strong`. Focus: 2 px `focus-ring`, no layout shift. Label above in Body S 600. Helper below in Caption `text-tertiary`. Error: border `danger`, message `danger` with icon.

### Card

`surface`, radius `radius-md`, elevation 1, padding 20. Tappable cards: pressed state darkens to `surface-sunken` (light) or lightens to `surface-raised` (dark).

### Chip / tag

Height 32, pill, 1 px `border`. Selected: `accent-subtle` fill, `accent-subtle-text`, no border. Genre and mood chips only; member tags use member color dot + label.

### Book cover tile

Aspect 2 : 3. Radius 4 / 8. Elevation 1. On dark, apply `--image-dim` (brightness 0.92) so bright covers do not glare. Missing cover: `surface-sunken` with title in H4 and the mark at 12% opacity.

### Avatar + member ring

Sizes 24, 32, 40, 56. Ring 2 px `member-n`, 2 px gap to image (gap = current `bg`). Progress ring variant: arc fills clockwise with member color over `surface-sunken` track.

### Reading progress

Track `surface-sunken`, 6 px tall, pill. One fill per reader in member color, stacked as small markers on a single track in circle view (max 6). Percent labels use lining + tabular figures. Never red on red: when accent equals member color, fall back to ink/paper.

### Chapter note

Left edge 3 px bar in author's `member-n`. Body L. Author + chapter in Caption. Spoiler-gated notes blur until reader's progress passes that chapter; placeholder says "Hidden until you reach Chapter N".

### Gemini message

`ai-surface` bubble, 1 px `ai-border`, `ai-text`. Radius 16 with 4 on the corner nearest the sender. Label "Gemini" in Overline. Friend messages: `surface` bubble, no border. Own messages: `accent-subtle` bubble. Streaming: three-dot shimmer at `dur-slow`, static under reduced motion.

### Navigation

- Mobile bottom bar: 4 to 5 items, height 64 + safe area, `surface` with 1 px top `border`, active = filled icon in `accent` (light) or `text-link` (dark) with label.
- Web top bar: height 64, `surface`, 1 px bottom `border`. Logo lockup left.
- Tabs: underline 2 px `accent`; inactive `text-secondary`.

### Sheet and modal

Radius `radius-xl` on top corners. Elevation 3. Drag handle 36 × 4 `border-strong`. Scrim token behind. Max width 480 on web modals.

### Toast

`surface-raised`, elevation 2, radius `radius-md`, 4 s auto-dismiss, bottom-center above nav. Icon + semantic color on icon only, not the whole toast.

### Empty states

Mark outline at 64 px in `border-strong`, H3 headline, Body S `text-secondary` line, one primary button. No illustrations in v1.

---

## 10. Light and dark mode

### 10.1 Behavior

1. Default follows system.
2. User override in Settings: System / Light / Dark. Persist.
3. Web: `data-theme="light|dark"` on `<html>` beats `prefers-color-scheme`. Remove attribute for System.
4. Switch is instant on first paint (no flash): set attribute in an inline head script before CSS.
5. Transition on switch: 200 ms color cross-fade on `background-color`, `color`, `border-color` only. Skip under reduced motion.

### 10.2 Rules for dark

| Rule | Why |
|---|---|
| Never `#000` ground or `#FFF` text | Pure extremes cause halation, harsh on long reads. Use `bg #14110F`, `text #F4EEE3`. |
| Lift depth with lighter surfaces | Shadows disappear on dark. |
| Desaturate and lighten accents | Saturated red vibrates against near-black. |
| Text accent ≠ fill accent | Fill carries paper text; link text needs lighter tint. |
| Dim photos slightly (0.92) | Covers glare otherwise. Never dim logos or avatars. |
| Semantic colors lighten, backgrounds deepen | Subtle tints become dark tinted wells. |
| Member colors lighten ~25% | Keep identity, regain contrast. |
| Reading mode dark option | Optional "Night paper": `bg #0F0D0B`, text `#D9CFBD`, 1.75 line-height. Lower contrast on purpose for long sessions. Still ≥7:1. |

### 10.3 Rules for light

- Ground is warm paper, not white. `surface-raised` is the only pure white and only for inputs, popovers, modals.
- Shadows are warm (ink-tinted), never neutral black.
- Accent is the deepest red; hover darkens, never lightens.

### 10.4 Token mapping check

Every component must reference only semantic tokens. Test: flip `data-theme` and screenshot all screens; any element that does not change is a hard-coded color. Fix.

### 10.5 Assets

- Logo: ship light and dark SVG variants (§2 colorways). Use `<picture>` with `prefers-color-scheme` or theme-aware component.
- App icon: single version (tile carries its own ground). Provide a dark-tinted and a monochrome variant for iOS/Android themed icons.
- Splash: `bg` of active theme.

---

## 11. Accessibility

- Contrast targets in §3.7.
- Focus always visible. Never remove outline without replacing.
- Tap targets ≥ 44 × 44.
- Support dynamic type / OS font scaling up to 200%. Layouts wrap, never clip. Cards grow.
- Color never alone: progress, member identity, errors, success all carry text or icon.
- Screen reader order matches visual order. Chapter notes announce author, chapter, then body. Spoiler-hidden notes announce "hidden until chapter N".
- Gemini replies are labeled as AI in text, not color only.
- Reduced motion honored (§7).
- Captions and transcripts for any audio or video.

---

## 12. Writing

- Warm, literate, brief. "Reading with 3 friends" not "3 collaborators active".
- Sentence case. No exclamation marks in system copy. No emoji in product chrome.
- Buttons are verbs: "Start circle", "Add note", "Ask Gemini".
- Privacy copy is plain: "Only your circle can see this."
- Spoiler language: "Hidden until Chapter 7", never "Spoiler!".
- Errors say what happened and what to do next. No blame.

---

## 13. Implementation

### 13.1 Web (CSS)

```html
<head>
  <script>
    // before CSS. No flash.
    try {
      var t = localStorage.getItem('theme');
      if (t === 'light' || t === 'dark') document.documentElement.dataset.theme = t;
    } catch (e) {}
  </script>
  <link rel="stylesheet" href="tokens.css">
</head>
```

```css
.btn-primary {
  background: var(--accent);
  color: var(--text-on-accent);
  font: var(--fw-semibold) 0.9375rem/1.33 var(--font-sans);
  height: 48px;
  padding-inline: var(--space-5);
  border-radius: var(--radius-md);
  transition: background var(--dur-fast) var(--ease-standard);
}
.btn-primary:hover { background: var(--accent-hover); }
.btn-primary:active { background: var(--accent-pressed); }
```

Laravel Blade: include `tokens.css` in the layout, add a theme toggle that writes `localStorage.theme` and sets `document.documentElement.dataset.theme`.

### 13.2 Flutter

> Production Flutter code lives in `flutter/lib/design_system/` (see `flutter/README.md`). The snippet below is a minimal illustration only; prefer the package.

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

@immutable
class BooklyColors extends ThemeExtension<BooklyColors> {
  const BooklyColors({
    required this.surfaceRaised, required this.surfaceSunken,
    required this.textSecondary, required this.textTertiary,
    required this.textLink, required this.accentSubtle,
    required this.accentSubtleText, required this.aiSurface,
    required this.aiBorder, required this.aiText,
    required this.border, required this.borderStrong,
    required this.members,
  });
  final Color surfaceRaised, surfaceSunken, textSecondary, textTertiary,
      textLink, accentSubtle, accentSubtleText, aiSurface, aiBorder, aiText,
      border, borderStrong;
  final List<Color> members;

  static const light = BooklyColors(
    surfaceRaised: Color(0xFFFFFFFF), surfaceSunken: Color(0xFFEBE3D5),
    textSecondary: Color(0xFF5C534A), textTertiary: Color(0xFF6B6258),
    textLink: Color(0xFF7A1F2B), accentSubtle: Color(0xFFEFDCD9),
    accentSubtleText: Color(0xFF5A1520), aiSurface: Color(0xFFEBE7F0),
    aiBorder: Color(0xFFCFC7DA), aiText: Color(0xFF3B2F4F),
    border: Color(0xFFD9CFBD), borderStrong: Color(0xFFB9AD98),
    members: [Color(0xFFB4741C), Color(0xFF1F7A74), Color(0xFF7A3F7E),
              Color(0xFF5B7A2A), Color(0xFF3F5F9A), Color(0xFFB4533A)],
  );
  static const dark = BooklyColors(
    surfaceRaised: Color(0xFF241F1B), surfaceSunken: Color(0xFF0F0D0B),
    textSecondary: Color(0xFFBDB2A3), textTertiary: Color(0xFF968B7D),
    textLink: Color(0xFFDE7B85), accentSubtle: Color(0xFF3A1A1E),
    accentSubtleText: Color(0xFFF0B4BA), aiSurface: Color(0xFF221D2B),
    aiBorder: Color(0xFF3A3149), aiText: Color(0xFFD8CDEA),
    border: Color(0xFF2E2823), borderStrong: Color(0xFF4A4239),
    members: [Color(0xFFE0A04A), Color(0xFF55C4BB), Color(0xFFC58AC9),
              Color(0xFF9CC25A), Color(0xFF8AA8E6), Color(0xFFE68A72)],
  );

  @override
  BooklyColors copyWith() => this;
  @override
  BooklyColors lerp(ThemeExtension<BooklyColors>? other, double t) =>
      t < 0.5 ? this : (other as BooklyColors? ?? this);
}

ThemeData booklyTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final scheme = ColorScheme(
    brightness: b,
    primary: dark ? const Color(0xFFB8434F) : const Color(0xFF7A1F2B),
    onPrimary: dark ? const Color(0xFFF4EEE3) : const Color(0xFFFBF8F2),
    secondary: dark ? const Color(0xFFDE7B85) : const Color(0xFF7A1F2B),
    onSecondary: dark ? const Color(0xFF14110F) : const Color(0xFFFBF8F2),
    error: dark ? const Color(0xFFF0786C) : const Color(0xFFC42B1C),
    onError: dark ? const Color(0xFF14110F) : const Color(0xFFFFFFFF),
    surface: dark ? const Color(0xFF1B1714) : const Color(0xFFFBF8F2),
    onSurface: dark ? const Color(0xFFF4EEE3) : const Color(0xFF1B1714),
  );
  final base = ThemeData(brightness: b, colorScheme: scheme, useMaterial3: true);
  final text = GoogleFonts.ralewayTextTheme(base.textTheme).apply(
    bodyColor: scheme.onSurface, displayColor: scheme.onSurface,
  );
  return base.copyWith(
    scaffoldBackgroundColor: dark ? const Color(0xFF14110F) : const Color(0xFFF4EEE3),
    textTheme: text,
    extensions: [dark ? BooklyColors.dark : BooklyColors.light],
  );
}

// Lining + tabular figures for counts and percentages
const numericStyle = TextStyle(
  fontFeatures: [FontFeature.liningFigures(), FontFeature.tabularFigures()],
);
```

Wire up: `MaterialApp(theme: booklyTheme(Brightness.light), darkTheme: booklyTheme(Brightness.dark), themeMode: userChoice)`. Persist `userChoice`.

### 13.3 Token pipeline

`tokens.json` → Style Dictionary → CSS, Dart, Swift, Android XML. Color tokens have two modes (`color.light.*`, `color.dark.*`); generate one theme output per mode.

---

## 14. Governance

- New color: must map to an existing semantic role or justify a new one. Add both light and dark in same PR.
- New component: spec states, both modes, a11y notes, before build.
- Changes to logo, accent, or typeface need owner sign-off.
- Version this package. Current: **v1.0**.

---

## 15. Open items

- Icon library final pick (Lucide vs Phosphor).
- Night-paper reading theme: ship in v1 or v1.1.
- Illustration style for empty states (deferred; none in v1).
- Member color assignment rule for circles over 6 (dashed ring is placeholder).
