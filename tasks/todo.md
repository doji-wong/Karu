# Actionable Task List: Karu Implementation

## Phase 1: Package Manifest & Core Models (`karu-models`)
- [x] **Task 1.1: Create Swift Package Manifest**
  - **Acceptance:** `Package.swift` targets macOS 14+, defines `KaruCore` library, `Karu` app target, and `KaruTests` test suite.
  - **Verify:** `swift package describe`
  - **Files:** `Package.swift`
- [x] **Task 1.2: Implement Transit State & Telemetry Models**
  - **Acceptance:** `TransitState.swift` defines `.idle`, `.cruising`, `.trafficStalled`, `.pitStop`, `.completed` with velocity formatting and state indicators.
  - **Verify:** `swift test --filter ModelTests`
  - **Files:** `Sources/KaruCore/Models/TransitState.swift`
- [x] **Task 1.3: Implement App Filter Rule & Preset Models**
  - **Acceptance:** `AppFilterRule.swift` defines `AppFocusCategory`, custom bundle rules, and Developer/Student/Writer default presets.
  - **Verify:** `swift test --filter ModelTests`
  - **Files:** `Sources/KaruCore/Models/AppFilterRule.swift`
- [x] **Task 1.4: Implement Trip Session, Habit & Vehicle Models**
  - **Acceptance:** `TripSession.swift`, `Habit.swift`, and `VehicleProfile.swift` conform to `Codable`, `Identifiable`, `Sendable`.
  - **Verify:** `swift test --filter ModelTests`
  - **Files:** `Sources/KaruCore/Models/TripSession.swift`, `Sources/KaruCore/Models/Habit.swift`, `Sources/KaruCore/Models/VehicleProfile.swift`
- [x] **Task 1.5: Write Model Unit Tests**
  - **Acceptance:** `ModelTests.swift` passes 100% assertions for serialization and model logic.
  - **Verify:** `swift test --filter ModelTests`
  - **Files:** `Tests/KaruCoreTests/ModelTests.swift`

---

## Phase 2: Transit Engine & Math Core (`transit-engine`)
- [x] **Task 2.1: Implement TransitEngine State Machine**
  - **Acceptance:** Manages cruise speed (100 km/h) vs stalled speed (0 km/h), ticks, distance, and pit stops.
  - **Verify:** `swift test --filter TransitEngineTests`
  - **Files:** `Sources/KaruCore/Core/TransitEngine.swift`
- [x] **Task 2.2: Implement Efficiency Math & Incident Logging**
  - **Acceptance:** Computes cruise efficiency percentage accurately; records `TrafficIncident` events when entering stall state.
  - **Verify:** `swift test --filter TransitEngineTests`
  - **Files:** `Sources/KaruCore/Core/TransitEngine.swift`
- [x] **Task 2.3: Write TransitEngine Unit Tests**
  - **Acceptance:** Tests verify state transitions, elapsed timers, pause/resume, and math formulas.
  - **Verify:** `swift test --filter TransitEngineTests`
  - **Files:** `Tests/KaruCoreTests/TransitEngineTests.swift`

---

## Phase 3: App Classifier & Distraction Monitor (`app-classifier`)
- [x] **Task 3.1: Implement AppClassifier**
  - **Acceptance:** $O(1)$ lookup for bundle IDs with custom override > preset > neutral heuristic hierarchy.
  - **Verify:** `swift test --filter AppClassifierTests`
  - **Files:** `Sources/KaruCore/Core/AppClassifier.swift`
- [x] **Task 3.2: Implement DistractionMonitor**
  - **Acceptance:** Event-driven `NSWorkspace.didActivateApplicationNotification` listener with category dispatching.
  - **Verify:** `swift test --filter AppClassifierTests`
  - **Files:** `Sources/KaruCore/Core/DistractionMonitor.swift`
- [x] **Task 3.3: Write AppClassifier Unit Tests**
  - **Acceptance:** Verifies bundle ID categorization, presets, and override priorities.
  - **Verify:** `swift test --filter AppClassifierTests`
  - **Files:** `Tests/KaruCoreTests/AppClassifierTests.swift`

---

## Phase 4: Local Persistence & In-Flight Scratchpad (`local-storage`)
- [x] **Task 4.1: Implement LocalStorageManager**
  - **Acceptance:** Atomic JSON read/write in `Application Support/Karu/` with error recovery.
  - **Verify:** `swift test --filter LocalStorageTests`
  - **Files:** `Sources/KaruCore/Storage/LocalStorageManager.swift`
- [x] **Task 4.2: Implement ScratchpadStore**
  - **Acceptance:** Keystroke debouncing, local disk auto-save, and session travel log snapshotting.
  - **Verify:** `swift test --filter LocalStorageTests`
  - **Files:** `Sources/KaruCore/Storage/ScratchpadStore.swift`
