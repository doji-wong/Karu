# DeskMinder-Inspired Frosted Glass Transit Flight Card

## Problem Statement
How might we blend the liquid glassmorphism, background blur depth, and tactile squircle elegance of **DeskMinder** (by Chapps™) with Karu's core metaphor — creating an ultra-clean **Frosted Glass Flight Card** centered strictly around the route progress bar, live timestamps, modern vector vehicle pod, and tactile glass controls?

---

## Recommended Direction

### 1. DeskMinder Frosted Glass Aesthetic
- **Glassmorphic Depth:** Deep dark frosted glass (`rgba(16, 18, 24, 0.78)`) with subtle multi-layer drop shadow and 1px specular inner glass border (`rgba(255, 255, 255, 0.12)`).
- **Sunset Solar to Neon Emerald Liquid Gradient:** Smooth `#FF5C00` ➔ `#22C55E` fluid gradient for the route progress line and status accents.

### 2. The Pure Progress Bar with Time (Centerpiece)
- **Top Row (Task & Timestamps):**
  - Left: Linked focus task / habit tag with a subtle glass capsule.
  - Right: `09:35 AM ➔ 10:25 AM` (`24m left` live countdown).
- **Liquid Progress Track:**
  - Origin code (`MAN`) ──── Glowing liquid gradient path ──── [⚡ Vector Vehicle Pod] ──── Dashed remaining line ──── Destination (`BGC`).
  - Modern vector vehicle pod (crisp `bolt.car.fill`, `car.side.fill`, `tram.fill` — **zero emojis**) glides in real-time along the track (`session.progressFraction`).
- **Live Status & Speed Badge:**
  - High-contrast `ON TIME` / `MISSION HOLD` / `GRIDLOCK` glass badge.
- **Tactile Glass Pill Controls:**
  - *When Idle:* Sleek glass duration pills (`25m`, `50m`, `90m`, `Open`) + glowing Launch button.
  - *When Active:* Tactile glass circular buttons (`pause.fill` / `play.fill`, `flag.checkered`, `xmark`).

### 3. Radical Elimination of Noise
- ❌ Odometer / Speedometer dials deleted.
- ❌ Heavy map tiles deleted.
- ❌ Cluttered multi-card widget decks replaced with this unified single glass card.

---

## Key Assumptions to Validate
- [ ] **Glass Legibility:** Text and timestamps remain crisp and readable over varying dark wallpapers.
- [ ] **Fluid Motion:** The vector vehicle pod glides smoothly across the liquid gradient line with 60fps/120fps ProMotion fluidity.

---

## MVP Scope

### In Scope
- `DeskMinderTransitCard.swift` implementing the frosted glassmorphic card, liquid gradient route track, modern vector vehicle pod, and tactile glass controls.
- Integration into `DiagnosticPopoverView.swift` (Menu Bar dropdown).
- Integration into `SidebarNotchView.swift` (Sidebar Bezel Notch flyout).
- Integration into `FloatingHUDView.swift` (Desktop Floating HUD).

### Not Doing
- Odometer / Speedometer analog arcs.
- External map renderers.
- Emojis for vehicles (100% vector SF Symbols).
