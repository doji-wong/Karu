import SwiftUI
import WidgetKit
import KaruCore

/// Small Airspeed & Focus Quota Instrument Gauge Widget (`systemSmall` — 158x158 pt).
public struct SmallAirspeedGaugeWidget: Widget {
    public let kind: String = "KaruSmallAirspeedGaugeWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FlightTelemetryTimelineProvider()) { entry in
            SmallAirspeedGaugeWidgetView(snapshot: entry.snapshot)
                .containerBackground(KaruTheme.carbonMatte, for: .widget)
        }
        .configurationDisplayName("Airspeed & Quota Gauge")
        .description("Minimalist cockpit flight computer showing daily focus quota progress ring, current airspeed velocity (540 kts), and streak.")
        .supportedFamilies([.systemSmall])
    }
}

/// Medium Focus Flight Dispatch Board Widget (`systemMedium` — 338x158 pt).
public struct MediumFlightDispatchWidget: Widget {
    public let kind: String = "KaruMediumFlightDispatchWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FlightTelemetryTimelineProvider()) { entry in
            MediumFlightDispatchWidgetView(snapshot: entry.snapshot)
                .containerBackground(KaruTheme.carbonMatte, for: .widget)
        }
        .configurationDisplayName("Focus Flight Dispatch")
        .description("Flight deck dispatch board with live route progress bar, daily flight quota, certified streak, and quick action controls.")
        .supportedFamilies([.systemMedium])
    }
}

@main
public struct KaruWidgetBundle: WidgetBundle {
    public init() {}

    public var body: some Widget {
        SmallAirspeedGaugeWidget()
        MediumFlightDispatchWidget()
    }
}
