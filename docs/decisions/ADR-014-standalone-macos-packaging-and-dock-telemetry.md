# ADR-014: Standalone macOS Packaging, Dynamic Dock Telemetry, and First-Time Pilot Onboarding

## Status
Accepted

## Date
2026-09-02

## Context
As Karu transitions from command-line development (`swift run Karu`) to a production macOS application, three essential capabilities were required:
1. **Standalone macOS Distribution Packaging:** Assembling a native, self-contained `Karu.app` bundle with high-resolution Apple-standard squircle application icon assets (`AppIcon.icns`), `Info.plist` bundle metadata, and ad-hoc code signing without third-party packaging frameworks.
2. **Interactive Dock Telemetry & Dynamic Dock Menu:** For users working without the Menu Bar visible (e.g. full-screen IDE spaces), the macOS Dock provides a glanceable surface for live flight telemetry (airspeed readout, circular flight progress ring, turbulence stall indicators) and right-click quick dispatch actions (`NSApplicationDelegate.applicationDockMenu`).
3. **First-Time Pilot Onboarding ("Pre-Flight Cockpit Briefing"):** First-time knowledge workers need a zero-friction briefing to calibrate their focus domain (Developer, Writer, Student, Designer), 1-click classify their currently open macOS applications via live `NSWorkspace` radar, understand the 540 kts velocity mental model, and authorize their maiden takeoff.

---

## Decision

### 1. Native Distribution Packaging Pipeline
- Created `Packaging/Info.plist` configuring bundle identifier (`com.karu.focustimer`), minimum system version (`macOS 14.0+`), and high-resolution support.
- Built a native Swift asset generator (`scripts/generate_app_icon.swift`) using `CoreGraphics` and `AppKit` to draw titanium aircraft silhouettes, radar telemetry rings, and pitch angle indices across 10 Apple standard icon resolutions (16x16 up to 1024x1024 Retina), compiled into `AppIcon.icns` via `iconutil`.
- Built `scripts/build_app.sh` to compile release binaries with `swift build -c release`, assemble the `.app` bundle hierarchy, apply ad-hoc code signing (`codesign --force --deep --sign -`), verify signatures, and create distributable `.zip` archives.

### 2. Interactive Dock Telemetry (`NSDockTile`)
- Implemented `DynamicDockTileView` (SwiftUI) rendering carbon-matte `#08080A` cockpit avionics, glowing circular progress arcs, digital airspeed readouts (`540 KTS`), and destination airport badges.
- Implemented `DockTelemetryManager` (@MainActor) to update `NSApp.dockTile.contentView` and `NSApp.dockTile.badgeLabel` with frame-rate throttling to guarantee `< 0.5%` continuous background CPU usage.
- Implemented `AppDelegate.applicationDockMenu(_:)` returning a live flight telemetry status header and 1-click flight dispatch actions (Takeoff, Gate Hold, Touchdown, Abort, Window shortcuts).

### 3. First-Time Pilot Onboarding Intake Flow
- Implemented `OnboardingView` and `OnboardingWindowController` presenting a 4-stage interactive briefing on first launch (`preferences.hasCompletedOnboarding == false`):
  1. **Stage 1 (Mission Intake):** Pilot role and daily flight quota (2h, 4h, 6h).
  2. **Stage 2 (1-Click App Radar):** Real-time `NSWorkspace` active application scanner with native icons and 1-click classification (Focus 🟢 / Hazard 🔴 / Neutral 🔵).
  3. **Stage 3 (Avionics & HUD):** Velocity mental model (540 kts cruise vs 0 kts stall) and presentation mode selection.
  4. **Stage 4 (Maiden Takeoff):** Authorized takeoff triggering spatial departure chime and transitioning directly to the HUD.

### 4. Dynamic Presentation Modes & Activation Policies
- Supported user choice in Preferences between:
  - **Standard Cockpit (`NSApplication.ActivationPolicy.regular`):** Appears in macOS Dock with dynamic live telemetry + Menu Bar HUD + Floating HUD.
  - **Stealth Recon (`NSApplication.ActivationPolicy.accessory`):** Hidden from macOS Dock, residing exclusively in the Menu Bar and Floating HUD.

---

## Consequences

- **Positive:** Self-contained `Karu.app` can be deployed, distributed, and launched directly from `/Applications` with high-resolution Apple icon branding.
- **Positive:** Users receive live telemetry right on the macOS Dock without occupying screen real estate.
- **Positive:** First-time pilots are onboarded and launch their maiden flight in under 45 seconds with their open applications already classified.
- **Positive:** 100% Local-First zero-cloud privacy architecture is strictly maintained with atomic persistence in `Application Support/Karu/preferences.json`.
