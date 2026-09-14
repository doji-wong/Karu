# Karu — Focus Flight & Avionics Telemetry (macOS)

> Turn deep work into an international flight run. Cruise at 540 kts in your focus zone; hit turbulence when distracted.

![macOS 14.0+](https://img.shields.io/badge/macOS-14.0%2B-black?style=flat-square&logo=apple)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange?style=flat-square&logo=swift)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI%20%2B%20AppKit-blue?style=flat-square)
![Local First](https://img.shields.io/badge/Data-100%25%20Local--First-green?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)

---

## 🧭 Overview

**Karu** is a native macOS Menu Bar & Floating HUD application for developers, students, and remote knowledge workers that replaces anxiety-inducing countdown timers with an **immersive flight navigation and air velocity metaphor**.

* **Cruising Altitude (540 kts):** Staying active in your IDE, terminal, writing app, or study material maintains maximum cruising velocity (540 kts) toward your destination.
* **In Turbulence (0 kts):** Switching into high-friction distraction apps (e.g. social media, Discord, games) creates air turbulence, immediately dropping your speed to 0 kts and freezing flight progress until you steer back.
* **Dual Airport Route Selection:** Independently select Origin and Destination IATA pairs (e.g. `YYZ ➔ HND`, `SIN ➔ LHR`, `SFO ➔ HND`) with real-time timezone conversion and cabin seat classes.
* **Inline Accordion Slide Drawers:** Zero popover clipping in floating HUDs; airport search and seat selection expand seamlessly inside the card.
* **Desktop Flight Telemetry Widgets:** Native macOS Sonoma/Sequoia Desktop Widgets (`systemSmall` speedometer gauge and `systemMedium` flight dispatch board with 1-click takeoff).
* **Dynamic Dock Tile Telemetry:** Mini cockpit progress arc and airspeed displayed on the macOS Dock tile with interactive contextual menu.
* **1-Click Running App Radar:** Scan active macOS applications with native app icons and configure whitelist/blacklist rules in 1 click.
* **Pilot's Flight Logbook (`Cmd + L`):** Track certified focus flight hours, distance flown in Nautical Miles (`NM`), touchdown streaks, and fleet on-time efficiency.
* **In-Flight Ambient Soundscapes:** Spatialized Rolls-Royce Trent and Olympus acoustic soundscapes with 400ms crossfades via `AVAudioEngine`.

---

## 🚀 Installation & Quick Start

### Option 1: Standalone Disk Image (Recommended)
Download the latest `Karu-v1.0.0.dmg` from GitHub Releases, open it, and drag **Karu** into your **Applications** folder.

### Option 2: 1-Command Local Installer (Developers)
```bash
# Clone and install directly to /Applications with widget registration
git clone https://github.com/doji-wong/Karu.git
cd Karu
./scripts/install_app.sh
```

---

## 📚 Project Documentation

- 📋 [**Product Requirements Document (PRD)**](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/PRD.md)
- 📐 [**Technical Specification (SPEC)**](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/SPEC.md)
- 🗺️ [**Capability Map**](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/CAPABILITY_MAP.md)
- 🗺️ [**Project Map**](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/PROJECT_MAP.md)
- 🏛️ **Architecture Decision Records (ADRs):**
  - [ADR-001: Native macOS Swift / SwiftUI & AppKit Architecture](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/decisions/ADR-001-tech-stack-and-architecture.md)
  - [ADR-002: Event-Driven Distraction Detection Engine](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/decisions/ADR-002-distraction-detection-engine.md)
  - [ADR-003: Menu Bar Popover & Floating HUD Panel Architecture](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/decisions/ADR-003-hud-window-and-menubar-management.md)
  - [ADR-004: Local-First Data, Habit, and Travel Log Persistence](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/decisions/ADR-004-local-data-and-habit-persistence.md)
  - [ADR-005: MacBook Notch HUD & Side-Notch Wings Integration](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/decisions/ADR-005-notch-hud-integration.md)
  - [ADR-006: Adaptive In-Flight Ambient Audio Engine via AVAudioEngine](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/decisions/ADR-006-ambient-audio-engine.md)
  - [ADR-007: Customizable App Classification & Filter Rules Architecture](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/decisions/ADR-007-app-classification-and-custom-filters.md)
  - [ADR-008: In-Flight Scratchpad Architecture (Superseded by ADR-009)](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/decisions/ADR-008-in-flight-scratchpad-architecture.md)
  - [ADR-009: Elimination of In-Flight Scratchpad for Cognitive Simplicity](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/decisions/ADR-009-scratchpad-elimination-and-cognitive-simplicity.md)
  - [ADR-010: Direction A Monochrome Avionics & Inline Accordion Drawers](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/decisions/ADR-010-monochrome-avionics-and-inline-accordion-card.md)
  - [ADR-011: Live 1-Click Running Application Radar Architecture](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/decisions/ADR-011-one-click-running-application-radar.md)
  - [ADR-012: Pilot Logbook & Flight Hours Telemetry Architecture](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/decisions/ADR-012-pilot-logbook-and-flight-hours-telemetry.md)
  - [ADR-013: Desktop Flight Telemetry Widgets & Curated Avionics Metrics](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/decisions/ADR-013-desktop-flight-telemetry-widgets.md)
  - [ADR-014: Standalone macOS Packaging, Dynamic Dock Telemetry & Pilot Onboarding](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/decisions/ADR-014-standalone-macos-packaging-and-dock-telemetry.md)
  - [ADR-015: Pre-Flight Dispatch Deck, Dynamic Route/Time Clearance & Modular Drawers](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/decisions/ADR-015-preflight-dispatch-deck-and-modular-aviation-drawers.md)

---

## 💻 Development & Packaging Commands

```bash
# Build with Warnings as Errors
swift build -Xswiftc -warnings-as-errors

# Run All Unit Tests
swift test

# Build Standalone Release Bundle (build/Karu.app)
./scripts/build_app.sh

# Build Standalone Distribution Disk Image (build/dist/Karu-v1.0.0.dmg)
./scripts/create_dmg.sh

# Install directly to /Applications with widget registration
./scripts/install_app.sh
```

---

## 📄 License
MIT License. See [LICENSE](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/LICENSE) for details.
