import Foundation

public enum AppGroupConfiguration {
    public static let identifier = "group.com.example.AppleBatteryTimeRemainingWidget"
    public static let telemetryFileName = "battery-telemetry.json"

    public static var fallbackTelemetryFileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(telemetryFileName)
    }

    public static var telemetryFileURL: URL {
        #if os(iOS)
        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier) {
            return appGroupURL.appendingPathComponent(telemetryFileName)
        }
        #endif

        return fallbackTelemetryFileURL
    }
}
