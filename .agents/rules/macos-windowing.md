# macOS Windowing & Notch Geometry

## 1. Notch Wings (`NSScreen.auxiliaryTopLeftArea` / `auxiliaryTopRightArea`)
- Modern MacBooks (M1/M2/M3 Pro & Air) feature a physical camera notch.
- Query `screen.auxiliaryTopLeftArea` and `screen.auxiliaryTopRightArea`:
  - If areas are non-nil and width > 0: Position the left wing (velocity) and right wing (progress/habit) directly in the auxiliary areas.
  - If areas are nil or user is on an external display (Studio Display / UltraWide): Fall back to the Menu Bar HUD status item and/or compact floating HUD pill.
- Re-evaluate screen layout upon `NSApplication.didChangeScreenParametersNotification`.

## 2. Menu Bar Status Item & Popover
- `NSStatusItem` configured with `NSStatusItem.variableLength`.
- Dynamic status icon reflecting transit state:
  - Cruising: Neon emerald route line glyph.
  - Traffic Stalled: Amber hazard triangle glyph.
  - Idle: Dim monochrome route glyph.
- `NSPopover` with `behavior = .transient` for the cockpit diagnostic dropdown.

## 3. Floating HUD Overlay Panel
- Custom `NSPanel` subclass:
  - `styleMask: [.nonactivatingPanel, .hudWindow, .borderless, .resizable]`
  - `level: .floating`
  - `collectionBehavior: [.canJoinAllSpaces, .fullScreenAuxiliary]`
  - `isMovableByWindowBackground: true`
  - `hasShadow: true`
- Ensures continuous visibility over full-screen IDEs and browser documents without stealing keyboard focus.
