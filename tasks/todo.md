# Actionable Task List: Karu Implementation

## Phase 1: Package Manifest & Core Models (`karu-models`)
- [x] **Task 1.1: Create Swift Package Manifest**
  - **Acceptance:** `Package.swift` targets macOS 14+, defines `KaruCore` library, `Karu` app target, and `KaruTests` test suite.
  - **Verify:** `swift package describe`
  - **Files:** `Package.swift`
- [x] **Task 1.2: Implement Transit State & Telemetry Models**
  - **Acceptance:** `TransitState.swift` defines `.idle`, `.cruising`, `.trafficStalled`, `.pitStop`, `.completed` with 540 kts velocity and airport definitions (`DestinationAirport`).
  - **Verify:** `swift test --filter ModelTests`
  - **Files:** `Sources/KaruCore/Models/TransitState.swift`
- [x] **Task 1.3: Implement App Filter Rule & Preset Models**
  - **Acceptance:** `AppFilterRule.swift` defines `AppFocusCategory`, custom bundle rules, and Developer/Student/Writer default presets.
  - **Verify:** `swift test --filter ModelTests`
  - **Files:** `Sources/KaruCore/Models/AppFilterRule.swift`
- [x] **Task 1.4: Implement Trip Session, Habit & Aircraft Models**
  - **Acceptance:** `TripSession.swift`, `Habit.swift`, and `VehicleProfile.swift` conform to `Codable`, `Identifiable`, `Sendable` with `TurbulenceEncounter` and `AircraftType`.
  - **Verify:** `swift test --filter ModelTests`
  - **Files:** `Sources/KaruCore/Models/TripSession.swift`, `Sources/KaruCore/Models/Habit.swift`, `Sources/KaruCore/Models/VehicleProfile.swift`
- [x] **Task 1.5: Write Model Unit Tests**
  - **Acceptance:** `ModelTests.swift` passes 100% assertions for serialization and model logic.
  - **Verify:** `swift test --filter ModelTests`
  - **Files:** `Tests/KaruCoreTests/ModelTests.swift`

---

## Phase 2: Flight Engine & Velocity Core (`transit-engine`)
- [x] **Task 2.1: Implement TransitEngine State Machine**
  - **Acceptance:** Manages cruise speed (540 kts) vs turbulence speed (0 kts), ticks, distance (NM), and gate holds.
  - **Verify:** `swift test --filter TransitEngineTests`
  - **Files:** `Sources/KaruCore/Core/TransitEngine.swift`
- [x] **Task 2.2: Implement Efficiency Math & Turbulence Logging**
  - **Acceptance:** Computes cruise efficiency percentage accurately; records `TurbulenceEncounter` events when entering stall state.
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

## Phase 4: Local Persistence & Storage (`local-storage`)
- [x] **Task 4.1: Implement LocalStorageManager**
  - **Acceptance:** Atomic JSON read/write in `Application Support/Karu/` for trips, habits, rules, and fleet preferences with error recovery.
  - **Verify:** `swift test --filter LocalStorageTests`
  - **Files:** `Sources/KaruCore/Storage/LocalStorageManager.swift`
- [x] **Task 4.2: Write LocalStorage Unit Tests**
  - **Acceptance:** Verifies roundtrip persistence, directory creation, and atomic write safety.
  - **Verify:** `swift test --filter LocalStorageTests`
  - **Files:** `Tests/KaruCoreTests/LocalStorageTests.swift`

---

## Phase 5: Ambient Audio Engine (`audio-engine`)
- [x] **Task 5.1: Implement AudioEngine with AVAudioEngine**
  - **Acceptance:** Low-latency playback with 400ms crossfade between cruise and stall nodes, seatbelt chime, and 5 aircraft soundscapes.
  - **Verify:** `swift test --filter AudioEngineTests`
  - **Files:** `Sources/KaruCore/Core/AudioEngine.swift`
