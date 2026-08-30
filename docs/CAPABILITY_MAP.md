# Capability Map: Karu (macOS Habit & Focus Timer)

This document establishes the decoupled module boundaries, dependencies, and build order for Karu.

---

## 🗺️ Module Registry

| Module ID | Target | Primary Responsibility | Input Boundary / Dependencies | Output Boundary / Consumers |
|---|---|---|---|---|
| `karu-models` | `KaruCore` | Core immutable domain models (`TransitState`, `TripSession`, `Habit`, `VehicleProfile`, `AppFilterRule`). | Standard Library, Foundation | All modules |
| `transit-engine` | `KaruCore` | Velocity calculation (100km/h vs 0km/h), elapsed cruise/stall time tracking, route progress, and pit stops. | `karu-models` | `macos-windowing-ui`, `audio-engine`, `local-storage` |
| `app-classifier` | `KaruCore` | $O(1)$ bundle ID classification (Focus / Distraction / Neutral) and event-driven `NSWorkspace` app listener. | `karu-models`, `AppKit.NSWorkspace` | `transit-engine` |
| `local-storage` | `KaruCore` | 100% local atomic JSON file persistence (`~/Library/Application Support/Karu/`) & auto-saving scratchpad store. | `karu-models`, `Foundation.FileManager` | `transit-engine`, `macos-windowing-ui` |
| `audio-engine` | `KaruCore` | `AVAudioEngine` low-latency ambient audio loops with 400ms crossfade between cruise and stall states. | `karu-models`, `AVFoundation` | `transit-engine`, `macos-windowing-ui` |
| `macos-windowing-ui` | `Karu` | Presentation layer: MenuBar Popover, Edge-Docked Sidebar HUD, Notch Wings, Floating HUD, Aviation & Navigation Cockpit cards, Garage & Settings. | `transit-engine`, `app-classifier`, `local-storage`, `audio-engine`, `AppKit`, `SwiftUI` | End User (macOS Desktop) |

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
        TE -->|Session Records| LS
    end
    
    subgraph KaruApp [Target: Karu (UI & Windowing)]
        UI[macos-windowing-ui]
        UI --> MB[MenuBar & Popover]
        UI --> SB[Sidebar HUD Panel]
        UI --> NW[Notch Wings]
        UI --> FH[Floating HUD]
        UI --> NAV[Navigation & Aviation Cockpit]
        UI --> GH[Garage & Settings]
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
4. `local-storage` (`Sources/KaruCore/Storage/`)
5. `audio-engine` (`Sources/KaruCore/Core/AudioEngine.swift`)
6. `macos-windowing-ui` (`Sources/Karu/UI/`, `AppDelegate.swift`, `KaruApp.swift`)

