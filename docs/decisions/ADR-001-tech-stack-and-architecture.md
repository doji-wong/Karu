# ADR-001: Native macOS Swift / SwiftUI and AppKit Architecture

## Status
Accepted

## Date
2026-08-29

## Context
Karu is designed to be a lightweight, ultra-responsive macOS utility that runs continuously in the system Menu Bar and renders an optional floating HUD overlay over active workspaces.

Key requirements:
- Sub-50MB RAM footprint and near-zero (<0.5%) idle CPU consumption so developers and students don't feel performance degradation during intense builds or multitasking.
- Native integration with macOS desktop primitives: `NSStatusItem` in the Menu Bar, `NSPopover`, `NSPanel` for floating HUDs, and `NSWorkspace` notifications.
- Fluid animations with smooth 60/120fps (ProMotion) transitions for telemetry gauges and speed indicators.

## Decision
Build Karu as a **pure native macOS application** using **Swift 5.9+ / SwiftUI** for the declarative UI layer and **AppKit (`NSStatusBar`, `NSPanel`, `NSVisualEffectView`)** for system windowing and low-level desktop lifecycle management.

## Alternatives Considered

### Electron / React
- **Pros:** Fast initial cross-platform prototyping with HTML/CSS.
- **Cons:** Heavy memory footprint (typically 150MB–300MB+ per instance), sluggish startup time, higher battery consumption, and clumsy integration with native macOS Menu Bar window behaviors.
- **Rejected:** Conflicts with our core performance and battery goals.

### Tauri (Rust + Webview)
- **Pros:** Lighter footprint than Electron, good web tooling.
- **Cons:** Menubar tray management and always-on-top translucent floating panels with native vibrancy (`NSVisualEffectView`) still require complex AppKit FFI/Objective-C bridging and are prone to macOS multi-monitor edge-case bugs.
- **Rejected:** Adds abstraction overhead compared to pure Swift/SwiftUI.

## Consequences
- **Positive:** Uncompromising native macOS look, feel, and performance. Native dark-mode vibrancy, instant cold starts, and minimal battery impact.
- **Positive:** Direct access to `NSWorkspace`, macOS Accessibility, and system notifications without third-party wrapper lag.
- **Negative:** Limited to macOS platform (which aligns with our 100% macOS focus).
