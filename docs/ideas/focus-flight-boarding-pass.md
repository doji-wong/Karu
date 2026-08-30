# Karu: Focus Flight & Minimalist Boarding Pass HUD

## Problem Statement
How might we transform Karu into an ultra-premium **Focus Flight Tracker** where work sessions feel like serene high-altitude flights—featuring a minimalist boarding-pass card (origin/destination, flight number, seat assignment, aircraft silhouette), real-time turbulence detection during distractions, and an expandable in-flight cockpit while removing sidebar bezel clutter?

---

## 🎨 Core Visual Design (Derived from Provided Reference UI)

```
┌─────────────────────────────────────────────────────────────┐
│  FL 288                                           Seat 26A  │
│                      Landing in 1h 15m                      │
│                                                             │
│  SIN ↗   ━━━━━━━━━━━━━━━━━●───────────────   ↘ LHR          │
│  11:30 PM              On Time               05:55 AM       │
│                                                             │
│     ✈️ [A350F Silhouette]                            A350F   │
└─────────────────────────────────────────────────────────────┘
```

### Visual Components & Data Mapping
1. **Header Row:**
   - **Flight Number (`FL 288` / `CODE-404`):** Editable session or project identifier (e.g. `DEV-25`, `STUDY-50`, `KR-777`).
   - **Seat Assignment (`Seat 26A` / `Seat 1A`):** Reflects user focus streak tier or custom seat (Seat 1A First Class unlocked with 7+ day streak).
   - **Subheader Countdown (`Landing in 1h 15m`):** Live remaining flight time or elapsed time in stopwatch mode.
2. **Flight Trajectory & Timestamps:**
   - **Origin (`SIN ↗` / `11:30 PM`):** Departure airport code with diagonal takeoff arrow + departure timestamp.
   - **Destination (`↘ LHR` / `05:55 AM`):** Arrival airport code with diagonal landing arrow + estimated arrival timestamp.
   - **Trajectory Line:** Solid glowing orange/coral progress track with a smooth blue flight position indicator (`▶`) gliding across the route.
   - **Status Badge (`On Time` / `In Turbulence` / `Gate Hold`):**
     - **On Time (Cruising):** Active in focus applications.
     - **In Turbulence (Stalled):** Active in blacklisted distraction apps (Discord, Twitter/X, Steam). Progress freezes, ETA extends, and card glows amber.
     - **Gate Hold (Paused):** Trip held on pit stop / coffee break.
3. **Aircraft Hangar Footer:**
   - **Aircraft Silhouette Vector:** Crisp, high-detail side profile of the active aircraft:
     - *Airbus A350F / A350-1000* (Long-haul widebody)
     - *Boeing 787-9 Dreamliner* (Serene lo-fi cruiser)
     - *Concorde SST* (Supersonic sprint 25m)
     - *Gulfstream G650* (Private executive deep work)
     - *Cessna 172 Skyhawk* (VFR short flight)
   - **Aircraft Identifier Label (`A350F`, `B787`, `CONCORDE`):** Tailored aircraft model name.

---

## 🛩️ Recommended Direction & Architecture

### 1. Unified Card Presentation (`FocusFlightCard.swift`)
- Create a dedicated, reusable SwiftUI component implementing the exact design layout.
- Integrates seamlessly into:
  - **Menu Bar Popover (`DiagnosticPopoverView.swift`):** Compact 340px boarding pass card with quick takeoff/land controls and audio mute toggle.
  - **Floating HUD (`FloatingHUDView.swift`):** Floating mini boarding pass overlay on screen with window background drag.
  - **Dynamic Notch Wings (`NotchWingsView.swift`):** Left wing shows `✈️ FL 288 · 560 kts`; Right wing shows `SIN ➔ LHR · 1h 15m`. Hovering expands the boarding pass.

### 2. Expandable Flight Deck & Moving World Map Window
- A dedicated "Expand Flight Deck" action opens an airline IFE (In-Flight Entertainment) window featuring:
  - **Great Circle Moving Map:** Curvature route rendering across global coordinates.
  - **Flight Telemetry Gauges:** Altitude (FL 380 / 38,000 ft), Ground Speed (540 kts / Mach 0.85), Cabin Pressure, and Headwind.
  - **Pilot's Logbook & Notes (Scratchpad):** Auto-saving Markdown in-flight journal.

### 3. In-Flight Audio System (`AudioEngine.swift`)
- **Cabin Ambient Loop:** Soothing widebody jet cabin hum (gentle pink/white noise filtered to promote focus).
- **Seatbelt Chime ("Ding-Dong"):** Plays native stereo chime on Takeoff (`startTrip`) and Touchdown (`completeTrip`).
- **Turbulence Ambience:** Smooth crossfade to buffeting airflow when distraction apps are frontmost.

### 4. Ditching the Sidebar Notch
- Completely remove `SidebarNotchView.swift` and the intrusive bezel edge button.
- Consolidate all controls into the Menu Bar Popover, Floating HUD, and Notch Wings.

---

## 🔑 Key Assumptions to Validate
- [ ] **Assumption 1 (Metaphor Resonance):** Users find flight terms (Takeoff, Turbulence, Touchdown, Seat 1A) more motivating and calmer than car traffic/gridlock metaphors.
- [ ] **Assumption 2 (Flight Customization):** Users enjoy quick inline editing of Origin/Destination (e.g. `SFO -> HND`) and Flight Number (`KR 288`).
- [ ] **Assumption 3 (Glanceability):** The single horizontal route track with timestamps provides instant situational awareness without cognitive load.

---

## 📦 MVP Scope & Refinement Checklist

### In-Scope (Phase 1)
- [x] **Remove `SidebarNotchView.swift`:** Ditch the bezel tab completely.
- [x] **New `FocusFlightCard.swift`:** Exact vector implementation of the reference flight card with departure/arrival airports, progress bar, blue plane pin, and aircraft silhouette.
- [x] **Airport Route Presets:** Built-in world pairs (`SIN -> LHR` 50m, `SFO -> HND` 90m, `JFK -> LHR` 60m, `HND -> CTS` 25m) + custom user editing.
- [x] **Turbulence Distraction Model:** Transit engine state `.trafficStalled` rebranded to `.turbulence` / holding loop with stall incidents logged as turbulence encounters.
- [x] **Aircraft Hangar Models:** Update vehicle profiles from cars to aircraft (Airbus A350, Boeing 787, Concorde SST, Gulfstream G650, Cessna 172).
- [x] **Seatbelt Chime & Cabin Hum:** Audio engine updated with ambient jet engine loops and audio chimes.

### Out of Scope (For Now)
- Real-time live ADS-B flight tracking from FlightRadar24 API (focus is productivity simulation, not tracking real planes).
- Multiplayer co-pilot cockpits.

---

## 🚫 Not Doing (and Why)
- **No Complex Flight Sim Physics / Stalls:** We keep transit math simple (time and progress) so users stay focused on work rather than playing a simulator.
- **No Cluttered Bezel Tabs:** The sidebar bezel notch caused screen edge interference; removing it keeps macOS clean.
