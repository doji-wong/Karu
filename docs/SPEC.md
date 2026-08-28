# Technical Specification: Karu Focus Timer

## 1. Objective
Karu is a high-performance, native macOS Menu Bar and Floating HUD utility that replaces anxiety-inducing countdown timers with a **route navigation and traffic velocity metaphor**.
- **Cruising Velocity (100 km/h):** Maintained while working inside user-designated focus applications (IDEs, writing tools, study materials).
- **Traffic Gridlock (0 km/h):** Triggered immediately upon switching to blacklisted distraction apps (social networks, chat channels, games).
- **In-Flight Scratchpad & Habits:** Instant, local-first note-taking and habit streak tracking during deep work runs.
- **Zero Cloud & Low Overhead:** 100% local persistence in `~/Library/Application Support/Karu/`, $<0.5\%$ idle CPU, $<45\text{ MB}$ RAM footprint.

---

## 2. Tech Stack
- **Target Platform:** macOS 14.0+ (Sonoma) & macOS 15.0+ (Sequoia), Apple Silicon & Intel
- **Language & Runtime:** Swift 5.9+ / Swift 6.x (Strict Concurrency enabled)
- **UI Frameworks:** SwiftUI + AppKit (`NSStatusBar`, `NSStatusItem`, `NSPanel`, `NSPopover`, `NSVisualEffectView`)
- **Audio Framework:** Apple `AVAudioEngine` (`AVAudioPlayerNode`, `AVAudioMixerNode`, `AVAudioPCMBuffer`)
- **Persistence:** Local-first JSON file storage with atomic writes (`Data.write(to:options: [.atomic])`) and SwiftData models
- **Build System:** Swift Package Manager (`Package.swift`)

---

## 3. Commands
- **Build Core Library & Executable:**
  ```bash
  swift build
  ```
- **Run Unit & Integration Test Suite:**
  ```bash
  swift test
  ```
- **Run Tests with Code Coverage:**
  ```bash
  swift test --enable-code-coverage
  ```
- **Format Code:**
  ```bash
  swift format format --in-place --recursive Sources/ Tests/
  ```
- **Lint Code:**
  ```bash
  swift format lint --strict --recursive Sources/ Tests/
  ```

---

## 4. Project Structure
```
Karu/
├── Package.swift                             # Swift package manifest
├── Sources/
│   ├── Models/                               # Module: karu-models
│   │   ├── TransitState.swift                # State machine enum & telemetry helpers
│   │   ├── AppFilterRule.swift               # Focus categories & preset rules
│   │   ├── TripSession.swift                 # Active trip, incident logs & metrics
│   │   ├── Habit.swift                       # Habit tracks & streak models
│   │   └── VehicleProfile.swift              # Vehicle skins, gauges & audio configs
│   ├── Core/                                 # Modules: transit-engine, app-classifier, audio-engine
│   │   ├── TransitEngine.swift               # Velocity, timer tick & efficiency engine
│   │   ├── AppClassifier.swift               # O(1) bundle ID rule evaluator
│   │   ├── DistractionMonitor.swift          # NSWorkspace event-driven listener
│   │   └── AudioEngine.swift                 # AVAudioEngine ambient crossfader
│   ├── Storage/                              # Module: local-storage
│   │   ├── LocalStorageManager.swift         # Atomic disk persistence engine
│   │   └── ScratchpadStore.swift             # Auto-saving live Markdown notes store
│   ├── UI/                                   # Module: macos-windowing-ui
│   │   ├── Theme/
│   │   │   └── KaruTheme.swift               # OLED palette, typography & tokens
│   │   ├── MenuBar/
│   │   │   ├── MenuBarController.swift       # NSStatusItem lifecycle & glyphs
│   │   │   └── DiagnosticPopoverView.swift   # Speedometer gauge & cockpit popover
│   │   ├── Notch/
│   │   │   ├── NotchWindowController.swift   # Hardware notch geometry manager
│   │   │   └── NotchWingsView.swift          # Left/Right telemetry wings & expander
│   │   ├── FloatingHUD/
│   │   │   ├── FloatingHUDPanel.swift        # NSPanel floating translucent overlay
│   │   │   └── FloatingHUDView.swift         # Mini speed pill & progress bar
│   │   ├── Scratchpad/
│   │   │   └── ScratchpadView.swift          # Live notes capture editor
│   │   ├── Garage/
│   │   │   └── GarageHangarView.swift        # Vehicle selector & theme customizer
│   │   └── Settings/
│   │       └── AppFilterSettingsView.swift   # Whitelist/blacklist bundle manager
│   └── Karu/                                 # Application Entry
│       ├── KaruApp.swift                     # SwiftUI main application struct
│       └── AppDelegate.swift                 # NSApplicationDelegate lifecycle bridge
├── Tests/
│   ├── CoreTests/
│   │   ├── ModelTests.swift                  # Codable & preset serialization tests
│   │   ├── TransitEngineTests.swift          # Velocity & efficiency math tests
│   │   ├── AppClassifierTests.swift          # Rule priority & bundle match tests
│   │   └── AudioEngineTests.swift            # Volume ramping & state crossfader tests
│   └── StorageTests/
│       └── LocalStorageTests.swift           # Atomic write & recovery tests
├── tasks/
│   ├── plan.md                               # Implementation phase roadmap
│   └── todo.md                               # Actionable task checklist
└── docs/
    ├── CAPABILITY_MAP.md                     # Module boundaries & build order
    ├── PRD.md                                # Product Requirements Document
    ├── PROJECT_MAP.md                        # Hierarchical context map
    └── decisions/                            # Architecture Decision Records (ADRs)
```

