# Technical Specification: Karu — Focus Flight & Avionics Telemetry

## 1. Objective
Karu is a native macOS Menu Bar & Floating HUD application for developers, students, and remote knowledge workers. It replaces anxiety-inducing countdown timers with an **immersive flight navigation and air velocity metaphor**:
- **Cruising Velocity (540 kts):** Active in user-approved focus workspaces (Xcode, VS Code, Obsidian, Terminal, Arc/Safari docs).
- **Turbulence Gridlock (0 kts):** Triggered immediately upon switching to blacklisted distraction apps (Discord, Twitter/X, Steam, Slack non-work channels).
- **Dual Airport Selection & Dynamic Boarding Pass:** Origin and Destination IATA pairs (e.g. `YYZ ➔ HND`, `SIN ➔ LHR`) with timezones, seat classes, and smooth inline accordion drawers.
- **Pilot's Logbook & Streak Tracking (`Cmd + L`):** Certified focus flight hours, distance flown (`NM`), touchdown logs, and on-time fleet efficiency.
- **In-Flight Ambient Audio:** Vehicle-specific Rolls-Royce Trent / Olympus acoustic soundscapes with 400ms crossfades via `AVAudioEngine`.
- **Zero Cloud & Low Overhead:** 100% local-first persistence in `~/Library/Application Support/Karu/`, $<0.5\%$ CPU, $<45\text{ MB}$ RAM.

---

## 2. Tech Stack
- **Target Platform:** macOS 14.0+ (Sonoma) & macOS 15.0+ (Sequoia), Apple Silicon & Intel
- **Language & Runtime:** Swift 5.9+ / Swift 6.x (Strict Concurrency `@MainActor` & `Sendable`)
- **UI Frameworks:** SwiftUI + AppKit (`NSStatusBar`, `NSStatusItem`, `NSPanel`, `NSVisualEffectView`)
- **Audio Framework:** Apple `AVAudioEngine` (`AVAudioPlayerNode`, `AVAudioMixerNode`, `AVAudioPCMBuffer`)
- **Persistence:** 100% Local-First JSON file storage with atomic writes (`Data.write(to:options: [.atomic])`) in `~/Library/Application Support/Karu/`
- **Build System:** Swift Package Manager (`Package.swift`) with zero third-party dependencies

---

## 3. Commands
- **Build Package / Targets with Warnings as Errors:**
  ```bash
  swift build -Xswiftc -warnings-as-errors
  ```
