# Idea: Interactive macOS Dock Tile & Telemetry Pop-out

## Problem Statement
How Might We leverage the macOS Dock as an optional, high-visibility avionics flight telemetry surface—displaying dynamic live airspeed badges and popping out the Pilot's Flight Logbook on click—while preserving Karu's stealth, zero-clutter Menu Bar identity?

---

## Recommended Direction: Dynamic Avionics Dock Tile (`NSDockTile` + Activation Policy Toggle)

### 1. Dual-Mode Activation Architecture
- **Default Mode (Stealth Menu Bar Agent):** `NSApplication.ActivationPolicy.accessory` (`LSUIElement = true`). Zero dock footprint, running exclusively in the Menu Bar, Notch wings, and Floating HUD.
- **Dock Mode (Avionics Station):** Toggleable in Preferences (`Cmd + ,`). Dynamically elevates to `NSApplication.ActivationPolicy.regular` without restarting the application.

### 2. Live Dock Tile Telemetry (`NSDockTile`)
- **Badge Readout:**
  - **Cruising:** `"540 kts"` (or formatted velocity).
  - **Turbulence:** `"STALL"` (caution state).
  - **Gate Hold:** `"HOLD"`.
  - **Idle / Touchdown:** `nil` (or streak count like `"🔥 12d"`).
- **Custom Dock Tile Graphics (Optional):** Procedural dark carbon icon with luminous progress ring via `NSApp.dockTile.contentView`.

### 3. 1-Click Dock Pop-Out (`applicationShouldHandleReopen`)
- Clicking the Karu Dock icon triggers `applicationShouldHandleReopen(_:hasVisibleWindows:)`, immediately presenting the **Pilot's Flight Logbook** (`Cmd + L`) centered with certified flight hours, distance flown (`NM`), touchdowns, and fleet on-time efficiency.

### 4. Native Dock Context Menu (`applicationDockMenu`)
- Right-clicking the Dock icon exposes quick cockpit actions:
  - 🛫 **Takeoff Flight** / ⏸ **Gate Hold**
  - 📖 **Pilot's Logbook** (`Cmd + L`)
  - ⊞ **Desktop Widgets** (`Cmd + Shift + W`)
  - 🔇 **Mute Ambient Soundscape**

---

## Key Assumptions to Validate
- [ ] **Assumption 1:** Dynamically changing `NSApp.setActivationPolicy` between `.regular` and `.accessory` does not disrupt active floating `NSPanel` HUD windows or notch overlays.
  - *Validation:* Test live policy transitions during active flight sessions in `AppDelegate.swift`.
- [ ] **Assumption 2:** Dock badge string updates via `NSApp.dockTile.badgeLabel` consume `< 0.01%` CPU and do not trigger layout churn.
  - *Validation:* Profile `NSDockTile` updates in Instruments.
- [ ] **Assumption 3:** `applicationShouldHandleReopen` cleanly brings the Logbook `NSWindow` to front even if minimized or unfocused.
  - *Validation:* Unit and integration tests in `AppDelegate`.

---

## MVP Scope

### In Scope
- `showInDock: Bool` user setting stored in `AppFilterRule.swift` / `LocalStorageManager`.
- Dynamic activation policy switching (`.regular` vs `.accessory`) in `AppDelegate`.
- Dock click handler opening Pilot's Logbook (`Cmd + L`).
- Real-time Dock badge velocity string updates (`540 kts`, `STALL`, `HOLD`).
- Native right-click Dock menu (`applicationDockMenu`).

### Not Doing (and Why)
- **Mandatory Dock Icon:** Refused. Karu is fundamentally a stealth menu bar app; the Dock icon MUST be opt-in.
- **Ticking Seconds on Dock Badge:** Refused to prevent timer anxiety and CPU battery drain.
- **Heavy Web/Video Renders in Dock:** Refused. Adheres strictly to native AppKit `NSDockTile` standards.

---

## Open Questions
- None. Requirements clarified and confirmed via user interview.
