//
//  BushelConfiguration.swift
//  BushelCloud
//
//  Configuration structures with validation
//

public import BushelFoundation
import Foundation

// MARK: - Configuration Error

/// Errors that can occur during configuration validation
public struct ConfigurationError: Error, Sendable {
  public let message: String
  public let key: String?

  public init(_ message: String, key: String? = nil) {
    self.message = message
    self.key = key
  }
}

// MARK: - Root Configuration

/// Root configuration containing all subsystem configurations
public struct BushelConfiguration: Sendable {
  public var cloudKit: CloudKitConfiguration?
  public var virtualBuddy: VirtualBuddyConfiguration?
  public var fetch: FetchConfiguration?
  public var sync: SyncConfiguration?
  public var export: ExportConfiguration?
  public var status: StatusConfiguration?
  public var list: ListConfiguration?
  public var clear: ClearConfiguration?

  public init(
    cloudKit: CloudKitConfiguration? = nil,
    virtualBuddy: VirtualBuddyConfiguration? = nil,
    fetch: FetchConfiguration? = nil,
    sync: SyncConfiguration? = nil,
    export: ExportConfiguration? = nil,
    status: StatusConfiguration? = nil,
    list: ListConfiguration? = nil,
    clear: ClearConfiguration? = nil
  ) {
    self.cloudKit = cloudKit
    self.virtualBuddy = virtualBuddy
    self.fetch = fetch
    self.sync = sync
    self.export = export
    self.status = status
    self.list = list
    self.clear = clear
  }

