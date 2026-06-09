// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AppleBatteryTimeRemainingWidget",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "BatteryTimeRemainingWidgetCore",
            targets: ["BatteryTimeRemainingWidgetCore"]
        )
    ],
    targets: [
        .target(
            name: "BatteryTimeRemainingWidgetCore",
            path: "Shared/BatteryTimeRemainingWidgetCore"
        ),
        .testTarget(
            name: "BatteryTimeRemainingWidgetCoreTests",
            dependencies: ["BatteryTimeRemainingWidgetCore"]
        )
    ]
)
