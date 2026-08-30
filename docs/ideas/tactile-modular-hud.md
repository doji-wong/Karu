# Tactile Modular Widget HUD & High-Contrast Design System

## Problem Statement
How might we transform Karu's focus experience from a raw telemetry dashboard into an ultra-sleek, modular tactile widget deck that delivers glanceable velocity momentum and frictionless study controls directly on the screen edge?

---

## Recommended Direction

Adopt the high-contrast, premium modular widget aesthetic from Yash Nikam's design sheet:
1. **Visual Foundation (Charcoal & Solar Orange):**
   - Deep matte black / charcoal squircle containers (`#0E0F12` and `#16181D`) with subtle 1px translucent borders (`rgba(255,255,255,0.07)`).
   - High-energy **Solar Orange (`#FF5C00` / `#FF7700`)** primary accents for velocity numbers, active route pins, and charging/streak gauges.
   - Secondary accents: **Cyber Cyan (`#00E5FF`)** for navigation route lines, **Emerald (`#00E676`)** for on-time cruise states, and **Hazard Crimson (`#FF3B30`)** for traffic gridlock stalls.
   - Clean, rounded modern typography with high hierarchy contrast (bold display numbers + micro uppercase monospace labels).

2. **The Hover & Tap Sidebar HUD Pill (`SidebarHUDPanel`):**
   - **Resting Edge Pill:** Ultra-compact, docked to the screen edge (left or right). Shows live velocity pill (`100 KM/H`), pulse dot, and ETA countdown.
   - **Hover / Tap Trigger:** Hovering or clicking smoothly expands an edge-anchored **Modular Widget Deck** with ProMotion spring transitions.
   - **Pin Mode:** A dedicated pin toggle lets users lock the widget deck open during intense focus sessions.

3. **The Modular Widget Stack:**
   - **Widget 1: Flight / Route Telemetry Header (Aviation Card):**
     - Origin ➔ Destination route banner (`MANILA BGC ──── ✈️ ────► MAKATI CBD`), `DEPARTURE` & `ARRIVAL` clocks, `ON TIME` emerald pill badge.
   - **Widget 2: Turn-by-Turn Navigation & Controls Card:**
     - Big bold milestone readout (`450M DEEP FOCUS CORRIDOR`), circular tactile action controls (`⏸️` Hold / Resume, `🏁` Complete / Dock, `✕` Abort).
     - 3-column bottom telemetry: `ETA 18m` | `Speed 100 km/h` | `Distance 8.9 km`.
   - **Widget 3: Vehicle Digital Twin & Efficiency Pod:**
     - Active focus vehicle silhouette with glowing efficiency percentage (`⚡ 94% CRUISE`) and battery/streak range.
   - **Widget 4: Dark GPS Vector Map:**
     - Dark CARTO vector map tile with glowing orange `EXIT 5` milestone badge and location beacon.
   - **Widget 5: In-Flight Scratchpad & Audio Utility Bar:**
     - Frictionless markdown notes input and ambient soundscape volume slider.

---

## Key Assumptions to Validate
- [ ] **Hover Friction:** Hover trigger feels responsive without triggering accidentally during normal mouse movements (tuned with 120ms debounce or toggle option).
- [ ] **Screen Edge Multi-Monitor Support:** Docking stays fixed to the active screen edge without jumping when displays reconfigure.
- [ ] **Visual Hierarchy:** Solar Orange + Charcoal palette provides instant readability against diverse desktop wallpapers and IDE backgrounds.

---

## MVP Scope

### In Scope
- Complete redesign of `KaruTheme.swift` with the Charcoal & Solar Orange design tokens, squircle card styles, and modular typography.
- Implementation of `SidebarHUDPanel` and `SidebarHUDView` featuring the resting edge pill and expandable modular widget deck.
- Full suite of modular widgets:
  1. Aviation Route Header Card
  2. Navigation Turn-by-Turn Card with circular controls
  3. EV Vehicle Digital Twin & Efficiency Pod
  4. Dark GPS Vector Map Card
  5. In-Flight Scratchpad & Ambient Soundscape controls
- Redesign of `FloatingHUDView.swift` and `DiagnosticPopoverView.swift` to match the new modular squircle widget aesthetic.
- Global shortcut / menu bar toggle integration in `AppDelegate.swift`.

### Not Doing (and Why)
- **Arbitrary Drag & Drop Widget Customization:** Keep the initial widget stack opinionated and beautifully arranged to avoid user setup friction.
- **Third-Party Integrations (Spotify/Uber APIs):** Keep Karu 100% local-first and zero-cloud without external API dependencies.
- **Complex Floating Window Managers:** Focus on the rock-solid, edge-docked sidebar HUD pill and Menu Bar HUD.

---

## Open Questions
- None. Direction and choices fully aligned through idea refinement.