- [x] **Task 5.2: Write AudioEngine Unit Tests**
  - **Acceptance:** Verifies volume ramps, state transitions, and node attachment.
  - **Verify:** `swift test --filter AudioEngineTests`
  - **Files:** `Tests/KaruCoreTests/AudioEngineTests.swift`

---

## Phase 6: macOS UI & Windowing Layer (`macos-windowing-ui`)
- [x] **Task 6.1: Implement KaruTheme & Graphic Components**
  - **Files:** `Sources/Karu/UI/Theme/KaruTheme.swift`, `DotMatrixLEDView.swift`, `AviationGraphicComponents.swift`
- [x] **Task 6.2: Implement MenuBarController & DiagnosticPopoverView**
  - **Files:** `Sources/Karu/UI/MenuBar/MenuBarController.swift`, `Sources/Karu/UI/MenuBar/DiagnosticPopoverView.swift`
- [x] **Task 6.3: Implement NotchWindowController & NotchWingsView**
  - **Files:** `Sources/Karu/UI/Notch/NotchWindowController.swift`, `Sources/Karu/UI/Notch/NotchWingsView.swift`
- [x] **Task 6.4: Implement FloatingHUDPanel & FloatingHUDView**
  - **Files:** `Sources/Karu/UI/FloatingHUD/FloatingHUDPanel.swift`, `Sources/Karu/UI/FloatingHUD/FloatingHUDView.swift`
- [x] **Task 6.5: Implement FocusFlightCard with Dual Airport Selector & Inline Accordion Drawers**
  - **Files:** `Sources/Karu/UI/Aviation/FocusFlightCard.swift`
- [x] **Task 6.6: Implement 1-Click Running App Radar in Settings**
  - **Files:** `Sources/Karu/UI/Settings/AppFilterSettingsView.swift`
- [x] **Task 6.7: Implement Pilot's Flight Logbook Window (Cmd + L)**
  - **Files:** `Sources/Karu/UI/Logbook/LogbookView.swift`
- [x] **Task 6.8: Implement Aircraft Fleet Hangar**
  - **Files:** `Sources/Karu/UI/Garage/GarageHangarView.swift`
- [x] **Task 6.9: Wire App Entry Point (KaruApp & AppDelegate)**
  - **Files:** `Sources/Karu/KaruApp.swift`, `Sources/Karu/AppDelegate.swift`

---

## Phase 7: Quality Verification & Release Readiness (`quality-and-release`)
- [x] **Task 7.1: Strict Compilation & Test Verification**
  - **Acceptance:** `swift build -Xswiftc -warnings-as-errors` passes with 0 warnings; `swift test` passes 31/31 tests.
- [x] **Task 7.2: Documentation & ADR Updates**
  - **Acceptance:** ADR-001 through ADR-012 recorded; SPEC.md, PRD.md, PROJECT_MAP.md, CAPABILITY_MAP.md updated.
- [x] **Task 7.3: Distribution Packaging (.app bundle)**
  - **Acceptance:** Application bundle packaging and asset catalog setup.
  - **Verify:** `./scripts/build_app.sh`
  - **Files:** `Packaging/Info.plist`, `scripts/generate_app_icon.swift`, `scripts/build_app.sh`

---

## Phase 8: Desktop Flight Telemetry Widgets (`widget-telemetry`)
- [x] **Task 8.1: Implement `WidgetTelemetrySnapshot` Domain Model**
  - **Acceptance:** `WidgetTelemetrySnapshot.swift` conforms to `Codable`, `Sendable`, `Equatable`, encapsulating state, airspeed, route, distance, efficiency %, daily quota, streak, and aircraft profile.
  - **Verify:** `swift test --filter WidgetTelemetryTests`
  - **Files:** `Sources/KaruCore/Models/WidgetTelemetrySnapshot.swift`
- [x] **Task 8.2: Implement Local Storage Snapshot Exporter in `KaruCore`**
  - **Acceptance:** `LocalStorageManager` supports `saveWidgetSnapshot(_:)` and `loadWidgetSnapshot()` with atomic persistence and fallback recovery.
  - **Verify:** `swift test --filter WidgetTelemetryTests`
  - **Files:** `Sources/KaruCore/Storage/LocalStorageManager.swift`
