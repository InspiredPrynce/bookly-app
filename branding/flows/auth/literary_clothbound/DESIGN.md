---
name: Literary Clothbound
colors:
  surface: '#fef9ef'
  surface-dim: '#dedad0'
  surface-bright: '#fef9ef'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f8f3e9'
  surface-container: '#f2ede3'
  surface-container-high: '#ede8de'
  surface-container-highest: '#e7e2d8'
  on-surface: '#1d1c16'
  on-surface-variant: '#4b463f'
  inverse-surface: '#32302a'
  inverse-on-surface: '#f5f0e6'
  outline: '#7c766e'
  outline-variant: '#cdc5bc'
  surface-tint: '#615e5a'
  primary: '#000000'
  on-primary: '#ffffff'
  primary-container: '#1d1b18'
  on-primary-container: '#87837f'
  inverse-primary: '#cbc5c0'
  secondary: '#825500'
  on-secondary: '#ffffff'
  secondary-container: '#fec168'
  on-secondary-container: '#774e00'
  tertiary: '#000000'
  on-tertiary: '#ffffff'
  tertiary-container: '#3f0207'
  on-tertiary-container: '#c66966'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#e7e1dc'
  primary-fixed-dim: '#cbc5c0'
  on-primary-fixed: '#1d1b18'
  on-primary-fixed-variant: '#494643'
  secondary-fixed: '#ffddb3'
  secondary-fixed-dim: '#f8bc63'
  on-secondary-fixed: '#291800'
  on-secondary-fixed-variant: '#624000'
  tertiary-fixed: '#ffdad8'
  tertiary-fixed-dim: '#ffb3b0'
  on-tertiary-fixed: '#3f0207'
  on-tertiary-fixed-variant: '#7a2e2e'
  background: '#fef9ef'
  on-background: '#1d1c16'
  surface-variant: '#e7e2d8'
typography:
  display:
    fontFamily: Playfair Display
    fontSize: 40px
    fontWeight: '600'
    lineHeight: 48px
    letterSpacing: -0.02em
  display-mobile:
    fontFamily: Playfair Display
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-lg:
    fontFamily: Playfair Display
    fontSize: 30px
    fontWeight: '600'
    lineHeight: 38px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Playfair Display
    fontSize: 26px
    fontWeight: '600'
    lineHeight: 34px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Playfair Display
    fontSize: 22px
    fontWeight: '500'
    lineHeight: 30px
  headline-sm:
    fontFamily: Playfair Display
    fontSize: 18px
    fontWeight: '500'
    lineHeight: 26px
  body-lg:
    fontFamily: Literata
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 30px
    letterSpacing: -0.005em
  body-md:
    fontFamily: Literata
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 26px
  body-sm:
    fontFamily: Literata
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 22px
  label-lg:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '600'
    lineHeight: 18px
    letterSpacing: 0.06em
  label-md:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.08em
  label-sm:
    fontFamily: Inter
    fontSize: 10px
    fontWeight: '500'
    lineHeight: 14px
    letterSpacing: 0.1em
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-tablet: 1.5rem
  margin: 1.25rem
  margin-tablet: 2rem
  margin-desktop: 3rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2.5rem
---

## Brand & Style

This design system translates the quiet dignity, physical craftsmanship, and timeless typography of antique clothbound volumes into a digital medium. Built for readers, collectors, and literary archivists, the interface departs entirely from hyper-stimulating utility software. It evokes the sensory intimacy of a private library: archival wove paper, foil-stamped typography, edge-gilding, and leather corners.

The overarching aesthetic blends **Editorial Minimalism** with **Tactile Heritage**. Visual compositions prioritize typographic rhythm, deliberate pacing, generous margins, and subtle material cues. Instead of bright alerts and synthetic gradients, interfaces utilize organic ink weights, debossed rule lines, and jewel-tone accents. The experience invites prolonged focus, contemplative reading, and tactile delight across every shelf, annotation, and reading session.

## Colors

The color palette is derived directly from classical publishing materials: rag paper, oak gall ink, bookbinder's gold leaf, and crushed madder cloth.

