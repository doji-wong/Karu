import SwiftUI
import WebKit
import KaruCore

/// Scenic city route presets for SpaceX Telemetry Live Route Tracker.
public enum CityRoutePreset: String, CaseIterable, Identifiable {
    case manilaBGC = "Manila BGC Trajectory"
    case tokyoShinjuku = "Tokyo Shinjuku → Shibuya"
    case londonThames = "London Thames River"
    case sfGoldenGate = "San Francisco Golden Gate"
    case seoulGangnam = "Seoul Gangnam Axis"
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

/// SpaceX-inspired CARTO Dark Matter real vector trajectory map.
public struct LiveRouteTrackingView: NSViewRepresentable {
    @Bindable public var engine: TransitEngine
    public var cityRoute: CityRoutePreset

    public init(engine: TransitEngine, cityRoute: CityRoutePreset = .manilaBGC) {
        self.engine = engine
        self.cityRoute = cityRoute
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
            timeRemainingStr = "\(mins)M REMAINING"
        } else {
            timeRemainingStr = "\(Int(velocity)) KM/H"
        }

        let js = """
        if (window.karuTracker) {
            window.karuTracker.updateState('\(stateStr)', \(velocity), '\(hazardApp)', '\(timeRemainingStr)');
            window.karuTracker.updateProgress(\(progress));
        }
        """
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

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
                body, html { margin: 0; padding: 0; width: 100%; height: 100%; overflow: hidden; background: #000000; font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; }
                #map { width: 100%; height: 100%; }
                
                /* Origin & Target Reticles */
                .origin-reticle {
                    width: 14px; height: 14px;
                    border: 1.5px solid #00E5FF;
                    border-radius: 50%;
                    background: rgba(0, 229, 255, 0.2);
                    box-shadow: 0 0 8px rgba(0, 229, 255, 0.8);
                }
                .target-reticle {
                    width: 16px; height: 16px;
                    border: 1.5px solid #FFFFFF;
                    border-radius: 3px;
                    background: rgba(255, 255, 255, 0.15);
                    box-shadow: 0 0 10px rgba(255, 255, 255, 0.6);
                }

                /* SpaceX Telemetry Beacon */
                .beacon-wrapper {
                    position: relative;
                    display: flex; flex-direction: column;
                    align-items: center; justify-content: center;
                }
                .beacon-ring {
                    width: 22px; height: 22px;
                    border-radius: 50%;
                    border: 1.5px solid #00E5FF;
                    background: rgba(0, 229, 255, 0.15);
                    box-shadow: 0 0 12px #00E5FF, inset 0 0 8px rgba(0, 229, 255, 0.5);
                    animation: pulse 1.8s cubic-bezier(0.215, 0.61, 0.355, 1) infinite;
                    display: flex; align-items: center; justify-content: center;
                }
                .beacon-dot {
                    width: 7px; height: 7px;
                    border-radius: 50%;
                    background: #FFFFFF;
                    box-shadow: 0 0 6px #FFFFFF;
                }
                .beacon-ring.anomaly {
                    border-color: #FF3B30;
                    box-shadow: 0 0 14px #FF3B30, inset 0 0 8px rgba(255, 59, 48, 0.5);
                }
                .beacon-ring.anomaly .beacon-dot {
                    background: #FF3B30;
                    box-shadow: 0 0 6px #FF3B30;
                }

                .telemetry-eta-pill {
                    position: absolute;
                    bottom: 100%;
                    left: 50%;
                    transform: translateX(-50%);
                    margin-bottom: 5px;
                    background: rgba(0, 0, 0, 0.92);
                    color: #00E5FF;
                    border: 1px solid #00E5FF;
                    padding: 2px 7px;
                    border-radius: 3px;
                    font-size: 9px;
                    font-weight: 700;
                    letter-spacing: 0.5px;
                    white-space: nowrap;
                    box-shadow: 0 0 8px rgba(0, 229, 255, 0.4);
                    pointer-events: none;
                }
                .telemetry-eta-pill.anomaly {
                    border-color: #FF3B30;
                    color: #FF3B30;
                    box-shadow: 0 0 8px rgba(255, 59, 48, 0.4);
                }

                @keyframes pulse {
                    0% { transform: scale(0.9); opacity: 1; }
                    70% { transform: scale(1.4); opacity: 0.4; }
                    100% { transform: scale(0.9); opacity: 1; }
                }
            </style>
        </head>
        <body>
            <div id="map"></div>
            <script>
                const routeCoordinates = [
                    \(waypointsJSON)
                ];

                const originCoord = routeCoordinates[0];
                const targetCoord = routeCoordinates[routeCoordinates.length - 1];

                const map = new maplibregl.Map({
                    container: 'map',
                    style: 'https://basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json',
                    center: [\(route.mapCenter.lng), \(route.mapCenter.lat)],
                    zoom: 13.5,
                    interactive: false,
                    attributionControl: false
                });

                // Telemetry Beacon Marker
                const wrapper = document.createElement('div');
                wrapper.className = 'beacon-wrapper';

                const etaBadge = document.createElement('div');
                etaBadge.className = 'telemetry-eta-pill';
                etaBadge.id = 'eta-pill';
                etaBadge.innerText = 'NOMINAL';
                wrapper.appendChild(etaBadge);

                const ring = document.createElement('div');
                ring.className = 'beacon-ring';
                ring.id = 'beacon-ring';
                const dot = document.createElement('div');
                dot.className = 'beacon-dot';
                ring.appendChild(dot);
                wrapper.appendChild(ring);

                const beaconMarker = new maplibregl.Marker({ element: wrapper, offset: [0, 0] })
                    .setLngLat(originCoord)
                    .addTo(map);

                // Origin Reticle
                const originEl = document.createElement('div');
                originEl.className = 'origin-reticle';
                new maplibregl.Marker({ element: originEl }).setLngLat(originCoord).addTo(map);

                // Target Reticle
                const targetEl = document.createElement('div');
                targetEl.className = 'target-reticle';
                new maplibregl.Marker({ element: targetEl }).setLngLat(targetCoord).addTo(map);

                map.on('load', () => {
                    // Base Planned Trajectory (Translucent White)
                    map.addSource('planned-trajectory', {
                        type: 'geojson',
                        data: {
                            type: 'Feature', properties: {},
                            geometry: { type: 'LineString', coordinates: routeCoordinates }
                        }
                    });
                    map.addLayer({
                        id: 'planned-trajectory', type: 'line', source: 'planned-trajectory',
                        layout: { 'line-join': 'round', 'line-cap': 'round' },
                        paint: { 'line-color': '#FFFFFF', 'line-width': 2, 'line-opacity': 0.25 }
                    });

                    // Active Laser Progress Trajectory (Glowing Electric Cyan)
                    map.addSource('laser-trajectory', {
                        type: 'geojson',
                        data: {
                            type: 'Feature', properties: {},
                            geometry: { type: 'LineString', coordinates: [routeCoordinates[0], routeCoordinates[0]] }
                        }
                    });
                    map.addLayer({
                        id: 'laser-trajectory', type: 'line', source: 'laser-trajectory',
                        layout: { 'line-join': 'round', 'line-cap': 'round' },
                        paint: { 'line-color': '#00E5FF', 'line-width': 3.5, 'line-opacity': 0.95 }
                    });
                });

                // Bridge
                window.karuTracker = {
                    updateState: function(state, velocity, hazardAppName, etaText) {
                        const ringEl = document.getElementById('beacon-ring');
                        const eta = document.getElementById('eta-pill');

                        if (state === 'trafficStalled') {
                            ringEl.className = 'beacon-ring anomaly';
                            eta.className = 'telemetry-eta-pill anomaly';
                            eta.innerText = 'ANOMALY: ' + (hazardAppName || 'HAZARD').toUpperCase();
                        } else if (state === 'pitStop') {
                            ringEl.className = 'beacon-ring';
                            eta.className = 'telemetry-eta-pill';
                            eta.innerText = 'HOLD / PAUSED';
                        } else {
                            ringEl.className = 'beacon-ring';
                            eta.className = 'telemetry-eta-pill';
                            eta.innerText = etaText || (velocity + ' KM/H');
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

                        if (map.getSource('laser-trajectory')) {
                            map.getSource('laser-trajectory').setData({
                                type: 'Feature', properties: {},
                                geometry: { type: 'LineString', coordinates: progressPoints }
                            });
                        }

                        beaconMarker.setLngLat([curLng, curLat]);
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