  /// Validate that all required fields are present
  public func validated() throws -> ValidatedBushelConfiguration {
    guard let cloudKit = cloudKit else {
      throw ConfigurationError("CloudKit configuration required", key: "cloudkit")
    }
    return ValidatedBushelConfiguration(
      cloudKit: try cloudKit.validated(),
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

// MARK: - Validated Root Configuration

/// Validated configuration with non-optional required fields
public struct ValidatedBushelConfiguration: Sendable {
  public let cloudKit: ValidatedCloudKitConfiguration
  public let virtualBuddy: VirtualBuddyConfiguration?
  public let fetch: FetchConfiguration?
  public let sync: SyncConfiguration?
  public let export: ExportConfiguration?
  public let status: StatusConfiguration?
  public let list: ListConfiguration?
  public let clear: ClearConfiguration?

  public init(
    cloudKit: ValidatedCloudKitConfiguration,
    virtualBuddy: VirtualBuddyConfiguration?,
    fetch: FetchConfiguration?,
    sync: SyncConfiguration?,
    export: ExportConfiguration?,
    status: StatusConfiguration?,
    list: ListConfiguration?,
    clear: ClearConfiguration?
  ) {
    self.cloudKit = cloudKit
    self.virtualBuddy = virtualBuddy
    self.fetch = fetch
    self.sync = sync
    self.export = export
    self.status = status
    self.list = list
    self.clear = clear
  }
}

// MARK: - CloudKit Configuration

/// CloudKit Server-to-Server authentication configuration
public struct CloudKitConfiguration: Sendable {
  public var containerID: String?
  public var keyID: String?
  public var privateKeyPath: String?

  public init(
    containerID: String? = nil,
    keyID: String? = nil,
    privateKeyPath: String? = nil
  ) {
    self.containerID = containerID
    self.keyID = keyID
    self.privateKeyPath = privateKeyPath
  }

  /// Validate that all required CloudKit fields are present
  public func validated() throws -> ValidatedCloudKitConfiguration {
    guard let containerID = containerID, !containerID.isEmpty else {
      throw ConfigurationError(
        "CloudKit container ID required. Set CLOUDKIT_CONTAINER_ID or use --cloudkit-container-id",
        key: "cloudkit.container_id"
      )
    }
    guard let keyID = keyID, !keyID.isEmpty else {
      throw ConfigurationError(
        "CloudKit key ID required. Set CLOUDKIT_KEY_ID or use --cloudkit-key-id",
        key: "cloudkit.key_id"
      )
    }
    guard let privateKeyPath = privateKeyPath, !privateKeyPath.isEmpty else {
      throw ConfigurationError(
        "CloudKit private key path required. Set CLOUDKIT_PRIVATE_KEY_PATH or use --cloudkit-private-key-path",
        key: "cloudkit.private_key_path"
      )
    }
    return ValidatedCloudKitConfiguration(
      containerID: containerID,
      keyID: keyID,
      privateKeyPath: privateKeyPath
    )
  }
}

/// Validated CloudKit configuration with non-optional fields
public struct ValidatedCloudKitConfiguration: Sendable {
  public let containerID: String
  public let keyID: String
  public let privateKeyPath: String

  public init(containerID: String, keyID: String, privateKeyPath: String) {
    self.containerID = containerID
    self.keyID = keyID
    self.privateKeyPath = privateKeyPath
  }
}

// MARK: - VirtualBuddy Configuration

/// VirtualBuddy TSS API configuration
public struct VirtualBuddyConfiguration: Sendable {
  public var apiKey: String?

  public init(apiKey: String? = nil) {
    self.apiKey = apiKey
  }
}

// MARK: - Sync Configuration

/// Sync command configuration
public struct SyncConfiguration: Sendable {
  public var dryRun: Bool
  public var restoreImagesOnly: Bool
  public var xcodeOnly: Bool
  public var swiftOnly: Bool
  public var noBetas: Bool
  public var noAppleWiki: Bool
  public var verbose: Bool
  public var force: Bool
  public var minInterval: Int?
  public var source: String?

  public init(
    dryRun: Bool = false,
    restoreImagesOnly: Bool = false,
    xcodeOnly: Bool = false,
    swiftOnly: Bool = false,
    noBetas: Bool = false,
    noAppleWiki: Bool = false,
    verbose: Bool = false,
    force: Bool = false,
    minInterval: Int? = nil,
    source: String? = nil
  ) {
    self.dryRun = dryRun
    self.restoreImagesOnly = restoreImagesOnly
    self.xcodeOnly = xcodeOnly
    self.swiftOnly = swiftOnly
    self.noBetas = noBetas
    self.noAppleWiki = noAppleWiki
    self.verbose = verbose
    self.force = force
    self.minInterval = minInterval
    self.source = source
  }
}

// MARK: - Export Configuration

/// Export command configuration
public struct ExportConfiguration: Sendable {
  public var output: String?
  public var pretty: Bool
  public var signedOnly: Bool
  public var noBetas: Bool
  public var verbose: Bool

  public init(
    output: String? = nil,
    pretty: Bool = false,
    signedOnly: Bool = false,
    noBetas: Bool = false,
    verbose: Bool = false
  ) {
    self.output = output
    self.pretty = pretty
    self.signedOnly = signedOnly
    self.noBetas = noBetas
    self.verbose = verbose
  }
}

// MARK: - Status Configuration

/// Status command configuration
public struct StatusConfiguration: Sendable {
  public var errorsOnly: Bool
  public var detailed: Bool

  public init(
    errorsOnly: Bool = false,
    detailed: Bool = false
  ) {
    self.errorsOnly = errorsOnly
    self.detailed = detailed
  }
}

// MARK: - List Configuration

/// List command configuration
public struct ListConfiguration: Sendable {
  public var restoreImages: Bool
  public var xcodeVersions: Bool
  public var swiftVersions: Bool

  public init(
    restoreImages: Bool = false,
    xcodeVersions: Bool = false,
    swiftVersions: Bool = false
  ) {
    self.restoreImages = restoreImages
    self.xcodeVersions = xcodeVersions
    self.swiftVersions = swiftVersions
  }
}

// MARK: - Clear Configuration

/// Clear command configuration
public struct ClearConfiguration: Sendable {
  public var yes: Bool
  public var verbose: Bool

  public init(
    yes: Bool = false,
    verbose: Bool = false
  ) {
    self.yes = yes
    self.verbose = verbose
  }
}
