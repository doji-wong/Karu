import SwiftUI
import WebKit
import KaruCore

/// Scenic city route presets for the Live Route Tracker.
public enum CityRoutePreset: String, CaseIterable, Identifiable {
    case manilaBGC = "Manila BGC Expressway"
    case tokyoShinjuku = "Tokyo Shinjuku → Shibuya"
    case londonThames = "London Tower Bridge → Westminster"
    case sfGoldenGate = "San Francisco Golden Gate"
    case seoulGangnam = "Seoul Gangnam → Itaewon"
    case parisChamps = "Paris Champs-Élysées"

    public var id: String { rawValue }

    public var startCoord: (lng: Double, lat: Double) {
        switch self {
        case .manilaBGC: return (121.0503, 14.5547)
        case .tokyoShinjuku: return (139.7005, 35.6896)
        case .londonThames: return (-0.0754, 51.5055)
        case .sfGoldenGate: return (-122.4783, 37.8199)
        case .seoulGangnam: return (127.0276, 37.4979)
        case .parisChamps: return (2.3088, 48.8698)
        }
    }

    public var endCoord: (lng: Double, lat: Double) {
        switch self {
        case .manilaBGC: return (121.0180, 14.5583)
        case .tokyoShinjuku: return (139.7016, 35.6580)
        case .londonThames: return (-0.1276, 51.5007)
        case .sfGoldenGate: return (-122.4194, 37.7749)
        case .seoulGangnam: return (126.9942, 37.5340)
        case .parisChamps: return (2.2945, 48.8738)
        }
    }

    public var mapCenter: (lng: Double, lat: Double) {
        return (
            (startCoord.lng + endCoord.lng) / 2.0,
            (startCoord.lat + endCoord.lat) / 2.0
        )
    }

    public var routeWaypoints: [(lng: Double, lat: Double)] {
        switch self {
        case .manilaBGC:
            return [
                (121.0503, 14.5547), (121.0470, 14.5520), (121.0415, 14.5490),
                (121.0350, 14.5450), (121.0290, 14.5420), (121.0240, 14.5460),
                (121.0200, 14.5510), (121.0180, 14.5583)
            ]
        case .tokyoShinjuku:
            return [
                (139.7005, 35.6896), (139.7020, 35.6850), (139.7010, 35.6790),
                (139.6990, 35.6740), (139.6980, 35.6680), (139.7000, 35.6630),
                (139.7016, 35.6580)
            ]
        case .londonThames:
            return [
                (-0.0754, 51.5055), (-0.0850, 51.5068), (-0.0950, 51.5050),
                (-0.1050, 51.5030), (-0.1130, 51.5015), (-0.1200, 51.5010),
                (-0.1276, 51.5007)
            ]
        case .sfGoldenGate:
            return [
                (-122.4783, 37.8199), (-122.4750, 37.8100), (-122.4680, 37.8000),
                (-122.4600, 37.7930), (-122.4500, 37.7870), (-122.4350, 37.7810),
                (-122.4194, 37.7749)
            ]
        case .seoulGangnam:
            return [
                (127.0276, 37.4979), (127.0230, 37.5020), (127.0180, 37.5080),
                (127.0120, 37.5140), (127.0060, 37.5200), (127.0000, 37.5270),
                (126.9942, 37.5340)
            ]
        case .parisChamps:
            return [
                (2.3088, 48.8698), (2.3060, 48.8702), (2.3030, 48.8708),
                (2.3010, 48.8715), (2.2990, 48.8722), (2.2970, 48.8730),
                (2.2945, 48.8738)
            ]
        }
    }
}

/// Live courier & delivery-style focus route tracking map with dual-polyline progression and vehicle marker.
public struct LiveRouteTrackingView: NSViewRepresentable {
    @Bindable public var engine: TransitEngine
    public var cityRoute: CityRoutePreset
    public var vehicleType: VehicleType

    public init(engine: TransitEngine, cityRoute: CityRoutePreset = .manilaBGC, vehicleType: VehicleType = .midnightEV) {
        self.engine = engine
        self.cityRoute = cityRoute
        self.vehicleType = vehicleType
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        context.coordinator.webView = webView

        let html = generateTrackingHTML()
        webView.loadHTMLString(html, baseURL: URL(string: "https://basemaps.cartocdn.com")!)
        return webView
    }

    public func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.parent = self
        
        let progress = engine.activeSession?.progressFraction ?? 0.0
        let velocity = engine.currentVelocity
        let stateStr = engine.state.rawValue
        let hazardApp = engine.activeSession?.incidents.last?.appName ?? ""
        
        var timeRemainingStr = "--"
        if let session = engine.activeSession, let target = session.targetDuration {
            let remaining = max(0, target - session.cruisingDuration)
            let mins = Int(remaining) / 60
            timeRemainingStr = "\(mins)m away"
        } else {
            timeRemainingStr = "\(Int(velocity)) km/h"
        }

