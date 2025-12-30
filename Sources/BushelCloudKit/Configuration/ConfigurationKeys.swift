//
//  ConfigurationKeys.swift
//  BushelCloud
//
//  Configuration keys for reading from providers
//

import ConfigKeyKit
import Foundation

/// Configuration keys for reading from providers
internal enum ConfigurationKeys {
  // MARK: - CloudKit Configuration

  /// CloudKit configuration keys
  internal enum CloudKit {
    // Using base key with auto-generation (no prefix for CloudKit ENV vars)
    internal static let containerID = ConfigKey<String>(
      "cloudkit.container_id",
      envPrefix: nil,  // Generates: CLI="cloudkit.container_id", ENV="CLOUDKIT_CONTAINER_ID"
      default: "iCloud.com.brightdigit.Bushel"
    )

    internal static let keyID = OptionalConfigKey<String>(
      "cloudkit.key_id",
      envPrefix: nil
    )

    internal static let privateKeyPath = OptionalConfigKey<String>(
      "cloudkit.private_key_path",
      envPrefix: nil
    )
  }

  // MARK: - VirtualBuddy Configuration

  /// VirtualBuddy TSS API configuration keys
  internal enum VirtualBuddy {
    internal static let apiKey = OptionalConfigKey<String>(
      "virtualbuddy.api_key",
      envPrefix: nil  // Generates: ENV="VIRTUALBUDDY_API_KEY"
    )
  }

  // MARK: - Fetch Configuration

  /// Fetch throttling configuration keys
  internal enum Fetch {
    internal static let intervalGlobal = OptionalConfigKey<Double>(
      bushelPrefixed: "fetch.interval_global"  // Generates: ENV="BUSHEL_FETCH_INTERVAL_GLOBAL"
    )

    /// Generate per-source interval key dynamically
    /// - Parameter source: Data source identifier (e.g., "appledb.dev")
    /// - Returns: An OptionalConfigKey<Double> for the source-specific interval
    internal static func intervalKey(for source: String) -> OptionalConfigKey<Double> {
      let normalized = source.replacingOccurrences(of: ".", with: "_")
      return OptionalConfigKey<Double>(
        "fetch.interval.\(normalized)",
        envPrefix: nil  // CLI: "fetch.interval.appledb_dev", ENV: "FETCH_INTERVAL_APPLEDB_DEV"
      )
    }
  }

  // MARK: - Sync Command Configuration

  /// Sync command configuration keys (using base key with BUSHEL prefix)
  internal enum Sync {
    internal static let dryRun = ConfigKey<Bool>(bushelPrefixed: "sync.dry_run")
    internal static let restoreImagesOnly = ConfigKey<Bool>(bushelPrefixed: "sync.restore_images_only")
    internal static let xcodeOnly = ConfigKey<Bool>(bushelPrefixed: "sync.xcode_only")
    internal static let swiftOnly = ConfigKey<Bool>(bushelPrefixed: "sync.swift_only")
    internal static let noBetas = ConfigKey<Bool>(bushelPrefixed: "sync.no_betas")
    internal static let noAppleWiki = ConfigKey<Bool>(bushelPrefixed: "sync.no_apple_wiki")
    internal static let verbose = ConfigKey<Bool>(bushelPrefixed: "sync.verbose")
    internal static let force = ConfigKey<Bool>(bushelPrefixed: "sync.force")
    internal static let minInterval = OptionalConfigKey<Int>(bushelPrefixed: "sync.min_interval")
    internal static let source = OptionalConfigKey<String>(bushelPrefixed: "sync.source")
  }

  // MARK: - Export Command Configuration

  /// Export command configuration keys
  internal enum Export {
    internal static let output = OptionalConfigKey<String>(bushelPrefixed: "export.output")
    internal static let pretty = ConfigKey<Bool>(bushelPrefixed: "export.pretty")
    internal static let signedOnly = ConfigKey<Bool>(bushelPrefixed: "export.signed_only")
    internal static let noBetas = ConfigKey<Bool>(bushelPrefixed: "export.no_betas")
    internal static let verbose = ConfigKey<Bool>(bushelPrefixed: "export.verbose")
  }

  // MARK: - Status Command Configuration

  /// Status command configuration keys
  internal enum Status {
    internal static let errorsOnly = ConfigKey<Bool>(bushelPrefixed: "status.errors_only")
    internal static let detailed = ConfigKey<Bool>(bushelPrefixed: "status.detailed")
  }

  // MARK: - List Command Configuration

  /// List command configuration keys
  internal enum List {
    internal static let restoreImages = ConfigKey<Bool>(bushelPrefixed: "list.restore_images")
    internal static let xcodeVersions = ConfigKey<Bool>(bushelPrefixed: "list.xcode_versions")
    internal static let swiftVersions = ConfigKey<Bool>(bushelPrefixed: "list.swift_versions")
  }

  // MARK: - Clear Command Configuration

  /// Clear command configuration keys
  internal enum Clear {
    internal static let yes = ConfigKey<Bool>(bushelPrefixed: "clear.yes")
    internal static let verbose = ConfigKey<Bool>(bushelPrefixed: "clear.verbose")
  }
}
