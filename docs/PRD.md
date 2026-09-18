# Karu — Product Requirements Document (PRD)

**Document Status:** Approved (Focus Flight Edition)  
**Version:** 2.2.0  
**Date:** 2026-09-18  
**Platform:** macOS 14.0+ (Apple Silicon & Intel)  
**Tech Foundation:** Native Swift / SwiftUI / AppKit (100% Local-First)


---

## 1. Executive Summary & Vision

Traditional focus timers (e.g., standard Pomodoro apps) rely on anxiety-inducing countdown clocks and passive timers that are either ignored or induce task friction. 

**Karu** is a high-performance, native macOS Menu Bar & Floating HUD application that replaces countdown clocks with an **aviation and flight velocity metaphor**. A focus session is framed as an international flight run between worldwide cities (e.g. `YYZ ➔ HND`, `SIN ➔ LHR`, `SFO ➔ HND`). Remaining active in your designated focus workspace keeps your aircraft cruising at standard flight velocity (**540 kts**); switching into high-friction distraction apps triggers instant **air turbulence**, stalling progress until you return to focus.

With integrated **Pilot Flight Hours Logbook**, **1-Click Running App Radar**, and **In-Flight Ambient Cabin Acoustics**, Karu turns deep study and software engineering sessions into a tangible journey of momentum.

---

## 2. Target Audience & Personas

1. **The Software Engineer / Terminal Worker:** Needs uninterrupted deep coding flow; spends hours switching between IDE, terminal, and documentation, but prone to muscle-memory context-switching (e.g., Reddit, Discord, YouTube, Twitter/X).
2. **The Student / Researcher:** Balances reading papers, drafting assignments, and problem-solving; needs a visible, low-friction momentum tracker in the macOS Menu Bar and hardware notch.
3. **The Remote Knowledge Worker:** Struggles with unstructured work blocks and wants to log certified pilot flight hours and streak consistency.

---

## 3. Product Metaphor & Core Mechanics

```
┌─────────────────────────────────────────────────────────────┐
│                      THE FLIGHT ENGINE                      │
│                                                             │
│   [Focus Workspace]  ─────────► [Cruising Velocity: 540 kts]│
│   (Xcode, VS Code, Docs)        (Clear Skies / On-Time)     │
│                                                             │
│   [Distraction App]  ─────────► [In Turbulence: 0 kts]      │
│   (Social, Video, Chat)         (Hazard Stall / Warning)    │
└─────────────────────────────────────────────────────────────┘
```

### 3.1 Cruising Velocity (540 kts)
* When a flight is active and the user's frontmost application is on the **Approved Workspace list** (or neutral), the transit engine runs at **Cruise State (540 kts)**.
* Visual indicators glow with a crisp white pulse; route distance accumulates steadily in **Nautical Miles (NM)** toward destination arrival.

### 3.2 Turbulence & Detours (The Distraction Filter)
* Karu monitors frontmost active application changes via macOS `NSWorkspace`.
* When the user activates a blacklisted distraction app (e.g., Discord, Steam, Twitter client, or configurable apps), the transit engine detects a **Turbulence Encounter**.
* Airspeed drops to **0 kts**. The Menu Bar, Notch Wings, and HUD shift to an amber/red turbulence alert state, and route progress freezes until the user steers back to their focus window.

### 3.3 Flight Presets & Flow Modes
* **Short Haul Sprint (25m):** High-intensity sprint (Pomodoro equivalent).
* **Cruising Altitude (50m):** Deep-work standard block.
* **Transcontinental Run (90m):** Extended ultradian cycle.
* **Open Flight Deck (Stopwatch):** Uncapped flow run with continuous velocity logging.

---

## 4. Feature Specifications

