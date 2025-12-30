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
  @Test("ConfigKey with explicit keys")
  func explicitKeys() {
    let key = ConfigKey<String>(cli: "test.key", env: "TEST_KEY")

    #expect(key.key(for: .commandLine) == "test.key")
    #expect(key.key(for: .environment) == "TEST_KEY")
  }

  @Test("ConfigKey with base string and default prefix")
  func baseStringWithDefaultPrefix() {
    let key = ConfigKey<String>(base: "cloudkit.container_id")

    #expect(key.key(for: .commandLine) == "cloudkit.container_id")
    #expect(key.key(for: .environment) == "BUSHEL_CLOUDKIT_CONTAINER_ID")
  }

  @Test("ConfigKey with base string and no prefix")
  func baseStringNoPrefix() {
    let key = ConfigKey<String>(base: "cloudkit.container_id", envPrefix: nil)

    #expect(key.key(for: .commandLine) == "cloudkit.container_id")
    #expect(key.key(for: .environment) == "CLOUDKIT_CONTAINER_ID")
  }

  @Test("ConfigKey with default value")
  func defaultValue() {
    let key = ConfigKey<String>(cli: "test.key", env: "TEST_KEY", default: "default-value")

    #expect(key.defaultValue == "default-value")
  }

  @Test("Boolean ConfigKey with default")
  func booleanDefaultValue() {
    let key = ConfigKey<Bool>(base: "sync.verbose", default: false)

    #expect(key.boolDefault == false)
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
    let style = StandardNamingStyle.screamingSnakeCaseNoPrefix
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
