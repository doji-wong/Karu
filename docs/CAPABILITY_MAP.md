# Capability Map: Karu (Focus Flight & Avionics Telemetry)

This document establishes the decoupled module boundaries, dependencies, and build order for Karu.

---

## 🗺️ Module Registry

| Module ID | Target | Primary Responsibility | Input Boundary / Dependencies | Output Boundary / Consumers |
|---|---|---|---|---|
| `karu-models` | `KaruCore` | Core immutable domain models (`TransitState`, `TripSession`, `Habit`, `AircraftType`, `AircraftProfile`, `AppFilterRule`, `DestinationAirport`). | Standard Library, Foundation | All modules |
| `transit-engine` | `KaruCore` | Velocity calculation (540 kts cruise vs 0 kts turbulence), elapsed cruise/stalled time tracking, route progress, and gate holds. | `karu-models` | `macos-windowing-ui`, `audio-engine`, `local-storage` |
| `app-classifier` | `KaruCore` | $O(1)$ bundle ID classification (Focus / Distraction / Neutral) and event-driven `NSWorkspace` app listener. | `karu-models`, `AppKit.NSWorkspace` | `transit-engine` |
| `local-storage` | `KaruCore` | 100% local atomic JSON file persistence (`~/Library/Application Support/Karu/`) for habits, trip logs, rules, and fleet preferences. | `karu-models`, `Foundation.FileManager` | `transit-engine`, `macos-windowing-ui` |
| `audio-engine` | `KaruCore` | `AVAudioEngine` low-latency ambient soundscapes with 400ms crossfade between cruise and turbulence states, plus cabin PA voice alerts. | `karu-models`, `AVFoundation` | `transit-engine`, `macos-windowing-ui` |
| `preflight-dispatch` | `Karu` | Pre-flight mission dispatch deck, dual route corridor with swap, 1-tap seat selector strip, dynamic destination duration memory, and modular accordion drawers. | `transit-engine`, `audio-engine`, `karu-models`, `SwiftUI` | `macos-windowing-ui` |
| `telemetry-widgets` | `KaruWidgets` & `Karu` | Desktop WidgetKit extensions (`systemSmall`, `systemMedium`) and interactive `NSDockTile` live cockpit telemetry. | `karu-models`, `local-storage`, `WidgetKit`, `AppIntents` | macOS Desktop, Dock |
| `macos-windowing-ui` | `Karu` | Presentation layer: MenuBar Popover, Notch Wings, Floating HUD Card, FocusFlightCard, Garage Hangar, Settings (1-Click App Radar), Pilot Onboarding, and Pilot's Logbook. | `transit-engine`, `app-classifier`, `local-storage`, `audio-engine`, `preflight-dispatch`, `AppKit`, `SwiftUI` | End User (macOS Desktop) |

---

## 🔗 Dependency Graph & Architecture

```mermaid
graph TD
    subgraph KaruCore [Target: KaruCore (Pure Logic)]
        M[karu-models] --> TE[transit-engine]
        M --> AC[app-classifier]
        M --> LS[local-storage]
        M --> AE[audio-engine]
        
        AC -->|AppCategory Dispatch| TE
        TE -->|State Transitions| AE
        TE -->|Flight Session Records| LS
    end
    
    subgraph KaruApp [Target: Karu (UI & Windowing)]
        UI[macos-windowing-ui]
        UI --> MB[MenuBar & Popover]
        UI --> NW[Notch Wings]
        UI --> FH[Floating HUD Card]
        UI --> FFC[FocusFlightCard & Accordion Drawers]
        UI --> LB[LogbookView (Cmd + L)]
        UI --> GH[Garage Hangar]
        UI --> SET[AppFilterSettings & 1-Click Radar]
    end
    
    TE --> UI
    AC --> UI
    LS --> UI
    AE --> UI
```

### Approved Build Order:
1. `karu-models` (`Sources/KaruCore/Models/`)
2. `transit-engine` (`Sources/KaruCore/Core/TransitEngine.swift`)
3. `app-classifier` (`Sources/KaruCore/Core/AppClassifier.swift`, `DistractionMonitor.swift`)
4. `local-storage` (`Sources/KaruCore/Storage/LocalStorageManager.swift`)
5. `audio-engine` (`Sources/KaruCore/Core/AudioEngine.swift`)
6. `macos-windowing-ui` (`Sources/Karu/UI/`, `AppDelegate.swift`, `KaruApp.swift`)
