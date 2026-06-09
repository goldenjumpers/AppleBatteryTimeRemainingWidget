import Foundation

public struct BatteryUsageSummary: Equatable, Sendable {
    public let cellularMegabytesPerHour: Double
    public let wifiMegabytesPerHour: Double
    public let screenOnMinutesPerHour: Double

    public init(
        cellularMegabytesPerHour: Double,
        wifiMegabytesPerHour: Double,
        screenOnMinutesPerHour: Double
    ) {
        self.cellularMegabytesPerHour = max(cellularMegabytesPerHour, 0)
        self.wifiMegabytesPerHour = max(wifiMegabytesPerHour, 0)
        self.screenOnMinutesPerHour = min(max(screenOnMinutesPerHour, 0), 60)
    }

    public static let placeholder = BatteryUsageSummary(
        cellularMegabytesPerHour: 220,
        wifiMegabytesPerHour: 780,
        screenOnMinutesPerHour: 22
    )
}
