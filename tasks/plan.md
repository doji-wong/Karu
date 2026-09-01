# Technical Implementation Plan: Karu (Focus Flight & Avionics Telemetry)

This plan outlines the sequenced execution phases for Karu, establishing clear validation gates between phases.

---

## 🚦 Phase Sequencing & Verification Gates

### Phase 1: Foundation & Aviation Models (`karu-models`) — [COMPLETED]
- **Deliverables:** `Package.swift`, `TransitState.swift`, `AppFilterRule.swift`, `TripSession.swift`, `Habit.swift`, `VehicleProfile.swift` (`AircraftType`).
- **Tests:** `ModelTests.swift` validating serialization, presets, timezones, and model math.
- **Verification Gate:** `swift build && swift test` passes with zero warnings.

---

### Phase 2: Flight Engine & Velocity Core (`transit-engine`) — [COMPLETED]
- **Deliverables:** `TransitEngine.swift` managing velocity telemetry (540 kts cruise vs 0 kts turbulence), state machine (`idle` $\to$ `cruising` $\to$ `trafficStalled` $\to$ `pitStop` $\to$ `completed`), tick mechanics, and on-time flight efficiency formulas.
- **Tests:** `TransitEngineTests.swift` validating airspeed transitions, efficiency calculations, and turbulence encounter tracking.
- **Verification Gate:** `swift test --filter TransitEngineTests` passes with 100% assertions satisfied.

---

### Phase 3: Distraction Detection & App Classifier (`app-classifier`) — [COMPLETED]
- **Deliverables:** `AppClassifier.swift` ($O(1)$ bundle ID lookup with preset fallbacks) and `DistractionMonitor.swift` (event-driven `NSWorkspace` listener).
- **Tests:** `AppClassifierTests.swift` validating preset rules, user custom overrides, and event dispatching.
- **Verification Gate:** `swift test --filter AppClassifierTests` passes.

---

### Phase 4: Local Storage & Data Persistence (`local-storage`) — [COMPLETED]
- **Deliverables:** `LocalStorageManager.swift` (atomic JSON read/write in `Application Support/Karu/` for trips, habits, rules, and fleet preferences).
- **Tests:** `LocalStorageTests.swift` validating atomic persistence, data integrity, and recovery.
- **Verification Gate:** `swift test --filter LocalStorageTests` passes.

---

### Phase 5: Ambient Audio Engine (`audio-engine`) — [COMPLETED]
- **Deliverables:** `AudioEngine.swift` with `AVAudioEngine`, `AVAudioPlayerNode`, `AVAudioMixerNode`, dual-tone seatbelt sign chime, and 400ms crossfader across 5 aircraft soundscapes.
- **Tests:** `AudioEngineTests.swift` validating volume ramping and node lifecycle.
- **Verification Gate:** `swift test --filter AudioEngineTests` passes.

---

### Phase 6: Direction A Avionics UI & Boarding Pass (`macos-windowing-ui`) — [COMPLETED]
- **Deliverables:**
  - Pure Carbon Matte Theme (`KaruTheme.swift`) & Dot Matrix LED Typography (`DotMatrixLEDView.swift`)
  - Menu Bar Status Item & Dashboard Popover (`MenuBarController.swift`, `DiagnosticPopoverView.swift`)
  - MacBook Hardware Notch Wings (`NotchWindowController.swift`, `NotchWingsView.swift`)
  - Floating HUD Overlay (`FloatingHUDPanel.swift`, `FloatingHUDView.swift`)
  - Direction A Focus Flight Card (`FocusFlightCard.swift`) with Dual Airport Route Selection and Smooth Inline Accordion Slide Drawers
  - Pilot's Flight Logbook Window (`LogbookView.swift` / `Cmd + L`)
  - 1-Click Running App Radar in Preferences (`AppFilterSettingsView.swift`)
  - Aircraft Fleet Hangar (`GarageHangarView.swift`)
  - App Entry Bridge (`KaruApp.swift`, `AppDelegate.swift`)
