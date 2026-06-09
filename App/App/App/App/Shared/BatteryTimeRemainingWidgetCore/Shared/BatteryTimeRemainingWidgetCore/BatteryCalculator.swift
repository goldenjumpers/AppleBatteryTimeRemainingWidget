import Foundation

public struct BatteryUsageSample: Codable, Equatable, Sendable {
    public let timestamp: Date
    public let batteryLevel: Double
    public let isLowPowerModeEnabled: Bool
    public let screenOnMinutesSincePreviousSample: Double
    public let cellularMegabytesSincePreviousSample: Double
    public let wifiMegabytesSincePreviousSample: Double

    public init(
        timestamp: Date,
        batteryLevel: Double,
        isLowPowerModeEnabled: Bool,
        screenOnMinutesSincePreviousSample: Double,
        cellularMegabytesSincePreviousSample: Double,
        wifiMegabytesSincePreviousSample: Double
    ) {
        self.timestamp = timestamp
        self.batteryLevel = min(max(batteryLevel, 0), 100)
        self.isLowPowerModeEnabled = isLowPowerModeEnabled
        self.screenOnMinutesSincePreviousSample = max(screenOnMinutesSincePreviousSample, 0)
        self.cellularMegabytesSincePreviousSample = max(cellularMegabytesSincePreviousSample, 0)
        self.wifiMegabytesSincePreviousSample = max(wifiMegabytesSincePreviousSample, 0)
    }
}

public struct BatteryRuntimeEstimate: Equatable, Sendable {
    public let remainingMinutes: Int
    public let percentPerHour: Double
    public let confidence: Double
    public let explanation: String

    public var formattedDuration: String {
        let hours = remainingMinutes / 60
        let minutes = remainingMinutes % 60

        if hours == 0 {
            return "\(minutes)m"
        }

        return "\(hours)h \(minutes)m"
    }
}

public struct BatteryCalculatorConfiguration: Equatable, Sendable {
    public let fallbackPercentPerHour: Double
    public let screenOnPercentPerHourBoost: Double
    public let cellularPercentPerGBBoost: Double
    public let wifiPercentPerGBBoost: Double
    public let lowPowerModeSavingsMultiplier: Double
    public let minimumDrainPercentPerHour: Double
    public let maximumDrainPercentPerHour: Double

    public init(
        fallbackPercentPerHour: Double = 7.5,
        screenOnPercentPerHourBoost: Double = 3.5,
        cellularPercentPerGBBoost: Double = 2.2,
        wifiPercentPerGBBoost: Double = 0.9,
        lowPowerModeSavingsMultiplier: Double = 0.82,
        minimumDrainPercentPerHour: Double = 0.8,
        maximumDrainPercentPerHour: Double = 35
    ) {
        self.fallbackPercentPerHour = fallbackPercentPerHour
        self.screenOnPercentPerHourBoost = screenOnPercentPerHourBoost
        self.cellularPercentPerGBBoost = cellularPercentPerGBBoost
        self.wifiPercentPerGBBoost = wifiPercentPerGBBoost
        self.lowPowerModeSavingsMultiplier = lowPowerModeSavingsMultiplier
        self.minimumDrainPercentPerHour = minimumDrainPercentPerHour
        self.maximumDrainPercentPerHour = maximumDrainPercentPerHour
    }
}

public struct BatteryTimeRemainingCalculator: Sendable {
    public let configuration: BatteryCalculatorConfiguration

    public init(configuration: BatteryCalculatorConfiguration = BatteryCalculatorConfiguration()) {
        self.configuration = configuration
    }

