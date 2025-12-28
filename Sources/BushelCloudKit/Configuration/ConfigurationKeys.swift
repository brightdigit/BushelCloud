//
//  ConfigurationKeys.swift
//  BushelCloud
//
//  Configuration keys for reading from providers
//

import Foundation

/// Configuration keys for reading from providers
internal enum ConfigurationKeys {
  /// CloudKit configuration keys
  internal enum CloudKit {
    internal static let containerID = "cloudkit.container_id"
    internal static let containerIDEnv = "CLOUDKIT_CONTAINER_ID"
    internal static let keyID = "cloudkit.key_id"
    internal static let keyIDEnv = "CLOUDKIT_KEY_ID"
    internal static let privateKeyPath = "cloudkit.private_key_path"
    internal static let privateKeyPathEnv = "CLOUDKIT_PRIVATE_KEY_PATH"
  }

  /// VirtualBuddy TSS API configuration keys
  internal enum VirtualBuddy {
    internal static let apiKey = "virtualbuddy.api_key"
    internal static let apiKeyEnv = "VIRTUALBUDDY_API_KEY"
  }

  /// Fetch throttling configuration keys
  internal enum Fetch {
    internal static let intervalGlobal = "fetch.interval_global"
    internal static let intervalGlobalEnv = "BUSHEL_FETCH_INTERVAL_GLOBAL"

    /// Per-source interval key prefix (e.g., "fetch.interval.appledb_dev")
    internal static func intervalKey(for source: String) -> String {
      "fetch.interval.\(source.replacingOccurrences(of: ".", with: "_"))"
    }
  }

  /// Sync command configuration keys
  internal enum Sync {
    internal static let dryRun = "sync.dry_run"
    internal static let restoreImagesOnly = "sync.restore_images_only"
    internal static let xcodeOnly = "sync.xcode_only"
    internal static let swiftOnly = "sync.swift_only"
    internal static let noBetas = "sync.no_betas"
    internal static let noAppleWiki = "sync.no_apple_wiki"
    internal static let verbose = "sync.verbose"
    internal static let force = "sync.force"
    internal static let minInterval = "sync.min_interval"
    internal static let source = "sync.source"
  }

  /// Export command configuration keys
  internal enum Export {
    internal static let output = "export.output"
    internal static let pretty = "export.pretty"
    internal static let signedOnly = "export.signed_only"
    internal static let noBetas = "export.no_betas"
    internal static let verbose = "export.verbose"
  }

  /// Status command configuration keys
  internal enum Status {
    internal static let errorsOnly = "status.errors_only"
    internal static let detailed = "status.detailed"
  }

  /// List command configuration keys
  internal enum List {
    internal static let restoreImages = "list.restore_images"
    internal static let xcodeVersions = "list.xcode_versions"
    internal static let swiftVersions = "list.swift_versions"
  }

  /// Clear command configuration keys
  internal enum Clear {
    internal static let yes = "clear.yes"
    internal static let verbose = "clear.verbose"
  }
}
