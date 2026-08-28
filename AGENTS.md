# Karu — Project Rules & Agent Guidelines

## 🧭 Project Overview & Vision
**Karu** is a native macOS Menu Bar & Floating HUD application for developers, students, and remote knowledge workers. It replaces anxiety-inducing countdown timers with a **route navigation and traffic velocity metaphor**:
- **Cruising Velocity (100 km/h):** Active in approved focus workspaces (Xcode, VS Code, Obsidian, Docs, Terminal).
- **Traffic Gridlock (0 km/h):** Active in blacklisted distraction apps (Discord, Twitter/X, Steam, social media).
- **Notch Wings & Dynamic Cockpit:** Telemetry anchored to MacBook camera notch and Menu Bar.
- **In-Flight Scratchpad & Habit Engine:** Local-first study notes and habit streaks.
- **In-Flight Audio:** Vehicle-specific ambient soundscapes via `AVAudioEngine`.

---

## 🛠️ Tech Stack & Minimum Requirements
- **Platform:** macOS 14.0+ (Sonoma) & macOS 15.0+ (Sequoia), Apple Silicon & Intel
- **Language:** Swift 5.9+ / Swift 6.x
- **UI Frameworks:** SwiftUI + AppKit (`NSStatusBar`, `NSPanel`, `NSVisualEffectView`)
- **Data Persistence:** 100% Local-First (SwiftData / Atomic JSON in `~/Library/Application Support/Karu/`)
- **Audio Engine:** `AVAudioEngine` + `AVAudioPlayerNode` / `AVAudioMixerNode`
- **Zero Cloud:** No user tracking, no telemetry, no mandatory cloud accounts

---

## ⚡ Core Architectural Decisions (ADR Summary)
- **ADR-001 (Native Architecture):** Pure native Swift/SwiftUI + AppKit. No Electron, no webview wrappers.
- **ADR-002 (Distraction Detection):** Event-driven via `NSWorkspace.didActivateApplicationNotification`. Zero polling loops.
- **ADR-003 (HUD & Windowing):** `NSPanel` with `.floating`, `.nonactivatingPanel`, `.canJoinAllSpaces`, and `.fullScreenAuxiliary`.
- **ADR-004 (Local-First Data):** Local atomic file writes and SwiftData models. Zero cloud dependency.
- **ADR-005 (Notch Integration):** Uses `NSScreen.auxiliaryTopLeftArea` / `auxiliaryTopRightArea` for hardware notch wings with graceful Menu Bar fallback on external/non-notch displays.
- **ADR-006 (Ambient Audio):** Low-latency `AVAudioEngine` sound pipelines with 400ms crossfade between cruise and stall states.
- **ADR-007 (App Classification):** Triple-state categorization (`focusWorkspace`, `distractionHazard`, `neutralUtility`) with bundle-ID lookup.

---

## 💻 Development & Build Commands
- **Build Package / Project:**
  ```bash
  swift build
  ```
- **Run Unit & Integration Tests:**
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

---

## 📐 Code Conventions & Best Practices

### 1. Swift 6 & Concurrency
- Use modern Swift concurrency (`async`/`await`, `Actor`, `@MainActor`).
- Mark all UI-bound observable stores and window controllers with `@MainActor`.
- Ensure models crossing thread boundaries conform to `Sendable`.
- Avoid legacy `DispatchQueue.main.async` in favor of `@MainActor` or `Task { @MainActor in ... }`.

### 2. SwiftUI & AppKit Hybrid Design
- Keep business logic in pure Swift models and ViewModel services.
- Wrap AppKit controls in `NSViewRepresentable` or manage window lifecycles through dedicated `NSWindowController` / `NSPanel` subclasses.
- Use `NSVisualEffectView` with `.behindWindow` blending and `.hudWindow` / `.popover` material for macOS dark-mode vibrancy.
- Support smooth 60fps/120fps ProMotion animations using SwiftUI spring animations (`.spring(response:dampingFraction:)`).

### 3. Performance & Resource Boundaries
- **CPU Ceiling:** `< 0.5%` continuous background CPU usage. Never run unthrottled `Timer.scheduledTimer` polling loops.
- **Memory Footprint:** `< 45 MB` idle and active RAM.
- **Cold Startup:** `< 300 ms` to menu bar readiness.
- **Audio Memory:** Pre-buffer compact audio loops in `AVAudioPCMBuffer`. Do not decode large audio files on main thread.

### 4. Safety & Data Privacy
- Never send user app usage, keystrokes, or notes to any external server.
- All file operations in `Application Support/Karu/` must be atomic (`Data.write(to:options: .atomic)`).
- Handle multi-screen disconnects and display parameter changes gracefully via `NSApplication.didChangeScreenParametersNotification`.

---

## 🧭 Project Map

```
Karu/
├── Package.swift                    # Swift package / project manifest
├── Sources/
│   ├── Karu/                        # App Entry Point & Lifecycle
│   │   ├── KaruApp.swift            # SwiftUI App entry & AppKit bridge
│   │   └── AppDelegate.swift        # NSApplicationDelegate & MenuBar controller
│   ├── Core/                        # State Engines & Services
│   │   ├── TransitEngine.swift      # Velocity, distance, cruise/stall state machine
│   │   ├── DistractionMonitor.swift # NSWorkspace active app listener
│   │   ├── AppClassifier.swift      # Whitelist/Blacklist/Neutral rule evaluator
│   │   └── AudioEngine.swift        # AVAudioEngine ambient soundscapes & crossfader
│   ├── Models/                      # Core Domain Models
│   │   ├── TripSession.swift        # Active and completed trip records
│   │   ├── Habit.swift              # Habit tracks, target times & streaks
│   │   ├── VehicleProfile.swift     # Vehicle skins, gauges & audio configs
│   │   └── AppFilterRule.swift      # Bundle ID classification models
│   ├── Storage/                     # Local-First Persistence
│   │   ├── LocalStorageManager.swift# Atomic JSON/SwiftData manager
│   │   └── ScratchpadStore.swift    # Auto-saving in-flight notes store
│   └── UI/                          # SwiftUI Views & AppKit Windows
│       ├── MenuBar/                 # Menu Bar HUD item & popover dashboard
│       ├── Notch/                   # Dynamic Notch wings & dropdown cockpit
│       ├── FloatingHUD/             # Translucent floating overlay panel
│       ├── Scratchpad/              # Live notes editor
│       ├── Garage/                  # Vehicle selection & hangar
│       └── Settings/                # App whitelist/blacklist & preference views
├── Tests/
│   ├── CoreTests/                   # Transit engine, classifier & math tests
│   └── StorageTests/                # Local persistence & atomic write tests
└── docs/                            # PRD, Architecture Decision Records (ADRs)
```

---

## ❓ Confusion Management & Escalation
1. **Ambiguous Requirements:** Stop and surface options with clear trade-offs before proceeding.
2. **Notch vs Non-Notch Geometry:** Always verify `screen.auxiliaryTopLeftArea != nil` before rendering Notch Wings; gracefully fall back to Menu Bar / Floating Pill.
3. **AppKit vs SwiftUI Boundaries:** UI components belong in SwiftUI; window levels, screen attachment, and menu bar lifecycle belong in AppKit controllers.
