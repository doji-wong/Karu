# Architectural Rules & Boundaries

## 1. System Components & Flow

```
                     ┌───────────────────────────────┐
                     │ NSWorkspace App Notifications │
                     └───────────────┬───────────────┘
                                     │ (didActivateApplication)
                                     ▼
                     ┌───────────────────────────────┐
                     │       AppClassifier           │
                     │  (Focus / Distraction / Neut) │
                     └───────────────┬───────────────┘
                                     │ (AppFocusCategory)
                                     ▼
                     ┌───────────────────────────────┐
                     │        TransitEngine          │
                     │  - Velocity (100km/h vs 0km/h)│
                     │  - Elapsed / Cruise / Stalled │
                     │  - Distance & ETA calculation │
                     └───────┬───────────────┬───────┘
                             │               │
             ┌───────────────▼┐             ┌▼────────────────┐
             │ UI Controller  │             │   AudioEngine   │
             │ - Notch Wings  │             │ - Ambient Loop  │
             │ - MenuBar HUD  │             │ - 400ms cross-  │
             │ - Floating HUD │             │   fade on stall │
             └────────────────┘             └─────────────────┘
```

## 2. Resource Budgets
- **Continuous CPU:** Must stay below 0.5% during cruising.
- **Active Memory:** Must stay below 45 MB total footprint.
- **Cold Start Time:** Under 300 ms to interactive menu bar status item.

## 3. Strict Event-Driven Pattern
- Polling loops for system state are strictly prohibited.
- Application activation must listen to `NSWorkspace.didActivateApplicationNotification`.
- Display configuration changes must listen to `NSApplication.didChangeScreenParametersNotification`.
- Audio playback must use `AVAudioEngine` and `AVAudioPCMBuffer` pre-loading.
