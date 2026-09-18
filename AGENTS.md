# Karu — Project Rules & Agent Guidelines

## 🧭 Project Overview & Vision
**Karu** is a native macOS Menu Bar & Floating HUD application for developers, students, and remote knowledge workers. It replaces anxiety-inducing countdown timers with an **aviation and flight velocity metaphor**:
- **Cruising Velocity (540 kts):** Active in approved focus workspaces (Xcode, VS Code, Obsidian, Docs, Terminal).
- **Turbulence Gridlock (0 kts):** Active in blacklisted distraction apps (Discord, Twitter/X, Steam, social media).
- **Dual Airport Selection & Boarding Pass:** Origin and Destination IATA pairs with inline accordion drawers and timezones.
- **Pilot's Logbook (`Cmd + L`):** Certified focus flight hours, distance flown (`NM`), touchdowns, and fleet on-time efficiency.
- **1-Click Running App Radar:** Fast whitelist/blacklist configuration via active macOS apps with native icons.
- **In-Flight Cabin Audio:** Vehicle-specific spatialized soundscapes via `AVAudioEngine`.

---

## 🛠️ Tech Stack & Minimum Requirements
- **Platform:** macOS 14.0+ (Sonoma) & macOS 15.0+ (Sequoia), Apple Silicon & Intel
- **Language:** Swift 5.9+ / Swift 6.x
- **UI Frameworks:** SwiftUI + AppKit (`NSStatusBar`, `NSPanel`, `NSVisualEffectView`)
- **Data Persistence:** 100% Local-First (Atomic JSON in `~/Library/Application Support/Karu/`)
- **Audio Engine:** `AVAudioEngine` + `AVAudioPlayerNode` / `AVAudioMixerNode`
- **Zero Cloud:** No user tracking, no telemetry, no mandatory cloud accounts

---

