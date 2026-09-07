# Pre-Flight Route Dispatch & Destination Time Control

## Problem Statement
How might we transform the start of every focus flight into an intentional, low-friction pre-flight dispatch ritual where selecting your departure and destination seamlessly controls your focus duration and flight telemetry?

---

## Recommended Direction: The Inline Avionics Pre-Flight Dispatch Deck

Instead of a generic timer countdown or an unexpected flight launch with stale settings, clicking **TAKEOFF** while parked at the gate transitions `FocusFlightCard` into the **Pre-Flight Dispatch Deck**:

1. **Departure Location (Origin)**:
   - Defaults to the previous airport or automatically matches your local macOS timezone (e.g. `YYZ`, `MNL`, `SFO`), with a 1-tap popout search to change departure airport or swap with destination.
2. **Arrival Destination**:
   - Easily selectable from global IATA airport nodes (`HND`, `LHR`, `CDG`, `SIN`, `JFK`, etc.) with flag, city name, local time, and great-circle nautical distance.
3. **Dedicated Destination Time Control**:
   - Each destination remembers its own customized flight duration (e.g., Tokyo `HND` = 25m sprint, London `LHR` = 60m deep work).
   - Switching destinations instantly restores that destination's target time.
   - Provides quick preset pills (`15m`, `25m`, `45m`, `60m`, `90m`), precision stepper (`[-]` / `[+]`), continuous slider, and a live arrival ETA in the destination airport's local timezone.
4. **Clear for Takeoff Confirmation**:
   - A single high-contrast crisp white button: `[ ✈️ CLEAR FOR TAKEOFF ]`.
   - Starts cruising at 540 kts, kicks off vehicle-specific ambient audio, and seamlessly returns to the active flight HUD.

---

## Stress-Test & Evaluation

| Dimension | Assessment | Notes |
| :--- | :--- | :--- |
| **User Value** | **High (Painkiller for Session Intentionality)** | Eliminates accidental starts and mental resistance by framing each work session as an intentional flight between two real-world cities. |
| **Feasibility** | **High / Low Cost** | Leverages existing `DestinationAirport`, `TransitEngine`, and `FocusFlightCard` infrastructure with zero new external dependencies. |
| **Differentiation** | **Extreme** | No other focus app connects destination timezones, flight corridors, and per-city duration memory into a tactile native macOS HUD. |

---

## Key Assumptions to Validate
- [ ] **Assumption 1 (Low Friction):** Pilots want to confirm their route and duration prior to takeoff without feeling slowed down by an extra click when taking off repeatedly.
  - *Validation*: Keep the origin pre-filled and destination time pre-loaded so takeoff is just 1 glance and 1 confirm click if no changes are desired.
- [ ] **Assumption 2 (Per-City Duration Habits):** Users naturally associate specific destinations with specific session types (e.g., short sprints to Tokyo, transcontinental deep work to London).
  - *Validation*: Storing `destinationDurations` in `KaruPreferences` allows immediate testing and custom personalization per user.
- [ ] **Assumption 3 (Window Size Elegance):** Expanding the Menu Bar popover downward to 390px feels smooth and does not clip or lose keyboard focus during airport search.
  - *Validation*: Enable `canBecomeKey = true` and dynamic height animation on `MenuBarPanel`.

---

## MVP Scope

### In Scope:
- **Pre-Flight Dispatch Drawer**: Integrated inside `FocusFlightCard` (`.preFlightDispatch`), opening whenever `TAKEOFF` is clicked while `engine.state == .idle`.
- **Dual Airport Selection**: Origin (departure) and Destination (arrival) with search, flags, IATA codes, and city names.
- **Dedicated Destination Time Control**:
  - Duration presets: `15m`, `25m`, `45m`, `60m`, `90m`.
  - Stepper (`[-]` / `[+]`) and slider.
  - Live destination arrival ETA and timezone offset display.
- **Local Persistence**: `KaruPreferences.destinationDurations` dictionary storing user-configured flight times per destination.
- **Dynamic Menu Bar Panel Resizing**: `MenuBarPanel.updatePanelSize` dynamically adjusting height from 122px/156px to 390px, supporting keyboard entry.

---

## Not Doing (and Why)

- **Not Doing Mandatory Multi-Step Wizards**: We are not forcing users through a multi-page modal wizard with separate "Next" buttons. All three controls (Origin, Destination, Time) live unified in one glanceable avionics deck.
- **Not Doing Rigid Fixed Flight Times by Geography**: We are not locking Tokyo to strictly 25 minutes or London to strictly 60 minutes based on real-world flight hours. Focus timers must prioritize user workflow flexibility over physical airliner flight time simulation.
- **Not Doing Mandatory Weather/Fuel Simulators**: No fuel loadout math or synthetic delay simulations to avoid clutter and maintain focus on deep work.

---

## Open Questions & Next Steps
- **Next Step:** Update `implementation_plan.md` to reflect these refined constraints and proceed with code implementation.
