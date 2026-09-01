# Spec: Desktop Flight Telemetry Widgets (Module: `widget-telemetry`)

## 1. Objective
Deliver an ambient, glanceable macOS Desktop & Notification Center Widget set (Small Airspeed Gauge + Medium Flight Dispatch Board) that displays daily focus flight hours, cruise efficiency, streak count, active route telemetry, and enables 1-click takeoff via macOS 14+ WidgetKit and AppIntents.

---

## 2. Tech Stack & Dependencies
- **Frameworks:** SwiftUI, WidgetKit, AppIntents
- **Platform:** macOS 14.0+ (Sonoma) & macOS 15.0+ (Sequoia)
- **Language:** Swift 5.9+ / Swift 6.x (`@MainActor`, `Sendable`, Swift Concurrency)
- **Data Sharing:** Atomic JSON snapshot persistence via `LocalStorageManager` (App Group / Application Support container)

---

## 3. Core Commands
- **Build Core & App Targets:** `swift build`
- **Build with Warnings as Errors:** `swift build -Xswiftc -warnings-as-errors`
- **Run All Tests:** `swift test`
- **Filter Widget / Snapshot Tests:** `swift test --filter WidgetTelemetryTests`

---

## 4. Architecture & Module Structure

```
Karu/
├── Sources/
│   ├── KaruCore/
│   │   ├── Models/
│   │   │   └── WidgetTelemetrySnapshot.swift   # Shared Codable data contract for widget timeline entries
│   │   └── Storage/
│   │       └── LocalStorageManager.swift       # Saves widget_snapshot.json on flight updates
│   └── Karu/
│       └── UI/
│           └── Widgets/
│               ├── SmallAirspeedGaugeWidgetView.swift   # Small (systemSmall) quota & airspeed ring
│               ├── MediumFlightDispatchWidgetView.swift  # Medium (systemMedium) split dispatch board
│               ├── FlightTelemetryTimelineProvider.swift # WidgetKit TimelineProvider
│               └── WidgetIntents.swift                  # AppIntents for 1-click Takeoff & Gate Hold
└── Tests/
    └── KaruCoreTests/
        └── WidgetTelemetryTests.swift                  # Unit tests for snapshot generation, serialization & recovery
```

---

## 5. Data Model Contract (`WidgetTelemetrySnapshot`)

```swift
public struct WidgetTelemetrySnapshot: Codable, Sendable, Equatable {
    // 1. Current Flight State & Velocity
    public let state: TransitState                 // idle, cruising, trafficStalled, pitStop, completed
    public let currentAirspeedKts: Int             // 540 vs 0

    // 2. Active Route & Navigation
    public let originIATA: String                  // e.g. "SFO"
    public let originCity: String                  // e.g. "San Francisco"
    public let destinationIATA: String             // e.g. "HND"
    public let destinationCity: String             // e.g. "Tokyo"
    public let statusBadgeText: String             // "CRUISING", "GATE HOLD", "TURBULENCE", "STANDBY"

    // 3. Daily Performance & Habit Telemetry
    public let dailyCompletedMinutes: Int          // e.g. 210
    public let dailyGoalMinutes: Int               // e.g. 300
    public let dailyDistanceNM: Double             // e.g. 1890.0
    public let dailyEfficiencyPercentage: Double   // e.g. 94.0
    public let currentStreakDays: Int              // e.g. 12
    public let activeAircraftName: String          // e.g. "A350F"
    public let lastUpdated: Date                   // Timestamp of export
    
    public static var previewMock: WidgetTelemetrySnapshot { ... }
}
```

---

## 6. Visual Design Specifications (Direction A Monochrome Avionics)

### Palette Tokens:
- **Base Background:** `#08080A` (Carbon Matte)
- **Elevated Surfaces:** `#151518` (Card & Pod backgrounds)
- **Borders & Dividers:** `rgba(255, 255, 255, 0.08)`
- **Primary Typography:** `#FFFFFF` (Avionics High-Contrast Sans & Monospace)
- **Secondary Telemetry:** `#8E8E93` (Muted labels & timestamps)
- **Status Accents:**
  - Cruise: `#22C55E` / `#FFFFFF`
  - Gate Hold: `#3B82F6` (Hold Blue)
  - Turbulence Warning: `#F59E0B` (Amber Caution)

### Typography & Layout Rules:
- **Small Widget (`systemSmall`):**
  - Circular progress track indicating `dailyCompletedMinutes / dailyGoalMinutes` (e.g. `210m / 300m`).
  - Centered Airspeed readout (`540` large bold + `KTS` small dot-matrix).
  - Bottom row: Streak pill (`🔥 12d`) and aircraft badge (`A350F`).
- **Medium Widget (`systemMedium`):**
  - **Left Pane (48% width):** "TODAY'S FLIGHT LOG" header, Certified Focus Hours (`3.5h`), Total Distance (`1,840 NM`), Efficiency (`94%`), Daily Goal bar.
  - **Right Pane (52% width):** Route banner (`SFO ✈ HND`), Status indicator badge (`CRUISING 540 kts`), and 1-Click Interactive Button (`TAKEOFF` / `HOLD`).

---

## 7. Testing Strategy
- **Unit Tests (`WidgetTelemetryTests`):**
  - Verify snapshot creation from active `TransitEngine` and `Habit` state.
  - Verify JSON Codable roundtrip serialization.
  - Verify graceful fallback defaults when snapshot file is missing or corrupted.
  - Verify daily progress calculation and streak representation.

---

## 8. Boundaries & Quality Rules
- **Always:** Use atomic file writes when persisting widget snapshot data; support dark mode avionics theme; conform models to `Sendable`.
- **Ask First:** Adding external package dependencies; changing local storage file names.
- **Never:** Use continuous polling timers in widget code; block the main thread decoding snapshots.

---

## 9. Success Criteria
- [ ] `WidgetTelemetrySnapshot` model created with 100% Codable and Sendable compliance.
- [ ] `LocalStorageManager` exports snapshots atomically on every transit engine state change.
- [ ] `SmallAirspeedGaugeWidgetView` and `MediumFlightDispatchWidgetView` render Direction A Monochrome Avionics styling faithfully.
- [ ] Unit tests in `WidgetTelemetryTests.swift` pass 100%.
- [ ] `swift build -Xswiftc -warnings-as-errors` passes cleanly.
