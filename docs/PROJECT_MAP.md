# Karu — Hierarchical Project Map

Use this map to selectively load context when implementing specific features.

---

## 1. Core State Engine & Distraction Logic (`Sources/Core/`)
- **`TransitEngine.swift`**: Manages the trip state machine (`idle`, `cruising`, `trafficStalled`, `completed`), velocity calculations (100 km/h vs 0 km/h), distance progression, and pause/pit-stops.
- **`DistractionMonitor.swift`**: Subscribes to `NSWorkspace.didActivateApplicationNotification`, detects frontmost application switches, and dispatches events to `AppClassifier`.
- **`AppClassifier.swift`**: Evaluates bundle IDs against custom rules, preset categories (Developer, Student, Writer), and returns `AppFocusCategory` (`focusWorkspace`, `distractionHazard`, `neutralUtility`).
- **`AudioEngine.swift`**: Manages `AVAudioEngine` ambient sound loop playback and 400ms crossfading between cruise and traffic-stall audio profiles.

---

## 2. Domain Models (`Sources/Models/`)
- **`TripSession.swift`**: Trip duration, date, route preset (25m City Dash, 50m Expressway, 90m Interstate, Stopwatch), cruise efficiency %, and traffic incident timestamps.
- **`Habit.swift`**: Focus habit track definitions, streak counts, daily goal durations, and lifetime travel stats.
- **`VehicleProfile.swift`**: Vehicle selection (Cyber Cruiser, Sarao Jeepney, Night Rain Hatchback, Shinkansen, Coastal Bus), audio sound profile references, and gauge aesthetics.
- **`AppFilterRule.swift`**: Bundle identifier rules and whitelist/blacklist definitions.

---

## 3. Storage & Local Persistence (`Sources/Storage/`)
- **`LocalStorageManager.swift`**: Handles atomic JSON / SwiftData persistence in `Application Support/Karu/`.
- **`ScratchpadStore.swift`**: Manages live keystroke auto-saving for in-flight Markdown notes and attaches notes to completed trip records.

---

## 4. UI & macOS Windowing (`Sources/UI/`)
- **`MenuBar/`**:
  - `MenuBarController.swift`: AppKit `NSStatusItem` lifecycle and icon rendering.
  - `DiagnosticPopoverView.swift`: SwiftUI dashboard with speed gauge, lane clearance, stall incident log, and quick controls.
- **`Notch/`**:
  - `NotchWindowController.swift`: `NSPanel` overlay anchored to `NSScreen.auxiliaryTopLeftArea` / `auxiliaryTopRightArea`.
  - `NotchWingsView.swift`: Left wing (speedometer) and Right wing (ETA & route progress) SwiftUI views with hover expansions.
- **`FloatingHUD/`**:
  - `FloatingHUDPanel.swift`: Non-activating, always-on-top translucent floating overlay window.
  - `FloatingHUDView.swift`: Compact speed pill and mini-route progress bar.
- **`Scratchpad/`**:
  - `ScratchpadView.swift`: Frictionless in-flight note-taking interface.
- **`Garage/`**:
  - `GarageHangarView.swift`: Vehicle customization, soundscape auditioning, and visual theme picker.
- **`Settings/`**:
  - `AppFilterSettingsView.swift`: App whitelist/blacklist management with drag-and-drop bundle ID picker and strictness toggles.

---

## 5. Documentation & Decision Records (`docs/`)
- [PRD.md](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/PRD.md): Complete product requirements, user personas, and feature specifications.
- [ADRs](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/decisions/): Architecture Decision Records covering Tech Stack (ADR-001), Distraction Engine (ADR-002), HUD Windowing (ADR-003), Persistence (ADR-004), Notch HUD (ADR-005), Audio Engine (ADR-006), and App Classification (ADR-007).
