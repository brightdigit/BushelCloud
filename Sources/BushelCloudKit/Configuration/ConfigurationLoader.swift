//
//  ConfigurationLoader.swift
//  BushelCloud
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

public import BushelFoundation
import ConfigKeyKit
import Configuration
import Foundation

// swiftlint:disable file_length

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
          "--virtualbuddy-api-key",
        ])
      )
    )

    // Priority 2: Environment variables
    providers.append(EnvironmentVariablesProvider())

    self.configReader = ConfigReader(providers: providers)
  }

  #if DEBUG
    /// Test-only initializer that accepts a pre-configured ConfigReader
    ///
    /// This allows tests to inject controlled configuration sources without
    /// modifying process-global state (environment variables).
    ///
    /// - Parameter configReader: Pre-configured ConfigReader for testing
    internal init(configReader: ConfigReader) {
      self.configReader = configReader
    }
  #endif

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

  // MARK: - Generic Helper Methods for ConfigKey (with defaults)

  /// Read a string value with automatic CLI → ENV → default fallback
  /// Returns non-optional since ConfigKey has a required default
  private func read(_ key: ConfigKeyKit.ConfigKey<String>) -> String {
    for source in ConfigKeySource.allCases {
      guard let keyString = key.key(for: source) else { continue }
      if let value = readString(forKey: keyString) {
        return value
      }
    }
    return key.defaultValue  // Non-optional!
  }

  /// Read an integer value with automatic CLI → ENV → default fallback
  /// Returns non-optional since ConfigKey has a required default
  private func read(_ key: ConfigKeyKit.ConfigKey<Int>) -> Int {
    for source in ConfigKeySource.allCases {
      guard let keyString = key.key(for: source) else { continue }
      if let value = readInt(forKey: keyString) {
        return value
      }
    }
    return key.defaultValue  // Non-optional!
  }

  /// Read a double value with automatic CLI → ENV → default fallback
  /// Returns non-optional since ConfigKey has a required default
  private func read(_ key: ConfigKeyKit.ConfigKey<Double>) -> Double {
    for source in ConfigKeySource.allCases {
      guard let keyString = key.key(for: source) else { continue }
      if let value = readDouble(forKey: keyString) {
        return value
      }
    }
    return key.defaultValue  // Non-optional!
  }

  /// Read a boolean value with enhanced ENV variable parsing
  ///
  /// Returns non-optional since ConfigKey has a required default.
  ///
  /// Boolean parsing rules:
  /// - CLI: Flag presence indicates true (e.g., --verbose)
  /// - ENV: Accepts "true", "1", "yes" (case-insensitive)
  /// - Empty string in ENV is treated as absent (falls back to default)
  ///
  /// - Parameter key: Configuration key with boolean type
  /// - Returns: Boolean value from CLI/ENV or the key's default
  private func read(_ key: ConfigKeyKit.ConfigKey<Bool>) -> Bool {
    // Try CLI first (presence-based for flags)
    if let cliKey = key.key(for: .commandLine),
      configReader.string(forKey: ConfigKey(cliKey)) != nil
    {
      return true
    }

    // Try ENV (may have string value like VERBOSE=true)
    if let envKey = key.key(for: .environment),
      let envValue = configReader.string(forKey: ConfigKey(envKey))
    {
      let lowercased = envValue.lowercased().trimmingCharacters(in: .whitespaces)
      return lowercased == "true" || lowercased == "1" || lowercased == "yes"
    }

    // Use default value (non-optional)
    return key.defaultValue
  }

  // MARK: - Generic Helper Methods for OptionalConfigKey (without defaults)

  /// Read a string value with automatic CLI → ENV fallback
  /// Returns optional since OptionalConfigKey has no default
  private func read(_ key: ConfigKeyKit.OptionalConfigKey<String>) -> String? {
    for source in ConfigKeySource.allCases {
      guard let keyString = key.key(for: source) else { continue }
      if let value = readString(forKey: keyString) {
        return value
      }
    }
    return nil  // No default available
  }

  /// Read an integer value with automatic CLI → ENV fallback
  /// Returns optional since OptionalConfigKey has no default
  private func read(_ key: ConfigKeyKit.OptionalConfigKey<Int>) -> Int? {
    for source in ConfigKeySource.allCases {
      guard let keyString = key.key(for: source) else { continue }
      if let value = readInt(forKey: keyString) {
        return value
      }
    }
    return nil  // No default available
  }

  /// Read a double value with automatic CLI → ENV fallback
  /// Returns optional since OptionalConfigKey has no default
  private func read(_ key: ConfigKeyKit.OptionalConfigKey<Double>) -> Double? {
    for source in ConfigKeySource.allCases {
      guard let keyString = key.key(for: source) else { continue }
      if let value = readDouble(forKey: keyString) {
        return value
      }
    }
    return nil  // No default available
  }

  // MARK: - Configuration Reading

  /// Load the complete configuration from all providers
  public func loadConfiguration() async throws -> BushelConfiguration {
    // CloudKit configuration (automatic CLI → ENV → default fallback)
    let cloudKit = CloudKitConfiguration(
      containerID: read(ConfigurationKeys.CloudKit.containerID),
      keyID: read(ConfigurationKeys.CloudKit.keyID),
      privateKeyPath: read(ConfigurationKeys.CloudKit.privateKeyPath),
      privateKey: read(ConfigurationKeys.CloudKit.privateKey),
      environment: read(ConfigurationKeys.CloudKit.environment)
    )

    // VirtualBuddy configuration
    let virtualBuddy = VirtualBuddyConfiguration(
      apiKey: read(ConfigurationKeys.VirtualBuddy.apiKey)
    )

    // Fetch configuration: Start with BushelKit's environment loading, then override with CLI
    var fetch = FetchConfiguration.loadFromEnvironment()

    // Override global interval if --min-interval provided
    if let minInterval = read(ConfigurationKeys.Sync.minInterval) {
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
      let intervalKey = ConfigurationKeys.Fetch.intervalKey(for: source.rawValue)
      if let interval = read(intervalKey) {
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
      dryRun: read(ConfigurationKeys.Sync.dryRun),
      restoreImagesOnly: read(ConfigurationKeys.Sync.restoreImagesOnly),
      xcodeOnly: read(ConfigurationKeys.Sync.xcodeOnly),
      swiftOnly: read(ConfigurationKeys.Sync.swiftOnly),
      noBetas: read(ConfigurationKeys.Sync.noBetas),
      noAppleWiki: read(ConfigurationKeys.Sync.noAppleWiki),
      verbose: read(ConfigurationKeys.Sync.verbose),
      force: read(ConfigurationKeys.Sync.force),
      minInterval: read(ConfigurationKeys.Sync.minInterval),
      source: read(ConfigurationKeys.Sync.source)
    )

    // Export command configuration
    let export = ExportConfiguration(
      output: read(ConfigurationKeys.Export.output),
      pretty: read(ConfigurationKeys.Export.pretty),
      signedOnly: read(ConfigurationKeys.Export.signedOnly),
      noBetas: read(ConfigurationKeys.Export.noBetas),
      verbose: read(ConfigurationKeys.Export.verbose)
    )

    // Status command configuration
    let status = StatusConfiguration(
      errorsOnly: read(ConfigurationKeys.Status.errorsOnly),
      detailed: read(ConfigurationKeys.Status.detailed)
    )

    // List command configuration
    let list = ListConfiguration(
      restoreImages: read(ConfigurationKeys.List.restoreImages),
      xcodeVersions: read(ConfigurationKeys.List.xcodeVersions),
      swiftVersions: read(ConfigurationKeys.List.swiftVersions)
    )

    // Clear command configuration
    let clear = ClearConfiguration(
      yes: read(ConfigurationKeys.Clear.yes),
      verbose: read(ConfigurationKeys.Clear.verbose)
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
