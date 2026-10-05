# Bookly design system: Flutter

Material 3. Light + dark. Raleway. Requires Flutter 3.27+ (uses `Color.withValues`, `WidgetState`, `CardThemeData`).

## Drop-in

1. Copy `lib/design_system/` into your app.
2. Copy `assets/` to project root. Merge `pubspec_snippet.yaml` into `pubspec.yaml`.
3. `flutter pub get`
4. Wire up the theme:

```dart
final themeMode = BooklyThemeMode();
await themeMode.load(); // before runApp

ValueListenableBuilder<ThemeMode>(
  valueListenable: themeMode,
  builder: (_, m, __) => MaterialApp(
    theme: BooklyTheme.light,
    darkTheme: BooklyTheme.dark,
    themeMode: m, // System / Light / Dark. Persisted.
    home: ...,
  ),
);
```

`lib/main_example.dart` is a runnable demo of all of it.

## Use tokens

```dart
final c = context.colors;                 // semantic colors, auto light/dark
Container(
  padding: const EdgeInsets.all(BooklySpace.s5),
  decoration: BoxDecoration(
    color: c.surface,
    borderRadius: BooklyRadius.rMd,
    border: Border.all(color: c.border),
    boxShadow: BooklyElevation.level(context, 1),
  ),
  child: Text('Chapter 7', style: BooklyType.h4),
);
```

Rules:
- Never hard-code hex in widgets. Use `context.colors.*`.
- Never use `BooklyBrand.*` in widgets except logo overrides.
- Use `ThemeMode.system` as default; user override in Settings.
- Animations: `duration: BooklyMotion.of(context, BooklyMotion.base)`.
- Counts, pages, percentages: `style: BooklyType.body.copyWith(fontFeatures: BooklyType.numeric)`. Raleway defaults to old-style figures.
- Long reading (chapter notes, Gemini answers): `BooklyType.reading`, constrain width to `BooklyBreakpoint.readingMaxWidth`.
- Mobile type: use `BooklyType.h1Mobile` etc. under 640dp width.

## Files

| File | What |
|---|---|
| `bookly_colors.dart` | `BooklyBrand`, `BooklyColors` ThemeExtension (light/dark, member colors, AI colors, lerp for animated theme switch) |
| `bookly_typography.dart` | `BooklyType` Raleway scale + `TextTheme` |
| `bookly_tokens.dart` | `BooklySpace`, `BooklyRadius`, `BooklyMotion`, `BooklyBreakpoint`, `BooklyBorder`, `BooklyElevation` |
| `bookly_theme.dart` | `BooklyTheme.light/dark`, `context.colors`, component themes (buttons, inputs, cards, chips, nav bar, tabs, sheets, dialogs, snackbars, progress, switch, list tile) |
| `bookly_theme_mode.dart` | System/Light/Dark controller, persisted |
| `bookly_logo.dart` | `BooklyMark`, `BooklyLockup`: vector, theme-aware, auto small-cut under 32dp |
| `bookly_components.dart` | `MemberAvatar`, `ReadingProgressBar`, `BooklyChatBubble` (own/friend/Gemini), `BookCover` |
| `bookly_design_system.dart` | barrel export |

## Logo in app

Prefer `BooklyMark` / `BooklyLockup` widgets. Vector, no asset, switches with theme, never pixelates.

```dart
const BooklyMark(size: 48);
const BooklyLockup(markSize: 40);
```

PNG fallback (resolution-aware, pick by brightness):

```dart
Image.asset(context.isDark
  ? 'assets/logo/bookly-lockup-dark.png'
  : 'assets/logo/bookly-lockup-light.png', width: 180);
```

SVG: `flutter_svg` with `assets/logo/*.svg`.

Big master PNGs (4096/8192 px) live outside the app in `/logos`. Do not bundle in the app; they bloat the binary. Use them for store listings, web, print, decks.

## Launcher icon

`dart run flutter_launcher_icons` with the config in `pubspec_snippet.yaml`. Adaptive foreground sits inside the 61% safe zone. Monochrome layer is for Android 13+ themed icons.

## Offline Raleway (production)

`google_fonts` downloads Raleway at runtime on first use. For offline and faster first paint:

1. Download Raleway 400, 500, 600, 700, 800 `.ttf` from Google Fonts.
2. Put them in `google_fonts/` at project root, named like `Raleway-Medium.ttf`, `Raleway-Bold.ttf`.
3. Add `- google_fonts/` to `flutter: assets:`.
4. In `main()`: `GoogleFonts.config.allowRuntimeFetching = false;`

## Dark mode notes

- Ground `#14110F`, text `#F4EEE3`. No pure black/white.
- Depth = lighter surface + 1px border, not shadow (`BooklyElevation.level` does this).
- Accent fill `#B8434F` (carries paper text). Red as text/link uses `textLink` `#DE7B85`.
- Covers dimmed 8% via `BookCover`.
- `BooklyColors.lerp` makes theme switches cross-fade.

## Accessibility

- Tap targets 44+. Buttons min height 48.
- Color never sole signal. `MemberAvatar`, `ReadingProgressBar`, `BooklyChatBubble` carry semantics labels.
- Respect OS text scaling; layouts must wrap. Test at 200%.
- Respect reduce-motion: `BooklyMotion.of`.
- Contrast pairs chosen for AA by calculation. Verify with tooling for new pairings.
