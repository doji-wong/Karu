# Karu — Antigravity & Gemini Project Guidelines

This file mirrors the core instructions in [AGENTS.md](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/AGENTS.md).

## Core Directives for Karu

1. **Native macOS First:**
   - Always implement native macOS architecture (Swift 5.9+ / Swift 6, SwiftUI + AppKit).
   - Never use Electron, React-for-desktop, or heavy web wrappers.
2. **Local-First & Privacy Guaranteed:**
   - 100% of user data, habits, notes, and trip logs reside in `~/Library/Application Support/Karu/`.
   - Never add third-party tracking, telemetry, or remote dependencies.
3. **Event-Driven & Battery Conscious:**
   - App-switching detection uses `NSWorkspace.didActivateApplicationNotification`.
   - Never use polling loops (`Timer.scheduledTimer`) for background application detection.
   - Respect target budgets: `< 0.5%` CPU idle/active, `< 45 MB` RAM.
4. **Windowing & Notch Primitives:**
   - Floating HUD uses `NSPanel` with `.nonactivatingPanel`, `.floating`, `.canJoinAllSpaces`.
   - Notch Wings use `NSScreen.auxiliaryTopLeftArea` and `NSScreen.auxiliaryTopRightArea` with automatic fallback to Menu Bar HUD on external or non-notch displays.
5. **Swift Concurrency:**
   - Mark UI components, view models, and window controllers with `@MainActor`.
   - Ensure thread-safe models conform to `Sendable`.

For full documentation and component references, see [docs/PRD.md](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/PRD.md) and [docs/PROJECT_MAP.md](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/PROJECT_MAP.md).
