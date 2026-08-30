# Karu — Hierarchical Project Map

Use this map to selectively load context when implementing specific features.

---

## 1. Core State Engine & Services (`Sources/KaruCore/Core/`)
- **`TransitEngine.swift`**: Manages the trip state machine (`idle`, `cruising`, `trafficStalled`, `pitStop`, `completed`), velocity calculation (100 km/h cruising vs 0 km/h gridlock), distance progression, and pause/pit-stops.
- **`DistractionMonitor.swift`**: Subscribes to `NSWorkspace.didActivateApplicationNotification`, detects frontmost application switches, and dispatches events to `AppClassifier`.
- **`AppClassifier.swift`**: Evaluates bundle IDs against custom rules, preset categories (Developer, Student, Writer), and returns `AppFocusCategory` (`focusWorkspace`, `distractionHazard`, `neutralUtility`).
- **`AudioEngine.swift`**: Manages `AVAudioEngine` ambient sound loop playback and 400ms crossfading between cruise and traffic-stall audio profiles.

---

## 2. Domain Models (`Sources/KaruCore/Models/`)
- **`TransitState.swift`**: Defines `TransitState` enum (`idle`, `cruising`, `trafficStalled`, `pitStop`, `completed`), target velocity, and `CityRoutePreset` definitions.
- **`TripSession.swift`**: Trip duration, date, route preset (25m City Dash, 50m Expressway, 90m Interstate, Stopwatch), cruise efficiency %, and traffic incident logs (`TrafficIncident`).
- **`Habit.swift`**: Focus habit track definitions, streak counts, daily goal durations, and lifetime travel stats.
- **`VehicleProfile.swift`**: Vehicle selection (Cyber Cruiser, Sarao Jeepney, Night Rain Hatchback, Shinkansen, Coastal Bus), audio sound profile references, and gauge aesthetics.
- **`AppFilterRule.swift`**: Bundle identifier rules, `AppFocusCategory`, and curated presets (`developer`, `student`, `writer`).

---

## 3. Storage & Local Persistence (`Sources/KaruCore/Storage/`)
- **`LocalStorageManager.swift`**: Handles 100% local atomic JSON persistence in `~/Library/Application Support/Karu/` with corrupted data fallback recovery.
- **`ScratchpadStore.swift`**: Manages live keystroke auto-saving for in-flight Markdown notes and attaches notes to completed trip records.

---

## 4. UI & macOS Windowing Subsystems (`Sources/Karu/UI/`)
- **`MenuBar/`**:
  - `MenuBarController.swift`: AppKit `NSStatusItem` lifecycle, dynamic state icons, and popover management.
  - `DiagnosticPopoverView.swift`: SwiftUI dashboard with speed gauge, lane clearance, stall incident log, route selector, and quick controls.
- **`Notch/`**:
  - `NotchWindowController.swift`: `NSPanel` overlay anchored to `NSScreen.auxiliaryTopLeftArea` / `auxiliaryTopRightArea`.
  - `NotchWingsView.swift`: Left wing (speedometer) and Right wing (ETA & route progress) SwiftUI views with hover expansions.
- **`FloatingHUD/`**:
  - `FloatingHUDPanel.swift`: Non-activating, always-on-top translucent floating overlay window.
  - `FloatingHUDView.swift`: Compact speed pill and mini-route progress bar.
- **`Sidebar/`**:
  - `SidebarHUDPanel.swift`: Edge-docked right-screen drawer panel with smooth hover & slide transitions.
  - `SidebarHUDView.swift`: Full-height sidebar hosting telemetry, route tracker, and modular cockpit widgets.
  - `SidebarNotchView.swift`: Bezel notch tab indicating transit state and slide-out trigger.
  - `ModularWidgets.swift`: Reusable cockpit widgets (speed gauge, trip progress, incident timeline, habit streak).
- **`Aviation/`**:
  - `AviationFlightCard.swift`: High-tech aerospace telemetry HUD card.
  - `CockpitDialCard.swift`: Radial analog/digital speedometer dial card.
  - `DeskMinderTransitCard.swift`: Minimalist desk-minder transit card with route selector and one-click controls.
- **`Navigation/`**:
  - `HighwayNavigationView.swift`: Waze-style route simulation and turn-by-turn focus milestones.
  - `LiveRouteTrackingView.swift`: Real-time highway clearance radar and waypoint progress.
  - `OpenFreeMapView.swift`: Vector map canvas rendering simulated transit paths across city presets.
- **`Theme/`**:
  - `KaruTheme.swift`: Dark OLED aerospace color tokens (`#0A0B0E`), glowing gradients, and glassmorphism styles.
  - `SpaceXTelemetryViews.swift`: Mission-control styled telemetry counters and altitude/speed readouts.
  - `VehicleDigitalTwinView.swift`: Animated visual representation of active vehicle and wheel dynamics.
- **`Garage/`**:
  - `GarageHangarView.swift`: Vehicle customization, soundscape auditioning, and visual theme picker.
- **`Scratchpad/`**:
  - `ScratchpadView.swift`: Frictionless in-flight note-taking interface with instant auto-save.
- **`Settings/`**:
  - `AppFilterSettingsView.swift`: App whitelist/blacklist management with bundle ID picker and strictness toggles.

---

## 5. Application Lifecycle (`Sources/Karu/`)
- **`KaruApp.swift`**: SwiftUI app entry point, system settings, and global keyboard shortcuts.
- **`AppDelegate.swift`**: `NSApplicationDelegate` coordinator wiring engines, window controllers, and notifications.

---

## 6. Unit & Integration Tests (`Tests/KaruCoreTests/`)
- **`TransitEngineTests.swift`**: Speed calculations, pause/pit-stops, incident logging, and auto-completion.
- **`AppClassifierTests.swift`**: Bundle ID lookups, custom user overrides, preset evaluation, and strict mode.
- **`LocalStorageTests.swift`**: Atomic writes, disk recovery, habit streaks, and trip session serialization.
- **`AudioEngineTests.swift`**: Volume ramp crossfading, audio lifecycle, and mute controls.
- **`ModelTests.swift`**: Codable compliance and domain model math verification.

---

## 7. Documentation & Decision Records (`docs/`)
- [PRD.md](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/PRD.md): Complete product requirements, personas, and feature specifications.
- [SPEC.md](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/SPEC.md): Full technical specification and API contracts.
- [CAPABILITY_MAP.md](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/CAPABILITY_MAP.md): Decoupled module boundaries and dependency graphs.
- [ADRs](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/decisions/): Architecture Decision Records covering Tech Stack (ADR-001) through In-Flight Scratchpad (ADR-008).