- **Run Complete Unit & Integration Test Suite:**
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
├── Package.swift                             # Swift package manifest (KaruCore library + Karu executable)
├── Sources/
│   ├── KaruCore/                             # Core Logic Library (Zero AppKit UI dependencies)
│   │   ├── Core/                             # State Engines & Services
│   │   │   ├── TransitEngine.swift           # Velocity (540 kts vs 0 kts), distance (NM), state machine
│   │   │   ├── DistractionMonitor.swift      # NSWorkspace active app notification listener
│   │   │   ├── AppClassifier.swift           # Whitelist/Blacklist/Neutral rule evaluator
│   │   │   └── AudioEngine.swift             # AVAudioEngine ambient soundscapes & crossfader
│   │   ├── Models/                           # Core Domain Models
│   │   │   ├── TransitState.swift            # State enum, airport definitions & seat classes
│   │   │   ├── TripSession.swift             # Active and completed trip records & turbulence logs
│   │   │   ├── Habit.swift                   # Habit tracks, target times & streaks
│   │   │   ├── VehicleProfile.swift          # Aircraft fleet types (A350F, B787, Concorde, G650, C172)
│   │   │   └── AppFilterRule.swift           # Bundle ID classification models & presets
│   │   └── Storage/                          # Local-First Persistence
│   │       └── LocalStorageManager.swift     # Atomic JSON file persistence manager
│   └── Karu/                                 # macOS Application Executable Target
│       ├── KaruApp.swift                     # SwiftUI App entry point & global menu commands
│       ├── AppDelegate.swift                 # NSApplicationDelegate coordinator & window management
│       └── UI/                               # SwiftUI Views & AppKit Window Controllers
│           ├── MenuBar/                      # MenuBarController & DiagnosticPopoverView
│           ├── Notch/                        # NotchWindowController & NotchWingsView
│           ├── FloatingHUD/                  # FloatingHUDPanel & FloatingHUDView
│           ├── Aviation/                     # FocusFlightCard, PreFlightDispatchDeckView, FlightCardDrawers, OrbitingTicketPopoutView
│           ├── Widgets/                      # SmallAirspeedGauge, MediumFlightDispatch, TimelineProvider, Simulator
│           ├── Dock/                         # DynamicDockTileView, DockTelemetryManager
│           ├── Onboarding/                   # OnboardingView, OnboardingWindowController
│           ├── Logbook/                      # LogbookView (Pilot's Flight Hours & Telemetry Logbook)
│           ├── Garage/                       # GarageHangarView (Aircraft Fleet & Audio Picker)
│           ├── Settings/                     # AppFilterSettingsView (1-Click Running App Radar & Rules)
│           └── Theme/                        # KaruTheme, KaruFormatters, DotMatrixLEDView, AviationGraphicComponents
├── Tests/
│   └── KaruCoreTests/                        # Comprehensive Unit & Integration Tests
│       ├── TransitEngineTests.swift          # Velocity (540 kts), efficiency, turbulence logs
│       ├── AppClassifierTests.swift          # Bundle ID matching, overrides & preset tests
│       ├── LocalStorageTests.swift           # Atomic persistence & crash-resilience tests
│       ├── AudioEngineTests.swift            # Soundscape lifecycle & crossfade tests
│       ├── ModelTests.swift                  # Serialization & domain model logic tests
│       └── WidgetTelemetryTests.swift        # Snapshot persistence & math tests
├── tasks/
│   ├── plan.md                               # Implementation roadmap & completed phases
│   └── todo.md                               # Actionable task checklist
└── docs/
    ├── CAPABILITY_MAP.md                     # Module boundaries & build order
    ├── PRD.md                                # Product Requirements Document
    ├── PROJECT_MAP.md                        # Hierarchical context map
    └── decisions/                            # Architecture Decision Records (ADR-001 - ADR-015)
```

---

## 5. Code Style & Key Patterns

```swift
// Example: Concurrency-safe, reactive State Engine with aviation velocity telemetry
import Foundation
import Observation

@Observable
@MainActor
public final class TransitEngine {
    public private(set) var state: TransitState = .idle
    public private(set) var currentVelocity: Double = 0.0 // kts (Knots ground speed)
    public private(set) var activeSession: TripSession?
    public private(set) var activeAircraft: AircraftType = .a350F
    
    public func startTrip(preset: FlightPreset = .sprint25, customDuration: TimeInterval? = nil) {
        let session = TripSession(preset: preset, targetDuration: customDuration ?? preset.targetDuration)
        self.activeSession = session
        self.state = .cruising
        self.currentVelocity = 540.0 // 540 kts standard cruise
    }

