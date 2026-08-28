# Live Focus Route & Delivery Tracking Spec

## Overview
Replaces generic maps with a **Live Delivery & Transit Tracking Interface** (inspired by Uber, DoorDash, and Waze tracking), where the user's focus session is visualized as an active route journey:
- **Full Route Polyline:** Shows the full path from Origin (Focus Start) to Destination (Session Complete) in subtle dark gray.
- **Progress Polyline:** Dynamically highlights the completed portion of the route in luminous neon emerald (`#10B981`) as focus time elapses.
- **Active Vehicle Marker:** A vehicle badge gliding along the route with an attached floating popup pill (`"18 min away · 100 km/h"`).
- **Origin & Destination Pins:**
  - Origin: Emerald Starting On-Ramp pin.
  - Destination: Rose Checkered Flag / Goal Arrival pin.
- **Traffic Gridlock Alerts:** Marker turns amber during distraction stalls with `"Traffic Hazard: [App Name]"` popup.
