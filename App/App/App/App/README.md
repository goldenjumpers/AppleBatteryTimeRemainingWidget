# Apple Battery Time Remaining Widget

This repository now contains the files in the structure you would add to an iOS app plus a WidgetKit extension:

```text
App/
  AppleBatteryTimeRemainingWidgetApp.swift
  BatteryDashboardView.swift
  BatteryUsageSummaryProvider.swift
  SmartBatteryViewModel.swift
Shared/
  BatteryTimeRemainingWidgetCore/
    AppGroupConfiguration.swift
    BatteryCalculator.swift
    BatteryTelemetryStore.swift
    BatteryUsageSummary.swift
WidgetExtension/
  BatteryTimeRemainingWidget.swift
Tests/
  BatteryTimeRemainingWidgetCoreTests/
    BatteryTimeRemainingCalculatorTests.swift
```

## What each folder does

- `Shared/BatteryTimeRemainingWidgetCore` is the reusable code that both the app and widget need. It calculates runtime, stores battery samples, holds the app group telemetry path, and defines recent usage summaries.
- `App` is the containing iOS app. It enables battery monitoring, records samples, shows a simple dashboard, and writes telemetry that the widget can read.
- `WidgetExtension` is the WidgetKit entry point. It reads the shared telemetry file, runs the calculator, and displays the estimate.
- `Tests` verifies the calculator behavior with Swift Testing.

## How to use this in Xcode

1. Open Xcode and create an **iOS App** target named `AppleBatteryTimeRemainingWidget`.
2. Add a **Widget Extension** target named `BatteryTimeRemainingWidgetExtension`.
3. Drag the repository folders into Xcode:
   - Add `App/*` only to the app target.
   - Add `WidgetExtension/*` only to the widget extension target.
   - Add `Shared/BatteryTimeRemainingWidgetCore/*` to both the app target and the widget extension target, or keep using the Swift Package and link the `BatteryTimeRemainingWidgetCore` library to both targets.
4. Enable **App Groups** for both targets and replace `group.com.example.AppleBatteryTimeRemainingWidget` in `AppGroupConfiguration.swift` with your real app group identifier.
5. Build and run the app once so it can collect and write battery samples.
6. Add the widget to the Home Screen or Lock Screen. The widget will read the shared samples and show an approximate remaining runtime.

## Where to customize inputs

`BatteryUsageSummaryProvider.currentSummary()` currently returns placeholders. Replace that method with privacy-safe aggregates from your app, such as:

- cellular MB/hour your app observed,
- Wi-Fi MB/hour your app observed,
- active session or screen-on minutes per hour,
- any other user-consented behavior signals you want to map into the calculator.

The calculator expects the containing app to gather this data because iOS does not expose all device-wide network, screen-time, or battery telemetry directly to widgets.

## Calculator usage

```swift
let calculator = BatteryTimeRemainingCalculator()
let estimate = calculator.estimateRemainingRuntime(
    currentBatteryLevel: 64,
    isLowPowerModeEnabled: ProcessInfo.processInfo.isLowPowerModeEnabled,
    recentCellularMegabytesPerHour: 350,
    recentWifiMegabytesPerHour: 900,
    recentScreenOnMinutesPerHour: 31,
    historicalSamples: samples
)

print(estimate.formattedDuration)
```

## Run tests

```bash
swift test
```