    public func handleAppCategoryChange(category: AppFocusCategory, appName: String, bundleIdentifier: String) {
        switch category {
        case .focusWorkspace:
            if state == .trafficStalled {
                state = .cruising
                currentVelocity = 540.0
            }
        case .distractionHazard:
            if state == .cruising {
                state = .trafficStalled
                currentVelocity = 0.0
            }
        case .neutralUtility:
            break
        }
    }
}
```

### Key Conventions:
- **Swift 6 Concurrency:** Mark all UI-bound stores, view models, and AppKit controllers with `@MainActor`. All models crossing thread boundaries conform to `Sendable`.
- **Pure Logic Decoupling:** `KaruCore` contains zero AppKit/SwiftUI presentation code.
- **Window Management:** Floating HUDs use `NSPanel` with `.nonactivatingPanel`, `.floating`, and `.canJoinAllSpaces`.
- **Inline Accordion Drawers:** Sub-pickers expand inline inside the card container to prevent borderless `NSPanel` popover clipping.

### 5.3 Packaging, Hardened Runtime & CI/CD Architecture
- **Hardened Runtime (`Packaging/Karu.entitlements`):** Enforces strict Gatekeeper compliance with zero JIT or unsigned memory exceptions.
- **Parameterized Code Signing (`scripts/build_app.sh`):** Supports `CODESIGN_IDENTITY` with `--options runtime`, `--timestamp`, and recursive `.appex` plugin signing.
- **Native DMG Generation (`scripts/create_dmg.sh`):** Builds compressed `UDZO` disk images with custom 540x380 AppleScript Finder positioning and `/Applications` drag-and-drop symlink using zero third-party dependencies.
- **Apple Notarization (`scripts/notarize_app.sh`):** Automates `xcrun notarytool` submission and `xcrun stapler` ticket attachment for seamless Gatekeeper clearance.
- **Continuous Integration & Delivery (`.github/workflows/`):** Strict PR quality gates (`build-and-test.yml` with `-warnings-as-errors`) and automated tag-triggered GitHub Releases (`release.yml`).

---

## 6. Testing Strategy
- **Framework:** Swift Testing (`@Suite`, `@Test`, `#expect`).
- **Target Line Coverage:** $\ge 90\%$ line coverage across `KaruCore` (Core, Models, Storage).
- **Core Test Suites:**
  - `TransitEngineTests`: 540 kts cruise velocity, 0 kts turbulence stall, gate hold pauses, trip completion and mileage.
  - `AppClassifierTests`: Priority chain (Custom Override $>$ Focus Preset Rule $>$ Neutral Default), strict mode evaluation.
  - `LocalStorageTests`: Atomic JSON writes, directory auto-creation, corruption recovery fallback.
  - `AudioEngineTests`: Pipeline initialization, mute controls, aircraft profile switching, state crossfade.
  - `ModelTests`: Codable serialization roundtrips, distance formulas, airport timezones.

---

## 7. Boundaries & Rules of Engagement

| Category | Rules |
|---|---|
| **Always Do** | Run `swift test` before committing any code changes. Maintain zero external cloud telemetry or tracking. Use atomic writes (`.atomic`) for all files in `~/Library/Application Support/Karu/`. Calibrate speed in knots (`kts`) and distance in nautical miles (`NM`). |
| **Ask First** | Adding external third-party SPM packages. Modifying local JSON storage schemas that would break backward compatibility. Adding new window controllers. |
| **Never Do** | Never use unthrottled `Timer.scheduledTimer` polling loops for active app detection. Never use Electron, React-for-desktop, or WebViews. Never send user activity, keystrokes, or notes to external servers. |

---

## 8. Success Criteria
- [x] `swift build -Xswiftc -warnings-as-errors` passes with 0 warnings.
- [x] `swift test` passes 100% of unit tests across all test suites.
- [x] App switching detects focus vs distraction in $<10\text{ ms}$ via event-driven `NSWorkspace` notifications.
- [x] Idle and active RAM usage remains $<45\text{ MB}$.
- [x] Background CPU usage during active transit remains $<0.5\%$.
- [x] Both Departure and Arrival airports are independently selectable with live timezone calculations.
- [x] Inline accordion drawers expand smoothly without window border clipping in floating HUD panels.
- [x] 1-Click Running App Radar lists running apps with native icons and 1-click classification.
- [x] Pilot's Logbook (`Cmd + L`) accurately records focus flight hours, distance flown, and on-time efficiency.
- [x] Standalone DMG packages cleanly via `scripts/create_dmg.sh` with styled Finder layout and zero external dependencies.
- [x] Hardened Runtime entitlements pass deep verification with `codesign --verify --deep --strict`.
- [x] GitHub Actions workflows automate PR verification and tag-driven GitHub Releases.

