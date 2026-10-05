# Lucide icons

Vendored. Never fetched at runtime — see PLAN.md §4.3 (Lucide, 24px grid,
1.75px stroke, no mixed icon libraries).

## Why these are vendored rather than pulled from a package

`IconData` is a font glyph. The stroke weight is baked into the typeface and
is not settable, so `Icons.*` and every `IconData`-based package are fixed at
whatever weight their font was drawn with — Material's outlined set renders
nearer 1.5px, Lucide-as-a-font nearer 2px, and neither can reach 1.75.

Reading the SVG instead makes the weight ours: `flutter_svg` parses the
`stroke-width` straight off the root `<svg>` element. That is the entire
reason `BooklyIcon` exists.

Source: https://github.com/lucide-icons/lucide — ISC, see `lucide/LICENSE`.

## The one edit

Every file in `lucide/` differs from upstream in exactly one attribute:

```
stroke-width="2"   ->   stroke-width="1.75"
```

Nothing else is touched. A re-vendor is therefore a one-line diff per icon,
and any unexpected diff in review means the file was edited by hand.

## Re-vendoring

```powershell
Invoke-WebRequest `
  -Uri "https://raw.githubusercontent.com/lucide-icons/lucide/main/icons/<upstream-name>.svg" `
  -OutFile "assets/icons/lucide/<upstream-name>.svg" -UseBasicParsing
```

then set `stroke-width="1.75"` on the root `<svg>`.

**Mind the upstream names.** Lucide has renamed icons across releases and the
filename is what `BooklyIconKind` maps to. This set currently uses `info`
(not `circle-info`), `triangle-alert` (not `alert-triangle`), `circle-check`
(not `check-circle-2`). A 404 on download means the name moved — check
https://lucide.dev/icons/ before assuming the network failed.

## Registering a new icon

1. Drop the `.svg` into `lucide/`.
2. Add a member to `BooklyIconKind`, mapping the stem of the filename.
3. Nothing in `pubspec.yaml`: `assets/icons/lucide/` is registered as a
   whole directory, so new files are picked up by `flutter pub get`.

Then use it — `const BooklyIcon(BooklyIconKind.yourIcon, size: 20)`.

## Attribution

`lucide/LICENSE` ships as an asset so the notice travels with the SVGs, but a
bundled file is not something a reader can *read*. PLAN.md Phase 3 Settings
still needs an in-app open-source licenses entry that surfaces this text;
`flutter`'s automatic `LicenseRegistry` only collects pubspec dependencies
and will not pick these up on its own.
