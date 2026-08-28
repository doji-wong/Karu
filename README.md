# Karu — Habit & Focus Timer (macOS)

> Turn deep work into a high-speed transit run. Cruise at peak velocity in your focus zone; hit gridlock when distracted.

![macOS 14.0+](https://img.shields.io/badge/macOS-14.0%2B-black?style=flat-square&logo=apple)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange?style=flat-square&logo=swift)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI%20%2B%20AppKit-blue?style=flat-square)
![Local First](https://img.shields.io/badge/Data-100%25%20Local--First-green?style=flat-square)

---

## 🧭 Overview

**Karu** is a native macOS Menu Bar & Floating HUD application for developers, students, and remote knowledge workers that replaces anxiety-inducing countdown timers with a **route navigation and traffic velocity metaphor**.

* **The Open Highway (Cruise State):** Staying active in your IDE, terminal, writing app, or study material maintains maximum cruising velocity (100 km/h) toward your destination.
* **Traffic & Detours (The Distraction Filter):** Switching into high-friction distraction apps (e.g. social media, Discord, games) creates road hazards, immediately dropping your speed to 0 km/h and stalling route progress until you steer back.
* **In-Flight Scratchpad:** Capture study notes, code snippets, or distractions during your run without leaving your active workspace.
* **Habit Engine:** Attach focus runs to daily habits and maintain streaks across sessions.

---

## 📚 Project Documentation

- 📋 [**Product Requirements Document (PRD)**](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/PRD.md)
- 🏛️ **Architecture Decision Records (ADRs):**
  - [ADR-001: Native macOS Swift / SwiftUI & AppKit Architecture](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/decisions/ADR-001-tech-stack-and-architecture.md)
  - [ADR-002: Event-Driven Distraction Detection Engine](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/decisions/ADR-002-distraction-detection-engine.md)
  - [ADR-003: Menu Bar Popover & Floating HUD Panel Architecture](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/decisions/ADR-003-hud-window-and-menubar-management.md)
  - [ADR-004: Local-First Data, Habit, and Travel Log Persistence](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/decisions/ADR-004-local-data-and-habit-persistence.md)
  - [ADR-005: MacBook Notch HUD & Side-Notch Wings Integration](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/decisions/ADR-005-notch-hud-integration.md)
  - [ADR-006: Adaptive In-Flight Ambient Audio Engine via AVAudioEngine](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/decisions/ADR-006-ambient-audio-engine.md)
  - [ADR-007: Customizable App Classification & Filter Rules Architecture](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/decisions/ADR-007-app-classification-and-custom-filters.md)

---

## 🚀 Key Interface Components

1. **Dynamic Notch Wings (MacBook Display):** Telemetry flanks the camera notch (Left: Velocity, Right: Route Progress), expanding into the cockpit dashboard on hover.
2. **Menu Bar HUD (Collapsed):** Minimalist status item in the top menu bar for external screens or non-notch setups.
3. **Diagnostic Dropdown (Expanded):** Dark-mode aerospace cockpit dashboard showing speed gauge, lane clearance, traffic stall log, and live scratchpad.
4. **Floating Cockpit Overlay:** Always-on-top translucent mini-HUD floating over full-screen IDEs and study docs.

