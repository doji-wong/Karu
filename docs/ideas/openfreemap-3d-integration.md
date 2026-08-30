no i# OpenFreeMap 3D Integration Spec

## Overview
Integrate **OpenFreeMap 3D Vector Tiles** (`https://tiles.openfreemap.org/styles/liberty` and `bright`) into Karu's native macOS interface via a lightweight `WKWebView` bridge, providing real-world 3D city navigation with 60° camera pitch, custom start/destination coordinates, and live vehicle tracking.

---

## Technical Design

### 1. `OpenFreeMapView.swift` (`NSViewRepresentable`)
- Embeds MapLibre GL JS with OpenFreeMap 3D Vector Tiles.
- Camera configuration:
  - `pitch: 60` (Isometric 3D perspective with extruded 3D buildings)
  - `bearing: dynamic` (aligns with vehicle driving heading)
  - `zoom: 15.5` (street-level cockpit navigation view)
- Dynamic markers:
  - Live animated vehicle icon positioned at `currentProgress` along the route coordinates.
  - Interactive Waze-style hazard callout balloons plotted on distraction stall events.
- Zero external native dependencies (uses standard macOS `WebKit.framework`).

### 2. Custom Start & Destination Coordinate Support
- Users can set custom route coordinates or choose city presets (e.g. Manila EDSA/Coastal, Tokyo Shinjuku/Metropolitan, SF Golden Gate, London Thames).
- Focus duration is mapped smoothly across the route length.

### 3. State Synchronization (Swift $\to$ JavaScript)
- On state transitions (`.cruising` vs `.trafficStalled`), Swift evaluates JavaScript calls:
  - `window.karuBridge.updateTransitState(state, velocity, hazardAppName)`
  - `window.karuBridge.updateProgress(progressFraction, distanceKm)`
