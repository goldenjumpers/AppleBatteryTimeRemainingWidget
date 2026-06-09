#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI

@main
struct AppleBatteryTimeRemainingWidgetApp: App {
    @StateObject private var model = SmartBatteryViewModel()

    var body: some Scene {
        WindowGroup {
            BatteryDashboardView(model: model)
                .task {
                    await model.refresh()
                }
        }
    }
}
#endif
