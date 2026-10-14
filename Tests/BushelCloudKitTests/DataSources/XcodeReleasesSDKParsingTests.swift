//
//  XcodeReleasesSDKParsingTests.swift
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
@testable import BushelFoundation

@Suite("XcodeReleases SDK Parsing")
internal struct XcodeReleasesSDKParsingTests {
  /// Trimmed copy of the xcodereleases.com/data.json shape.
  private static let json = """
    [
      {
        "date": {"day": 28, "month": 9, "year": 2026},
        "name": "Xcode",
        "requires": "26.6",
        "sdks": {
          "iOS": [{"build": "24B5089g", "number": "27.2"}],
          "watchOS": [{"build": "24S5091f", "number": "27.2"}]
        },
        "version": {"build": "27B5028f", "number": "27.2", "release": {"beta": 2}}
      },
      {
        "date": {"day": 5, "month": 10, "year": 2026},
        "name": "Xcode",
        "requires": "26.6",
        "sdks": {
          "iOS": [{"build": "24A340", "number": "27.0"}],
          "tvOS": [{"number": "27.0"}]
        },
        "version": {"build": "27A9275", "number": "27.1", "release": {"rc": 1}}
      },
      {
        "date": {"day": 1, "month": 6, "year": 2010},
        "name": "Xcode",
        "requires": "10.6",
        "version": {"build": "4A100", "number": "4.0", "release": {"release": true}}
      }
    ]
    """

  private static func output() throws -> XcodeReleasesFetcher.Output {
    let releases = try JSONDecoder().decode(
      [XcodeReleasesFetcher.XcodeRelease].self,
      from: Data(json.utf8)
    )
    return XcodeReleasesFetcher.makeOutput(from: releases)
  }

  @Test("Every Xcode release still maps to an XcodeVersion")
  internal func testXcodeVersionsUnchanged() throws {
    let output = try Self.output()
    #expect(output.xcodeVersions.map(\.buildNumber) == ["27B5028f", "27A9275", "4A100"])
    #expect(output.xcodeVersions[0].sdkVersions?.contains("\"iOS\":\"27.2\"") == true)
  }

  @Test("SDKs with a build become appearances; entries without one are skipped")
  internal func testSDKAppearances() throws {
    let appearances = try Self.output().sdkAppearances

    #expect(appearances.count == 3)
    #expect(appearances.allSatisfy { $0.platform != .tvOS })

    let iosBeta = try #require(appearances.first { $0.buildNumber == "24B5089g" })
    #expect(iosBeta.platform == .iOS)
    #expect(iosBeta.version == "27.2")
    #expect(iosBeta.xcodeRecordName == "XcodeVersion-27B5028f")
    #expect(iosBeta.xcodeIsPrerelease)
    #expect(iosBeta.xcodePrereleaseLabel == "Beta 2")

    let iosRC = try #require(appearances.first { $0.buildNumber == "24A340" })
    #expect(iosRC.xcodePrereleaseLabel == "RC 1")
  }
}
