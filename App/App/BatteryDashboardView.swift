#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI

struct BatteryDashboardView: View {
    @ObservedObject var model: SmartBatteryViewModel

    var body: some View {
        NavigationStack {
            List {
                Section("Smart estimate") {
                    HStack {
                        Text("Remaining")
                        Spacer()
                        Text(model.estimate.formattedDuration)
                            .font(.title3.bold())
                    }
                    HStack {
                        Text("Drain")
                        Spacer()
                        Text("\(model.estimate.percentPerHour, specifier: "%.1f")% / hr")
                    }
                    HStack {
                        Text("Confidence")
                        Spacer()
                        Text("\(Int(model.estimate.confidence * 100))%")
                    }
                    Text(model.estimate.explanation)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Current inputs") {
                    LabeledContent("Battery", value: "\(Int(model.currentBatteryLevel))%")
                    LabeledContent("Low Power Mode", value: model.isLowPowerModeEnabled ? "On" : "Off")
                    LabeledContent("Cellular", value: "\(Int(model.recentUsage.cellularMegabytesPerHour)) MB/hr")
                    LabeledContent("Wi-Fi", value: "\(Int(model.recentUsage.wifiMegabytesPerHour)) MB/hr")
                    LabeledContent("Screen Activity", value: "\(Int(model.recentUsage.screenOnMinutesPerHour)) min/hr")
                }
            }
            .navigationTitle("Smart Battery")
            .toolbar {
                Button("Refresh") {
                    Task {
                        await model.refresh()
                    }
                }
            }
        }
    }
}
#endif
