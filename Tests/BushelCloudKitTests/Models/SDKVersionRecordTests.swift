//
//  SDKVersionRecordTests.swift
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
internal import MistKit
internal import Testing

@testable import BushelCloudKit

@Suite("SDKVersionRecord CloudKit Mapping")
internal struct SDKVersionRecordTests {
  private static let releaseDate = Date(timeIntervalSince1970: 1_780_000_000)
  private static let supersededAt = Date(timeIntervalSince1970: 1_782_000_000)

  private static let superseded = SDKVersionRecord(
    platform: .iOS,
    version: "27.0",
    buildNumber: "24A5318c",
    isPrerelease: true,
    prereleaseLabel: "Beta 5",
    releaseDate: releaseDate,
    xcodeVersion: "XcodeVersion-27A5318c",
    supersededBy: "SDKVersion-iOS-24A340",
    supersededAt: supersededAt
  )

  private static let minimal = SDKVersionRecord(
    platform: .watchOS,
    version: "27.0",
    buildNumber: "24R340",
    isPrerelease: false,
    releaseDate: releaseDate
  )

  @Test("Record name combines platform and build")
  internal func testRecordName() {
    #expect(Self.superseded.recordName == "SDKVersion-iOS-24A5318c")
    #expect(Self.minimal.recordName == "SDKVersion-watchOS-24R340")
  }

  @Test("Convert to CloudKit fields with all data")
  internal func testToCloudKitFieldsComplete() {
    let fields = Self.superseded.toCloudKitFields()

    fields["platform"]?.assertStringEquals("iOS")
    fields["version"]?.assertStringEquals("27.0")
    fields["buildNumber"]?.assertStringEquals("24A5318c")
    fields["isPrerelease"]?.assertBoolEquals(true)
    fields["prereleaseLabel"]?.assertStringEquals("Beta 5")
    fields["releaseDate"]?.assertDateEquals(Self.releaseDate)
    fields["xcodeVersion"]?.assertReferenceEquals("XcodeVersion-27A5318c")
    fields["supersededBy"]?.assertReferenceEquals("SDKVersion-iOS-24A340")
    fields["supersededAt"]?.assertDateEquals(Self.supersededAt)
  }

  @Test("Optional fields are omitted when nil")
  internal func testToCloudKitFieldsMinimal() {
    let fields = Self.minimal.toCloudKitFields()

    #expect(fields.count == 5)
    #expect(fields["prereleaseLabel"] == nil)
    #expect(fields["xcodeVersion"] == nil)
    #expect(fields["supersededBy"] == nil)
    #expect(fields["supersededAt"] == nil)
  }

  @Test("Roundtrip conversion preserves data")
  internal func testRoundtrip() {
    for original in [Self.superseded, Self.minimal] {
      let recordInfo = MockRecordInfo.create(
        recordType: SDKVersionRecord.cloudKitRecordType,
        recordName: original.recordName,
        fields: original.toCloudKitFields()
      )
      #expect(SDKVersionRecord.from(recordInfo: recordInfo) == original)
    }
  }

  @Test("Unknown platform fails to decode")
  internal func testUnknownPlatform() {
    var fields = Self.minimal.toCloudKitFields()
    fields["platform"] = .string("carOS")
    let recordInfo = MockRecordInfo.create(
      recordType: SDKVersionRecord.cloudKitRecordType,
      recordName: "SDKVersion-carOS-1A1",
      fields: fields
    )
    #expect(SDKVersionRecord.from(recordInfo: recordInfo) == nil)
  }
}