- [x] **Task 8.3: Write `WidgetTelemetryTests` Suite**
  - **Acceptance:** Unit tests verify snapshot creation, serialization roundtrip, and corrupted JSON fallback.
  - **Verify:** `swift test --filter WidgetTelemetryTests`
  - **Files:** `Tests/KaruCoreTests/WidgetTelemetryTests.swift`
- [x] **Task 8.4: Implement Direction A Small Airspeed Gauge Widget (`SmallAirspeedGaugeWidgetView`)**
  - **Acceptance:** Renders circular progress ring (`dailyCompletedMinutes / dailyGoalMinutes`), prominent `540 KTS` airspeed readout, streak badge (`🔥 12d`), and aircraft badge (`A350F`) in `#08080A` carbon matte aesthetic.
  - **Verify:** `swift build`
  - **Files:** `Sources/Karu/UI/Widgets/SmallAirspeedGaugeWidgetView.swift`
- [x] **Task 8.5: Implement Direction A Medium Flight Dispatch Board Widget (`MediumFlightDispatchWidgetView`)**
  - **Acceptance:** Renders dual-column avionics terminal: Left pane displays Today's Flight Log (Hours, NM, Efficiency %, Goal bar); Right pane displays Route (`SFO ✈ HND`), status badge (`CRUISING 540 kts`), and 1-Click Takeoff button.
  - **Verify:** `swift build`
  - **Files:** `Sources/Karu/UI/Widgets/MediumFlightDispatchWidgetView.swift`
- [x] **Task 8.6: Implement Timeline Provider & App Intents & In-App Simulator**
  - **Acceptance:** `FlightTelemetryTimelineProvider.swift`, `WidgetIntents.swift`, and `WidgetSimulatorView.swift` provide TimelineProvider, AppIntents for 1-click takeoff and gate hold, and in-app simulator (`Cmd + Shift + W`).
  - **Verify:** `swift build`
  - **Files:** `Sources/Karu/UI/Widgets/FlightTelemetryTimelineProvider.swift`, `Sources/Karu/UI/Widgets/WidgetIntents.swift`, `Sources/Karu/UI/Widgets/WidgetSimulatorView.swift`
- [x] **Task 8.7: Wire Engine State Transitions to Snapshot Exporter & Full Verification**
  - **Acceptance:** Engine state transitions automatically update `widget_snapshot.json`; `swift build -Xswiftc -warnings-as-errors` and all 35 tests pass cleanly.
  - **Verify:** `swift test && swift build -Xswiftc -warnings-as-errors`
  - **Files:** `Sources/Karu/AppDelegate.swift`, `Sources/KaruCore/Core/TransitEngine.swift`

---

## Phase 9: Standalone Distribution Packaging, Dynamic Dock Telemetry & First-Time Onboarding (`packaging-dock-onboarding`)
- [x] **Task 9.1: Implement App Icon Asset Pipeline & Packaging Pipeline**
  - **Acceptance:** `generate_app_icon.swift` programmatically draws 10 standard Apple squircle icon sizes and compiles `AppIcon.icns`; `build_app.sh` compiles release binary, builds `build/Karu.app`, codesigns ad-hoc, and produces `build/dist/Karu-v1.0.0-macOS.zip`.
  - **Verify:** `./scripts/build_app.sh`
  - **Files:** `Packaging/Info.plist`, `scripts/generate_app_icon.swift`, `scripts/build_app.sh`
- [x] **Task 9.2: Implement `KaruPreferences` & Local Storage Persistence**
  - **Acceptance:** `KaruPreferences.swift` models onboarding status, presentation modes (`.standardDock` vs `.menuBarOnly`), dock badge styles, and daily flight goals; persisted atomically in `preferences.json`.
  - **Verify:** `swift test --filter LocalStorageTests`
  - **Files:** `Sources/KaruCore/Models/KaruPreferences.swift`, `Sources/KaruCore/Storage/LocalStorageManager.swift`
