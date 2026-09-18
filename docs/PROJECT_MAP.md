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
- **`WidgetTelemetrySnapshot.swift`**: Immutable, curated 12-field telemetry contract for Desktop and Notification Center widgets.
- **`KaruPreferences.swift`**: 100% Local-First user preferences (`hasCompletedOnboarding`, `presentationMode`, `dockBadgeStyle`, `dailyFlightGoalMinutes`, `selectedMissionRole`).

---

## 3. Storage & Local Persistence (`Sources/KaruCore/Storage/`)
- **`LocalStorageManager.swift`**: Handles 100% local atomic JSON persistence in `~/Library/Application Support/Karu/` (`trips.json`, `habits.json`, `rules.json`, `vehicle.json`, `widget_snapshot.json`) with corrupted data fallback recovery.

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
  - `FocusFlightCard.swift`: Direction A luxury monochrome carbon matte boarding pass card with active telemetry, negative countdown indicator, ETA pod, luminous progress track, and accordion drawer coordinator.
  - `PreFlightDispatchDeckView.swift`: Pre-flight mission dispatch deck with dual corridor selector, 1-tap seat selector strip, destination time control, and takeoff clearance.
  - `FlightCardDrawers.swift`: Modular inline accordion slide drawers (Route, Seat, Audio, Logbook, App Radar) and custom mission input rows.
  - `OrbitingTicketPopoutView.swift`: 3D cutout pop-out orbiting boarding pass ticket with interactive tear-off and seat picker.
  - `DotMatrixLEDView.swift`: Dot matrix typography and route arrow renderers.
  - `AviationGraphicComponents.swift`: Luminous slider track, avionics ETA pod, and telemetry gauges.
- **`Widgets/`**:
  - `SmallAirspeedGaugeWidgetView.swift`: Direction A Small Widget (`systemSmall`) with circular quota progress ring and 540 kts speedometer.
  - `MediumFlightDispatchWidgetView.swift`: Direction A Medium Widget (`systemMedium`) split dispatch board with daily flight log and 1-click takeoff button.
  - `FlightTelemetryTimelineProvider.swift`: WidgetKit `TimelineProvider` loading atomic snapshots.
  - `WidgetIntents.swift`: macOS 14+ `AppIntent` handlers (`TakeoffIntent`, `GateHoldIntent`).
  - `WidgetSimulatorView.swift`: In-App Desktop Widget Simulator & Preview window (`Cmd + Shift + W`).
- **`Dock/`**:
  - `DynamicDockTileView.swift`: Mini carbon-matte cockpit avionics rendered directly in `NSApp.dockTile.contentView`.
  - `DockTelemetryManager.swift`: Coordinates live circular progress, airspeed readout, and dynamic badge string with `< 0.5%` CPU throttling.
- **`Onboarding/`**:
  - `OnboardingView.swift`: 4-stage interactive pre-flight cockpit intake window (Mission questions, 1-Click App Radar, velocity briefing, maiden takeoff ignition).
  - `OnboardingWindowController.swift`: Modal window controller presenting onboarding on first launch or via Menu bar request.
- **`Logbook/`**:
  - `LogbookView.swift`: Dedicated Pilot's Flight Logbook window (`Cmd + L`) tracking total focus flight hours, distance flown (`NM`), touchdowns, fleet on-time efficiency, and historical session logs.
- **`Garage/`**:
  - `GarageHangarView.swift`: Aircraft fleet hangar, acoustic soundscape testbed, and volume tuning.
- **`Settings/`**:
  - `AppFilterSettingsView.swift`: 1-Click Running App Radar (scans active apps with native icons), rule manager, and Display & Dock settings.
- **`Theme/`**:
  - `KaruTheme.swift`: Dark carbon matte tokens (`#08080A`, `#151518`), typography, and corner radiuses.
  - `KaruFormatters.swift`: Centralized high-performance cached formatters for timestamps, ETAs, logbook dates, ticket dates, distances, and negative countdowns.

---

## 5. Application Lifecycle, Packaging & CI/CD Pipelines
- **`KaruApp.swift`**: SwiftUI app entry point, system menu commands (`Cmd + L`, `Cmd + Shift + F`, `Cmd + Shift + G`, `Cmd + Shift + W`, `Cmd + ,`).
- **`AppDelegate.swift`**: `NSApplicationDelegate` coordinator wiring engines, window controllers, widget exporter, dock telemetry manager, onboarding controller, and `applicationDockMenu`.
- **`Packaging/`**: `Info.plist`, `WidgetInfo.plist`, `Karu.entitlements` (Hardened Runtime), `AppIcon.icns`, `generate_app_icon.swift`.
- **`scripts/`**:
  - `build_app.sh`: Automated release compilation, `.app` bundle assembly, embedded `KaruWidgets.appex` packaging, and parameterized code signing.
  - `create_dmg.sh`: Native zero-dependency Finder-styled drag-and-drop DMG builder using `hdiutil` and AppleScript layout automation.
  - `notarize_app.sh`: Apple Notary service submission (`xcrun notarytool`) and ticket stapling (`xcrun stapler`) helper.
  - `install_app.sh`: 1-command installer copying to `/Applications/` and registering with macOS LaunchServices / WidgetKit.
- **`.github/workflows/`**:
  - `build-and-test.yml`: Continuous integration workflow testing on `macos-14` with zero compiler warnings.
  - `release.yml`: Tag-triggered automated release workflow generating signed and notarized DMGs, SHA-256 checksums, and GitHub Releases.

---

## 6. Unit & Integration Tests (`Tests/KaruCoreTests/`)
- **`TransitEngineTests.swift`**: 540 kts speed calculations, gate hold pauses, turbulence encounter logging, and flight auto-completion.
- **`AppClassifierTests.swift`**: Bundle ID lookups, custom user overrides, preset evaluation, and strict mode.
- **`LocalStorageTests.swift`**: Atomic writes, disk recovery, habit streaks, preferences persistence, and trip session serialization.
- **`AudioEngineTests.swift`**: Volume ramp crossfading, audio lifecycle, and mute controls.
- **`ModelTests.swift`**: Codable compliance, KaruPreferences serialization, and domain model math verification.
- **`WidgetTelemetryTests.swift`**: Snapshot persistence, serialization & math tests.

---

## 7. Documentation & Decision Records (`docs/`)
- [PRD.md](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/PRD.md): Product requirements, personas, and feature specifications.
- [SPEC.md](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/SPEC.md): Technical specification and architectural guidelines.
- [SPEC-widget.md](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/SPEC-widget.md): Desktop flight telemetry widget specification.
- [CAPABILITY_MAP.md](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/CAPABILITY_MAP.md): Decoupled module boundaries and dependency graphs.
- [ADRs](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/decisions/): Architecture Decision Records covering ADR-001 through ADR-016.

