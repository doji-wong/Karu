import Foundation
import SwiftUI
import WidgetKit
import KaruCore

/// Timeline Entry holding a point-in-time `WidgetTelemetrySnapshot`.
public struct FlightTelemetryEntry: TimelineEntry, Sendable {
    public let date: Date
    public let snapshot: WidgetTelemetrySnapshot

    public init(date: Date = Date(), snapshot: WidgetTelemetrySnapshot = .previewMock) {
        self.date = date
        self.snapshot = snapshot
    }
}

/// WidgetKit Timeline Provider for Karu Desktop and Notification Center Widgets.
public struct FlightTelemetryTimelineProvider: TimelineProvider {
    public typealias Entry = FlightTelemetryEntry

    private let storage: LocalStorageManager

    public init(storage: LocalStorageManager = LocalStorageManager()) {
        self.storage = storage
    }

    public func placeholder(in context: Context) -> FlightTelemetryEntry {
        FlightTelemetryEntry(date: Date(), snapshot: .previewMock)
    }

    public func getSnapshot(in context: Context, completion: @escaping (FlightTelemetryEntry) -> Void) {
        let currentSnapshot = storage.loadWidgetSnapshot()
        let entry = FlightTelemetryEntry(date: Date(), snapshot: currentSnapshot)
        completion(entry)
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<FlightTelemetryEntry>) -> Void) {
        let currentSnapshot = storage.loadWidgetSnapshot()
        let currentDate = Date()
        let entry = FlightTelemetryEntry(date: currentDate, snapshot: currentSnapshot)

        // Schedule next reload in 15 minutes or when explicit notifications occur
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate) ?? currentDate.addingTimeInterval(900)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}
