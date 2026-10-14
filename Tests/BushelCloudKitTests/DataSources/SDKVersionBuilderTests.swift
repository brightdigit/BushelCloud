//
//  SDKVersionBuilderTests.swift
//  BushelCloud
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
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

internal import Foundation
internal import Testing

@testable import BushelCloudKit

@Suite("SDKVersion Builder")
internal struct SDKVersionBuilderTests {
  // MARK: - Helpers

  private static func day(_ value: Int) -> Date {
    Date(timeIntervalSince1970: TimeInterval(value) * 86_400)
  }

  private static func appearance(
    _ version: String,
    _ build: String,
    xcode xcodeBuild: String,
    day dayValue: Int,
    label: String? = nil,
    platform: SDKVersionRecord.Platform = .iOS
  ) -> SDKAppearance {
    SDKAppearance(
      platform: platform,
      version: version,
      buildNumber: build,
      xcodeRecordName: "XcodeVersion-\(xcodeBuild)",
      xcodeReleaseDate: day(dayValue),
      xcodeIsPrerelease: label != nil,
      xcodePrereleaseLabel: label
    )
  }

  private static func record(
    _ records: [SDKVersionRecord],
    build: String
  ) -> SDKVersionRecord? {
    records.first { $0.buildNumber == build }
  }

  // MARK: - Grouping & prerelease detection

  @Test("One record per platform + build across Xcode releases")
  internal func testGroupsByPlatformAndBuild() {
    let records = SDKVersionBuilder.build(from: [
      Self.appearance("27.0", "24A340", xcode: "27A100", day: 10),
      Self.appearance("27.0", "24A340", xcode: "27A200", day: 20),
      Self.appearance(
        "27.0", "24A340", xcode: "27A100", day: 10, platform: .watchOS
      ),
    ])

    #expect(records.count == 2)
    #expect(
      Set(records.map(\.recordName)) == ["SDKVersion-iOS-24A340", "SDKVersion-watchOS-24A340"]
    )
  }

  @Test("Build only in beta Xcodes is a prerelease with the first beta's label")
  internal func testPrereleaseLabel() throws {
    let records = SDKVersionBuilder.build(from: [
      Self.appearance("27.0", "24A5318c", xcode: "27A5", day: 5, label: "Beta 5"),
      Self.appearance("27.0", "24A5318c", xcode: "27A6", day: 3, label: "Beta 4"),
    ])

    let beta = try #require(records.first)
    #expect(beta.isPrerelease)
    #expect(beta.prereleaseLabel == "Beta 4")
    #expect(beta.releaseDate == Self.day(3))
    #expect(beta.xcodeVersion == "XcodeVersion-27A6")
  }

  @Test("Build shipped first in an RC then in a final Xcode is a release")
  internal func testRCBuildBecomesRelease() throws {
    let records = SDKVersionBuilder.build(from: [
      Self.appearance("27.0", "24A340", xcode: "27RC", day: 10, label: "RC 1"),
      Self.appearance("27.0", "24A340", xcode: "27GM", day: 17),
    ])

    let sdk = try #require(records.first)
    #expect(!sdk.isPrerelease)
    #expect(sdk.prereleaseLabel == nil)
    #expect(sdk.releaseDate == Self.day(10))
    #expect(sdk.xcodeVersion == "XcodeVersion-27GM")
  }

  // MARK: - Supersession

  @Test("Beta is superseded by the final SDK with the same version")
  internal func testSupersededBySameVersion() throws {
    let records = SDKVersionBuilder.build(from: [
      Self.appearance("27.0", "24A5318c", xcode: "B5", day: 5, label: "Beta 5"),
      Self.appearance("27", "24A340", xcode: "GM", day: 30),
      Self.appearance("27.0.1", "24A400", xcode: "GM2", day: 60),
    ])

    let beta = try #require(Self.record(records, build: "24A5318c"))
    #expect(beta.supersededBy == "SDKVersion-iOS-24A340")
    #expect(beta.supersededAt == Self.day(30))
  }

  @Test("Beta falls back to the next higher final version released after it")
  internal func testSupersededByHigherVersion() throws {
    let records = SDKVersionBuilder.build(from: [
      Self.appearance("26.0", "23A100", xcode: "OLD", day: 1),
      Self.appearance("26.5", "23F5040a", xcode: "B1", day: 10, label: "Beta 1"),
      Self.appearance("27.0", "24A340", xcode: "GM", day: 40),
      Self.appearance("27.1", "24B80", xcode: "GM2", day: 70),
    ])

    let beta = try #require(Self.record(records, build: "23F5040a"))
    #expect(beta.supersededBy == "SDKVersion-iOS-24A340")
  }

  @Test("Newest beta with no final release is not superseded")
  internal func testCurrentBetaNotSuperseded() throws {
    let records = SDKVersionBuilder.build(from: [
      Self.appearance("27.0", "24A340", xcode: "GM", day: 30),
      Self.appearance("27.1", "24B5040e", xcode: "B2", day: 50, label: "Beta 2"),
    ])

    let beta = try #require(Self.record(records, build: "24B5040e"))
    #expect(beta.isPrerelease)
    #expect(beta.supersededBy == nil)
    #expect(beta.supersededAt == nil)
  }

  @Test("Supersession never crosses platforms")
  internal func testSupersessionIsPerPlatform() throws {
    let records = SDKVersionBuilder.build(from: [
      Self.appearance(
        "27.0", "24R5318c", xcode: "B5", day: 5, label: "Beta 5", platform: .watchOS
      ),
      Self.appearance(
        "27.0", "24A340", xcode: "GM", day: 30, platform: .iOS
      ),
    ])

    let watchBeta = try #require(Self.record(records, build: "24R5318c"))
    #expect(watchBeta.supersededBy == nil)
  }

  // MARK: - Ordering

  @Test("Final SDKs are ordered before prereleases for upload")
  internal func testReleasesSortBeforePrereleases() {
    let records = SDKVersionBuilder.build(from: [
      Self.appearance("27.1", "24B5040e", xcode: "B2", day: 50, label: "Beta 2"),
      Self.appearance("27.0", "24A340", xcode: "GM", day: 30),
      Self.appearance("26.0", "23A100", xcode: "OLD", day: 1),
    ])

    #expect(records.map(\.buildNumber) == ["24A340", "23A100", "24B5040e"])
  }

  // MARK: - Version comparison

  @Test("Version numbers ignore trailing zeros and compare numerically")
  internal func testVersionNumber() {
    #expect(VersionNumber("27") == VersionNumber("27.0"))
    #expect(VersionNumber("27.0.0") == VersionNumber("27"))
    #expect(VersionNumber("26.10") > VersionNumber("26.9"))
    #expect(VersionNumber("27.0.1") > VersionNumber("27.0"))
  }
}
