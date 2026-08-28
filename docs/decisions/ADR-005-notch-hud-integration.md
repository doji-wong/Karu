# ADR-005: MacBook Notch HUD & Side-Notch Wings Integration

## Status
Accepted

## Date
2026-08-29

## Context
Modern MacBooks (14" and 16" MacBook Pro, M2/M3 MacBook Air) have a physical camera notch at the top center of the display. 

Instead of treating the notch as dead screen real estate or solely relying on the crowded right-hand side of the macOS Menu Bar, we want to anchor the live velocity telemetry directly to the camera notch ("Side-Notch Wings").

Key UX goals:
- **Left Wing:** Live Velocity (`⚡ 100 km/h` cruising green, shifts to `⚠️ 0 km/h [GRIDLOCK]` when distracted).
- **Right Wing:** Route progress & habit tag (`📍 24m remaining · Deep Work`).
- **Dynamic Expand:** Hovering or clicking the notch expands an aerodynamic dropdown cockpit dashboard right under the notch.
- **Display Fallback:** Seamlessly adapt to external monitors (Studio Display, ultra-wides, non-notch Macs) by defaulting to the Menu Bar HUD / Floating pill without crashing or layout distortion.

## Decision
Implement the Notch HUD using a non-activating `NSPanel` overlay mapped to **`NSScreen.auxiliaryTopLeftArea` and `NSScreen.auxiliaryTopRightArea`** (introduced in macOS 12.0+).

1. **Notch Geometry Detection:**
   ```swift
   if let screen = NSScreen.main,
      let leftArea = screen.auxiliaryTopLeftArea,
      let rightArea = screen.auxiliaryTopRightArea {
       // MacBook with hardware notch detected: position side wings
   } else {
       // Non-notch Mac / External display: fall back to MenuBar HUD / Dynamic Island pill
   }
   ```
2. **Windowing & Behavior:**
   - Use `NSPanel` with `.nonactivatingPanel` and collection behavior `.canJoinAllSpaces` so the notch wings remain pinned across full-screen desktops.
   - Mouse hover detection triggers smooth spring animations expanding the cockpit dropdown.

## Alternatives Considered

### Relying solely on `NSStatusItem` in the Menu Bar
- **Pros:** Native standard API.
- **Cons:** On notch MacBooks with many running apps, Menu Bar items often get hidden or pushed behind the notch.
- **Rejected:** Hardware notch integration gives Karu a distinct, modern, top-tier aesthetic.

## Consequences
- **Positive:** Gives Karu an innovative, physical hardware-integrated identity on modern MacBooks.
- **Positive:** Zero screen clutter—occupies the unused black space flanking the camera notch.
- **Negative:** Requires handling screen reconfiguration notifications (`NSApplication.didChangeScreenParametersNotification`) when users plug into external monitors or switch displays.
