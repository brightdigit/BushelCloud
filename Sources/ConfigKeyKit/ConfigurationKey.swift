//
//  ConfigurationKey.swift
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

import Foundation

// swiftlint:disable file_length

// MARK: - Configuration Key Source

/// Source for configuration keys (CLI arguments or environment variables)
public enum ConfigKeySource: CaseIterable, Sendable {
  /// Command-line arguments (e.g., --cloudkit-container-id)
  case commandLine

  /// Environment variables (e.g., CLOUDKIT_CONTAINER_ID)
  case environment
}

// MARK: - Naming Style

/// Protocol for transforming base key strings into different naming conventions
public protocol NamingStyle: Sendable {
  /// Transform a base key string according to this naming style
  /// - Parameter base: Base key string (e.g., "cloudkit.container_id")
  /// - Returns: Transformed key string
  func transform(_ base: String) -> String
}

/// Common naming styles for configuration keys
public enum StandardNamingStyle: NamingStyle, Sendable {
  /// Dot-separated lowercase (e.g., "cloudkit.container_id")
  case dotSeparated

  /// Screaming snake case with prefix (e.g., "BUSHEL_CLOUDKIT_CONTAINER_ID")
  case screamingSnakeCase(prefix: String?)

  public func transform(_ base: String) -> String {
    switch self {
    case .dotSeparated:
      return base

    case .screamingSnakeCase(let prefix):
      let snakeCase = base.uppercased().replacingOccurrences(of: ".", with: "_")
      if let prefix = prefix {
        return "\(prefix)_\(snakeCase)"
      }
      return snakeCase
    }
  }
}

// MARK: - Configuration Key Protocol

/// Protocol for configuration keys that support multiple sources
public protocol ConfigurationKey: Sendable {
  /// Get the key string for a specific source
  /// - Parameter source: The configuration source (CLI or ENV)
  /// - Returns: The key string for that source, or nil if the key doesn't support that source
  func key(for source: ConfigKeySource) -> String?
}

// MARK: - Generic Configuration Key

/// Configuration key for values with default fallbacks
///
/// Use `ConfigKey` when a configuration value has a sensible default
/// that should be used when not provided by the user. The `read()` method
/// will always return a non-optional value.
///
/// Example:
/// ```swift
/// let containerID = ConfigKey<String>(
///   base: "cloudkit.container_id",
///   default: "iCloud.com.brightdigit.Bushel"
/// )
/// // read(containerID) returns String (non-optional)
/// ```
public struct ConfigKey<Value: Sendable>: ConfigurationKey, Sendable {
  private let baseKey: String?
  private let styles: [ConfigKeySource: any NamingStyle]
  private let explicitKeys: [ConfigKeySource: String]
  public let defaultValue: Value  // Non-optional!

  /// Initialize with explicit CLI and ENV keys and required default
  public init(cli: String? = nil, env: String? = nil, default defaultVal: Value) {
    self.baseKey = nil
    self.styles = [:]
    var keys: [ConfigKeySource: String] = [:]
    if let cli = cli { keys[.commandLine] = cli }
    if let env = env { keys[.environment] = env }
    self.explicitKeys = keys
    self.defaultValue = defaultVal
  }

  /// Initialize from a base key string with naming styles and required default
  /// - Parameters:
  ///   - base: Base key string (e.g., "cloudkit.container_id")
  ///   - styles: Dictionary mapping sources to naming styles
  ///   - defaultVal: Required default value
  public init(
    base: String,
    styles: [ConfigKeySource: any NamingStyle],
    default defaultVal: Value
  ) {
    self.baseKey = base
    self.styles = styles
    self.explicitKeys = [:]
    self.defaultValue = defaultVal
  }

  /// Convenience initializer with standard naming conventions and required default
  /// - Parameters:
  ///   - base: Base key string (e.g., "cloudkit.container_id")
  ///   - envPrefix: Prefix for environment variable (defaults to nil)
  ///   - defaultVal: Required default value
  public init(_ base: String, envPrefix: String? = nil, default defaultVal: Value) {
    self.baseKey = base
    self.styles = [
      .commandLine: StandardNamingStyle.dotSeparated,
      .environment: StandardNamingStyle.screamingSnakeCase(prefix: envPrefix),
    ]
    self.explicitKeys = [:]
    self.defaultValue = defaultVal
  }

  public func key(for source: ConfigKeySource) -> String? {
    // Check for explicit key first
    if let explicit = explicitKeys[source] {
      return explicit
    }

    // Generate from base key and style
    guard let base = baseKey, let style = styles[source] else {
      return nil
    }

    return style.transform(base)
  }
}

extension ConfigKey: CustomDebugStringConvertible {
  public var debugDescription: String {
    let cliKey = key(for: .commandLine) ?? "nil"
    let envKey = key(for: .environment) ?? "nil"
    return "ConfigKey(cli: \(cliKey), env: \(envKey), default: \(defaultValue))"
  }
}

// MARK: - Convenience Initializers for BUSHEL Prefix

