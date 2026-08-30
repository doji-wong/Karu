# ADR-010: Direction A Monochrome Avionics Telemetry & Inline Accordion Card Architecture

## Status
Accepted

## Date
2026-08-30

## Context
Karu initially explored multiple UI prototypes, including colorful multi-widget sidebars (`SidebarHUDPanel`), highway road maps (`HighwayNavigationView`), and separate floating popovers for airport and seat class selections.

This created two major issues:
1. **Metaphor Inconsistency:** Mixing highway car navigation (km/h) with flight cards, SpaceX telemetry, and circular dials diluted the brand identity.
2. **Window Clipping Bugs with Sub-Popovers:** When `.popover` was invoked from inside a borderless floating `NSPanel` (e.g. `FloatingHUDPanel`), macOS AppKit could not properly attach the transient popover window chrome, causing severe visual clipping and window border boundary collisions.
3. **Route Inflexibility:** Only the destination airport was customizable, forcing departure to remain fixed.

## Decision
1. **Consolidate on Direction A (Focus Flight & Boarding Pass):**
   - High-contrast pure jet black carbon surface (`#08080A`), obsidian containers (`#151518`), and crisp white typography (`#FFFFFF`).
   - Calibrate telemetry velocity in standard aviation units: **540 kts** (Knots ground speed) and **Nautical Miles (NM)** distance tracking.
2. **Dual Independent Airport Route Selection:**
   - Both Departure (Origin) and Arrival (Destination) airports are independently selectable from global IATA airport nodes (e.g. `YYZ ➔ HND`, `SIN ➔ LHR`, `SFO ➔ HND`).
3. **Inline Accordion Slide Drawers (Zero Popover Clipping):**
   - Replace detached `.popover` sub-windows with smooth inline accordion drawers (`FlightCardDrawer`) directly inside the card container.
   - The card dynamically adjusts its height (`122px` idle ➔ `156px` hover ➔ `348px` drawer expanded) using smooth SwiftUI spring animations (`.spring(response: 0.32, dampingFraction: 0.82)`), completely eliminating `NSPanel` window clipping.

## Alternatives Considered

### Standard AppKit `NSPopover` attachment
- **Pros:** Native system standard.
- **Cons:** Flaky attachment inside non-activating, floating `NSPanel`s; draws drop shadows and borders outside panel bounds.
- **Rejected:** Inline card drawers provide a unified, beautiful mobile-inspired HUD interaction with zero clipping.

### Separate floating modal windows
- **Pros:** Detached management.
- **Cons:** Window clutter on macOS workspaces; disrupts focus.
- **Rejected:** Inline accordion is compact and self-contained.

## Consequences
- **Positive:** Sleek, consistent luxury monochrome boarding pass aesthetic.
- **Positive:** Completely solves window clipping and multi-monitor popover coordinate bugs.
- **Positive:** Users can customize any departure/destination pair with accurate timezone calculations.
- **Negative:** `FocusFlightCard` must manage internal accordion drawer state transitions.