- [x] **Task 4.3: Write LocalStorage Unit Tests**
  - **Acceptance:** Verifies roundtrip persistence, directory creation, and atomic write safety.
  - **Verify:** `swift test --filter LocalStorageTests`
  - **Files:** `Tests/KaruCoreTests/LocalStorageTests.swift`

---

## Phase 5: Ambient Audio Engine (`audio-engine`)
- [x] **Task 5.1: Implement AudioEngine with AVAudioEngine**
  - **Acceptance:** Low-latency playback with 400ms crossfade between cruise and stall nodes.
  - **Verify:** `swift test --filter AudioEngineTests`
  - **Files:** `Sources/KaruCore/Core/AudioEngine.swift`
- [x] **Task 5.2: Write AudioEngine Unit Tests**
  - **Acceptance:** Verifies volume ramps, state transitions, and node attachment.
  - **Verify:** `swift test --filter AudioEngineTests`
  - **Files:** `Tests/KaruCoreTests/AudioEngineTests.swift`

---

## Phase 6: macOS UI & Windowing Layer (`macos-windowing-ui`)
- [x] **Task 6.1: Implement KaruTheme Design System**
  - **Files:** `Sources/Karu/UI/Theme/KaruTheme.swift`
- [x] **Task 6.2: Implement MenuBarController & DiagnosticPopoverView**
  - **Files:** `Sources/Karu/UI/MenuBar/MenuBarController.swift`, `Sources/Karu/UI/MenuBar/DiagnosticPopoverView.swift`
- [x] **Task 6.3: Implement NotchWindowController & NotchWingsView**
  - **Files:** `Sources/Karu/UI/Notch/NotchWindowController.swift`, `Sources/Karu/UI/Notch/NotchWingsView.swift`
- [x] **Task 6.4: Implement FloatingHUDPanel & FloatingHUDView**
  - **Files:** `Sources/Karu/UI/FloatingHUD/FloatingHUDPanel.swift`, `Sources/Karu/UI/FloatingHUD/FloatingHUDView.swift`
- [x] **Task 6.5: Implement ScratchpadView, GarageHangarView & Settings**
  - **Files:** `Sources/Karu/UI/Scratchpad/ScratchpadView.swift`, `Sources/Karu/UI/Garage/GarageHangarView.swift`, `Sources/Karu/UI/Settings/AppFilterSettingsView.swift`
- [x] **Task 6.6: Wire App Entry Point (KaruApp & AppDelegate)**
  - **Files:** `Sources/Karu/KaruApp.swift`, `Sources/Karu/AppDelegate.swift`

---

## Phase 7: Edge-Docked Sidebar & Navigation Cockpit (`sidebar-cockpit`)
- [x] **Task 7.1: Implement Edge-Docked Sidebar HUD Panel**
  - **Acceptance:** Full-height right-bezel drawer with smooth slide toggle and screen parameter resilience.
  - **Files:** `Sources/Karu/UI/Sidebar/SidebarHUDPanel.swift`, `Sources/Karu/UI/Sidebar/SidebarHUDView.swift`, `Sources/Karu/UI/Sidebar/SidebarNotchView.swift`
- [x] **Task 7.2: Implement Modular Cockpit Cards**
  - **Acceptance:** Reusable `DeskMinderTransitCard`, `CockpitDialCard`, and `AviationFlightCard` for modular HUD assembly.
  - **Files:** `Sources/Karu/UI/Aviation/`, `Sources/Karu/UI/Sidebar/ModularWidgets.swift`
- [x] **Task 7.3: Implement Highway Navigation & Route Radar**
  - **Acceptance:** Waze-style route simulation, waypoint progress, and live lane clearance indicators.
  - **Files:** `Sources/Karu/UI/Navigation/HighwayNavigationView.swift`, `LiveRouteTrackingView.swift`, `OpenFreeMapView.swift`
- [x] **Task 7.4: Implement Vehicle Digital Twin & SpaceX Telemetry**
  - **Acceptance:** Animated vehicle visualizer with wheel spin physics and mission-control telemetry styling.
  - **Files:** `Sources/Karu/UI/Theme/VehicleDigitalTwinView.swift`, `Sources/Karu/UI/Theme/SpaceXTelemetryViews.swift`

---

## Phase 8: Context Optimization & Release Hardening (`quality-and-release`)
- [x] **Task 8.1: Context Engineering & Documentation Sync**
  - **Acceptance:** Sync `AGENTS.md`, `GEMINI.md`, `CLAUDE.md`, `docs/PROJECT_MAP.md`, `docs/CAPABILITY_MAP.md`, `.agents/rules/`.
- [x] **Task 8.2: Strict Compilation & Test Verification**
  - **Acceptance:** `swift build -Xswiftc -warnings-as-errors` and `swift test` pass with 100% assertions.
- [ ] **Task 8.3: Release Packaging & App Icon Asset Bundle**
  - **Acceptance:** `.app` bundle build script and asset catalog generation for macOS distribution.

