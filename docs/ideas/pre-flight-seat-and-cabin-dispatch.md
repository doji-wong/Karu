# Pre-Flight Seat Assignment & Cabin Class Dispatch

## Problem Statement
How might we integrate seat assignment (task categorization and mission objective) into Karu's pre-flight takeoff sequence so choosing what you are about to work on feels as tangible and satisfying as taking your seat on a supersonic airliner, without introducing friction or cognitive drag?

---

## Recommended Direction: High-Density Inline Seat Strip with Expandable Custom Mission Deck

Rather than hiding seat selection behind an extra drawer drill-down or forcing a clunky multi-step wizard, the pre-flight dispatch view incorporates an **Avionics Horizontal Seat Strip** directly between Route Selection and Time Control:

```
┌─────────────────────────────────────────────────────────────┐
│ 01 / DEPARTURE: 🇨🇦 YYZ 10:45 AM    ⇄   02 / ARRIVAL: 🇯🇵 HND 11:45 PM │
├─────────────────────────────────────────────────────────────┤
│ 03 / SEAT & CABIN CLASS                                     │
│ [ 🧠 1A DEEP ] [ 🎓 2B STUDY ] [ 📚 3C RSCH ] [ 📖 4D READ ] │
│ [ ⚡️ 5F CODE ] [ ⚙️ 7X CUSTOM ]                              │
│                                                             │
│ (If 7X selected):                                           │
│ [ Seat Code: 7X ]  [ Task: BACKEND AUTH ENGINE            ] │
├─────────────────────────────────────────────────────────────┤
│ 04 / TIME CONTROL (HND · TOKYO)                     ETA 00:10 │
│ [15M]  [25M]  [45M]  [60M]  [90M]                           │
│ [ - ] ━━━━━━━●━━━━━━━━━━━━ [ + ]  25M                       │
├─────────────────────────────────────────────────────────────┤
│                 [ ✈️ CLEAR FOR TAKEOFF ]                     │
└─────────────────────────────────────────────────────────────┘
```

### Key Behaviors:
1. **1-Tap Seat Assignment:**
   - Tap any badge (`1A`, `2B`, `3C`, `4D`, `5F`, `7X`) to immediately bind the seat class, cabin title, badge icon, and color theme.
   - High-contrast visual highlight: Selected seat adopts crisp white background with bold black typography, while unselected seats remain sleek dark obsidian pills.
2. **Inline Custom Mission Entry (7X):**
   - Tapping `7X` smoothly slides open an inline dual-field deck directly underneath the pills: an editable seat code (default `7X`, up to 3 chars) and custom task title (e.g. `AUTH ENGINE`, `MATH CH 4`).
   - Entering text updates the engine's active mission immediately.
3. **Independent Control Planes:**
   - Seat assignment determines the focus modality and task classification (saved to `TripSession.seatCode` and `taskTitle`).
   - Destination determines physical distance (`NM`), arrival timezone (`ETA`), and remembered session duration (`destinationDurations`).
   - They operate as independent, composable axes of control.

---

## Stress-Test & Evaluation

| Dimension | Assessment | Notes |
| :--- | :--- | :--- |
| **User Value** | **High (Painkiller for Session Intentionality)** | Declaring what you are working on before takeoff primes the brain for singular focus and creates pristine categorization in the Pilot's Logbook (`Cmd + L`). |
| **Feasibility** | **High / Low Friction** | Reuses existing `FocusSeatClass` models and `engine.updateSeat(...)` calls. Requires ~40px of vertical space in `FocusFlightCard`. |
| **Differentiation** | **Extreme** | No other focus timer treats task categories as physical aircraft seat reservations with cabin classes (First Suite, Quiet Zone, Flight Deck). |

---

## Hidden Assumptions & Stress Points

1. **Space Constraint in Menu Bar Popover:**
   - *Assumption:* Adding the seat strip will fit cleanly within the popover without making the window feel overly tall.
   - *Validation:* Standardizing the pre-flight dispatch height to ~440px ensures complete visibility on all MacBook displays while maintaining ample breathing room.
2. **Text Editing in Menu Bar Panels:**
   - *Assumption:* Users can click into the custom task `TextField` and type without losing panel focus.
   - *Validation:* `MenuBarPanel.canBecomeKey = true` has already been enabled in `MenuBarController.swift`, ensuring native keyboard focus and key events work seamlessly.
3. **Speed of Departure:**
   - *Assumption:* Returning pilots don't want to re-select their seat every single flight if they are working on the same task.
   - *Validation:* The dispatch card pre-selects the last active seat by default. If no changes are needed, the pilot simply hits `[ ✈️ CLEAR FOR TAKEOFF ]` immediately.

---

## MVP Scope

### In Scope:
- **Horizontal Seat Strip in `preFlightDispatchView`:**
  - 5 standard seats: `1A` (Deep Work), `2B` (Study), `3C` (Research), `4D` (Read), `5F` (Code).
  - 1 custom seat pill: `7X` (Custom Mission).
- **Inline Custom Deck:**
  - Appears when `7X` is active, allowing editing of seat code and task description with auto-capitalization.
- **Engine Synchronization:**
  - Immediately synchronizes with `TransitEngine.updateSeat(...)` so HUD, Notch wings, Menu Bar item, and Logbook reflect the chosen seat upon takeoff.
- **Layout Calibration:**
  - Calibrate `FocusFlightCard` height for `.preFlightDispatch` to accommodate both route corridor, seat strip, and time controls smoothly.

---

## Not Doing (and Why)

- **Not Doing Full-Screen Cabin Layout:** A top-down graphical seat map takes too much vertical real estate (>120px) and adds unnecessary interaction friction to a routine workflow.
- **Not Doing Mandatory Task Typing:** Forcing a pilot to type a sentence before every flight creates cognitive resistance. Standard presets (`1A Deep Work`, `5F Coding`) provide instant 1-tap clearance.
- **Not Doing Rigid Seat-to-Duration Coupling:** We do not lock `1A` to 45m or `5F` to 90m; duration memory remains anchored to the destination airport, giving the pilot full autonomy.

---

## Open Questions & Verification Plan
- **Verification:**
  1. Build with `swift build -Xswiftc -warnings-as-errors`.
  2. Run unit tests (`swift test`) to verify `startTrip` captures the selected seat and custom duration accurately.
  3. Verify keyboard entry in custom task field works cleanly.
