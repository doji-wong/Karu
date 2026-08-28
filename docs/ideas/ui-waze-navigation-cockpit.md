# UI Concept: Waze-Style Highway Navigation & Dynamic Notch Cockpit

## Problem Statement
How might we transform Karu's focus tracking into an intuitive, visually stunning **"Waze for Deep Work"** navigation experience that visualizes focus momentum as an active highway journey with live traffic hazard pins and fluid MacBook notch spring physics?

---

## 🧭 Recommended Direction: The Waze-for-Focus Navigation Engine

### 1. Live Highway Route Map (`HighwayNavigationView.swift`)
Replaces flat progress bars with an animated, vector-rendered highway navigation map:
- **The Open Road:** A curved neon highway track with animated center-line dash markers that move forward at high speed while cruising (100 km/h) and freeze abruptly when stalled (0 km/h).
- **Vehicle Avatar:** Active Garage vehicle (Midnight EV, Classic Sarao, Rain Hatchback, Shinkansen, Coastal Bus) renders dynamically on the track.
- **Waze-Style Traffic Hazard Pins:**
  - Whenever `DistractionMonitor` detects an unapproved app switch (e.g. Discord, Twitter, Steam), a **Hazard Pin / Traffic Congestion Zone** (`⚠️ Traffic Jam · Discord`) appears directly on the route map.
  - Historical stall incidents are plotted as road hazard markers along the trip route.
- **Waypoints & Milestones:**
  - `0%` Start On-Ramp $\to$ `50%` Rest Stop Milestone $\to$ `100%` Destination Arrival Flag.
- **Lane Telemetry Banner:**
  - *Cruising:* `🟢 LANE 1 CLEAR · CRUISE 100 KM/H · ETA 18 MIN`
  - *Stalled:* `🔴 GRIDLOCK DETECTED · ROAD HAZARD: DISCORD · VELOCITY 0 KM/H`

### 2. Liquid Notch Spring Physics (`NotchWingsView.swift` & `NotchDropdownCockpitView.swift`)
- **Wings:** Flank the MacBook camera notch (`⚡ 100 km/h` on left wing, `📍 18m · Deep Work` on right wing).
- **Hover Expansion:** When the mouse hovers over the notch area, SwiftUI spring animations (`.spring(response: 0.35, dampingFraction: 0.75)`) smoothly drop down an aerodynamic mini cockpit directly under the notch, displaying the live mini highway track and speed gauge.
- **Display Fallback:** Seamlessly renders in the Menu Bar popover or floating HUD on non-notch external displays.

### 3. Glassmorphism Floating Mini-HUD Overlay
- An ultra-compact, draggable OLED glass widget that can toggle between:
  - Mode A: Minimalist Speedometer Pill (`⚡ 100 km/h · 18m`)
  - Mode B: Mini Highway Route View with live animated car avatar

---

## 🎯 Key Assumptions to Validate
- [ ] **Smooth 60/120fps Rendering:** Vector highway line animation must run via SwiftUI `TimelineView` with `< 0.2%` CPU overhead.
- [ ] **Glitch-Free Notch Hover:** Mouse tracking around `auxiliaryTopLeftArea` / `auxiliaryTopRightArea` must feel fluid without flickering.
- [ ] **Glanceable Clarity:** Users must instantly recognize whether their lane is clear or blocked at a 0.5-second glance.

---

## 🛠️ Implementation Scope (MVP Refinement)

### In-Scope:
1. **`HighwayNavigationView` Component:**
   - Vector route track with animated highway road markings.
   - Vehicle avatar moving along the curve from 0% to 100%.
   - Traffic Hazard Pins plotted on stall events.
   - Lane telemetry status readout.
2. **`NotchDropdownCockpitView` Component:**
   - Dynamic notch drop-down with spring animations on mouse enter/exit.
3. **Cockpit Popover Integration:**
   - Embedding the Waze highway navigation map directly in `DiagnosticPopoverView`.
4. **Floating HUD Highway Mode:**
   - Expanding `FloatingHUDView` to display the mini-highway avatar.

### Not Doing (and Why):
- ❌ **Full Real-World Apple Maps Satellite 3D Rendering:** Too heavy for a menu bar utility; 2D/isometric vector highway track is much faster, cleaner, and matches the OLED aerospace aesthetic with zero GPU battery drain.
- ❌ **Multiplayer Live Ghost Cars:** Deferred to v1.2 roadmap; focus on single-player deep work flow first.

---

## ❓ Open Questions for Execution
1. Would you like the highway map view to be rendered in **Top-Down 2D Schematic Mode** (sleek transit subway/highway line) or **Isometric Perspective 2.5D Mode** (road receding into the distance)?
