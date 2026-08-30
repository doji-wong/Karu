# Technical Implementation Plan: Karu (Focus Flight & Avionics Telemetry)

This plan outlines the sequenced execution phases for Karu, establishing clear validation gates between phases.

---

## 🚦 Phase Sequencing & Verification Gates

### Phase 1: Foundation & Aviation Models (`karu-models`) — [COMPLETED]
- **Deliverables:** `Package.swift`, `TransitState.swift`, `AppFilterRule.swift`, `TripSession.swift`, `Habit.swift`, `VehicleProfile.swift` (`AircraftType`).
- **Tests:** `ModelTests.swift` validating serialization, presets, timezones, and model math.
- **Verification Gate:** `swift build && swift test` passes with zero warnings.

---

## Phase 2: Flight Engine & Velocity Core (`transit-engine`) — [COMPLETED]
- **Deliverables:** `TransitEngine.swift` managing velocity telemetry (540 kts cruise vs 0 kts turbulence), state machine (`idle` $\to$ `cruising` $\to$ `trafficStalled` $\to$ `pitStop` $\to$ `completed`), tick mechanics, and on-time flight efficiency formulas.
- **Tests:** `TransitEngineTests.swift` validating airspeed transitions, efficiency calculations, and turbulence encounter tracking.
- **Verification Gate:** `swift test --filter TransitEngineTests` passes with 100% assertions satisfied.

---

## Phase 3: Distraction Detection & App Classifier (`app-classifier`) — [COMPLETED]
- **Deliverables:** `AppClassifier.swift` ($O(1)$ bundle ID lookup with preset fallbacks) and `DistractionMonitor.swift` (event-driven `NSWorkspace` listener).
- **Tests:** `AppClassifierTests.swift` validating preset rules, user custom overrides, and event dispatching.
- **Verification Gate:** `swift test --filter AppClassifierTests` passes.

---

## Phase 4: Local Storage & Data Persistence (`local-storage`) — [COMPLETED]
- **Deliverables:** `LocalStorageManager.swift` (atomic JSON read/write in `Application Support/Karu/` for trips, habits, rules, and fleet preferences).
- **Tests:** `LocalStorageTests.swift` validating atomic persistence, data integrity, and recovery.
- **Verification Gate:** `swift test --filter LocalStorageTests` passes.

---

## Phase 5: Ambient Audio Engine (`audio-engine`) — [COMPLETED]
- **Deliverables:** `AudioEngine.swift` with `AVAudioEngine`, `AVAudioPlayerNode`, `AVAudioMixerNode`, dual-tone seatbelt sign chime, and 400ms crossfader across 5 aircraft soundscapes.
- **Tests:** `AudioEngineTests.swift` validating volume ramping and node lifecycle.
- **Verification Gate:** `swift test --filter AudioEngineTests` passes.

---

## Phase 6: Direction A Avionics UI & Boarding Pass (`macos-windowing-ui`) — [COMPLETED]
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
- **Verification Gate:** `swift build -Xswiftc -warnings-as-errors` passes; `swift test` 25/25 tests pass.
