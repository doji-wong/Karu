import SwiftUI
import WebKit
import KaruCore

/// Live courier & delivery-style focus route tracking map with dual-polyline progression and dynamic vehicle marker.
public struct LiveRouteTrackingView: NSViewRepresentable {
    @Bindable public var engine: TransitEngine

    public init(engine: TransitEngine) {
        self.engine = engine
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
        webView.loadHTMLString(html, baseURL: URL(string: "https://tiles.openfreemap.org")!)
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

    // MARK: - HTML/JS Map Template
    private func generateTrackingHTML() -> String {
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
                    width: 26px; height: 26px;
                    background: #10B981; border: 2px solid #ffffff;
                    border-radius: 50%; display: flex; align-items: center; justify-content: center;
                    box-shadow: 0 0 10px rgba(16, 185, 129, 0.6);
                    color: white; font-size: 13px; font-weight: bold;
                }
                .destination-pin {
                    width: 26px; height: 26px;
                    background: #F43F5E; border: 2px solid #ffffff;
                    border-radius: 50%; display: flex; align-items: center; justify-content: center;
                    box-shadow: 0 0 10px rgba(244, 63, 94, 0.6);
                    color: white; font-size: 13px; font-weight: bold;
                }

                /* Courier/Vehicle Marker with Floating Tooltip */
                .vehicle-marker-wrapper {
                    position: relative;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                }
                .vehicle-marker {
                    width: 32px; height: 32px;
                    background: #10B981; border: 2px solid #ffffff;
                    border-radius: 50%; display: flex; align-items: center; justify-content: center;
                    box-shadow: 0 0 16px rgba(16, 185, 129, 0.9);
                    color: black; font-size: 16px; font-weight: bold;
                    transition: background 0.3s ease, transform 0.3s ease;
                }
                .vehicle-marker.stalled {
                    background: #F59E0B;
                    box-shadow: 0 0 18px rgba(245, 158, 11, 0.9);
                    animation: pulse 1s infinite;
                }
                .vehicle-marker.pitstop {
                    background: #06B6D4;
                }

                .floating-eta-badge {
                    position: absolute;
                    bottom: 100%;
                    left: 50%;
                    transform: translateX(-50%);
                    margin-bottom: 8px;
                    background: rgba(11, 13, 19, 0.92);
                    color: #ffffff;
                    border: 1px solid #10B981;
                    padding: 3px 8px;
                    border-radius: 6px;
                    font-size: 10px;
                    font-weight: 700;
                    white-space: nowrap;
                    box-shadow: 0 4px 10px rgba(0,0,0,0.5);
                    pointer-events: none;
                }
                .floating-eta-badge::after {
                    content: '';
                    position: absolute;
                    top: 100%;
                    left: 50%;
                    transform: translateX(-50%);
                    border-width: 4px;
                    border-style: solid;
                    border-color: rgba(11, 13, 19, 0.92) transparent transparent transparent;
                }
                .floating-eta-badge.stalled {
                    border-color: #F59E0B;
                    color: #FCD34D;
                }

                @keyframes pulse {
                    0% { transform: scale(1); }
                    50% { transform: scale(1.12); }
                    100% { transform: scale(1); }
                }
            </style>
        </head>
        <body>
            <div id="map"></div>
            <script>
                // Scenic expressway route coordinates (Manila Coastal to BGC Expressway)
                const routeCoordinates = [
                    [121.0503, 14.5547],
                    [121.0470, 14.5520],
                    [121.0415, 14.5490],
                    [121.0350, 14.5450],
                    [121.0290, 14.5420],
                    [121.0240, 14.5460],
                    [121.0200, 14.5510],
                    [121.0180, 14.5583]
                ];

                const pickupCoord = routeCoordinates[0];
                const dropoffCoord = routeCoordinates[routeCoordinates.length - 1];

                const map = new maplibregl.Map({
                    container: 'map',
                    style: 'https://basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json',
                    center: [121.034, 14.551],
                    zoom: 13.5,
                    interactive: false,
                    attributionControl: false
                });

                // Vehicle marker element with tooltip
                const wrapper = document.createElement('div');
                wrapper.className = 'vehicle-marker-wrapper';

                const badge = document.createElement('div');
                badge.className = 'floating-eta-badge';
                badge.id = 'eta-badge';
                badge.innerText = 'Ready';
                wrapper.appendChild(badge);

                const markerEl = document.createElement('div');
                markerEl.className = 'vehicle-marker';
                markerEl.id = 'vehicle-icon';
                markerEl.innerHTML = '⚡';
                wrapper.appendChild(markerEl);

                const courierMarker = new maplibregl.Marker({ element: wrapper, offset: [0, -10] })
                    .setLngLat(pickupCoord)
                    .addTo(map);

                // Origin & Destination Markers
                const originEl = document.createElement('div');
                originEl.className = 'origin-pin';
                originEl.innerHTML = '🟢';
                new maplibregl.Marker({ element: originEl }).setLngLat(pickupCoord).addTo(map);

                const destEl = document.createElement('div');
                destEl.className = 'destination-pin';
                destEl.innerHTML = '🏁';
                new maplibregl.Marker({ element: destEl }).setLngLat(dropoffCoord).addTo(map);

                map.on('load', () => {
                    // Full route layer (subtle gray)
                    map.addSource('delivery-full-route', {
                        type: 'geojson',
                        data: {
                            type: 'Feature',
                            properties: {},
                            geometry: {
                                type: 'LineString',
                                coordinates: routeCoordinates
                            }
                        }
                    });

                    map.addLayer({
                        id: 'delivery-full-route',
                        type: 'line',
                        source: 'delivery-full-route',
                        layout: { 'line-join': 'round', 'line-cap': 'round' },
                        paint: {
                            'line-color': '#334155',
                            'line-width': 6,
                            'line-opacity': 0.7
                        }
                    });

                    // Progress traveled route layer (neon emerald)
                    map.addSource('delivery-progress-route', {
                        type: 'geojson',
                        data: {
                            type: 'Feature',
                            properties: {},
                            geometry: {
                                type: 'LineString',
                                coordinates: [routeCoordinates[0], routeCoordinates[0]]
                            }
                        }
                    });

                    map.addLayer({
                        id: 'delivery-progress-route',
                        type: 'line',
                        source: 'delivery-progress-route',
                        layout: { 'line-join': 'round', 'line-cap': 'round' },
                        paint: {
                            'line-color': '#10B981',
                            'line-width': 6,
                            'line-opacity': 0.95
                        }
                    });
                });

                window.karuTracker = {
                    updateState: function(state, velocity, hazardAppName, etaText) {
                        const icon = document.getElementById('vehicle-icon');
                        const eta = document.getElementById('eta-badge');

                        if (state === 'trafficStalled') {
                            icon.className = 'vehicle-marker stalled';
                            icon.innerHTML = '⚠️';
                            eta.className = 'floating-eta-badge stalled';
                            eta.innerText = 'Gridlock · ' + (hazardAppName || 'Distraction');
                        } else if (state === 'pitStop') {
                            icon.className = 'vehicle-marker pitstop';
                            icon.innerHTML = '☕';
                            eta.className = 'floating-eta-badge';
                            eta.innerText = 'Pit Stop';
                        } else {
                            icon.className = 'vehicle-marker';
                            icon.innerHTML = '⚡';
                            eta.className = 'floating-eta-badge';
                            eta.innerText = etaText || (velocity + ' km/h');
                        }
                    },
                    updateProgress: function(progress) {
                        const fraction = Math.min(1.0, Math.max(0.0, progress));
                        const totalPoints = routeCoordinates.length;
                        const targetIndex = Math.floor(fraction * (totalPoints - 1));
                        
                        // Calculate interpolated point
                        const currentSegmentFraction = (fraction * (totalPoints - 1)) - targetIndex;
                        const p1 = routeCoordinates[targetIndex];
                        const p2 = routeCoordinates[Math.min(targetIndex + 1, totalPoints - 1)];

                        const curLng = p1[0] + (p2[0] - p1[0]) * currentSegmentFraction;
                        const curLat = p1[1] + (p2[1] - p1[1]) * currentSegmentFraction;

                        // Update progress line
                        const progressPoints = routeCoordinates.slice(0, targetIndex + 1);
                        progressPoints.push([curLng, curLat]);

                        if (map.getSource('delivery-progress-route')) {
                            map.getSource('delivery-progress-route').setData({
                                type: 'Feature',
                                properties: {},
                                geometry: {
                                    type: 'LineString',
                                    coordinates: progressPoints
                                }
                            });
                        }

                        courierMarker.setLngLat([curLng, curLat]);
                        map.easeTo({
                            center: [curLng, curLat],
                            duration: 500
                        });
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
