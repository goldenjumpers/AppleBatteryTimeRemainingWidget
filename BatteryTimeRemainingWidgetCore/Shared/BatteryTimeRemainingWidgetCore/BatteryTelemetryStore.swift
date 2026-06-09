import Foundation

public actor BatteryTelemetryStore {
    private let fileURL: URL
    private let maximumSampleCount: Int

    public init(fileURL: URL, maximumSampleCount: Int = 96) {
        self.fileURL = fileURL
        self.maximumSampleCount = maximumSampleCount
    }

    public func loadSamples() throws -> [BatteryUsageSample] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode([BatteryUsageSample].self, from: data)
    }

    public func append(_ sample: BatteryUsageSample) throws {
        var samples = try loadSamples()
        samples.append(sample)
        samples = Array(samples.sorted { $0.timestamp < $1.timestamp }.suffix(maximumSampleCount))

        let directoryURL = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(samples)
        try data.write(to: fileURL, options: [.atomic])
    }
}
