# Sidebar Bezel Notch with Circular Telemetry Rings & Pointer Flyout Cards

## Problem Statement
How might we seamlessly anchor Karu to the macOS screen bezel as an organic hardware-like **Sidebar Notch**, featuring glanceable circular progress rings that fly out high-fidelity cockpit cards on hover or tap?

---

## Recommended Direction

### 1. The Organic Bezel Notch Shelf (`SidebarNotchShelf`)
- Anchored directly flush to the right (or left) macOS screen bezel.
- Organic continuous bezier curves protruding into the display area with deep matte black background (`#0A0B0E`).
- Houses 3 vertical circular telemetry ring gauges:
  1. **Gauge 1 (Flight Speed & Mission Progress):**
     - Solar Orange / Emerald circular progress ring with center vehicle icon (`bolt.car.fill` / `bus.fill` / `car.side.fill` / `tram.fill`).
     - Live metric underneath: `73%` progress or `100 KM/H`.
     - Hover/Tap Flyout: The **Aviation Flight Card** (`AviationFlightCard`) with departure/arrival times, live moving vehicle route bar, and `ON TIME` status + circular flight controls.
  2. **Gauge 2 (Cockpit Speedometer & Dial Odometer):**
     - Cyan / Electric Blue circular progress ring with gauge/tachometer icon.
     - Live metric underneath: `859 MPH` or `32.5k FT`.
     - Hover/Tap Flyout: The **Cockpit Altimeter / Speedometer Dial Card** (`CockpitDialCard`) with moving continuous semicircle arc, yellow needle, moving green LCD odometer, and live altitude.
  3. **Gauge 3 (Habit Streak & In-Flight Logbook):**
     - Warm Amber / Golden circular progress ring with flame icon.
     - Live metric underneath: `🔥 4d` streak or `14.8 KM`.
     - Hover/Tap Flyout: **In-Flight Scratchpad & Audio Utility Card** (`InFlightScratchpadWidget`) with notes editor and soundscape volume slider.

### 2. Aerodynamic Pointer Flyout Cards (`FlyoutPointerCard`)
- Deep matte black card (`#0C0D10`) with 16px rounded corners, subtle 1px glass border (`rgba(255,255,255,0.08)`), and soft drop shadow.
- An aerodynamic triangular pointer arrow extends from the card right edge pointing directly into the active circular ring gauge in the bezel notch.
- Smooth spring physics transition (`.spring(response: 0.3, dampingFraction: 0.75)`).
- Hover-to-reveal with 120ms debounce or tap-to-pin open.

---

## Key Assumptions to Validate
- [ ] **Mouse Tracking & Edge Proximity:** Hovering near the screen bezel feels effortless without triggering during normal full-screen window scrolling.
- [ ] **Pointer Alignment:** The flyout arrow smoothly aligns vertically with whichever of the 3 ring gauges is currently hovered/active.
- [ ] **Multi-Screen Positioning:** Properly sticks to the edge of the active screen using `NSScreen.main?.visibleFrame`.

---

## MVP Scope

### In Scope
- Organic Bezier Sidebar Notch Shelf (`SidebarNotchShelfShape`) rendered flush with screen edge.
- 3 interactive circular ring gauges with glow strokes and typography.
- Pointer flyout bubble card (`FlyoutBubbleShape`) showing the corresponding aviation cockpit card on hover/tap.
- Dynamic switching between Gauge 1 (Aviation Flight Card), Gauge 2 (Cockpit Dial Card), and Gauge 3 (Scratchpad / Route Log).
- Global keyboard shortcut (`⌘ + ⇧ + S`) and Menu Bar toggle integration.

### Not Doing
- Blocking screen clicks outside the notch/flyout (window remains `.nonactivatingPanel` with `.canJoinAllSpaces`).
- Complex custom plugin gauges for uninstalled third-party apps (focus strictly on Karu's transit velocity, habits, and notes).

---

## Open Questions
- None. Design and interaction model fully aligned.
