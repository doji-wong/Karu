# Technical Implementation Plan: Karu (macOS Habit & Focus Timer)

This plan outlines the sequenced execution phases for Karu, establishing clear validation gates between phases.

---

## 🚦 Phase Sequencing & Verification Gates

### Phase 1: Foundation & Models (`karu-models`)
- **Deliverables:** `Package.swift`, `TransitState.swift`, `AppFilterRule.swift`, `TripSession.swift`, `Habit.swift`, `VehicleProfile.swift`.
- **Tests:** `ModelTests.swift` validating serialization, presets, and model math.
- **Verification Gate:** `swift build && swift test` passes with zero warnings.

---

### Phase 2: Transit Engine & Math Core (`transit-engine`)
- **Deliverables:** `TransitEngine.swift` managing velocity curves, state machine (`idle` $\to$ `cruising` $\to$ `trafficStalled` $\to$ `pitStop` $\to$ `completed`), tick mechanics, and cruise efficiency formulas.
- **Tests:** `TransitEngineTests.swift` validating speed transitions, efficiency calculations, and stall incident tracking.
- **Verification Gate:** `swift test --filter TransitEngineTests` passes with 100% assertions satisfied.

---

### Phase 3: Distraction Detection & App Classifier (`app-classifier`)
- **Deliverables:** `AppClassifier.swift` ($O(1)$ bundle ID lookup with preset fallbacks) and `DistractionMonitor.swift` (event-driven `NSWorkspace` listener).
- **Tests:** `AppClassifierTests.swift` validating preset rules, user custom overrides, and event dispatching.
- **Verification Gate:** `swift test --filter AppClassifierTests` passes.

---

### Phase 4: Local Storage & In-Flight Scratchpad (`local-storage`)
- **Deliverables:** `LocalStorageManager.swift` (atomic JSON read/write in `Application Support/Karu/`) and `ScratchpadStore.swift` (debounced auto-save & session snapshotting).
- **Tests:** `LocalStorageTests.swift` validating atomic persistence, data integrity, and recovery.
- **Verification Gate:** `swift test --filter LocalStorageTests` passes.

---

### Phase 5: Ambient Audio Engine (`audio-engine`)
- **Deliverables:** `AudioEngine.swift` with `AVAudioEngine`, `AVAudioPlayerNode`, `AVAudioMixerNode`, and 400ms crossfader.
- **Tests:** `AudioEngineTests.swift` validating volume ramping and node lifecycle.
- **Verification Gate:** `swift test --filter AudioEngineTests` passes.

---

### Phase 6: macOS UI & Windowing Layer (`macos-windowing-ui`)
- **Deliverables:**
  - Dark OLED Aerospace Theme (`KaruTheme.swift`)
  - Menu Bar Status Item & Dashboard Popover (`MenuBarController.swift`, `DiagnosticPopoverView.swift`)
  - MacBook Notch Wings (`NotchWindowController.swift`, `NotchWingsView.swift`)
  - Floating HUD Overlay (`FloatingHUDPanel.swift`, `FloatingHUDView.swift`)
  - Scratchpad Editor (`ScratchpadView.swift`)
  - Garage & Hangar Selector (`GarageHangarView.swift`)
  - App Whitelist/Blacklist Settings (`AppFilterSettingsView.swift`)
  - App Entry Bridge (`KaruApp.swift`, `AppDelegate.swift`)
- **Verification Gate:** `swift build` passes; manual launch and interactive testing.