### 4.1 Focus Flight Card & In-Flight Telemetry (`FocusFlightCard.swift`)
* High-contrast luxury black & white flight deck interface:
  * **Dual Airport Route Corridor:** Departure and arrival airports with live timezone delta and great-circle nautical distance.
  * **Negative Overtime Countdown:** High-contrast remaining and overdue timer displays (`-MM:SS` countdown and overtime indications via `KaruFormatters`).
  * **Luminous Slider Track:** Interactive scrubber showing elapsed cruise distance, target arrival progress, and gate status.
  * **Avionics ETA Pod:** Compact inset pod with destination ETA, timezone, and telemetry status badges.
  * **Smooth Inline Accordion Drawer Coordinator:** Dynamic expansion without window clipping bugs in borderless floating `NSPanel`s.

### 4.2 Pre-Flight Dispatch Deck (`PreFlightDispatchDeckView.swift`)
* Structured 4-stage clearance sequence presented prior to flight takeoff:
  1. **Dual Route Corridor:** Origin and Destination selector cards with 1-tap corridor swap (`⇄`) and inline search.
  2. **Seat & Cabin Class Selector:** Horizontal strip with standard presets (`1A Deep Work`, `2B Study`, `3C Research`, `4D Read`, `5F Code`) and custom `7X` mission objective entry.
  3. **Destination Time Control:** Per-airport duration memory (`destinationDurations`), preset duration pills (`15M`, `25M`, `45M`, `60M`, `90M`), precision stepper, slider, and live ETA in destination timezone.
  4. **Clear for Takeoff:** High-contrast 1-tap clearance triggering departure soundscape and 540 kts cruising state.

### 4.3 Modular Aviation Drawers (`FlightCardDrawers.swift`)
* Decoupled inline accordion drawer components:
  * `FlightCardAirportPickerDrawer`: Searchable global airport directory with IATA codes, cities, and timezones.
  * `FlightCardSeatDrawer`: Standalone seat and custom mission objective configuration.
  * `FlightCardAudioDrawer`: Vehicle soundscape selection and volume controls.
  * `FlightCardLogbookDrawer`: In-flight quick access to session history and efficiency stats.
  * `FlightCardAppRadarDrawer`: Live active application scanner and 1-click whitelist/blacklist rules.
  * `CustomMissionInputRow`: Reusable uppercase custom task and seat code input row.

### 4.4 1-Click Running App Radar (`AppFilterSettingsView.swift`)
* Live scanning of active macOS user applications via `NSWorkspace.shared.runningApplications`.
* Displays native application icons, names, and bundle IDs.
* 1-Click classification buttons for `Focus Workspace`, `Distraction Hazard`, or `Neutral Utility`.
* Instant persistence to local storage with manual rescan and search filtering.

### 4.5 Pilot's Flight Logbook Window (`LogbookView.swift` / `Cmd + L`)
* Dedicated analytics and flight log utility window tracking:
  * Total Certified Flight Hours (`HRS`)
  * Total Distance Flown in Nautical Miles (`NM`)
  * Touchdown Count & Streak History
  * Fleet On-Time Cruising Efficiency Percentage (`%`)
  * Detailed chronological session log table with turbulence incident counts.

### 4.6 Dynamic Notch HUD / Side-Notch Wings (`NotchWingsView.swift`)
* Hardware camera notch attachment on modern MacBooks using `NSScreen.auxiliaryTopLeftArea` / `auxiliaryTopRightArea`.
* **Left Wing:** Live Airspeed Telemetry (`⚡ 540 kts` cruise glow; shifts to `⚠️ 0 kts TURBULENCE` when distracted).
* **Right Wing:** Route progress & habit tag (e.g. `HND ➔ 24m remaining`).
* Automated fallback to Menu Bar HUD on external or non-notch displays.

### 4.7 Desktop Flight Telemetry Widgets (`KaruWidgets`)
* Native WidgetKit desktop extensions for macOS 14.0+ (Sonoma) and macOS 15.0+ (Sequoia):
  * **Small Airspeed Gauge (`systemSmall`):** Circular daily flight quota ring, 540 kts digital speedometer, and habit streak counter.
  * **Medium Flight Dispatch (`systemMedium`):** Split board with route telemetry corridor, flight progress bar, live ETA, and 1-click interactive takeoff intent (`TakeoffIntent`).
