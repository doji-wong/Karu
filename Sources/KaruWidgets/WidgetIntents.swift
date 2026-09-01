import Foundation
import AppIntents
import KaruCore

/// AppIntent for 1-click desktop takeoff from Karu widgets.
@available(macOS 14.0, *)
public struct TakeoffIntent: AppIntent {
    public static var title: LocalizedStringResource = "Start Focus Flight"
    public static var description = IntentDescription("Launches a new focus flight at cruising velocity (540 kts).")
    public static var openAppWhenRun: Bool = false

    public init() {}

    public func perform() async throws -> some IntentResult {
        await MainActor.run {
            NotificationCenter.default.post(name: .karuWidgetDidRequestTakeoff, object: nil)
        }
        return .result()
    }
}

/// AppIntent for 1-click desktop gate hold / pause from Karu widgets.
@available(macOS 14.0, *)
public struct GateHoldIntent: AppIntent {
    public static var title: LocalizedStringResource = "Gate Hold Flight"
    public static var description = IntentDescription("Pauses the active focus flight for a temporary gate hold.")
    public static var openAppWhenRun: Bool = false

    public init() {}

    public func perform() async throws -> some IntentResult {
        await MainActor.run {
            NotificationCenter.default.post(name: .karuWidgetDidRequestGateHold, object: nil)
        }
        return .result()
    }
}

public extension Notification.Name {
    static let karuWidgetDidRequestTakeoff = Notification.Name("karuWidgetDidRequestTakeoff")
    static let karuWidgetDidRequestGateHold = Notification.Name("karuWidgetDidRequestGateHold")
}
