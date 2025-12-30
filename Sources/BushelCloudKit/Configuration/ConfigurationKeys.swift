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
      base: "cloudkit.container_id",
      envPrefix: nil,  // Generates: CLI="cloudkit.container_id", ENV="CLOUDKIT_CONTAINER_ID"
      default: "iCloud.com.brightdigit.Bushel"
    )

    internal static let keyID = ConfigKey<String>(
      base: "cloudkit.key_id",
      envPrefix: nil
    )

    internal static let privateKeyPath = ConfigKey<String>(
      base: "cloudkit.private_key_path",
      envPrefix: nil
    )
  }

  // MARK: - VirtualBuddy Configuration

  /// VirtualBuddy TSS API configuration keys
  internal enum VirtualBuddy {
    internal static let apiKey = ConfigKey<String>(
      base: "virtualbuddy.api_key",
      envPrefix: nil  // Generates: ENV="VIRTUALBUDDY_API_KEY"
    )
  }

  // MARK: - Fetch Configuration

  /// Fetch throttling configuration keys
  internal enum Fetch {
    internal static let intervalGlobal = ConfigKey<Double>(
      base: "fetch.interval_global",
      envPrefix: "BUSHEL"  // Generates: ENV="BUSHEL_FETCH_INTERVAL_GLOBAL"
    )

    /// Generate per-source interval key dynamically
    /// - Parameter source: Data source identifier (e.g., "appledb.dev")
    /// - Returns: A ConfigKey<Double> for the source-specific interval
    internal static func intervalKey(for source: String) -> ConfigKey<Double> {
      let normalized = source.replacingOccurrences(of: ".", with: "_")
      return ConfigKey<Double>(
        base: "fetch.interval.\(normalized)",
        envPrefix: nil  // CLI: "fetch.interval.appledb_dev", ENV: "FETCH_INTERVAL_APPLEDB_DEV"
      )
    }
  }

  // MARK: - Sync Command Configuration

  /// Sync command configuration keys (using base key with BUSHEL prefix)
  internal enum Sync {
    internal static let dryRun = ConfigKey<Bool>(base: "sync.dry_run")
    internal static let restoreImagesOnly = ConfigKey<Bool>(base: "sync.restore_images_only")
    internal static let xcodeOnly = ConfigKey<Bool>(base: "sync.xcode_only")
    internal static let swiftOnly = ConfigKey<Bool>(base: "sync.swift_only")
    internal static let noBetas = ConfigKey<Bool>(base: "sync.no_betas")
    internal static let noAppleWiki = ConfigKey<Bool>(base: "sync.no_apple_wiki")
    internal static let verbose = ConfigKey<Bool>(base: "sync.verbose")
    internal static let force = ConfigKey<Bool>(base: "sync.force")
    internal static let minInterval = ConfigKey<Int>(base: "sync.min_interval")
    internal static let source = ConfigKey<String>(base: "sync.source")
  }

  // MARK: - Export Command Configuration

  /// Export command configuration keys
  internal enum Export {
    internal static let output = ConfigKey<String>(base: "export.output")
    internal static let pretty = ConfigKey<Bool>(base: "export.pretty")
    internal static let signedOnly = ConfigKey<Bool>(base: "export.signed_only")
    internal static let noBetas = ConfigKey<Bool>(base: "export.no_betas")
    internal static let verbose = ConfigKey<Bool>(base: "export.verbose")
  }

  // MARK: - Status Command Configuration

  /// Status command configuration keys
  internal enum Status {
    internal static let errorsOnly = ConfigKey<Bool>(base: "status.errors_only")
    internal static let detailed = ConfigKey<Bool>(base: "status.detailed")
  }

  // MARK: - List Command Configuration

  /// List command configuration keys
  internal enum List {
    internal static let restoreImages = ConfigKey<Bool>(base: "list.restore_images")
    internal static let xcodeVersions = ConfigKey<Bool>(base: "list.xcode_versions")
    internal static let swiftVersions = ConfigKey<Bool>(base: "list.swift_versions")
  }

  // MARK: - Clear Command Configuration

  /// Clear command configuration keys
  internal enum Clear {
    internal static let yes = ConfigKey<Bool>(base: "clear.yes")
    internal static let verbose = ConfigKey<Bool>(base: "clear.verbose")
  }
}
