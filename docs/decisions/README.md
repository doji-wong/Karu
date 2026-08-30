# Architecture Decision Records (ADRs)

This directory documents all significant technical and architectural decisions for the **Karu** project.

---

## 📋 Decision Log

| ADR | Title | Status | Date | Primary Impact |
|---|---|---|---|---|
| [ADR-001](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/decisions/ADR-001-tech-stack-and-architecture.md) | Native macOS Swift / SwiftUI & AppKit Architecture | **Accepted** | 2026-08-29 | Core native macOS technology choice; rejected Electron/Tauri |
| [ADR-002](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/decisions/ADR-002-distraction-detection-engine.md) | Event-Driven Distraction Detection via `NSWorkspace` | **Accepted** | 2026-08-29 | Battery-friendly event notifications; zero polling loops |
| [ADR-003](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/decisions/ADR-003-hud-window-and-menubar-management.md) | Menu Bar Popover & Floating HUD Panel Architecture | **Accepted** | 2026-08-29 | AppKit `NSStatusItem` & non-activating `NSPanel` overlay |
| [ADR-004](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/decisions/ADR-004-local-data-and-habit-persistence.md) | Local-First Data, Habit, and Travel Log Persistence | **Accepted** | 2026-08-29 | 100% local atomic JSON file storage; zero cloud tracking |
| [ADR-005](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/decisions/ADR-005-notch-hud-integration.md) | MacBook Notch HUD & Side-Notch Wings Integration | **Accepted** | 2026-08-29 | `NSScreen.auxiliaryTopLeftArea` hardware notch telemetry |
| [ADR-006](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/decisions/ADR-006-ambient-audio-engine.md) | Adaptive In-Flight Ambient Audio Engine via `AVAudioEngine` | **Accepted** | 2026-08-29 | Low-latency audio loops with 400ms cruise/stall crossfade |
| [ADR-007](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/decisions/ADR-007-app-classification-and-custom-filters.md) | Customizable App Classification & Filter Rules Architecture | **Accepted** | 2026-08-29 | Triple-state category engine (`focus`, `hazard`, `neutral`) |
| [ADR-008](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/decisions/ADR-008-in-flight-scratchpad-architecture.md) | In-Flight Scratchpad & Note-Taking Architecture | **Superseded** | 2026-08-29 | Superseded by ADR-009 (eliminated notes friction) |
| [ADR-009](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/decisions/ADR-009-scratchpad-elimination-and-cognitive-simplicity.md) | Elimination of In-Flight Scratchpad for Cognitive Simplicity | **Accepted** | 2026-08-30 | Deletion of notes store and UI to eliminate cognitive clutter |
| [ADR-010](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/decisions/ADR-010-monochrome-avionics-and-inline-accordion-card.md) | Direction A Monochrome Avionics & Inline Accordion Drawers | **Accepted** | 2026-08-30 | Pure carbon matte `#08080A`, Knots/NM math, dual airports, zero popover clipping |
| [ADR-011](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/decisions/ADR-011-one-click-running-application-radar.md) | Live 1-Click Running Application Radar Architecture | **Accepted** | 2026-08-30 | `NSWorkspace` active application discovery with native icons & 1-click rules |
| [ADR-012](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/decisions/ADR-012-pilot-logbook-and-flight-hours-telemetry.md) | Pilot Logbook & Flight Hours Telemetry Architecture | **Accepted** | 2026-08-30 | Dedicated Logbook window (`Cmd + L`) tracking hours, distance & efficiency |

---

## 🧭 ADR Lifecycle & Review Guidelines
1. **Immutable History:** Never edit past ADRs to rewrite history. When a decision changes, create a new ADR that references and supersedes the former.
2. **Standard Format:** Every ADR must include **Status**, **Date**, **Context**, **Decision**, **Alternatives Considered** (with reasons for rejection), and **Consequences**.