- [x] **Task 9.3: Implement Dynamic Dock Telemetry View & Manager (`NSDockTile`)**
  - **Acceptance:** `DynamicDockTileView.swift` and `DockTelemetryManager.swift` render live circular flight progress rings, airspeed velocity (`540 KTS`), and state badges on the macOS Dock icon with `< 0.5%` CPU throttling.
  - **Verify:** `swift build -Xswiftc -warnings-as-errors`
  - **Files:** `Sources/Karu/UI/Dock/DynamicDockTileView.swift`, `Sources/Karu/UI/Dock/DockTelemetryManager.swift`
- [x] **Task 9.4: Implement Dynamic Dock Context Menu (`applicationDockMenu`)**
  - **Acceptance:** `AppDelegate.applicationDockMenu(_:)` delivers live telemetry status, 1-click takeoff/gate hold/touchdown/abort flight dispatch controls, and cockpit window shortcuts.
  - **Verify:** `swift build`
  - **Files:** `Sources/Karu/AppDelegate.swift`
- [x] **Task 9.5: Implement First-Time Pilot Onboarding ("Pre-Flight Cockpit Briefing")**
  - **Acceptance:** 4-stage interactive modal window (`OnboardingView.swift` & `OnboardingWindowController.swift`) prompting mission questions, 1-Click workspace radar app scanning, velocity mental model briefing, and maiden takeoff ignition.
  - **Verify:** `swift build -Xswiftc -warnings-as-errors`
  - **Files:** `Sources/Karu/UI/Onboarding/OnboardingView.swift`, `Sources/Karu/UI/Onboarding/OnboardingWindowController.swift`
- [x] **Task 9.6: Implement Display & Dock Settings & Replay Briefing Action**
  - **Acceptance:** `AppFilterSettingsView.swift` includes "Display & Dock" tab for presentation mode, dock badge style, dynamic dock graphics toggle, and "Replay Cockpit Briefing...".
  - **Verify:** `swift build`
  - **Files:** `Sources/Karu/UI/Settings/AppFilterSettingsView.swift`, `Sources/Karu/KaruApp.swift`
- [x] **Task 9.7: Record ADR-014 & Full Verification**
  - **Acceptance:** ADR-014 recorded; `swift build -Xswiftc -warnings-as-errors` and all 37 tests pass with 0 errors/warnings.
  - **Verify:** `swift test && swift build -Xswiftc -warnings-as-errors`
  - **Files:** `docs/decisions/ADR-014-standalone-macos-packaging-and-dock-telemetry.md`

---

## Phase 10: Performance, Battery & Memory Optimization (`perf-optimization`)

- [x] **Task 10.1: CoreAudio Adaptive Low-Power Lifecycle in `AudioEngine`**
  - **Description:** Implement adaptive power management in `AudioEngine` to pause/stop `AVAudioEngine` and player node DSP loops when in `.idle`, `.completed`, `.pitStop`, or muted states, letting macOS CPU cores and audio hardware enter low-power sleep states. Optimize audio buffer synthesis to 2.0s seamless loops.
  - **Acceptance Criteria:**
    - `AudioEngine` is paused when no sound is actively required.
    - Transitions to `.cruising` / `.trafficStalled` wake audio on demand.
    - Audio synthesis memory is reduced by 50%.
  - **Verify:** `swift test --filter AudioEngineTests`
  - **Files:** `Sources/KaruCore/Core/AudioEngine.swift`
  - **Scope:** Small (1 file)

- [x] **Task 10.2: Kernel Timer Coalescing & Tolerance in `TransitEngine`**
  - **Description:** Configure `timer.tolerance = 0.1` and add the timer to `RunLoop.main` in `.common` mode to allow kernel wakeup coalescing and prevent timer starvation during UI interactions.
  - **Acceptance Criteria:**
    - Timer uses 100ms tolerance for power coalescing.
    - Timer operates in `.common` mode.
  - **Verify:** `swift test --filter TransitEngineTests`
  - **Files:** `Sources/KaruCore/Core/TransitEngine.swift`
  - **Scope:** XS (1 file)

