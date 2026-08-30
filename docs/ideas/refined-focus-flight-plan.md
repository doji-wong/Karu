# Karu: Refined Focus Flight & Minimalist Boarding Pass Architecture

## 1. Problem Statement
How might we build an ultra-premium native macOS **Focus Flight Tracker** where work sessions feel like serene high-altitude flights—featuring a minimalist boarding-pass card with dual selectable airports (`YYZ ➔ HND`), smooth inline accordion selection drawers, 1-click running app classification radar, and a clean pilot logbook while completely eliminating note-taking clutter?

---

## 2. Core Decisions & Scope

### In-Scope:
1. **Focus Flight Theme:** Direction A monochrome carbon aesthetic (`#08080A`), 5x7 Dot-Matrix LED typography, and genuine aviation telemetry (knots, flight levels, nautical miles).
2. **Dual Selectable Airport Corridors:** Both Origin and Destination airports are independently selectable with live nautical distance calculation and time-zone conversion.
3. **Inline Accordion Drawers:** Route and seat selection smoothly slide open directly inside the card (zero popup clipping).
4. **Minimal Floating Card:** High-contrast floating HUD pill sits on screen when the Menu Bar popover is closed/minimized (`Cmd + Shift + F`).
5. **1-Click Live App Radar:** Preferences scans `NSWorkspace.shared.runningApplications` with app icons for 1-click classification.
6. **Aircraft Fleet & Cabin Soundscape:** 5 aircraft (A350F, B787, Concorde, G650, C172) with acoustic pink noise cabin hums and dual-tone seatbelt chimes.
7. **Clean Pilot's Logbook (`Cmd + L`):** Track total flight hours, focus streaks, and on-time efficiency %.

### Explicitly Cut (Not Doing):
1. **No In-Flight Scratchpad / Notes:** Ditching notes eliminates cognitive friction and keeps the app 100% focused on momentum.
2. **No Popover Sub-Windows:** All dropdowns animate inline within card boundaries.
3. **No Heavy 900px Sidebar Panels:** The interface remains ultra-minimal.