---

## 5. Code Style & Conventions

```swift
// Example: Concurrency-safe, reactive State Engine pattern
import Foundation
import Observation

@Observable
@MainActor
public final class TransitEngine {
    public private(set) var state: TransitState = .idle
    public private(set) var currentVelocity: Double = 0.0 // km/h
    public private(set) var cruisingTime: TimeInterval = 0
    public private(set) var stalledTime: TimeInterval = 0
    
    public var cruiseEfficiency: Double {
        let totalActive = cruisingTime + stalledTime
        guard totalActive > 0 else { return 100.0 }
        return (cruisingTime / totalActive) * 100.0
    }
    
    public func handleAppCategoryChange(_ category: AppFocusCategory, appName: String, bundleId: String) {
        switch category {
        case .focusWorkspace:
            transitionToCruise()
        case .distractionHazard:
            transitionToStall(appName: appName, bundleId: bundleId)
        case .neutralUtility:
            break // Maintain current velocity state
        }
    }
    
    private func transitionToCruise() {
        guard state != .cruising else { return }
        state = .cruising
        currentVelocity = 100.0
    }
    
    private func transitionToStall(appName: String, bundleId: String) {
        guard state != .trafficStalled else { return }
        state = .trafficStalled
        currentVelocity = 0.0
    }
}
```

### Key Style Rules:
- **Concurrency:** Mark all UI stores and window managers with `@MainActor`. Ensure cross-queue data models conform to `Sendable`.
- **Observation:** Use Swift's native `@Observable` macro (macOS 14+) for view models.
- **Windowing:** Subclass `NSPanel` for floating HUDs with `.nonactivatingPanel` to prevent editor focus disruption.
- **Vibrancy:** Use `NSVisualEffectView` with `.behindWindow` blending and `.hudWindow` / `.popover` material for dark aerospace aesthetics.

---

## 6. Testing Strategy
- **Unit Testing Framework:** `XCTest` / Swift Testing.
- **Target Coverage:** $\ge 85\%$ line coverage on `Sources/Models/`, `Sources/Core/`, and `Sources/Storage/`.
- **Test Scenarios:**
  - `ModelTests`: Verify `Codable` roundtripping, defaults, preset collections.
  - `TransitEngineTests`: Verify tick accuracy, transition states (`idle` $\to$ `cruising` $\to$ `stalled` $\to$ `completed`), pause/pit-stops, and cruise efficiency percentage formula.
  - `AppClassifierTests`: Verify rule hierarchy (User Custom Rule $>$ Selected Preset Rule $>$ Neutral Default Heuristic).
  - `LocalStorageTests`: Verify atomic file writes in sandboxed test directory, corruption recovery, and schema deserialization.
  - `AudioEngineTests`: Verify volume curves and state transitions.

---

## 7. Boundaries & Rules of Engagement

| Category | Rules |
|---|---|
| **Always Do** | Run `swift test` before committing any code changes. Ensure models crossing concurrency boundaries are `Sendable`. Use atomic writes (`.atomic`) for file updates in `~/Library/Application Support/Karu/`. Gracefully check for hardware notch geometry before rendering notch wings. |
| **Ask First** | Adding external third-party SwiftPM dependencies (standard is zero third-party dependencies). Modifying data schemas that break local JSON compatibility. Modifying audio engine architecture. |
| **Never Do** | Never introduce network calls, cloud tracking, or telemetry libraries. Never use unthrottled `Timer.scheduledTimer` polling loops for active application detection. Never use Electron or WebViews. |

---

## 8. Success Criteria

- [ ] `swift build` compiles cleanly with zero warnings or errors under Swift 6.
- [ ] `swift test` passes 100% of unit and integration tests across Core, Models, and Storage.
- [ ] App switching detects focus vs distraction in $<10\text{ ms}$ via `NSWorkspace` notifications.
- [ ] Idle and active memory usage remains $<45\text{ MB}$.
- [ ] Continuous background CPU usage during active transit remains $<0.5\%$.
- [ ] Notch wings cleanly render in `auxiliaryTopLeftArea` / `auxiliaryTopRightArea` with automated fallback to Menu Bar HUD on external monitors.
- [ ] Scratchpad notes persist across app restarts with atomic local writes.
- [ ] Adaptive audio smoothly crossfades between cruising and traffic-stall loops over 400ms without pops or glitches.

---

## 9. Assumptions & Open Questions

### Assumptions:
1. Target deployment target is macOS 14.0+ (Sonoma) and macOS 15.0+ (Sequoia).
2. Hardware notch integration leverages native AppKit `NSScreen.auxiliaryTopLeftArea` / `auxiliaryTopRightArea`.
3. In-flight audio uses lightweight synthesized / packaged loop buffers in `AVAudioPCMBuffer`.

### Open Questions:
- None currently blocking. Browser-level deep URL filtering is deferred to v1.1 per ADR-002.