- [x] **Task 10.3: Thread-Safe In-Memory JSON Caching in `LocalStorageManager`**
  - **Description:** Add in-memory caching to `LocalStorageManager` for preferences, vehicle profiles, habits, custom rules, and widget snapshots to eliminate redundant disk reads and JSON parsing during background ticks.
  - **Acceptance Criteria:**
    - Loads return cached models in O(1) memory lookup.
    - Saves update cache and write atomically to disk.
  - **Verify:** `swift test --filter LocalStorageTests`
  - **Files:** `Sources/KaruCore/Storage/LocalStorageManager.swift`
  - **Scope:** Small (1 file)

- [x] **Task 10.4: App Radar Icon Downscaling & Caching**
  - **Description:** Implement 48x48 pt downscaling and memory caching for running application icons in `AppFilterSettingsView` and `OnboardingView` to reduce memory footprint by 50-80 MB.
  - **Acceptance Criteria:**
    - Icons are resized to thumbnail dimensions before storage.
    - App memory usage stays < 45 MB with 40+ running apps.
  - **Verify:** `swift build -Xswiftc -warnings-as-errors`
  - **Files:** `Sources/Karu/UI/Settings/AppFilterSettingsView.swift`, `Sources/Karu/UI/Onboarding/OnboardingView.swift`
  - **Scope:** Small (2 files)

- [x] **Task 10.5: Atomic Lock Optimizations in `AppClassifier`**
  - **Description:** Refactor `AppClassifier` cache rebuilding to execute inside the locked critical section, eliminating lock thrashing.
  - **Acceptance Criteria:**
    - `setPreset`, `setCustomRule`, and `removeCustomRule` rebuild cache atomically within a single lock acquisition.
  - **Verify:** `swift test --filter AppClassifierTests`
  - **Files:** `Sources/KaruCore/Core/AppClassifier.swift`
  - **Scope:** XS (1 file)

### Checkpoint: Performance & Battery Optimization
- [x] All unit tests pass cleanly (`swift test`)
- [x] Build succeeds with zero warnings (`swift build -Xswiftc -warnings-as-errors`)

---

## Phase 11: Native macOS Desktop Widget Extension Packaging & Registration (`widget-appex`)

- [x] **Task 11.1: Implement `KaruWidgets.swift` (`WidgetBundle`)**
  - **Description:** Create the native Widget entry point conforming to `WidgetBundle`, containing `SmallAirspeedGaugeWidget` (`systemSmall`) and `MediumFlightDispatchWidget` (`systemMedium`), hooked to `FlightTelemetryTimelineProvider`.
  - **Acceptance Criteria:**
    - Declares `@main struct KaruWidgetBundle: WidgetBundle`.
    - Declares `SmallAirspeedGaugeWidget` and `MediumFlightDispatchWidget` with correct metadata, descriptions, and `.containerBackground`.
  - **Verification:** `swift build`
  - **Files:** `Sources/KaruWidgets/KaruWidgetsMain.swift`
  - **Scope:** Small (1 file)

- [x] **Task 11.2: Add Widget Extension Configuration & Plist**
  - **Description:** Create `Packaging/WidgetInfo.plist` with `NSExtensionPointIdentifier` set to `com.apple.widgetkit-extension` and update `Package.swift` or build script for extension targeting.
  - **Acceptance Criteria:**
    - `WidgetInfo.plist` is properly configured for macOS 14+ WidgetKit.
  - **Verification:** `plutil -lint Packaging/WidgetInfo.plist`
  - **Files:** `Packaging/WidgetInfo.plist`
  - **Scope:** XS (1 file)