    public func estimateRemainingRuntime(
        currentBatteryLevel: Double,
        isLowPowerModeEnabled: Bool,
        recentCellularMegabytesPerHour: Double,
        recentWifiMegabytesPerHour: Double,
        recentScreenOnMinutesPerHour: Double,
        historicalSamples: [BatteryUsageSample]
    ) -> BatteryRuntimeEstimate {
        let currentLevel = min(max(currentBatteryLevel, 0), 100)
        guard currentLevel > 0 else {
            return BatteryRuntimeEstimate(
                remainingMinutes: 0,
                percentPerHour: configuration.maximumDrainPercentPerHour,
                confidence: 1,
                explanation: "Battery is empty."
            )
        }

        let trendDrain = behavioralTrendPercentPerHour(from: historicalSamples)
        let usageAdjustedDrain = usageAdjustedPercentPerHour(
            baseDrain: trendDrain ?? configuration.fallbackPercentPerHour,
            cellularMegabytesPerHour: recentCellularMegabytesPerHour,
            wifiMegabytesPerHour: recentWifiMegabytesPerHour,
            screenOnMinutesPerHour: recentScreenOnMinutesPerHour,
            isLowPowerModeEnabled: isLowPowerModeEnabled
        )
        let boundedDrain = min(
            max(usageAdjustedDrain, configuration.minimumDrainPercentPerHour),
            configuration.maximumDrainPercentPerHour
        )
        let minutes = Int((currentLevel / boundedDrain * 60).rounded(.down))
        let confidence = confidenceScore(sampleCount: historicalSamples.count, trendDrain: trendDrain)
        let trendDescription = trendDrain == nil ? "fallback profile" : "behavioral trend history"
        let powerModeDescription = isLowPowerModeEnabled ? "low power mode savings" : "standard power mode"

        return BatteryRuntimeEstimate(
            remainingMinutes: max(minutes, 0),
            percentPerHour: rounded(boundedDrain),
            confidence: confidence,
            explanation: "Estimated from \(trendDescription), recent screen activity, Wi-Fi/cellular data usage, and \(powerModeDescription)."
        )
    }

    private func behavioralTrendPercentPerHour(from samples: [BatteryUsageSample]) -> Double? {
        let orderedSamples = samples.sorted { $0.timestamp < $1.timestamp }
        guard orderedSamples.count >= 2 else {
            return nil
        }

        var weightedDrainTotal = 0.0
        var weightTotal = 0.0

        for pair in zip(orderedSamples, orderedSamples.dropFirst()) {
            let previous = pair.0
            let current = pair.1
            let elapsedHours = current.timestamp.timeIntervalSince(previous.timestamp) / 3_600
            let batteryDrop = previous.batteryLevel - current.batteryLevel

            guard elapsedHours > 0, batteryDrop > 0 else {
                continue
            }

            let recencyWeight = 1 + Double(orderedSamples.firstIndex(of: current) ?? 0) / Double(orderedSamples.count)
            weightedDrainTotal += (batteryDrop / elapsedHours) * recencyWeight
            weightTotal += recencyWeight
        }

        guard weightTotal > 0 else {
            return nil
        }

        return weightedDrainTotal / weightTotal
    }

    private func usageAdjustedPercentPerHour(
        baseDrain: Double,
        cellularMegabytesPerHour: Double,
        wifiMegabytesPerHour: Double,
        screenOnMinutesPerHour: Double,
        isLowPowerModeEnabled: Bool
    ) -> Double {
        let normalizedScreenOn = min(max(screenOnMinutesPerHour, 0), 60) / 60
        let cellularGigabytes = max(cellularMegabytesPerHour, 0) / 1_024
        let wifiGigabytes = max(wifiMegabytesPerHour, 0) / 1_024

        var adjustedDrain = baseDrain
        adjustedDrain += normalizedScreenOn * configuration.screenOnPercentPerHourBoost
        adjustedDrain += cellularGigabytes * configuration.cellularPercentPerGBBoost
        adjustedDrain += wifiGigabytes * configuration.wifiPercentPerGBBoost

        if isLowPowerModeEnabled {
            adjustedDrain *= configuration.lowPowerModeSavingsMultiplier
        }

        return adjustedDrain
    }

    private func confidenceScore(sampleCount: Int, trendDrain: Double?) -> Double {
        guard trendDrain != nil else {
            return 0.35
        }

        let sampleConfidence = min(Double(sampleCount) / 16, 1)
        return rounded(0.45 + sampleConfidence * 0.5)
    }

    private func rounded(_ value: Double) -> Double {
        (value * 100).rounded() / 100
    }
}
