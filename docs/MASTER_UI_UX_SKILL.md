# Master UI · UX · Frontend Skill

Autonomous master skill for building world-class websites, apps, decks, and media.

## Summary of Core Standards Applied to Wedding Time App:

### 1. Apple HIG & Mobile UX Principles
- **Touch Targets:** Minimum 44×44 pt on touch screens, 8 pt spacing between interactive targets.
- **Visual Feedback:** Responsive touch states within 100ms, haptic confirmation for critical actions.
- **Navigation:** 3–5 primary tabs at the bottom, predictable back behavior, no hidden primary destinations.
- **Glass & Materials:** Translucent blur / glass applied only to floating functional layers (nav, sheets, modals), never content.

### 2. Design Tokens & Semantic Systems
- **Palette Architecture:** Primary, Secondary, Accent, Surface, Background, Signal/Status (Error, Success).
- **Light & Dark Mode Parity:** Desaturated, accessible tonal variants with >= 4.5:1 text contrast in both modes.
- **Typography Scale:** Fluid responsive scale with explicit hierarchy, tabular figures for countdowns/prices/data.

### 3. Persian & RTL Typography Standards
- **Line Heights:** >= 1.6–1.8 for Persian running text to prevent glyph clipping (چ, گ, پ, ژ).
- **Zero-Width Non-Joiner (ZWNJ / نیم‌فاصله):** Enforced on prefixes/suffixes (می‌شود, ها, تر).
- **Bidirectional Isolation:** `dir="rtl"` root with isolated `dir="ltr"` for numbers, codes, and URLs.
- **Font Pairing:** Harmonized weights and optical x-height between Latin display and Persian body type.

### 4. Accessibility & Quality Floor (WCAG 2.2 AA)
- **Zero Color-Only Signals:** Every state/alert pairs color with an icon and clear text description.
- **Focus Indicators:** Visible, high-contrast focus rings for keyboard navigation.
- **Reduced Motion:** Respects `prefers-reduced-motion` across all transitions and particle effects.
- **No Generic AI Slop:** Hand-crafted distinctive aesthetics, custom artwork over generic stock, and contextual typography.
