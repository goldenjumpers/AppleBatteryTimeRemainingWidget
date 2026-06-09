import Foundation
import Testing
@testable import BatteryTimeRemainingWidgetCore

@Suite("Battery time remaining calculator")
struct BatteryTimeRemainingCalculatorTests {
    @Test("estimates runtime using behavior trend and activity inputs")
    func estimatesRuntimeFromTrendsAndUsage() {
        let samples = makeSamples(levels: [90, 86, 82, 78], intervalHours: 1)
        let calculator = BatteryTimeRemainingCalculator()

        let estimate = calculator.estimateRemainingRuntime(
            currentBatteryLevel: 50,
            isLowPowerModeEnabled: false,
            recentCellularMegabytesPerHour: 512,
            recentWifiMegabytesPerHour: 1_024,
            recentScreenOnMinutesPerHour: 30,
            historicalSamples: samples
        )

        #expect(estimate.percentPerHour == 7.75)
        #expect(estimate.remainingMinutes == 387)
        #expect(estimate.confidence > 0.45)
        #expect(estimate.explanation.contains("behavioral trend history"))
    }

    @Test("low power mode extends the runtime estimate")
    func lowPowerModeExtendsRuntime() {
        let samples = makeSamples(levels: [80, 74, 68, 62], intervalHours: 1)
        let calculator = BatteryTimeRemainingCalculator()

        let standardEstimate = calculator.estimateRemainingRuntime(
            currentBatteryLevel: 40,
            isLowPowerModeEnabled: false,
            recentCellularMegabytesPerHour: 1_024,
            recentWifiMegabytesPerHour: 0,
            recentScreenOnMinutesPerHour: 45,
            historicalSamples: samples
        )
        let lowPowerEstimate = calculator.estimateRemainingRuntime(
            currentBatteryLevel: 40,
            isLowPowerModeEnabled: true,
            recentCellularMegabytesPerHour: 1_024,
            recentWifiMegabytesPerHour: 0,
            recentScreenOnMinutesPerHour: 45,
            historicalSamples: samples
        )

        #expect(lowPowerEstimate.remainingMinutes > standardEstimate.remainingMinutes)
        #expect(lowPowerEstimate.percentPerHour < standardEstimate.percentPerHour)
    }

    @Test("uses fallback profile when there is not enough history")
    func fallbackForSparseHistory() {
        let calculator = BatteryTimeRemainingCalculator()

        let estimate = calculator.estimateRemainingRuntime(
            currentBatteryLevel: 30,
            isLowPowerModeEnabled: false,
            recentCellularMegabytesPerHour: 0,
            recentWifiMegabytesPerHour: 0,
            recentScreenOnMinutesPerHour: 0,
            historicalSamples: []
        )

        #expect(estimate.percentPerHour == 7.5)
        #expect(estimate.remainingMinutes == 240)
        #expect(estimate.confidence == 0.35)
        #expect(estimate.explanation.contains("fallback profile"))
    }

    private func makeSamples(levels: [Double], intervalHours: TimeInterval) -> [BatteryUsageSample] {
        let start = Date(timeIntervalSince1970: 1_800_000_000)

        return levels.enumerated().map { index, level in
            BatteryUsageSample(
                timestamp: start.addingTimeInterval(Double(index) * intervalHours * 3_600),
                batteryLevel: level,
                isLowPowerModeEnabled: false,
                screenOnMinutesSincePreviousSample: 20,
                cellularMegabytesSincePreviousSample: 128,
                wifiMegabytesSincePreviousSample: 256
            )
        }
    }
}
