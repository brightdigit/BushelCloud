//
//  ConfigurationLoader.swift
//  BushelCloud
//
//  Central configuration management using Swift Configuration
//

public import BushelFoundation
import Configuration
import Foundation

/// Actor responsible for loading configuration from CLI arguments and environment variables
public actor ConfigurationLoader {
  private let configReader: ConfigReader

  /// Initialize the configuration loader with command-line and environment providers
  public init() {
    var providers: [any ConfigProvider] = []

    // Priority 1: Command-line arguments (automatically parses all --key value and --flag arguments)
    providers.append(
      CommandLineArgumentsProvider(
        secretsSpecifier: .specific([
          "--cloudkit-key-id",
          "--cloudkit-private-key-path",
          "--virtualbuddy-api-key"
        ])
      )
    )

    // Priority 2: Environment variables
    providers.append(EnvironmentVariablesProvider())

    self.configReader = ConfigReader(providers: providers)
  }

  // MARK: - Helper Methods

  /// Read a string value from configuration
  private func readString(forKey key: String) -> String? {
    configReader.string(forKey: ConfigKey(key))
  }

  /// Read an integer value from configuration
  private func readInt(forKey key: String) -> Int? {
    guard let stringValue = configReader.string(forKey: ConfigKey(key)) else {
      return nil
    }
    return Int(stringValue)
  }

  /// Read a double value from configuration
  private func readDouble(forKey key: String) -> Double? {
    guard let stringValue = configReader.string(forKey: ConfigKey(key)) else {
      return nil
    }
    return Double(stringValue)
  }

  /// Read a boolean value from configuration
  /// Swift Configuration uses presence for booleans (--flag means true)
  private func readBool(forKey key: String) -> Bool? {
    configReader.string(forKey: ConfigKey(key)) != nil
  }

  // MARK: - Configuration Reading

  /// Load the complete configuration from all providers
  public func loadConfiguration() async throws -> BushelConfiguration {
    // CloudKit configuration (dual-key fallback: CLI → ENV → default)
    let cloudKit = CloudKitConfiguration(
      containerID: readString(forKey: ConfigurationKeys.CloudKit.containerID)
        ?? readString(forKey: ConfigurationKeys.CloudKit.containerIDEnv)
        ?? "iCloud.com.brightdigit.Bushel",
      keyID: readString(forKey: ConfigurationKeys.CloudKit.keyID)
        ?? readString(forKey: ConfigurationKeys.CloudKit.keyIDEnv),
      privateKeyPath: readString(forKey: ConfigurationKeys.CloudKit.privateKeyPath)
        ?? readString(forKey: ConfigurationKeys.CloudKit.privateKeyPathEnv)
    )

    // VirtualBuddy configuration
    let virtualBuddy = VirtualBuddyConfiguration(
      apiKey: readString(forKey: ConfigurationKeys.VirtualBuddy.apiKey)
        ?? readString(forKey: ConfigurationKeys.VirtualBuddy.apiKeyEnv)
    )

    // Fetch configuration: Start with BushelKit's environment loading, then override with CLI
    var fetch = FetchConfiguration.loadFromEnvironment()

    // Override global interval if --min-interval provided
    if let minInterval = readInt(forKey: ConfigurationKeys.Sync.minInterval) {
      fetch = FetchConfiguration(
        globalMinimumFetchInterval: TimeInterval(minInterval),
        perSourceIntervals: fetch.perSourceIntervals,
        useDefaults: true
      )
    }

    // Override per-source intervals from CLI or ENV
    var perSourceIntervals = fetch.perSourceIntervals

    for source in DataSource.allCases {
      // Try CLI arg first (e.g., "fetch.interval.appledb_dev")
      // Then try ENV var (e.g., "BUSHEL_FETCH_INTERVAL_APPLEDB_DEV")
      let cliKey = ConfigurationKeys.Fetch.intervalKey(for: source.rawValue)
      if let interval =
        readDouble(forKey: cliKey) ?? readDouble(forKey: source.environmentKey)
      {
        perSourceIntervals[source.rawValue] = interval
      }
    }

    // Rebuild fetch configuration with updated intervals if any were found
    if !perSourceIntervals.isEmpty {
      fetch = FetchConfiguration(
        globalMinimumFetchInterval: fetch.globalMinimumFetchInterval,
        perSourceIntervals: perSourceIntervals,
        useDefaults: fetch.useDefaults
      )
    }

    // Sync command configuration
    let sync = SyncConfiguration(
      dryRun: readBool(forKey: ConfigurationKeys.Sync.dryRun) ?? false,
      restoreImagesOnly: readBool(forKey: ConfigurationKeys.Sync.restoreImagesOnly) ?? false,
      xcodeOnly: readBool(forKey: ConfigurationKeys.Sync.xcodeOnly) ?? false,
      swiftOnly: readBool(forKey: ConfigurationKeys.Sync.swiftOnly) ?? false,
      noBetas: readBool(forKey: ConfigurationKeys.Sync.noBetas) ?? false,
      noAppleWiki: readBool(forKey: ConfigurationKeys.Sync.noAppleWiki) ?? false,
      verbose: readBool(forKey: ConfigurationKeys.Sync.verbose) ?? false,
      force: readBool(forKey: ConfigurationKeys.Sync.force) ?? false,
      minInterval: readInt(forKey: ConfigurationKeys.Sync.minInterval),
      source: readString(forKey: ConfigurationKeys.Sync.source)
    )

    // Export command configuration
    let export = ExportConfiguration(
      output: readString(forKey: ConfigurationKeys.Export.output),
      pretty: readBool(forKey: ConfigurationKeys.Export.pretty) ?? false,
      signedOnly: readBool(forKey: ConfigurationKeys.Export.signedOnly) ?? false,
      noBetas: readBool(forKey: ConfigurationKeys.Export.noBetas) ?? false,
      verbose: readBool(forKey: ConfigurationKeys.Export.verbose) ?? false
    )

    // Status command configuration
    let status = StatusConfiguration(
      errorsOnly: readBool(forKey: ConfigurationKeys.Status.errorsOnly) ?? false,
      detailed: readBool(forKey: ConfigurationKeys.Status.detailed) ?? false
    )

    // List command configuration
    let list = ListConfiguration(
      restoreImages: readBool(forKey: ConfigurationKeys.List.restoreImages) ?? false,
      xcodeVersions: readBool(forKey: ConfigurationKeys.List.xcodeVersions) ?? false,
      swiftVersions: readBool(forKey: ConfigurationKeys.List.swiftVersions) ?? false
    )

    // Clear command configuration
    let clear = ClearConfiguration(
      yes: readBool(forKey: ConfigurationKeys.Clear.yes) ?? false,
      verbose: readBool(forKey: ConfigurationKeys.Clear.verbose) ?? false
    )

    return BushelConfiguration(
      cloudKit: cloudKit,
      virtualBuddy: virtualBuddy,
      fetch: fetch,
      sync: sync,
      export: export,
      status: status,
      list: list,
      clear: clear
    )
  }
}