### Light Mode (The Reading Desk)
- **Canvas / Background**: Warm Paper (`#F6F1E7`), providing an eye-resting base reminiscent of uncoated heavy stock.
- **Primary Text**: Warm Charcoal (`#1C1A17`), possessing softer contrast than pitch black to emulate letterpress ink absorption.
- **Secondary Text / Metadata**: Weathered Vellum (`#6A645A`), calibrated for captions, pagination, and publication dates.
- **Structural Dividers**: Muted Rule (`#E6DEC9`), rendering whisper-thin hair lines and deckled-edge separators.

### Dark Mode (The Night Salon)
- **Canvas / Background**: Deep Ink (`#12100E`), deep without cold blue undertones.
- **Elevated Surface**: Surface Dark (`#181512`), used for sheet overlays, book cards, and modals.
- **Primary Text**: Soft Ivory (`#F4EFE6`), balancing readability without screen glare.
- **Secondary Text**: Muted Subtitle (`#A89E8D`), muted vintage parchment tone.
- **Structural Dividers**: Dark Rule (`#2E2720`), low-luminance separation.

### Accents
- **Burnished Amber**: (`#C8913D` in Light Mode, `#DFAC56` in Dark Mode) serves as the primary mark of distinction, referencing gilt edges and spine foil stamping. Used for active progress, bookmarks, and highlights.
- **Muted Oxblood**: (`#7A2E2E`) serves as an editorial stamp of finality or literary distinction, applied to reading status seals, critical notifications, and destructive actions.

## Typography

The typography establishes a dual-voiced editorial hierarchy:
1. **The Literary Voice (Playfair Display & Literata)**: Used for primary narratives, book titles, chapter headers, pulling quotes, and long-form reader views. Playfair Display brings high stroke contrast and sweeping terminals to section titles, while Literata introduces humanist warmth and optical comfort for sustained reading.
2. **The Bibliographic Voice (Inter)**: Anchors metadata, ISBN numbers, classification badges, reading metrics, and interactive triggers. Always crisp, slightly spaced, and small, it plays the supporting role of archival card-catalog indexing.

### Rules of Usage
- All `label-*` tokens must use uppercase transformations (`text-transform: uppercase`) paired with their expansive letter-spacing to mimic traditional book spine stamping.
- Display and headline levels should never be set in all-caps; preserve their natural sentence or title case to showcase the serif italic and ligatures.
- Editorial pull-quotes must use `Playfair Display` italic at `headline-md` or `headline-lg`.

## Layout & Spacing

Layouts follow classical book architecture: wide gutters, unhurried negative space, and disciplined proportioning based on the Golden Ratio and octavo book dimensions.

- **Mobile Viewports (Under 640px)**: A 4-column fluid layout with `1.25rem` outer margins. Content groups are separated by generous vertical stacks (`space-xl`), allowing the eye to rest between disparate literary blocks.
- **Tablet / Large Reader Viewports (640px - 1024px)**: An 8-column layout with `2rem` margins. The content reflows into dual columns mimicking a spread: the left housing edition covers and curation metadata, the right containing chapters, summaries, or reading activity.
- **Desktop Library (1024px+)**: A 12-column restrained grid capped at a maximum reading width of 1140px, keeping longform copy to a comfortable 65-75 character line length.

Spacing tokens dictate rhythm: micro labels and card details rely on `space-xs` and `space-sm`, while section breaks and thematic dividers consistently demand `space-xl`.

## Elevation & Depth

This design system avoids modern, synthetic drop shadows and diffuse multi-colored blurs. Depth is tactile, physical, and restrained, echoing physical paper, cloth, and bookboard.