- [x] **Task 11.3: Update Build & Packaging Pipeline for `.appex` Embedding**
  - **Description:** Update `scripts/build_app.sh` to compile `KaruWidgets`, package `Karu.app/Contents/PlugIns/KaruWidgets.appex`, codesign both `.appex` and `.app`, and assemble the release archive.
  - **Acceptance Criteria:**
    - `build/Karu.app/Contents/PlugIns/KaruWidgets.appex` is assembled and codesigned with `codesign --deep`.
  - **Verification:** `./scripts/build_app.sh`
  - **Files:** `scripts/build_app.sh`
  - **Scope:** Small (1 file)

- [x] **Task 11.4: Implement 1-Command System Installer Script (`install_app.sh`)**
  - **Description:** Create `scripts/install_app.sh` that builds `Karu.app` with embedded widgets, installs to `/Applications/Karu.app`, registers with macOS LaunchServices / `widgetkitd`, and informs the user how to drag it to their desktop.
  - **Acceptance Criteria:**
    - Copies `Karu.app` into `/Applications/`.
    - Triggers `lsregister` / LaunchServices refresh so widgets immediately appear in the macOS Desktop Widget Gallery ("Edit Widgets...").
  - **Verification:** `./scripts/install_app.sh`
  - **Files:** `scripts/install_app.sh`
  - **Scope:** Small (1 file)

### Checkpoint: Release & Widget Verification
- [x] `./scripts/build_app.sh` packages `Karu.app` with embedded `KaruWidgets.appex` cleanly
- [x] `swift test` passes 100% of unit tests
- [x] Widgets are ready to appear on macOS desktop

---

## Phase 12: Production Release Pipeline & Distribution Packaging (`release-dmg-pipeline`)

- [x] **Task 12.1: Hardened Runtime Entitlements (`Packaging/Karu.entitlements`)**
  - **Acceptance:** Entitlements plist created for main executable under Hardened Runtime.
  - **Verify:** `plutil -lint Packaging/Karu.entitlements`
  - **Files:** `Packaging/Karu.entitlements`

- [x] **Task 12.2: Parameterized Code Signing & Hardened Runtime in `build_app.sh`**
  - **Acceptance:** Supports `CODESIGN_IDENTITY`, adds `--options runtime`, binds entitlements, and passes `codesign --verify --deep --strict`.
  - **Verify:** `./scripts/build_app.sh`
  - **Files:** `scripts/build_app.sh`

- [x] **Task 12.3: Native Standalone DMG Packager (`scripts/create_dmg.sh`)**
  - **Acceptance:** Generates `build/dist/Karu-v1.0.0.dmg` with styled 540x380 Finder layout, centered app icon, `/Applications` link, and UDZO compression with zero external tools.
  - **Verify:** `./scripts/create_dmg.sh`
  - **Files:** `scripts/create_dmg.sh`

- [x] **Task 12.4: Apple Notarization & Stapling Utility (`scripts/notarize_app.sh`)**
  - **Acceptance:** Wraps `xcrun notarytool` and `xcrun stapler` for DMG release images with Keychain or environment variable authentication.
  - **Verify:** `test -x scripts/notarize_app.sh`
  - **Files:** `scripts/notarize_app.sh`

- [x] **Task 12.5: GitHub Actions CI/CD Workflows**
  - **Acceptance:** Continuous build and test on PR/push (`build-and-test.yml`), automated release packaging and artifact attachment on `v*` tags (`release.yml`).
  - **Verify:** `.github/workflows/build-and-test.yml`, `.github/workflows/release.yml`
  - **Files:** `.github/workflows/build-and-test.yml`, `.github/workflows/release.yml`

- [x] **Task 12.6: License & Release Documentation**
  - **Acceptance:** `LICENSE` file created with MIT License; `README.md` updated with badges, installation methods, and build commands.
  - **Verify:** `cat LICENSE`, `cat README.md`
  - **Files:** `LICENSE`, `README.md`

### Checkpoint: Production Release Pipeline Verification
- [x] `scripts/create_dmg.sh` executes and generates clean `build/dist/Karu-v1.0.0.dmg`
- [x] `swift test` passes 100% of unit tests
- [x] Code signing passes deep verification with Hardened Runtime