extension ConfigKey {
  /// Convenience initializer for keys with BUSHEL prefix
  /// - Parameters:
  ///   - base: Base key string (e.g., "sync.dry_run")
  ///   - defaultVal: Required default value
  public init(bushelPrefixed base: String, default defaultVal: Value) {
    self.init(base, envPrefix: "BUSHEL", default: defaultVal)
  }
}

// MARK: - Optional Configuration Key

/// Configuration key for optional values without defaults
///
/// Use `OptionalConfigKey` when a configuration value has no sensible default
/// and should be `nil` when not provided by the user. The `read()` method
/// will return an optional value.
///
/// Example:
/// ```swift
/// let apiKey = OptionalConfigKey<String>(base: "api.key")
/// // read(apiKey) returns String?
/// ```
public struct OptionalConfigKey<Value: Sendable>: ConfigurationKey, Sendable {
  private let baseKey: String?
  private let styles: [ConfigKeySource: any NamingStyle]
  private let explicitKeys: [ConfigKeySource: String]

  /// Initialize with explicit CLI and ENV keys (no default)
  public init(cli: String? = nil, env: String? = nil) {
    self.baseKey = nil
    self.styles = [:]
    var keys: [ConfigKeySource: String] = [:]
    if let cli = cli { keys[.commandLine] = cli }
    if let env = env { keys[.environment] = env }
    self.explicitKeys = keys
  }

  /// Initialize from a base key string with naming styles (no default)
  /// - Parameters:
  ///   - base: Base key string (e.g., "cloudkit.key_id")
  ///   - styles: Dictionary mapping sources to naming styles
  public init(
    base: String,
    styles: [ConfigKeySource: any NamingStyle]
  ) {
    self.baseKey = base
    self.styles = styles
    self.explicitKeys = [:]
  }

  /// Convenience initializer with standard naming conventions (no default)
  /// - Parameters:
  ///   - base: Base key string (e.g., "cloudkit.key_id")
  ///   - envPrefix: Prefix for environment variable (defaults to nil)
  public init(_ base: String, envPrefix: String? = nil) {
    self.baseKey = base
    self.styles = [
      .commandLine: StandardNamingStyle.dotSeparated,
      .environment: StandardNamingStyle.screamingSnakeCase(prefix: envPrefix),
    ]
    self.explicitKeys = [:]
  }

  public func key(for source: ConfigKeySource) -> String? {
    // Check for explicit key first
    if let explicit = explicitKeys[source] {
      return explicit
    }

    // Generate from base key and style
    guard let base = baseKey, let style = styles[source] else {
      return nil
    }

    return style.transform(base)
  }
}

extension OptionalConfigKey: CustomDebugStringConvertible {
  public var debugDescription: String {
    let cliKey = key(for: .commandLine) ?? "nil"
    let envKey = key(for: .environment) ?? "nil"
    return "OptionalConfigKey(cli: \(cliKey), env: \(envKey))"
  }
}

// MARK: - Convenience Initializers for BUSHEL Prefix

extension OptionalConfigKey {
  /// Convenience initializer for keys with BUSHEL prefix
  /// - Parameter base: Base key string (e.g., "sync.min_interval")
  public init(bushelPrefixed base: String) {
    self.init(base, envPrefix: "BUSHEL")
  }
}

// MARK: - Specialized Initializers for Booleans

extension ConfigKey where Value == Bool {
  /// Initialize a boolean configuration key with non-optional default
  /// - Parameters:
  ///   - cli: Command-line argument name
  ///   - env: Environment variable name
  ///   - defaultVal: Default value (defaults to false)
  public init(cli: String, env: String, default defaultVal: Bool = false) {
    self.baseKey = nil
    self.styles = [:]
    var keys: [ConfigKeySource: String] = [:]
    keys[.commandLine] = cli
    keys[.environment] = env
    self.explicitKeys = keys
    self.defaultValue = defaultVal
  }

  /// Initialize a boolean configuration key from base string
  /// - Parameters:
  ///   - base: Base key string (e.g., "sync.verbose")
  ///   - envPrefix: Prefix for environment variable (defaults to nil)
  ///   - defaultVal: Default value (defaults to false)
  public init(_ base: String, envPrefix: String? = nil, default defaultVal: Bool = false) {
    self.baseKey = base
    self.styles = [
      .commandLine: StandardNamingStyle.dotSeparated,
      .environment: StandardNamingStyle.screamingSnakeCase(prefix: envPrefix),
    ]
    self.explicitKeys = [:]
    self.defaultValue = defaultVal
  }

  /// Non-optional default value accessor for booleans
  @available(*, deprecated, message: "Use defaultValue directly instead")
  public var boolDefault: Bool {
    defaultValue  // Already non-optional!
  }
}

// MARK: - BUSHEL Prefix Convenience

extension ConfigKey where Value == Bool {
  /// Convenience initializer for boolean keys with BUSHEL prefix
  /// - Parameters:
  ///   - base: Base key string (e.g., "sync.verbose")
  ///   - defaultVal: Default value (defaults to false)
  public init(bushelPrefixed base: String, default defaultVal: Bool = false) {
    self.init(base, envPrefix: "BUSHEL", default: defaultVal)
  }
}