### Depth Hierarchy
1. **Debossed / Recessed (Field Inputs & Well Insets)**: An inset shadow technique mimicking hot-metal press indentations into heavy stock. Form fields and search wells rely on 1px borders paired with an internal soft top tint (`inset 0 1px 2px rgba(0,0,0,0.06)`).
2. **Surface Layer (Cards & Panels)**: Completely flat surfaces bounded by hairline borders (`1px solid #E6DEC9` in Light, `1px solid #2E2720` in Dark). Hierarchy is produced via tonal shifts rather than floating separation.
3. **Clothbound Spine Elevation (Book Covers & Modals)**: Physical volumes cast asymmetric, directional ambient shadows simulating side-lit shelf lighting: `box-shadow: -4px 6px 16px -2px rgba(28, 26, 23, 0.12), -1px 2px 4px 0px rgba(28, 26, 23, 0.08)`.
4. **Overlays & Floating Sheets**: Full drawer sheets slide up with an overarching paper deckle border and a subtle warm-tinted shroud: `rgba(28, 26, 23, 0.45)`.

## Shapes

The geometric personality of this design system is architectural, structured, and disciplined. 

- **Level 1 (Soft - 0.25rem base radius)** is strictly observed. Extreme roundedness and bubbly forms are prohibited, as they erode literary authority.
- Cards, book containers, interactive inputs, and buttons embrace subtle softening (`0.25rem` / 4px), replicating the subtly rounded corners of pressed book covers and cardstock.
- Larger sheet containers and full-bleed bottom sheets step up to `0.5rem` (8px) at most.
- **Pills and circles** are reserved strictly for circular profile portraits, progress rings, and bookmark ribbon tags.

## Components

### Buttons
- **Primary Action (Cloth & Foil)**: High-contrast Warm Charcoal background with Soft Ivory typography and subtle gold border highlight. Padding is `space-sm` vertically, `space-lg` horizontally. Corners are `0.25rem`. Press state shifts background toward Deep Ink with a minute inward deboss.
- **Secondary Action (Paper & Rule)**: Warm Paper surface with a `1px` Muted Border and Charcoal text. On hover/active, the background shifts subtly to tone down the paper brightness (`#EFE8DC`).
- **Accent Action (Gilt Gold)**: Burnished Amber background with Deep Ink text. Reserved for primary conversion events (e.g., "Add to Library", "Purchase Edition").

### Chips & Badges
- Miniature bibliographic tags. Set in `label-sm` with all-caps uppercase styling and `0.1em` letter spacing.
- Bound by a crisp `1px` hairline border with an internal padding of `space-xs` and `space-sm`. No heavy fills; chips exist as delicate parchment labels.

### Lists & Chapter Indexes
- Clean horizontal bands separated by `1px` Muted Border hairline rules.
- Left column: Chapter or section numeral set in small italic serif or tabular sans.
- Center: Title set in `headline-sm` or `body-md`.
- Right: Page index or read percentage set in `label-md`. Rows yield an ink-wash hover state.

### Checkboxes & Radios
- Square 16px checkbox frames with a crisp `1px` border. Check indicators use an elegant serif checkmark glyph rather than a generic vector arrow.
- Radio buttons feature a concentric ring pattern with a Burnished Amber core dot.

### Input Fields
- Styled after library card-catalog entries. Backgrounds sit flush with the canvas or recessed with an inset tint.
- The default state displays a single bottom border (`1.5px solid #E6DEC9`) rather than a four-sided container.
- Focus state elevates the bottom border to `Burnished Amber` with zero glowing halos.

### Cards (Book Jackets & Library Editions)
- Book jacket cards use a portrait ratio of 2:3.
- Features a left-side 2px gradient spine strip that replicates the fold and hinge of a bound hardcover volume.
- Elevated with the directional clothbound spine shadow.
- Metadata below the jacket utilizes `headline-sm` for title and `label-md` for the author line.

### Literary Additions
- **The Ribbon Bookmark**: A decorative ribbon tab floating from the top edge of active reading interfaces, tinted in Burnished Amber or Muted Oxblood.
- **Pull Quote Block**: Centered display container flanked above and below by ornamental centered rules (`* * *` or single brass rule), rendered in `Playfair Display` italic.
- **Reading Progress Spine**: A thin, continuous vertical track alongside reader views depicting the volume's physical progress via a gold thread indicator.