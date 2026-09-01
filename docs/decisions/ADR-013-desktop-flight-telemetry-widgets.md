# ADR-013: Desktop Flight Telemetry Widgets & Curated Avionics Metrics

## 📄 Status
**Accepted** (2026-09-01)

---

## 🧭 Context & Problem Statement
Users frequently work with multiple windows across displays, leaving empty desktop wallpaper or Notification Center space. While Karu offers real-time awareness via the Menu Bar and Notch Wings, users need an **ambient, glanceable desktop overview** of their daily focus progress, habit streak, and flight efficiency without switching windows or opening the app popover.

However, desktop focus widgets often suffer from three major anti-patterns:
1. **Timer Anxiety:** Sub-second countdown timers on the desktop cause cognitive fragmentation and cortisol spikes.
2. **Data Overload:** Cramming complex incident logs and GPS coordinates onto a desktop widget creates visual clutter.
3. **Battery Drain:** Continuous background polling to update desktop widgets violates Karu's `< 0.5%` CPU budget.

---

## 🎯 Architectural Decision

We adopt **Option A (Dual Widget Set)** powered by Apple **WidgetKit** and **AppIntents** in macOS 14+ (Sonoma) and macOS 15+ (Sequoia):

1. **Curated 12-Field Data Contract (`WidgetTelemetrySnapshot`):**
   - **Daily Quota Telemetry:** `dailyCompletedMinutes`, `dailyGoalMinutes`, `dailyDistanceNM`, `dailyEfficiencyPercentage`, `currentStreakDays`, `activeAircraftName`.
   - **Active Flight Ops:** `state`, `currentAirspeedKts`, `originIATA`, `destinationIATA`, `statusBadgeText`, `lastUpdated`.
   - **Intentional Cuts (Per HIG & Research):** Sub-second countdown tickers, individual distraction app names, and lifetime vanity metrics are **excluded** from the widget (reserved for the dedicated `Cmd + L` Logbook).

2. **Direction A Monochrome Avionics Visual Identity:**
   - **Base Palette:** `#08080A` carbon matte background, `#151518` elevated containers, `#FFFFFF` high-contrast avionics text, dot-matrix LED typography, and amber `#F59E0B` turbulence warning indicators.
   - **Small Widget (`systemSmall`):** Circular progress ring (`completed / goal`), center `540 KTS` airspeed indicator, and streak/fleet pill.
   - **Medium Widget (`systemMedium`):** Split-screen dispatch board: Left column for Daily Flight Log (Hours, NM, Efficiency %, Streak); Right column for Active Route (`SFO ✈ HND`) and interactive 1-click **Takeoff / Gate Hold** button.

3. **Zero-Polling Event-Driven Data Sharing:**
   - Snapshots are written atomically to `Application Support/Karu/widget_snapshot.json` by `LocalStorageManager` only on state transitions and flight completion.
   - Timeline invalidations are dispatched via `WidgetCenter.shared.reloadAllTimelines()`. Zero background polling loops.

---

## ⚖️ Alternatives Considered & Rejected

| Alternative | Reason for Rejection |
|---|---|
| **Sub-Second Live Ticking Timer** | Rejected. Ticking second counters increase cognitive stress and drain battery. Apple HIG recommends static progress rings. |
| **Large Heatmap Widget (`systemLarge`)** | Rejected for initial release. 7-day dense charts belong in the certified Logbook window (`Cmd + L`) to maintain widget minimalism. |
| **Direct Polling from Widget Extension** | Rejected. Violates Karu's zero-polling rule (ADR-002). Timeline providers refresh solely on state-driven events. |

---

## 🚀 Consequences & Impact

### Positive:
- Provides instant glanceable motivation in `< 2 seconds` directly from the desktop.
- 1-Click Takeoff via `AppIntent` eliminates friction to start a focus flight.
- 100% local-first, zero cloud dependencies, `< 0.01%` background CPU usage.

### Negative / Trade-offs:
- Desktop widgets on macOS require App Group or shared directory access for sandbox compatibility.