        let js = """
        if (window.karuTracker) {
            window.karuTracker.updateState('\(stateStr)', \(velocity), '\(hazardApp)', '\(timeRemainingStr)');
            window.karuTracker.updateProgress(\(progress));
        }
        """
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    // MARK: - Vehicle Icon Mapping
    private var vehicleEmoji: String {
        switch vehicleType {
        case .midnightEV: return "🚗"
        case .classicSarao: return "🚐"
        case .nightRainHatchback: return "🚙"
        case .shinkansenExpress: return "🚄"
        case .coastalBus: return "🚌"
        }
    }

    private var vehicleStalledEmoji: String { "⚠️" }
    private var vehiclePitStopEmoji: String { "☕" }

    // MARK: - HTML/JS Map Template
    private func generateTrackingHTML() -> String {
        let route = cityRoute
        let waypointsJSON = route.routeWaypoints.map { "[\($0.lng), \($0.lat)]" }.joined(separator: ",\n                    ")

        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1.0" />
            <link href="https://unpkg.com/maplibre-gl@3.6.2/dist/maplibre-gl.css" rel="stylesheet" />
            <script src="https://unpkg.com/maplibre-gl@3.6.2/dist/maplibre-gl.js"></script>
            <style>
                body, html { margin: 0; padding: 0; width: 100%; height: 100%; overflow: hidden; background: #0B0D13; font-family: -apple-system, sans-serif; }
                #map { width: 100%; height: 100%; }
                
                /* Origin & Destination Pins */
                .origin-pin {
                    width: 28px; height: 28px;
                    background: #10B981; border: 2.5px solid #ffffff;
                    border-radius: 50%; display: flex; align-items: center; justify-content: center;
                    box-shadow: 0 0 12px rgba(16, 185, 129, 0.7);
                    font-size: 14px;
                }
                .destination-pin {
                    width: 28px; height: 28px;
                    background: #F43F5E; border: 2.5px solid #ffffff;
                    border-radius: 50%; display: flex; align-items: center; justify-content: center;
                    box-shadow: 0 0 12px rgba(244, 63, 94, 0.7);
                    font-size: 14px;
                }

                /* Vehicle Marker — Shows the actual vehicle emoji */
                .vehicle-marker-wrapper {
                    position: relative;
                    display: flex; flex-direction: column;
                    align-items: center;
                }
                .vehicle-icon {
                    width: 40px; height: 40px;
                    display: flex; align-items: center; justify-content: center;
                    font-size: 26px;
                    filter: drop-shadow(0 2px 6px rgba(0,0,0,0.5));
                    transition: transform 0.3s ease;
                }
                .vehicle-icon.stalled {
                    animation: shake 0.4s infinite;
                }
                .vehicle-glow {
                    position: absolute;
                    bottom: -4px;
                    width: 32px; height: 10px;
                    background: radial-gradient(ellipse, rgba(16,185,129,0.5) 0%, transparent 70%);
                    border-radius: 50%;
                    transition: background 0.3s ease;
                }
                .vehicle-glow.stalled {
                    background: radial-gradient(ellipse, rgba(245,158,11,0.6) 0%, transparent 70%);
                }

                .floating-eta-badge {
                    position: absolute;
                    bottom: 100%;
                    left: 50%;
                    transform: translateX(-50%);
                    margin-bottom: 6px;
                    background: rgba(11, 13, 19, 0.94);
                    color: #ffffff;
                    border: 1px solid #10B981;
                    padding: 3px 10px;
                    border-radius: 8px;
                    font-size: 10px;
                    font-weight: 700;
                    white-space: nowrap;
                    box-shadow: 0 4px 12px rgba(0,0,0,0.6);
                    pointer-events: none;
                }
                .floating-eta-badge::after {
                    content: '';
                    position: absolute;
                    top: 100%;
                    left: 50%;
                    transform: translateX(-50%);
                    border-width: 5px;
                    border-style: solid;
                    border-color: rgba(11, 13, 19, 0.94) transparent transparent transparent;
                }
                .floating-eta-badge.stalled {
                    border-color: #F59E0B;
                    color: #FCD34D;
                }

                @keyframes shake {
                    0%, 100% { transform: translateX(0); }
                    25% { transform: translateX(-2px); }
                    75% { transform: translateX(2px); }
                }
            </style>
        </head>
        <body>
            <div id="map"></div>
            <script>
                const routeCoordinates = [
                    \(waypointsJSON)
                ];

                const pickupCoord = routeCoordinates[0];
                const dropoffCoord = routeCoordinates[routeCoordinates.length - 1];

                const map = new maplibregl.Map({
                    container: 'map',
                    style: 'https://basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json',
                    center: [\(route.mapCenter.lng), \(route.mapCenter.lat)],
                    zoom: 13.5,
                    interactive: false,
                    attributionControl: false
                });

                // ── Vehicle marker with emoji icon ──
                const wrapper = document.createElement('div');
                wrapper.className = 'vehicle-marker-wrapper';

                const badge = document.createElement('div');
                badge.className = 'floating-eta-badge';
                badge.id = 'eta-badge';
                badge.innerText = 'Ready';
                wrapper.appendChild(badge);

                const iconEl = document.createElement('div');
                iconEl.className = 'vehicle-icon';
                iconEl.id = 'vehicle-icon';
                iconEl.innerText = '\(vehicleEmoji)';
                wrapper.appendChild(iconEl);

                const glowEl = document.createElement('div');
                glowEl.className = 'vehicle-glow';
                glowEl.id = 'vehicle-glow';
                wrapper.appendChild(glowEl);

                const courierMarker = new maplibregl.Marker({ element: wrapper, offset: [0, -20] })
                    .setLngLat(pickupCoord)
                    .addTo(map);

                // Origin Pin (Start)
                const originEl = document.createElement('div');
                originEl.className = 'origin-pin';
                originEl.innerHTML = '📍';
                new maplibregl.Marker({ element: originEl }).setLngLat(pickupCoord).addTo(map);

                // Destination Pin (Goal)
                const destEl = document.createElement('div');
                destEl.className = 'destination-pin';
                destEl.innerHTML = '🏁';
                new maplibregl.Marker({ element: destEl }).setLngLat(dropoffCoord).addTo(map);

                map.on('load', () => {
                    // Full route (dark gray)
                    map.addSource('delivery-full-route', {
                        type: 'geojson',
                        data: {
                            type: 'Feature', properties: {},
                            geometry: { type: 'LineString', coordinates: routeCoordinates }
                        }
                    });
                    map.addLayer({
                        id: 'delivery-full-route', type: 'line', source: 'delivery-full-route',
                        layout: { 'line-join': 'round', 'line-cap': 'round' },
                        paint: { 'line-color': '#334155', 'line-width': 6, 'line-opacity': 0.7 }
                    });

                    // Progress route (neon emerald)
                    map.addSource('delivery-progress-route', {
                        type: 'geojson',
                        data: {
                            type: 'Feature', properties: {},
                            geometry: { type: 'LineString', coordinates: [routeCoordinates[0], routeCoordinates[0]] }
                        }
                    });
                    map.addLayer({
                        id: 'delivery-progress-route', type: 'line', source: 'delivery-progress-route',
                        layout: { 'line-join': 'round', 'line-cap': 'round' },
                        paint: { 'line-color': '#10B981', 'line-width': 6, 'line-opacity': 0.95 }
                    });
                });

                // State bridge
                const CRUISE_EMOJI = '\(vehicleEmoji)';
                const STALL_EMOJI = '\(vehicleStalledEmoji)';
                const PITSTOP_EMOJI = '\(vehiclePitStopEmoji)';

                window.karuTracker = {
                    updateState: function(state, velocity, hazardAppName, etaText) {
                        const icon = document.getElementById('vehicle-icon');
                        const eta = document.getElementById('eta-badge');
                        const glow = document.getElementById('vehicle-glow');

                        if (state === 'trafficStalled') {
                            icon.innerText = STALL_EMOJI;
                            icon.className = 'vehicle-icon stalled';
                            glow.className = 'vehicle-glow stalled';
                            eta.className = 'floating-eta-badge stalled';
                            eta.innerText = '⚠️ Gridlock · ' + (hazardAppName || 'Distraction');
                        } else if (state === 'pitStop') {
                            icon.innerText = PITSTOP_EMOJI;
                            icon.className = 'vehicle-icon';
                            glow.className = 'vehicle-glow';
                            eta.className = 'floating-eta-badge';
                            eta.innerText = 'Pit Stop';
                        } else {
                            icon.innerText = CRUISE_EMOJI;
                            icon.className = 'vehicle-icon';
                            glow.className = 'vehicle-glow';
                            eta.className = 'floating-eta-badge';
                            eta.innerText = etaText || (velocity + ' km/h');
                        }
                    },
                    updateProgress: function(progress) {
                        const fraction = Math.min(1.0, Math.max(0.0, progress));
                        const totalPoints = routeCoordinates.length;
                        const targetIndex = Math.floor(fraction * (totalPoints - 1));
                        const currentSegmentFraction = (fraction * (totalPoints - 1)) - targetIndex;
                        const p1 = routeCoordinates[targetIndex];
                        const p2 = routeCoordinates[Math.min(targetIndex + 1, totalPoints - 1)];

                        const curLng = p1[0] + (p2[0] - p1[0]) * currentSegmentFraction;
                        const curLat = p1[1] + (p2[1] - p1[1]) * currentSegmentFraction;

                        const progressPoints = routeCoordinates.slice(0, targetIndex + 1);
                        progressPoints.push([curLng, curLat]);

                        if (map.getSource('delivery-progress-route')) {
                            map.getSource('delivery-progress-route').setData({
                                type: 'Feature', properties: {},
                                geometry: { type: 'LineString', coordinates: progressPoints }
                            });
                        }

                        courierMarker.setLngLat([curLng, curLat]);
                        map.easeTo({ center: [curLng, curLat], duration: 500 });
                    }
                };
            </script>
        </body>
        </html>
        """
    }

    public final class Coordinator: NSObject {
        var parent: LiveRouteTrackingView
        var webView: WKWebView?

        init(_ parent: LiveRouteTrackingView) {
            self.parent = parent
        }
    }
}
