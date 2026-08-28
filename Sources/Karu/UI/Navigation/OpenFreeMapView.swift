import SwiftUI
import WebKit
import KaruCore

/// OpenFreeMap 3D Vector Map view using WebKit & MapLibre GL with 60° pitch and 3D buildings.
public struct OpenFreeMapView: NSViewRepresentable {
    @Bindable public var engine: TransitEngine
    public var styleKey: String = "openstreetmap3d"
    public var startCoordinates: (lng: Double, lat: Double) = (121.0503, 14.5547) // Default Manila BGC
    public var endCoordinates: (lng: Double, lat: Double) = (121.0180, 14.5583)

    public init(
        engine: TransitEngine,
        styleKey: String = "openstreetmap3d",
        startCoordinates: (lng: Double, lat: Double) = (121.0503, 14.5547),
        endCoordinates: (lng: Double, lat: Double) = (121.0180, 14.5583)
    ) {
        self.engine = engine
        self.styleKey = styleKey
        self.startCoordinates = startCoordinates
        self.endCoordinates = endCoordinates
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground") // Transparent background
        context.coordinator.webView = webView

        let html = generateMapHTML()
        webView.loadHTMLString(html, baseURL: URL(string: "https://tiles.openfreemap.org")!)
        return webView
    }

    public func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.parent = self
        
        let progress = engine.activeSession?.progressFraction ?? 0.0
        let velocity = engine.currentVelocity
        let stateStr = engine.state.rawValue
        let hazardApp = engine.activeSession?.incidents.last?.appName ?? ""

        let js = """
        if (window.karuBridge) {
            window.karuBridge.updateTransitState('\(stateStr)', \(velocity), '\(hazardApp)');
            window.karuBridge.updateProgress(\(progress));
        }
        """
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    // MARK: - HTML/JS Map Template
    private func generateMapHTML() -> String {
        let styleURL = styleKey == "openstreetmap3d"
            ? "https://tiles.openfreemap.org/styles/liberty"
            : "https://tiles.openfreemap.org/styles/bright"

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
                .car-marker {
                    width: 32px; height: 32px;
                    background: #10B981; border: 2px solid #ffffff;
                    border-radius: 50%; display: flex; align-items: center; justify-content: center;
                    box-shadow: 0 0 14px rgba(16, 185, 129, 0.8);
                    color: black; font-size: 16px; font-weight: bold;
                    transition: transform 0.3s ease, background-color 0.3s ease;
                }
                .car-marker.stalled {
                    background: #F59E0B;
                    box-shadow: 0 0 16px rgba(245, 158, 11, 0.9);
                    animation: pulse 1s infinite;
                }
                .hazard-popup {
                    background: rgba(11, 13, 19, 0.92);
                    border: 1px solid #F59E0B;
                    color: #fff; padding: 4px 8px; border-radius: 6px;
                    font-size: 10px; font-weight: bold;
                }
                @keyframes pulse {
                    0% { transform: scale(1); }
                    50% { transform: scale(1.15); }
                    100% { transform: scale(1); }
                }
            </style>
        </head>
        <body>
            <div id="map"></div>
            <script>
                const startLng = \(startCoordinates.lng);
                const startLat = \(startCoordinates.lat);
                const endLng = \(endCoordinates.lng);
                const endLat = \(endCoordinates.lat);

                const map = new maplibregl.Map({
                    container: 'map',
                    style: '\(styleURL)',
                    center: [startLng, startLat],
                    zoom: 15.5,
                    pitch: 60,
                    bearing: -15,
                    interactive: false,
                    attributionControl: false
                });

                // Vehicle marker element
                const el = document.createElement('div');
                el.className = 'car-marker';
                el.innerHTML = '⚡';

                const marker = new maplibregl.Marker({ element: el })
                    .setLngLat([startLng, startLat])
                    .addTo(map);

                let currentProgress = 0;
                let activeState = 'idle';

                // Add 3D Extruded Buildings Layer when style loads
                map.on('style.load', () => {
                    const layers = map.getStyle().layers;
                    let labelLayerId;
                    for (let i = 0; i < layers.length; i++) {
                        if (layers[i].type === 'symbol' && layers[i].layout['text-field']) {
                            labelLayerId = layers[i].id;
                            break;
                        }
                    }

                    if (!map.getLayer('3d-buildings') && map.getSource('openmaptiles')) {
                        map.addLayer({
                            'id': '3d-buildings',
                            'source': 'openmaptiles',
                            'source-layer': 'building',
                            'type': 'fill-extrusion',
                            'minzoom': 14,
                            'paint': {
                                'fill-extrusion-color': '#181E2C',
                                'fill-extrusion-height': ['get', 'render_height'],
                                'fill-extrusion-base': ['get', 'render_min_height'],
                                'fill-extrusion-opacity': 0.85
                            }
                        }, labelLayerId);
                    }
                });

                window.karuBridge = {
                    updateTransitState: function(state, velocity, hazardAppName) {
                        activeState = state;
                        if (state === 'trafficStalled') {
                            el.className = 'car-marker stalled';
                            el.innerHTML = '⚠️';
                        } else {
                            el.className = 'car-marker';
                            el.innerHTML = '⚡';
                        }
                    },
                    updateProgress: function(progress) {
                        currentProgress = Math.min(1.0, Math.max(0.0, progress));
                        const curLng = startLng + (endLng - startLng) * currentProgress;
                        const curLat = startLat + (endLat - startLat) * currentProgress;

                        marker.setLngLat([curLng, curLat]);
                        map.easeTo({
                            center: [curLng, curLat],
                            duration: 800,
                            pitch: 60
                        });
                    }
                };
            </script>
        </body>
        </html>
        """
    }

    public final class Coordinator: NSObject {
        var parent: OpenFreeMapView
        var webView: WKWebView?

        init(_ parent: OpenFreeMapView) {
            self.parent = parent
        }
    }
}
