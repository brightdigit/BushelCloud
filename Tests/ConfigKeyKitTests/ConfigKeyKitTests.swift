//
//  ConfigKeyKitTests.swift
//  ConfigKeyKit
//
//  Tests for ConfigKeyKit configuration infrastructure
//

import Testing
@testable import ConfigKeyKit

@Suite("ConfigKey Tests")
struct ConfigKeyTests {
  @Test("ConfigKey with explicit keys and default")
  func explicitKeys() {
    let key = ConfigKey<String>(cli: "test.key", env: "TEST_KEY", default: "default-value")

    #expect(key.key(for: .commandLine) == "test.key")
    #expect(key.key(for: .environment) == "TEST_KEY")
    #expect(key.defaultValue == "default-value")
  }

  @Test("ConfigKey with base string and default prefix")
  func baseStringWithDefaultPrefix() {
    let key = ConfigKey<String>(bushelPrefixed: "cloudkit.container_id", default: "iCloud.com.example.App")

    #expect(key.key(for: .commandLine) == "cloudkit.container_id")
    #expect(key.key(for: .environment) == "BUSHEL_CLOUDKIT_CONTAINER_ID")
    #expect(key.defaultValue == "iCloud.com.example.App")
  }

  @Test("ConfigKey with base string and no prefix")
  func baseStringNoPrefix() {
    let key = ConfigKey<String>("cloudkit.container_id", envPrefix: nil, default: "iCloud.com.example.App")

    #expect(key.key(for: .commandLine) == "cloudkit.container_id")
    #expect(key.key(for: .environment) == "CLOUDKIT_CONTAINER_ID")
    #expect(key.defaultValue == "iCloud.com.example.App")
  }

  @Test("ConfigKey with default value")
  func defaultValue() {
    let key = ConfigKey<String>(cli: "test.key", env: "TEST_KEY", default: "default-value")

    #expect(key.defaultValue == "default-value")
  }

  @Test("Boolean ConfigKey with default")
  func booleanDefaultValue() {
    let key = ConfigKey<Bool>(bushelPrefixed: "sync.verbose", default: false)

    #expect(key.defaultValue == false)
  }
}

@Suite("NamingStyle Tests")
struct NamingStyleTests {
  @Test("Dot-separated style")
  func dotSeparatedStyle() {
    let style = StandardNamingStyle.dotSeparated
    #expect(style.transform("cloudkit.container_id") == "cloudkit.container_id")
  }

  @Test("Screaming snake case with prefix")
  func screamingSnakeCaseWithPrefix() {
    let style = StandardNamingStyle.screamingSnakeCase(prefix: "BUSHEL")
    #expect(style.transform("cloudkit.container_id") == "BUSHEL_CLOUDKIT_CONTAINER_ID")
  }

  @Test("Screaming snake case without prefix")
  func screamingSnakeCaseNoPrefix() {
    let style = StandardNamingStyle.screamingSnakeCase(prefix: nil)
    #expect(style.transform("cloudkit.container_id") == "CLOUDKIT_CONTAINER_ID")
  }

  @Test("Screaming snake case with nil prefix")
  func screamingSnakeCaseNilPrefix() {
    let style = StandardNamingStyle.screamingSnakeCase(prefix: nil)
    #expect(style.transform("sync.verbose") == "SYNC_VERBOSE")
  }
}

@Suite("ConfigKeySource Tests")
struct ConfigKeySourceTests {
  @Test("All cases")
  func allCases() {
    let sources = ConfigKeySource.allCases
    #expect(sources.count == 2)
    #expect(sources.contains(.commandLine))
    #expect(sources.contains(.environment))
  }
}

@Suite("OptionalConfigKey Tests")
struct OptionalConfigKeyTests {
  @Test("OptionalConfigKey with explicit keys")
  func explicitKeys() {
    let key = OptionalConfigKey<String>(cli: "test.key", env: "TEST_KEY")

    #expect(key.key(for: .commandLine) == "test.key")
    #expect(key.key(for: .environment) == "TEST_KEY")
  }

  @Test("OptionalConfigKey with base string and default prefix")
  func baseStringWithDefaultPrefix() {
    let key = OptionalConfigKey<String>(bushelPrefixed: "cloudkit.key_id")

    #expect(key.key(for: .commandLine) == "cloudkit.key_id")
    #expect(key.key(for: .environment) == "BUSHEL_CLOUDKIT_KEY_ID")
  }

  @Test("OptionalConfigKey with base string and no prefix")
  func baseStringNoPrefix() {
    let key = OptionalConfigKey<String>("cloudkit.key_id", envPrefix: nil)

    #expect(key.key(for: .commandLine) == "cloudkit.key_id")
    #expect(key.key(for: .environment) == "CLOUDKIT_KEY_ID")
  }

  @Test("OptionalConfigKey and ConfigKey generate identical keys")
  func keyGenerationParity() {
    let optional = OptionalConfigKey<String>(bushelPrefixed: "test.key")
    let withDefault = ConfigKey<String>(bushelPrefixed: "test.key", default: "default")

    #expect(optional.key(for: .commandLine) == withDefault.key(for: .commandLine))
    #expect(optional.key(for: .environment) == withDefault.key(for: .environment))
  }

  @Test("OptionalConfigKey for Int type")
  func intOptionalKey() {
    let key = OptionalConfigKey<Int>(bushelPrefixed: "sync.min_interval")

    #expect(key.key(for: .commandLine) == "sync.min_interval")
    #expect(key.key(for: .environment) == "BUSHEL_SYNC_MIN_INTERVAL")
  }

  @Test("OptionalConfigKey for Double type")
  func doubleOptionalKey() {
    let key = OptionalConfigKey<Double>(bushelPrefixed: "fetch.interval_global")

    #expect(key.key(for: .commandLine) == "fetch.interval_global")
    #expect(key.key(for: .environment) == "BUSHEL_FETCH_INTERVAL_GLOBAL")
  }
}
