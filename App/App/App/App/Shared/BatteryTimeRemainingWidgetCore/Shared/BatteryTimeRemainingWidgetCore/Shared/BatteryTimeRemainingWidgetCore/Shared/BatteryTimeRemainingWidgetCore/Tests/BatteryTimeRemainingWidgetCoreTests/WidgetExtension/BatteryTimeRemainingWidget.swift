#if canImport(SwiftUI) && canImport(UIKit) && canImport(WidgetKit)
import BatteryTimeRemainingWidgetCore
import SwiftUI
import UIKit
import WidgetKit

struct BatteryEntry: TimelineEntry {
    let date: Date
    let batteryLevel: Double
    let isLowPowerModeEnabled: Bool
    let estimate: BatteryRuntimeEstimate
}

struct BatteryTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> BatteryEntry {
        makeEntry(
            date: Date(),
            batteryLevel: 72,
            isLowPowerModeEnabled: false,
            cellularMegabytesPerHour: 220,
            wifiMegabytesPerHour: 780,
            screenOnMinutesPerHour: 22,
            samples: sampleHistory
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (BatteryEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BatteryEntry>) -> Void) {
        Task {
            let store = BatteryTelemetryStore(fileURL: AppGroupConfiguration.telemetryFileURL)
            let samples = (try? await store.loadSamples()) ?? sampleHistory
            let recentUsage = BatteryUsageSummary.placeholder
            let entry = makeEntry(
                date: Date(),
                batteryLevel: max(UIDevice.current.batteryLevel * 100, 0),
                isLowPowerModeEnabled: ProcessInfo.processInfo.isLowPowerModeEnabled,
                cellularMegabytesPerHour: recentUsage.cellularMegabytesPerHour,
                wifiMegabytesPerHour: recentUsage.wifiMegabytesPerHour,
                screenOnMinutesPerHour: recentUsage.screenOnMinutesPerHour,
                samples: samples
            )
            completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(15 * 60))))
        }
    }

    private func makeEntry(
        date: Date,
        batteryLevel: Double,
        isLowPowerModeEnabled: Bool,
        cellularMegabytesPerHour: Double,
        wifiMegabytesPerHour: Double,
        screenOnMinutesPerHour: Double,
        samples: [BatteryUsageSample]
    ) -> BatteryEntry {
        let calculator = BatteryTimeRemainingCalculator()
        let estimate = calculator.estimateRemainingRuntime(
            currentBatteryLevel: batteryLevel,
            isLowPowerModeEnabled: isLowPowerModeEnabled,
            recentCellularMegabytesPerHour: cellularMegabytesPerHour,
            recentWifiMegabytesPerHour: wifiMegabytesPerHour,
            recentScreenOnMinutesPerHour: screenOnMinutesPerHour,
            historicalSamples: samples
        )

        return BatteryEntry(
            date: date,
            batteryLevel: batteryLevel,
            isLowPowerModeEnabled: isLowPowerModeEnabled,
            estimate: estimate
        )
    }

    private var sampleHistory: [BatteryUsageSample] {
        let now = Date()
        return [
            BatteryUsageSample(timestamp: now.addingTimeInterval(-10_800), batteryLevel: 88, isLowPowerModeEnabled: false, screenOnMinutesSincePreviousSample: 0, cellularMegabytesSincePreviousSample: 0, wifiMegabytesSincePreviousSample: 0),
            BatteryUsageSample(timestamp: now.addingTimeInterval(-7_200), batteryLevel: 82, isLowPowerModeEnabled: false, screenOnMinutesSincePreviousSample: 24, cellularMegabytesSincePreviousSample: 210, wifiMegabytesSincePreviousSample: 410),
            BatteryUsageSample(timestamp: now.addingTimeInterval(-3_600), batteryLevel: 76, isLowPowerModeEnabled: false, screenOnMinutesSincePreviousSample: 28, cellularMegabytesSincePreviousSample: 170, wifiMegabytesSincePreviousSample: 620)
        ]
    }
}

struct BatteryWidgetView: View {
    let entry: BatteryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Battery")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(entry.estimate.formattedDuration)
                .font(.title.bold())
            Text("~\(Int(entry.estimate.percentPerHour))% / hr")
                .font(.caption)
            if entry.isLowPowerModeEnabled {
                Label("Low Power", systemImage: "leaf.fill")
                    .font(.caption2)
                    .foregroundStyle(.green)
            }
        }
        .containerBackground(.background, for: .widget)
    }
}

@main
struct BatteryTimeRemainingWidget: Widget {
    let kind = "BatteryTimeRemainingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BatteryTimelineProvider()) { entry in
            BatteryWidgetView(entry: entry)
        }
        .configurationDisplayName("Smart Battery")
        .description("Predicts remaining battery from behavior, data usage, and Low Power Mode.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
#endif
