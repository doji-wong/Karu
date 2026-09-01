# Project: Karu — macOS Focus Timer & Route Navigation HUD

## Tech Stack
- **Language:** Swift 5.9+ / Swift 6.x
- **Platforms:** macOS 14.0+ (Sonoma) & macOS 15.0+ (Sequoia), Apple Silicon & Intel
- **UI Architecture:** SwiftUI + AppKit (`NSStatusBar`, `NSPanel`, `NSVisualEffectView`)
- **Core Library:** `KaruCore` (decoupled pure Swift models, state engines, audio, storage)
- **Application:** `Karu` (executable target with MenuBar, Notch Wings, Sidebar HUD, Floating HUD, and settings)
- **Audio Engine:** `AVAudioEngine` + `AVAudioPlayerNode` / `AVAudioMixerNode`
- **Data Persistence:** 100% Local-First atomic JSON in `~/Library/Application Support/Karu/`

## Essential Commands
- **Build Package / Targets:** `swift build`
- **Build with Warnings as Errors:** `swift build -Xswiftc -warnings-as-errors`
- **Run Unit Tests:** `swift test`
- **Filter Tests:** `swift test --filter TransitEngineTests`
- **Format / Lint:** `swift format lint --strict`
- **Clean Build Artifacts:** `swift package clean`

## Code Conventions & Architecture
- **Concurrency:** Mark all UI-bound stores, controllers, and views with `@MainActor`. Ensure cross-thread data types conform to `Sendable`.
- **Pure Core Logic:** Keep business logic inside `Sources/KaruCore/` with zero AppKit UI dependencies.
- **Event-Driven App Switching:** Subscribes to `NSWorkspace.didActivateApplicationNotification`. NEVER use polling loops (`Timer.scheduledTimer`).
- **Window Management:** Custom `NSPanel` subclasses configured with `.nonactivatingPanel`, `.floating`, `.canJoinAllSpaces`, `.fullScreenAuxiliary`.
- **Visual Design:** Direction A Monochrome Avionics (`#08080A` carbon matte base, `#151518` elevated surfaces, `#FFFFFF` high-contrast avionics text, Knots/NM velocity telemetry).

## Hard Boundaries & Budgets
- **CPU:** `< 0.5%` continuous background CPU usage.
- **RAM:** `< 45 MB` total memory footprint.
- **Startup:** `< 300 ms` cold start to menu bar item.
- **Privacy:** 100% local-first data storage. Zero network tracking or cloud dependencies.
- **Storage Safety:** All file writes to `Application Support/Karu/` MUST use atomic writes (`Data.write(to:options: [.atomic])`).

## Project Structure
- `Sources/KaruCore/Core/`: `TransitEngine.swift`, `DistractionMonitor.swift`, `AppClassifier.swift`, `AudioEngine.swift`
- `Sources/KaruCore/Models/`: `TransitState.swift`, `TripSession.swift`, `Habit.swift`, `VehicleProfile.swift`, `AppFilterRule.swift`
- `Sources/KaruCore/Storage/`: `LocalStorageManager.swift`
- `Sources/Karu/`: `KaruApp.swift`, `AppDelegate.swift`
- `Sources/Karu/UI/`: `MenuBar/`, `Notch/`, `FloatingHUD/`, `Aviation/`, `Logbook/`, `Garage/`, `Settings/`, `Theme/`
- `Tests/KaruCoreTests/`: `TransitEngineTests.swift`, `AppClassifierTests.swift`, `LocalStorageTests.swift`, `AudioEngineTests.swift`, `ModelTests.swift`