## ⚡ Core Architectural Decisions (ADR Summary)
- **ADR-001 (Native Architecture):** Pure native Swift/SwiftUI + AppKit. No Electron, no webview wrappers.
- **ADR-002 (Distraction Detection):** Event-driven via `NSWorkspace.didActivateApplicationNotification`. Zero polling loops.
- **ADR-003 (HUD & Windowing):** `NSPanel` with `.floating`, `.nonactivatingPanel`, `.canJoinAllSpaces`, and `.fullScreenAuxiliary`.
- **ADR-004 (Local-First Data):** Local atomic file writes. Zero cloud dependency.
- **ADR-005 (Notch Integration):** Uses `NSScreen.auxiliaryTopLeftArea` / `auxiliaryTopRightArea` for hardware notch wings with graceful Menu Bar fallback on external/non-notch displays.
- **ADR-006 (Ambient Audio):** Low-latency `AVAudioEngine` sound pipelines with 400ms crossfade between cruise and stall states.
- **ADR-007 (App Classification):** Triple-state categorization (`focusWorkspace`, `distractionHazard`, `neutralUtility`) with bundle-ID lookup.
- **ADR-008 (In-Flight Scratchpad):** Superseded by ADR-009.
- **ADR-009 (Scratchpad Elimination):** Complete deletion of notes feature to eliminate cognitive overhead and focus on telemetry.
- **ADR-010 (Direction A Monochrome Avionics):** Pure carbon matte `#08080A`, Knots/NM velocity, dual airport selection, and inline accordion drawers.
- **ADR-011 (1-Click Running App Radar):** Active app discovery via `NSWorkspace` with native icons and 1-click rules.
- **ADR-012 (Pilot's Logbook):** Certified flight hours, distance flown, touchdowns, and on-time efficiency tracking (`Cmd + L`).
- **ADR-013 (Desktop Telemetry Widgets):** Curated 12-field telemetry snapshot and interactive 1-click takeoff widget (`systemSmall` / `systemMedium`).
- **ADR-014 (Packaging & Dock Telemetry):** Standalone `Karu.app` release packaging, dynamic `NSDockTile` avionics, and 4-stage pilot intake.
- **ADR-015 (Pre-Flight Dispatch Deck & Modular Drawers):** 4-section clearance deck, modular drawer decomposition, dynamic destination durations, and cached formatters.
- **ADR-016 (Hardened Runtime, Notarization & CI/CD Pipeline):** Hardened Runtime entitlements, zero-dependency DMG packager, xcrun notarytool/stapler integration, and automated GitHub Actions release workflow.



---

## 💻 Development & Build Commands
- **Build Package / Targets:**
  ```bash
  swift build
  ```
- **Build with Warnings as Errors:**
  ```bash
  swift build -Xswiftc -warnings-as-errors
  ```
- **Run All Unit Tests:**
  ```bash
  swift test
  ```
- **Format & Lint:**
  ```bash
  swift format lint --strict
  ```
- **Clean Build Artifacts:**
  ```bash
  swift package clean
  ```
- **Package Standalone DMG:**
  ```bash
  ./scripts/create_dmg.sh
  ```
- **Notarize Release:**
  ```bash
  ./scripts/notarize_app.sh build/dist/Karu-v1.0.0.dmg
  ```


---

## 📐 Code Conventions & Best Practices

### 1. Swift 6 & Concurrency
- Use modern Swift concurrency (`async`/`await`, `Actor`, `@MainActor`).
- Mark all UI-bound observable stores and window controllers with `@MainActor`.
- Ensure models crossing thread boundaries conform to `Sendable`.
- Avoid legacy `DispatchQueue.main.async` in favor of `@MainActor` or `Task { @MainActor in ... }`.

### 2. SwiftUI & AppKit Hybrid Design
- Keep core business logic in pure Swift models (`KaruCore`) decoupled from AppKit / SwiftUI.
- Wrap AppKit controls in `NSViewRepresentable` or manage window lifecycles through dedicated `NSWindowController` / `NSPanel` subclasses.
- Use `NSVisualEffectView` with `.behindWindow` blending and `.hudWindow` / `.popover` material for macOS dark-mode vibrancy.
- Support smooth 60fps/120fps ProMotion animations using SwiftUI spring animations (`.spring(response:dampingFraction:)`).

### 3. Performance & Resource Boundaries
- **CPU Ceiling:** `< 0.5%` continuous background CPU usage. Never run unthrottled `Timer.scheduledTimer` polling loops.
- **Memory Footprint:** `< 45 MB` idle and active RAM.
- **Cold Startup:** `< 300 ms` to menu bar readiness.
- **Audio Memory:** Pre-buffer compact audio loops in `AVAudioPCMBuffer`. Do not decode large audio files on main thread.

### 4. Safety & Data Privacy
- Never send user app usage, keystrokes, or logs to any external server.
- All file operations in `Application Support/Karu/` must be atomic (`Data.write(to:options: .atomic)`).
- Handle multi-screen disconnects and display parameter changes gracefully via `NSApplication.didChangeScreenParametersNotification`.

---

## 🧭 Project Map

```
Karu/
├── Package.swift                         # Swift package manifest (KaruCore library + Karu executable)
├── Sources/
│   ├── KaruCore/                         # Core Logic Library (Zero AppKit UI dependencies)
│   │   ├── Core/                         # State Engines & Services
│   │   │   ├── TransitEngine.swift       # Velocity (540 kts vs 0 kts), distance (NM), state machine
│   │   │   ├── DistractionMonitor.swift  # NSWorkspace active app notification listener
│   │   │   ├── AppClassifier.swift       # Whitelist/Blacklist/Neutral rule evaluator
│   │   │   └── AudioEngine.swift         # AVAudioEngine ambient soundscapes & crossfader
│   │   ├── Models/                       # Core Domain Models
│   │   │   ├── TransitState.swift        # State enum, speed formatting, route presets
│   │   │   ├── TripSession.swift         # Active and completed trip records & turbulence logs
│   │   │   ├── Habit.swift               # Habit tracks, target times & streaks
│   │   │   ├── VehicleProfile.swift      # Aircraft fleet types (A350F, B787, Concorde, G650, C172)
│   │   │   └── AppFilterRule.swift       # Bundle ID classification models & presets
│   │   └── Storage/                      # Local-First Persistence
│   │       └── LocalStorageManager.swift # Atomic JSON persistence manager
│   └── Karu/                             # macOS Application Executable Target
│       ├── KaruApp.swift                 # SwiftUI App entry point & global menu commands
│       ├── AppDelegate.swift             # NSApplicationDelegate & window coordination
│       └── UI/                           # SwiftUI Views & AppKit Window Controllers
│           ├── MenuBar/                  # MenuBarController & DiagnosticPopoverView
│           ├── Notch/                    # NotchWindowController & NotchWingsView
│           ├── FloatingHUD/              # FloatingHUDPanel & FloatingHUDView
│           ├── Aviation/                 # FocusFlightCard, PreFlightDispatchDeckView, FlightCardDrawers, OrbitingTicketPopoutView
│           ├── Widgets/                  # SmallAirspeedGauge, MediumFlightDispatch, TimelineProvider, Simulator
│           ├── Dock/                     # DynamicDockTileView, DockTelemetryManager
│           ├── Onboarding/               # OnboardingView, OnboardingWindowController
│           ├── Logbook/                  # LogbookView (Pilot's Flight Logbook - Cmd + L)
│           ├── Garage/                   # GarageHangarView (Aircraft fleet & audio picker)
│           ├── Settings/                 # AppFilterSettingsView (1-Click App Radar & Rules)
│           └── Theme/                    # KaruTheme, KaruFormatters (Design tokens, palette & typography)
├── Packaging/                            # Standalone bundle packaging, icons & security entitlements
│   ├── Info.plist                        # macOS application bundle property list
│   ├── WidgetInfo.plist                  # WidgetKit extension bundle property list
│   ├── Karu.entitlements                 # Hardened Runtime security entitlements
│   └── generate_app_icon.swift           # CoreGraphics Apple squircle icon generator
├── scripts/                              # Standalone compilation, DMG packaging and notarization scripts
│   ├── build_app.sh                      # Release compilation and standalone .app packager
│   ├── create_dmg.sh                     # Native zero-dependency Finder-styled DMG packager
│   ├── notarize_app.sh                   # Apple Notary submission & ticket stapling helper
│   └── install_app.sh                    # System installer (/Applications/) and LaunchServices registrar
├── .github/workflows/                    # Continuous integration and automated release workflows
│   ├── build-and-test.yml                # PR & push validation on macOS 14 with warnings as errors
│   └── release.yml                       # Tag-triggered automated DMG build, notarization & GitHub Release
├── Tests/
│   └── KaruCoreTests/                    # Comprehensive unit tests
│       ├── TransitEngineTests.swift      # Velocity (540 kts), efficiency, turbulence logs
│       ├── AppClassifierTests.swift      # Bundle ID matching, overrides & preset tests
│       ├── LocalStorageTests.swift       # Atomic persistence & crash-resilience tests
│       ├── AudioEngineTests.swift        # Soundscape lifecycle & crossfade tests
│       ├── ModelTests.swift              # Serialization & domain model logic tests
│       └── WidgetTelemetryTests.swift    # Snapshot persistence, serialization & math tests
└── docs/                                 # PRD, Specifications, and Architecture Decision Records (ADR-001 - ADR-016)

```
