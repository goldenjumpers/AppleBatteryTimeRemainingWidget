#if canImport(Combine) && canImport(UIKit)
import BatteryTimeRemainingWidgetCore
import Combine
import Foundation
import UIKit

@MainActor
final class SmartBatteryViewModel: ObservableObject {
    @Published private(set) var currentBatteryLevel = 0.0
    @Published private(set) var isLowPowerModeEnabled = false
    @Published private(set) var recentUsage = BatteryUsageSummary.placeholder
    @Published private(set) var estimate = BatteryRuntimeEstimate(
        remainingMinutes: 0,
        percentPerHour: 0,
        confidence: 0,
        explanation: "Waiting for battery samples."
    )

    private let calculator = BatteryTimeRemainingCalculator()
    private let usageProvider = BatteryUsageSummaryProvider()
    private let telemetryStore: BatteryTelemetryStore

    init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        telemetryStore = BatteryTelemetryStore(fileURL: AppGroupConfiguration.telemetryFileURL)
    }

    func refresh() async {
        currentBatteryLevel = max(Double(UIDevice.current.batteryLevel) * 100, 0)
        isLowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled
        recentUsage = usageProvider.currentSummary()

        do {
            let samples = try await telemetryStore.loadSamples()
            estimate = calculator.estimateRemainingRuntime(
                currentBatteryLevel: currentBatteryLevel,
                isLowPowerModeEnabled: isLowPowerModeEnabled,
                recentCellularMegabytesPerHour: recentUsage.cellularMegabytesPerHour,
                recentWifiMegabytesPerHour: recentUsage.wifiMegabytesPerHour,
                recentScreenOnMinutesPerHour: recentUsage.screenOnMinutesPerHour,
                historicalSamples: samples
            )

            try await telemetryStore.append(
                BatteryUsageSample(
                    timestamp: Date(),
                    batteryLevel: currentBatteryLevel,
                    isLowPowerModeEnabled: isLowPowerModeEnabled,
                    screenOnMinutesSincePreviousSample: recentUsage.screenOnMinutesPerHour,
                    cellularMegabytesSincePreviousSample: recentUsage.cellularMegabytesPerHour,
                    wifiMegabytesSincePreviousSample: recentUsage.wifiMegabytesPerHour
                )
            )
        } catch {
            estimate = calculator.estimateRemainingRuntime(
                currentBatteryLevel: currentBatteryLevel,
                isLowPowerModeEnabled: isLowPowerModeEnabled,
                recentCellularMegabytesPerHour: recentUsage.cellularMegabytesPerHour,
                recentWifiMegabytesPerHour: recentUsage.wifiMegabytesPerHour,
                recentScreenOnMinutesPerHour: recentUsage.screenOnMinutesPerHour,
                historicalSamples: []
            )
        }
    }

}
#endif
