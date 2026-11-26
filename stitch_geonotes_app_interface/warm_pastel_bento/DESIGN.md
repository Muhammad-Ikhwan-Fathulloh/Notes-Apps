---
name: Warm Pastel Bento
colors:
  surface: '#fff9eb'
  surface-dim: '#e0dac4'
  surface-bright: '#fff9eb'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#fbf3dd'
  surface-container: '#f5eed8'
  surface-container-high: '#efe8d2'
  surface-container-highest: '#e9e2cd'
  on-surface: '#1e1c0e'
  on-surface-variant: '#4a4640'
  inverse-surface: '#343122'
  inverse-on-surface: '#f8f1da'
  outline: '#7b766f'
  outline-variant: '#ccc5bd'
  surface-tint: '#605e5c'
  primary: '#000000'
  on-primary: '#ffffff'
  primary-container: '#1c1b1a'
  on-primary-container: '#868382'
  inverse-primary: '#cac6c4'
  secondary: '#a13f25'
  on-secondary: '#ffffff'
  secondary-container: '#ff8667'
  on-secondary-container: '#741f07'
  tertiary: '#6f5d00'
  on-tertiary: '#ffffff'
  tertiary-container: '#c1aa4d'
  on-tertiary-container: '#4c3f00'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#e6e2df'
  primary-fixed-dim: '#cac6c4'
  on-primary-fixed: '#1c1b1a'
  on-primary-fixed-variant: '#484645'
  secondary-fixed: '#ffdbd2'
  secondary-fixed-dim: '#ffb4a1'
  on-secondary-fixed: '#3c0800'
  on-secondary-fixed-variant: '#812810'
  tertiary-fixed: '#fce27d'
  tertiary-fixed-dim: '#dec665'
  on-tertiary-fixed: '#221b00'
  on-tertiary-fixed-variant: '#544600'
  background: '#fff9eb'
  on-background: '#1e1c0e'
  surface-variant: '#e9e2cd'
typography:
  headline-xl:
    fontFamily: Plus Jakarta Sans
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 52px
    letterSpacing: -0.03em
  headline-xl-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 36px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.03em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 36px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: -0.02em
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: -0.01em
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-md:
    fontFamily: Space Grotesk
    fontSize: 13px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Space Grotesk
    fontSize: 11px
    fontWeight: '600'
    lineHeight: 14px
    letterSpacing: 0.04em
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  gutter: 0.75rem
  gutter-md: 1rem
  margin: 1rem
  margin-md: 1.5rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 0.75rem
  space-lg: 1.25rem
  space-xl: 2rem
---

## Brand & Style

This design system establishes an expressive, warm, tactile experience tailored for creative mobile note-taking and spatial documentation. Drawing inspiration from modern neo-editorial bento layouts and organic stationery aesthetics, the interface balances high-impact typography with cheerful, muted pastel surfaces. 

### Key Characteristics
- **Personality:** Tactile, optimistic, focused, organized, and effortlessly stylish.
- **Visual Movement:** Contemporary Neo-Brutalist Minimalism meets Warm Tactile Bento. Large architectural display typography pairs with soft-cornered, playful color blocks and deep obsidian contrast elements.
- **Emotional Intent:** Reduces the cognitive overhead of standard note-taking apps by making organization feel like assembling a modular stationery scrapbook.

## Colors

The palette revolves around a core creamy parchment neutral complemented by punchy, high-personality pastel swatches that categorize content, plus deep near-black elements to anchor visual structure.

### Palette Architecture
- **Parchment Base (Neutral):** `#F5EED8` creates a warm, physical notebook canvas that reduces screen glare while providing tactile warmth.
- **Obsidian Ink (Primary):** `#1A1918` anchors navigation panels, floating action buttons, high-priority filter pills, and high-contrast title cards.
- **Coral Sunset (Secondary):** `#F47D5E` accents daily planning modules, action milestones, and critical status markers.
- **Morning Sunlight (Tertiary):** `#F9DF7B` used for active highlights, quick capture media cards, and attention states.
- **Supporting Pastels:**
  - *Sage Meadow:* `#BDDDB8` for lists, checklist modules, and environmental notes.
  - *Periwinkle Sky:* `#BACEEB` for media galleries, external references, and geolocation indicators.
  - *Alabaster Cream:* `#FFFDF5` for secondary card surface overlays and high-legibility form inputs.

## Typography

The type system blends geometric friendliness with editorial density. **Plus Jakarta Sans** delivers humanist clarity with tight, confident tracking for editorial headers and body text. **Space Grotesk** serves as the technical counterpoint, applying mechanical discipline to metadata, category counts, coordinates (lat/long), and badge indicators.

