# ADR-015: Pre-Flight Dispatch Deck, Dynamic Route/Time Clearance, and Modular Aviation Drawers

## Status
Accepted

## Date
2026-09-08

## Context
In earlier iterations of Karu, initiating a focus session occurred via an instantaneous takeoff action. While immediate, this interaction presented several product and architectural limitations:

1. **Lack of Session Intentionality:** Launching directly into flight without confirming destination, duration, or mission objective often led to friction or mid-flight cancellations when the preset did not match the user's immediate work goal.
2. **Disconnected Seat & Task Context:** Seat assignment (`FocusSeatClass` — e.g. `1A Deep Work`, `5F Code`) was hidden behind detached popout tickets (`OrbitingTicketPopoutView`) rather than integrated into the flight clearance ritual.
3. **Monolithic UI Architecture:** `FocusFlightCard.swift` had grown to over 1,200 lines, intermixing active flight telemetry, boarding pass layout, airport picker search lists, audio drawer controls, and custom task text fields. This high cyclomatic complexity made layout calibration error-prone.
4. **Stale Duration Defaults:** Users naturally associate specific routes with distinct focus modes (e.g. short 25-minute sprints to Tokyo `HND`, 60-minute deep architecture blocks to London `LHR`). The app lacked per-airport duration memory.
5. **Formatter Heap Churn:** Formatting dates, ETAs, flight times, and countdown strings across multiple view updates per second incurred repeated `DateFormatter` and `NumberFormatter` instantiations.

---

## Decision

### 1. Pre-Flight Dispatch Clearance Deck (`PreFlightDispatchDeckView.swift`)
Replaced the abrupt takeoff action with a structured 4-stage inline avionics clearance deck presented whenever `engine.state == .idle`:
- **01 & 02 / Dual Airport Corridor:** Displays departure and arrival airports with IATA badges, local city times, and a 1-tap corridor swap button (`⇄`). Tapping either airport reveals the full search drawer.
- **03 / Seat & Cabin Class Strip:** A horizontal selector with 5 standard presets (`1A Deep Work`, `2B Study`, `3C Research`, `4D Read`, `5F Code`) and a custom `7X` pill that smoothly expands the `CustomMissionInputRow` for direct task title and seat code entry.
- **04 / Destination Time Control:** Instant preset pills (`15M`, `25M`, `45M`, `60M`, `90M`), precision `[-]` / `[+]` steppers, continuous slider, and a live arrival ETA computed in the destination airport's local timezone.
- **Clear for Takeoff Action:** A full-width, high-contrast button (`[ ✈️ CLEAR FOR TAKEOFF ]`) that synchronizes route, duration, and seat into `TransitEngine` and transitions smoothly to cruising velocity (540 kts).

### 2. Modular Drawer Decomposition (`FlightCardDrawers.swift`)
Decomposed `FocusFlightCard` into dedicated, single-responsibility subviews:
- `FlightCardAirportPickerDrawer`: Searchable global airport grid with IATA codes, cities, country flags, and timezones.
- `FlightCardSeatDrawer`: Standalone seat selection and mission assignment drawer.
- `FlightCardAudioDrawer`: Vehicle ambient soundscape picker and volume attenuator.
- `FlightCardLogbookDrawer`: In-flight quick access to recent flight records and efficiency telemetry.
- `FlightCardAppRadarDrawer`: Live running application scan and 1-click classification.
- `CustomMissionInputRow`: Reusable compact text input strip with automatic uppercase styling.
- `SelectablePill`: Reusable high-contrast avionics pill button.

### 3. Dynamic Destination Duration Memory (`KaruPreferences.destinationDurations`)
- Extended `KaruPreferences` with `destinationDurations: [String: Int]` storing customized flight minutes keyed by airport IATA code.
- When a pilot switches destination in `PreFlightDispatchDeckView`, the target duration is automatically restored to their previous preference for that destination (defaulting to 25m if unconfigured).

### 4. Centralized High-Performance Formatter Cache (`KaruFormatters.swift`)
Consolidated all avionics string formatting into a `@MainActor` cached static enum:
- `formatFlightTimestamp(_:timeZoneIdentifier:)`: Cached `EEE, h:mm a` formatter with timezone switching.
- `formatETA(_:timeZoneIdentifier:)`: Cached `h:mm a` destination arrival formatter.
- `formatLogbookDate(_:)`: Cached `MMM d, h:mm a` historical log formatter.
- `formatTicketDate(_:)`: Cached `yyyy/MM/dd` ticket formatter.
- `formatDistanceKm(_:)`: Decimal number formatter with grouping separators.
- `formatNegativeRemainingTime(_:)`: Standardized countdown time formatting (`-MM:SS` / `-HH:MM`).

---

## Alternatives Considered

1. **Multi-Step Modal Wizard:**
   - *Proposal:* A multi-page wizard prompting (Step 1: Origin, Step 2: Destination, Step 3: Duration, Step 4: Seat).
   - *Rejected:* Introduces too much friction for routine daily focus blocks. A unified 1-page deck allows 1-tap clearance for returning pilots.
2. **Graphical Top-Down Aircraft Seat Map:**
   - *Proposal:* An interactive 2D cabin layout with seat rows (1A through 24F).
   - *Rejected:* Requires over 120px of vertical space, causing window clipping in menu bar popovers and slowing down task selection.
3. **Rigid Real-World Flight Durations:**
   - *Proposal:* Lock flight durations to real-world airliner hours (e.g. SFO to HND locked to 11 hours).
   - *Rejected:* Karu is a productivity tool, not a flight simulator; users require adaptable durations between 15 and 90 minutes.

---

## Consequences

- **Positive:** Takeoffs feel intentional and rewarding, reducing mid-flight cancellations and priming the user's mindset before focus begins.
- **Positive:** `FocusFlightCard.swift` is reduced by over 50%, with clear boundaries between active flight monitoring, pre-flight clearance, and modular slide-out drawers.
- **Positive:** Zero frame-time regressions or memory churn from Date/Number formatters.
- **Positive:** Unit-tested via `TransitEngineTests.testPreFlightDispatchClearance` ensuring route, seat, and custom duration propagate correctly on takeoff.
