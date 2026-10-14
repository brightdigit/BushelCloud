//
//  SDKVersionBuilder.swift
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

public import Foundation

/// One SDK as listed inside one Xcode release on xcodereleases.com.
public struct SDKAppearance: Sendable, Equatable {
  public let platform: SDKVersionRecord.Platform
  public let version: String
  public let buildNumber: String
  /// Record name of the Xcode release that bundled the SDK (`XcodeVersion-<build>`).
  public let xcodeRecordName: String
  public let xcodeReleaseDate: Date
  public let xcodeIsPrerelease: Bool
  /// "Beta 3", "RC 1", or `nil` for a final Xcode release.
  public let xcodePrereleaseLabel: String?

  public init(
    platform: SDKVersionRecord.Platform,
    version: String,
    buildNumber: String,
    xcodeRecordName: String,
    xcodeReleaseDate: Date,
    xcodeIsPrerelease: Bool,
    xcodePrereleaseLabel: String?
  ) {
    self.platform = platform
    self.version = version
    self.buildNumber = buildNumber
    self.xcodeRecordName = xcodeRecordName
    self.xcodeReleaseDate = xcodeReleaseDate
    self.xcodeIsPrerelease = xcodeIsPrerelease
    self.xcodePrereleaseLabel = xcodePrereleaseLabel
  }
}

/// Builds `SDKVersionRecord`s from the SDKs listed in each Xcode release.
///
/// Rules:
/// - One record per platform + SDK build.
/// - An SDK build is a **prerelease** only if every Xcode that bundled it was a
///   prerelease. Once a final Xcode ships the same build, it becomes a release.
/// - `releaseDate` is the earliest Xcode release date that bundled the build.
/// - A prerelease is **superseded** by the earliest final SDK on the same platform
///   with the same version. If no same-version release exists, the earliest final
///   SDK with a higher version released on or after the prerelease is used.
public enum SDKVersionBuilder {
  public static func build(from appearances: [SDKAppearance]) -> [SDKVersionRecord] {
    let grouped = Dictionary(grouping: appearances) { appearance in
      GroupKey(platform: appearance.platform, buildNumber: appearance.buildNumber)
    }

    let records = grouped.values.compactMap(makeRecord(from:))
    return resolveSupersession(records)
      .sorted(by: sortOrder)
  }

  // MARK: - Grouping

  private struct GroupKey: Hashable {
    let platform: SDKVersionRecord.Platform
    let buildNumber: String
  }

  private static func makeRecord(from group: [SDKAppearance]) -> SDKVersionRecord? {
    let byDate = group.sorted { $0.xcodeReleaseDate < $1.xcodeReleaseDate }
    guard let first = byDate.first else {
      return nil
    }

    let firstFinal = byDate.first { !$0.xcodeIsPrerelease }
    let isPrerelease = firstFinal == nil

    return SDKVersionRecord(
      platform: first.platform,
      version: first.version,
      buildNumber: first.buildNumber,
      isPrerelease: isPrerelease,
      prereleaseLabel: isPrerelease ? first.xcodePrereleaseLabel : nil,
      releaseDate: first.xcodeReleaseDate,
      xcodeVersion: (firstFinal ?? first).xcodeRecordName
    )
  }

  // MARK: - Supersession

  private static func resolveSupersession(_ records: [SDKVersionRecord]) -> [SDKVersionRecord] {
    let finalsByPlatform = Dictionary(grouping: records.filter { !$0.isPrerelease }, by: \.platform)

    return records.map { record in
      guard record.isPrerelease,
        let finals = finalsByPlatform[record.platform],
        let replacement = replacement(for: record, among: finals)
      else {
        return record
      }

      var resolved = record
      resolved.supersededBy = replacement.recordName
      resolved.supersededAt = replacement.releaseDate
      return resolved
    }
  }

  private static func replacement(
    for prerelease: SDKVersionRecord,
    among finals: [SDKVersionRecord]
  ) -> SDKVersionRecord? {
    let target = VersionNumber(prerelease.version)
    let earliestFirst = finals.sorted { $0.releaseDate < $1.releaseDate }

    if let sameVersion = earliestFirst.first(where: { VersionNumber($0.version) == target }) {
      return sameVersion
    }

    return
      earliestFirst
      .filter { VersionNumber($0.version) > target && $0.releaseDate >= prerelease.releaseDate }
      .min { VersionNumber($0.version) < VersionNumber($1.version) }
  }

  private static func sortOrder(_ lhs: SDKVersionRecord, _ rhs: SDKVersionRecord) -> Bool {
    // Final releases first so `supersededBy` targets are uploaded before the
    // prereleases that reference them, then newest first.
    if lhs.isPrerelease != rhs.isPrerelease {
      return !lhs.isPrerelease
    }
    if lhs.releaseDate != rhs.releaseDate {
      return lhs.releaseDate > rhs.releaseDate
    }
    return lhs.recordName < rhs.recordName
  }
}

// MARK: - Version Comparison

/// Numeric dotted version where trailing zeros are ignored ("27" == "27.0" == "27.0.0").
internal struct VersionNumber: Comparable, Sendable {
  internal let components: [Int]

  internal init(_ string: String) {
    var parts = string.split(separator: ".").map { Int($0) ?? 0 }
    while parts.count > 1, parts.last == 0 {
      parts.removeLast()
    }
    self.components = parts
  }

  internal static func < (lhs: Self, rhs: Self) -> Bool {
    let count = Swift.max(lhs.components.count, rhs.components.count)
    for index in 0..<count {
      let left = index < lhs.components.count ? lhs.components[index] : 0
      let right = index < rhs.components.count ? rhs.components[index] : 0
      if left != right {
        return left < right
      }
    }
    return false
  }
}