- **Verification Gate:** `swift build -Xswiftc -warnings-as-errors` passes; `swift test` passes 31/31 tests.

---

### Phase 8: Desktop Flight Telemetry Widgets (`widget-telemetry`) — [COMPLETED]
- **Deliverables:**
  - Data Contract & Snapshot Exporter (`WidgetTelemetrySnapshot.swift`, `LocalStorageManager.swift`)
  - Direction A Small Airspeed Gauge & Quota Widget View (`SmallAirspeedGaugeWidgetView.swift`)
  - Direction A Medium Flight Dispatch Board Widget View (`MediumFlightDispatchWidgetView.swift`)
  - WidgetKit Timeline Provider & App Intents & In-App Simulator (`FlightTelemetryTimelineProvider.swift`, `WidgetIntents.swift`, `WidgetSimulatorView.swift`)
- **Tests:** `WidgetTelemetryTests.swift` validating snapshot decoding, data export on state transitions, and fallback resilience.
- **Verification Gate:** `swift build -Xswiftc -warnings-as-errors` and all unit tests pass.

---

### Phase 9: Standalone Distribution Packaging, Dynamic Dock Telemetry & Onboarding — [COMPLETED]
- **Deliverables:**
  - Standalone Application packager (`scripts/build_app.sh`, `scripts/generate_app_icon.swift`, `Packaging/Info.plist`)
  - Dynamic Dock Tile Telemetry (`DynamicDockTileView.swift`, `DockTelemetryManager.swift`, `applicationDockMenu`)
  - 4-Stage First-Time Pilot Onboarding Briefing (`OnboardingView.swift`, `OnboardingWindowController.swift`)
- **Tests:** `swift test` and standalone `.app` assembly verified.

---

### Phase 10: Performance, Battery & Memory Optimization (`perf-optimization`) — [PLANNED]
- **Deliverables:**
  - **AudioEngine CoreAudio Low-Power Lifecycle:** Automatic sleep/pause when idle/paused/completed/muted; on-demand activation; 2.0s optimized audio buffers.
  - **TransitEngine Kernel Timer Coalescing:** Timer tolerance (0.1s) and `.common` run loop mode for low-power operation.
  - **LocalStorageManager In-Memory Caching:** Thread-safe memory cache for instant O(1) reads and reduced disk I/O.
  - **App Radar Icon Downscaler & Cache:** 48x48 pt thumbnails reducing RAM by 50-80 MB.
  - **AppClassifier Atomic Lock Optimizations:** Zero lock-thrashing cache rebuilds.
- **Tests:** `AudioEngineTests`, `LocalStorageTests`, `TransitEngineTests`, `AppClassifierTests`.
- **Verification Gate:** `swift test` passes 100%, CPU idle < 0.1%, RAM < 45 MB.

---

### Phase 11: Native macOS Desktop Widget Extension Packaging (`widget-appex`) — [PLANNED]
- **Deliverables:**
  - `KaruWidgets.swift`: `@main struct KaruWidgetBundle: WidgetBundle`, `SmallAirspeedGaugeWidget: Widget`, and `MediumFlightDispatchWidget: Widget`.
  - `Packaging/WidgetInfo.plist`: Extension point `com.apple.widgetkit-extension`.
  - `Package.swift`: `KaruWidgets` target definition.
  - `scripts/build_app.sh`: Automated compilation and embedding of `Contents/PlugIns/KaruWidgets.appex` inside `Karu.app`.
  - `scripts/install_app.sh`: 1-click install to `/Applications/Karu.app` and system LaunchServices / WidgetKit registration so Karu widgets immediately appear in the macOS Desktop Widget Gallery ("Edit Widgets...").
- **Verification Gate:** `build/Karu.app/Contents/PlugIns/KaruWidgets.appex` verified; code-signed; detected by macOS WidgetKit.
