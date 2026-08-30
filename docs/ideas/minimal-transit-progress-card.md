# Minimal Transit Flight Progress Card (Modern Vector Edition)

## Problem Statement
How might we create a radically simplified, ultra-sleek **Transit Flight Progress Card** that displays only the route progress bar, departure/arrival timestamps, and live moving vector vehicle (zero emojis, zero dials, zero maps) with peak glanceability?

---

## Recommended Direction

### 1. Modern Vector Vehicle Visuals (Zero Emojis)
- All vehicle indicators are rendered using **crisp, modern vector SF Symbols** with glowing neon halos:
  - **Midnight EV:** `bolt.car.fill` / `car.side.fill`
  - **Classic Sarao:** `bus.fill`
  - **Night Rain Hatchback:** `car.side.rear.open` / `car.side.fill`
  - **Shinkansen Express:** `tram.fill` / `train.side.front.car`
  - **Coastal Bus:** `bus.doubledecker.fill`
- Rendered in high-contrast monochrome white inside a glowing neon circular pod that smoothly glides across the trajectory line.

### 2. The Pure Flight Progress Card (`TransitFlightProgressCard`)
- **Header Timestamps:** `DEPARTURE: 09:35 AM` ──── `ARRIVAL: 10:25 AM` with live countdown `📍 24m remaining`.
- **The Route Line:**
  - Origin station (`ABC PARIS`).
  - Solid glowing route line behind the vehicle.
  - Moving modern vector vehicle pod (`session.progressFraction`).
  - Dashed route line ahead of the vehicle.
  - Destination station (`XYZ NEW YORK`).
- **Live Status Badge:** High-contrast `ON TIME` (cruising), `MISSION HOLD` (paused), or `GRIDLOCK` (distraction alert).
- **Subtle Integrated Controls:**
  - *When Idle:* Sleek preset pills (`25m`, `50m`, `90m`, `Open`) + `START` button.
  - *When Active:* Tactile circular action buttons (`⏸️` Hold, `🏁` Dock, `✕` Abort).
- **Footer:** Vehicle badge (`EV-01`, `SARAO`) + Gold vehicle vector insignia.

### 3. Eliminated Components
- ❌ Odometer / Speedometer dials removed.
- ❌ Map tiles removed.
- ❌ Multi-card widget clutter removed.
- ❌ Emojis removed (replaced 100% with high-resolution vector symbols).

---

## MVP Scope

- `TransitFlightProgressCard.swift` implemented with modern vector symbols and clean progress trajectory.
- `DiagnosticPopoverView.swift` simplified to feature this single card + minimal toolbar.
- `SidebarNotchView.swift` simplified to trigger this single card from the bezel notch.
- `FloatingHUDView.swift` updated to match this pure card layout.
