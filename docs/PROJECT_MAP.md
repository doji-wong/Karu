# Karu — Hierarchical Project Map

Use this map to selectively load context when working on specific features.

---

## 1. Core State Engine & Services (`Sources/KaruCore/Core/`)
- **`TransitEngine.swift`**: Manages the flight state machine (`idle`, `cruising`, `trafficStalled`, `pitStop`, `completed`), velocity telemetry (540 kts cruising vs 0 kts turbulence), distance progression in Nautical Miles (`NM`), and gate holds.
- **`DistractionMonitor.swift`**: Subscribes to `NSWorkspace.didActivateApplicationNotification`, detects frontmost application switches event-driven, and dispatches events to `AppClassifier`.
- **`AppClassifier.swift`**: Evaluates bundle IDs against custom rules, preset categories (Developer, Student, Writer), and returns `AppFocusCategory` (`focusWorkspace`, `distractionHazard`, `neutralUtility`).
- **`AudioEngine.swift`**: Manages `AVAudioEngine` ambient sound loop playback and 400ms crossfading between cruising soundscapes and turbulence audio profiles.

---

## 2. Domain Models (`Sources/KaruCore/Models/`)
- **`TransitState.swift`**: Defines `TransitState` enum, airport definitions (`DestinationAirport`), route presets (`AirportRoutePreset`), and seat classes (`FocusSeatClass`).
- **`TripSession.swift`**: Flight duration, start/end dates, preset (`sprint25`, `cruise50`, `longHaul90`, `openFlight`), cruise efficiency %, distance in NM, and turbulence encounter logs (`TurbulenceEncounter`).
- **`Habit.swift`**: Focus habit track definitions, streak counts, daily goal durations, and lifetime flight stats.
- **`VehicleProfile.swift`**: Aircraft fleet selection (`a350F`, `b787Dreamliner`, `concordeSST`, `gulfstreamG650`, `cessna172`), audio profile references, and sound configuration.
- **`AppFilterRule.swift`**: Bundle identifier rules, `AppFocusCategory`, and curated presets (`developer`, `student`, `writer`).

---

## 3. Storage & Local Persistence (`Sources/KaruCore/Storage/`)
- **`LocalStorageManager.swift`**: Handles 100% local atomic JSON persistence in `~/Library/Application Support/Karu/` (`trips.json`, `habits.json`, `rules.json`, `vehicle.json`) with corrupted data fallback recovery.

---

## 4. UI & macOS Windowing Subsystems (`Sources/Karu/UI/`)
- **`MenuBar/`**:
  - `MenuBarController.swift`: AppKit `NSStatusItem` lifecycle, dynamic state icons, and popover management.
  - `DiagnosticPopoverView.swift`: Minimalist popover container hosting the FocusFlightCard.
- **`Notch/`**:
  - `NotchWindowController.swift`: `NSPanel` overlay anchored to `NSScreen.auxiliaryTopLeftArea` / `auxiliaryTopRightArea`.
  - `NotchWingsView.swift`: Left wing (airspeed) and Right wing (ETA & route progress) SwiftUI views with hover expansions.
- **`FloatingHUD/`**:
  - `FloatingHUDPanel.swift`: Non-activating, always-on-top translucent floating overlay window.
  - `FloatingHUDView.swift`: Floating HUD container with hover actions.
- **`Aviation/`**:
  - `FocusFlightCard.swift`: Direction A luxury monochrome carbon matte boarding pass card with dual airport selection, ETA pod, luminous progress track, quick mute, and inline accordion slide drawers for airport and seat class selection.
  - `OrbitingTicketPopoutView.swift`: 3D cutout pop-out orbiting boarding pass ticket with interactive tear-off and seat picker.
  - `DotMatrixLEDView.swift`: Dot matrix typography and route arrow renderers.
  - `AviationGraphicComponents.swift`: Luminous slider track, avionics ETA pod, and telemetry gauges.
- **`Logbook/`**:
  - `LogbookView.swift`: Dedicated Pilot's Flight Logbook window (`Cmd + L`) tracking total focus flight hours, distance flown (`NM`), touchdowns, fleet on-time efficiency, and historical session logs.
- **`Garage/`**:
  - `GarageHangarView.swift`: Aircraft fleet hangar, acoustic soundscape testbed, and volume tuning.
- **`Settings/`**:
  - `AppFilterSettingsView.swift`: 1-Click Running App Radar (scans active apps with native icons) and rule manager.
- **`Theme/`**:
  - `KaruTheme.swift`: Dark carbon matte tokens (`#08080A`, `#151518`), typography, and corner radiuses.

---

## 5. Application Lifecycle (`Sources/Karu/`)
- **`KaruApp.swift`**: SwiftUI app entry point, system menu commands (`Cmd + L`, `Cmd + Shift + F`, `Cmd + Shift + G`, `Cmd + ,`).
- **`AppDelegate.swift`**: `NSApplicationDelegate` coordinator wiring engines, window controllers, and notifications.

---

## 6. Unit & Integration Tests (`Tests/KaruCoreTests/`)
- **`TransitEngineTests.swift`**: 540 kts speed calculations, gate hold pauses, turbulence encounter logging, and flight auto-completion.
- **`AppClassifierTests.swift`**: Bundle ID lookups, custom user overrides, preset evaluation, and strict mode.
- **`LocalStorageTests.swift`**: Atomic writes, disk recovery, habit streaks, and trip session serialization.
- **`AudioEngineTests.swift`**: Volume ramp crossfading, audio lifecycle, and mute controls.
- **`ModelTests.swift`**: Codable compliance and domain model math verification.

---

## 7. Documentation & Decision Records (`docs/`)
- [PRD.md](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/PRD.md): Product requirements, personas, and feature specifications.
- [SPEC.md](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/SPEC.md): Technical specification and architectural guidelines.
- [CAPABILITY_MAP.md](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/CAPABILITY_MAP.md): Decoupled module boundaries and dependency graphs.
- [ADRs](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/decisions/): Architecture Decision Records covering ADR-001 through ADR-012.