### Typography Hierarchy Guidelines
- Display headlines use tight negative tracking (`-0.03em` to `-0.02em`) to echo contemporary magazine covers.
- Editor note body copy retains generous line height (`1.5` to `1.6`) for reading and inline writing comfort.
- Lat/long coordinates, timestamps, and numeric badges must always use `label-sm` or `label-md` in Space Grotesk to guarantee tabular alignment and distinct visual hierarchy.

## Layout & Spacing

The layout is built around an asymmetric 2-column or 4-column dynamic bento grid tailored for touch-first handheld viewports.

### Grid Rhythm
- **Outer Margins:** `1rem` (16px) on mobile viewports ensures maximum usable canvas space; `1.5rem` (24px) for tablet and wide displays.
- **Card Gutters:** `0.75rem` (12px) creates compact, punchy card clusters without feeling overcrowded.
- **Bento Card Structure:** Note blocks follow variable aspect ratios (1:1 square, 1:2 vertical tall, 2:1 horizontal span) allowing checklists, photo highlights, and plain-text snippets to interlock seamlessly.

## Elevation & Depth

Visual hierarchy avoids generic diffuse drop shadows, relying instead on high-contrast surface color layering, pill containment, and subtle micro-borders.

### Surface Tiers
- **Canvas Base:** Flat `#F5EED8` or deep `#1A1918` canvas foundation.
- **Cards & Bento Units:** Completely flat color fills (Coral, Sage, Butter, Sky) paired with an optional ultra-subtle border (`rgba(0, 0, 0, 0.04)`) to maintain edge clarity against varied backgrounds.
- **Overlays & Floating Modals:** Modals and bottom sheets use solid cream backgrounds (`#FFFDF5`) with a 1px boundary border (`rgba(26, 25, 24, 0.08)`) and an ambient, low-diffusion lift: `0px 12px 32px rgba(26, 25, 24, 0.12)`.
- **Floating Controls (FAB & Micro-Dock):** Elevated with a subtle tactile dark halo (`0px 6px 16px rgba(0, 0, 0, 0.18)`) to signal instant interactive availability.

## Shapes

The shape system emphasizes friendly organic curvature through hyper-rounded corners and pill contours.

### Shape Scale
- **Interactive Badges & Filter Tabs:** Full pill shapes (`border-radius: 9999px`) provide touch-friendly visual affordance.
- **Cards & Content Blocks:** `rounded-xl` (1.5rem / 24px to 28px) creates chunky, pebble-like bento compartments.
- **Sheet Drawers & Modals:** Top edge radii use `2rem` (32px) for an inviting presentation.
- **Form Controls:** Full pill or `1rem` (16px) rounded containers for seamless visual coherence with notes cards.

## Components

### Buttons & Interactive Badges
- **Primary Buttons:** Pill-shaped (`border-radius: 9999px`), deep obsidian background (`#1A1918`), stark white typography, with `space-sm` vertical and `space-lg` horizontal padding.
- **Category Filter Pills:** Ghost pill containers with thin 1px outline (`rgba(26, 25, 24, 0.15)`) when inactive; solid black background with white text and an embedded counter chip when active.
- **Floating Action Button (FAB):** Circular (`56px × 56px`), solid `#1A1918` with cream iconography, or floating pill dock combining action keys (Camera, Text, Location, Checklist).

### Bento Note Cards
- **Construction:** Enclosed colored cards (Coral `#F47D5E`, Sage `#BDDDB8`, Sunlight `#F9DF7B`, Sky `#BACEEB`) with `rounded-xl` corners and `space-md` inner padding.
- **Header Strip:** Contains bold note category/title, a top-right circular touch target (`36px × 36px`) for bookmark/favorite states, and subtle drag-handle affordance bars.
- **Embedded Lists:** Checklist items inside cards use translucent circle checkboxes with strike-through text treatments.

### Form Inputs & Auth Controls
- **Text Inputs:** Light cream (`#FFFDF5`) containers with 1px border (`rgba(26, 25, 24, 0.1)`), deep ink text, and subtle placeholder styling (`rgba(26, 25, 24, 0.4)`).
- **Focused State:** Solid 1.5px `#1A1918` ring border, maintaining crisp tactile focus without glowing effects.

### Location & Coordinate Badges (CRUD Notes)
- **Lat/Long Chip:** Monospaced pill badge rendered in `Space Grotesk` (`label-sm`), featuring a mini pin icon, light semi-translucent backdrop (`rgba(0,0,0,0.06)`), and inline status dot (e.g., active GPS lock vs manual drop).
- **Status Indicators:** 8px dot indicators paired with subtle muted badges (e.g., *Draft*, *Synchronized*, *Archived*).