* Local-first snapshots loaded atomically from `widget_snapshot.json` via `FlightTelemetryTimelineProvider`.

### 4.8 Dynamic Dock Telemetry & Interactive Menu (`DockTelemetryManager.swift`)
* Mini carbon-matte cockpit avionics rendered directly in `NSApp.dockTile.contentView` (`DynamicDockTileView`).
* Live circular progress arc, digital airspeed readout (`540 KTS`), and destination badge with `< 0.5%` CPU throttling.
* Interactive macOS Dock contextual menu (`NSApplicationDelegate.applicationDockMenu`) for quick takeoff, gate hold, and touchdown.

### 4.9 First-Time Pilot Onboarding Briefing (`OnboardingView.swift`)
* 4-stage interactive cockpit briefing on maiden launch:
  1. Role & Daily Flight Quota selection.
  2. 1-Click App Radar active application scanning.
  3. Avionics velocity mental model introduction.
  4. Maiden takeoff ignition with departure chime.

### 4.10 In-Flight Acoustic Engine (`AudioEngine.swift`)
* Low-latency spatialized ambient cabin soundscapes using `AVAudioEngine` for 5 distinct aircraft models:
  1. *Airbus A350F* (Rolls-Royce Trent XWB turbofan hum)
  2. *Boeing 787-9 Dreamliner* (Serene acoustic cabin dampening)
  3. *Concorde SST* (Mach 2.0 supersonic aerodynamic rush)
  4. *Gulfstream G650* (Whisper-quiet executive jet FL450 cruising air)
  5. *Cessna 172 Skyhawk* (Lycoming 4-cylinder rhythmic propeller drone)
* 400ms smooth crossfading between cruising soundscapes and turbulence alert soundscapes.
* Integrated cabin voice announcements and chime sequences for takeoff, turbulence, and touchdown.

### 4.11 Standalone DMG Packaging, Hardened Runtime & Apple Notarization
* Native zero-dependency standalone disk image builder (`scripts/create_dmg.sh`) using macOS `hdiutil` and AppleScript Finder layout styling (540x380 window, 110 pt icons, `/Applications` symlink).
* Strict Hardened Runtime configuration (`Packaging/Karu.entitlements`) with zero JIT or unsigned memory exceptions.
* Automated Apple Notarization and ticket stapling via `scripts/notarize_app.sh` (`xcrun notarytool` and `xcrun stapler`) ensuring seamless Gatekeeper approval on macOS 14 Sonoma and macOS 15 Sequoia.

### 4.12 Automated CI/CD Release Pipeline
* GitHub Actions continuous integration workflow (`build-and-test.yml`) enforcing zero compiler warnings (`-warnings-as-errors`) and parallel unit test execution on `macos-14` runners.
* Automated semantic release workflow (`release.yml`) triggered on `v*` tags: imports Apple Developer certificate, builds `.app` and `.appex`, generates DMG, executes notarization, computes SHA-256 checksums, and publishes GitHub Releases.

---


## 5. Non-Functional Requirements & Performance Budgets

| Metric | Target Budget | Implementation Strategy |
|---|---|---|
| **CPU Usage (Active Transit)** | $< 0.5\%$ continuous | Event-driven notifications; zero unthrottled polling |
| **RAM Footprint** | $< 45\text{ MB}$ active & idle | Zero WebViews; pre-allocated PCM audio buffers |
| **Cold Launch Time** | $< 300\text{ ms}$ to Menu Bar | Lightweight async AppKit lifecycle |
| **Data Privacy** | 100% Local-First | Atomic JSON in `~/Library/Application Support/Karu/`; zero network calls |
