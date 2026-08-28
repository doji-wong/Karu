# ADR-003: Menu Bar Popover and Floating HUD Window Architecture

## Status
Accepted

## Date
2026-08-29

## Context
Karu requires two primary interface presentations:
1. **Menu Bar HUD & Popover:** A status bar item that is always accessible without cluttering the macOS Dock, with a dropdown popover for telemetry, controls, and scratchpad.
2. **Floating HUD Overlay:** An optional, compact, floating mini-widget that stays on top of full-screen IDEs or browser windows.

Both presentations must handle multi-display setups, macOS Mission Control, Spaces, and full-screen apps without visual glitches or focus hijacking.

## Decision
1. **Menu Bar Status Item:** Implement using `NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)` coupled with an `NSPopover` hosting a SwiftUI `DiagnosticDashboardView`.
2. **Floating HUD Panel:** Implement using a custom subclass of `NSPanel` with the following configuration:
   - `styleMask: [.nonactivatingPanel, .hudWindow, .borderless, .resizable]`
   - `level: .floating` (floats above normal app windows)
   - `collectionBehavior: [.canJoinAllSpaces, .fullScreenAuxiliary]` (stays visible across macOS Spaces and over full-screen apps)
   - `isMovableByWindowBackground: true` (user can drag and place it anywhere on screen)
   - `hasShadow: true` with native material vibrancy background.

## Alternatives Considered

### Standard `NSWindow`
- **Pros:** Standard window lifecycle.
- **Cons:** Hijacks keyboard focus upon appearing, doesn't stay visible across full-screen Spaces, and creates unnecessary clutter in the macOS Dock.
- **Rejected:** Fails the distraction-free requirement.

### Single Menu Bar-only interface (no floating HUD)
- **Pros:** Simpler implementation.
- **Cons:** In full-screen work modes (e.g. full-screen Xcode or VS Code), the macOS Menu Bar auto-hides, causing users to lose their continuous visual momentum feedback.
- **Rejected:** A floating overlay option is essential for students and developers working full-screen.

## Consequences
- **Positive:** Smooth, non-disruptive user experience that respects macOS Spaces and full-screen applications.
- **Positive:** Users can choose between a quiet Menu Bar-only experience or an active floating cockpit HUD.
- **Negative:** Requires handling window coordinate persistence across multiple monitors and display resolution changes.
