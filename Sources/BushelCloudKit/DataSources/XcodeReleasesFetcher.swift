//
//  XcodeReleasesFetcher.swift
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

public import BushelFoundation
public import BushelLogging
internal import Foundation
internal import Logging

#if canImport(FelinePineSwift)
  internal import FelinePineSwift
#endif

#if canImport(FoundationNetworking)
  internal import FoundationNetworking
#endif

/// Fetcher for Xcode releases from xcodereleases.com JSON API
public struct XcodeReleasesFetcher: DataSourceFetcher, Sendable {
  public typealias Record = [XcodeVersionRecord]

  /// Xcode versions plus every SDK each release bundled.
  public struct Output: Sendable {
    public let xcodeVersions: [XcodeVersionRecord]
    public let sdkAppearances: [SDKAppearance]
  }

  // MARK: - API Models

  internal struct XcodeRelease: Codable {
    struct Checksums: Codable {
      // API provides checksums but we don't use them currently
    }

    struct Compilers: Codable {
      struct Compiler: Codable {
        let number: String?
      }

      let swift: [Compiler]?
    }

    struct ReleaseDate: Codable {
      let day: Int
      let month: Int
      let year: Int

      var toDate: Date {
        let components = DateComponents(year: year, month: month, day: day)
        return Calendar.current.date(from: components) ?? Date()
      }
    }

    struct Links: Codable {
      struct Download: Codable {
        let url: String
      }

      struct Notes: Codable {
        let url: String
      }

      let download: Download?
      let notes: Notes?
    }

    struct SDKs: Codable {
      struct SDK: Codable {
        let build: String?
        let number: String?
      }

      let iOS: [SDK]?
      let macOS: [SDK]?
      let tvOS: [SDK]?
      let visionOS: [SDK]?
      let watchOS: [SDK]?
    }

    struct Version: Codable {
      struct Release: Codable {
        let beta: Int?
        let rc: Int?

        var isPrerelease: Bool {
          beta != nil || rc != nil
        }

        /// "Beta 3" / "RC 1", or `nil` for a final release.
        var label: String? {
          if let beta {
            return "Beta \(beta)"
          }
          if let rc {
            return "RC \(rc)"
          }
          return nil
        }
      }

      let build: String
      let number: String
      let release: Release
    }

    let checksums: Checksums?
    let compilers: Compilers?
    let date: ReleaseDate
    let links: Links?
    let name: String
    let requires: String
    let sdks: SDKs?
    let version: Version
  }

  // MARK: - Type Properties

  // swiftlint:disable:next force_unwrapping
  private static let xcodeReleasesURL = URL(string: "https://xcodereleases.com/data.json")!

  // MARK: - Initializers

  public init() {}

  // MARK: - Public API

  /// Fetch all Xcode releases from xcodereleases.com
  public func fetch() async throws -> [XcodeVersionRecord] {
    try await fetchWithSDKs().xcodeVersions
  }

  /// Fetch all Xcode releases along with the SDKs each one bundled.
  public func fetchWithSDKs() async throws -> Output {
    let (data, _) = try await URLSession.shared.data(from: Self.xcodeReleasesURL)
    let releases = try JSONDecoder().decode([XcodeRelease].self, from: data)
    return Self.makeOutput(from: releases)
  }

  // MARK: - Mapping

  internal static func makeOutput(from releases: [XcodeRelease]) -> Output {
    Output(
      xcodeVersions: releases.map(makeXcodeVersion(from:)),
      sdkAppearances: releases.flatMap(makeSDKAppearances(from:))
    )
  }

  private static func makeSDKAppearances(from release: XcodeRelease) -> [SDKAppearance] {
    guard let sdks = release.sdks else {
      return []
    }

    let xcodeRecordName = "XcodeVersion-\(release.version.build)"
    let releaseDate = release.date.toDate
    let byPlatform: [(SDKVersionRecord.Platform, [XcodeRelease.SDKs.SDK]?)] = [
      (.iOS, sdks.iOS),
      (.macOS, sdks.macOS),
      (.tvOS, sdks.tvOS),
      (.visionOS, sdks.visionOS),
      (.watchOS, sdks.watchOS),
    ]

    return byPlatform.flatMap { platform, entries in
      (entries ?? []).compactMap { sdk -> SDKAppearance? in
        // Older entries may lack a build or number; they can't be matched, so skip them.
        guard let build = sdk.build, !build.isEmpty, let number = sdk.number else {
          return nil
        }
        return SDKAppearance(
          platform: platform,
          version: number,
          buildNumber: build,
          xcodeRecordName: xcodeRecordName,
          xcodeReleaseDate: releaseDate,
          xcodeIsPrerelease: release.version.release.isPrerelease,
          xcodePrereleaseLabel: release.version.release.label
        )
      }
    }
  }

  private static func makeXcodeVersion(from release: XcodeRelease) -> XcodeVersionRecord {
    // Build SDK versions JSON (if SDK info is available)
    var sdkDict: [String: String] = [:]
    if let sdks = release.sdks {
      if let ios = sdks.iOS?.first, let number = ios.number { sdkDict["iOS"] = number }
      if let macos = sdks.macOS?.first, let number = macos.number { sdkDict["macOS"] = number }
      if let tvos = sdks.tvOS?.first, let number = tvos.number { sdkDict["tvOS"] = number }
      if let visionos = sdks.visionOS?.first, let number = visionos.number {
        sdkDict["visionOS"] = number
      }
      if let watchos = sdks.watchOS?.first, let number = watchos.number {
        sdkDict["watchOS"] = number
      }
    }

    // Encode SDK dictionary to JSON string with proper error handling
    let sdkString: String? = {
      do {
        let data = try JSONEncoder().encode(sdkDict)
        return String(data: data, encoding: .utf8)
      } catch {
        Self.logger.warning(
          "Failed to encode SDK versions for \(release.name): \(error)"
        )
        return nil
      }
    }()

    // Extract Swift version (if compilers info is available)
    let swiftVersion = release.compilers?.swift?.first?.number

    // Store requires string temporarily for later resolution
    // Format: "REQUIRES:<version string>|NOTES_URL:<url>"
    var notesField = "REQUIRES:\(release.requires)"
    if let notesURL = release.links?.notes?.url {
      notesField += "|NOTES_URL:\(notesURL)"
    }

    // Convert download URL string to URL if available
    let downloadURL: URL? = {
      guard let urlString = release.links?.download?.url else {
        return nil
      }
      return URL(string: urlString)
    }()

    return XcodeVersionRecord(
      version: release.version.number,
      buildNumber: release.version.build,
      releaseDate: release.date.toDate,
      downloadURL: downloadURL,
      fileSize: nil,  // Not provided by API
      isPrerelease: release.version.release.isPrerelease,
      minimumMacOS: nil,  // Will be resolved in DataSourcePipeline
      includedSwiftVersion: swiftVersion.map { "SwiftVersion-\($0)" },
      sdkVersions: sdkString,
      notes: notesField
    )
  }
}

// MARK: - Loggable Conformance
extension XcodeReleasesFetcher: Loggable {
  public static let loggingCategory: BushelLogging.Category = .hub
}
