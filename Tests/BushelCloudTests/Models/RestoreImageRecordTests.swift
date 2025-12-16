//
//  RestoreImageRecordTests.swift
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
import MistKit
import Testing

@testable import BushelCloudKit
@testable import BushelFoundation

@Suite("RestoreImageRecord CloudKit Mapping")
struct RestoreImageRecordTests {
  @Test("Convert to CloudKit fields with all data")
  func testToCloudKitFieldsComplete() {
    let record = TestFixtures.sonoma14_2_1
    let fields = record.toCloudKitFields()

    // Required fields
    fields["version"]?.assertStringEquals("14.2.1")
    fields["buildNumber"]?.assertStringEquals("23C71")
    fields["downloadURL"]?.assertStringEquals(
      "https://updates.cdn-apple.com/2023/macos/23C71/RestoreImage.ipsw"
    )
    fields["fileSize"]?.assertInt64Equals(13_500_000_000)
    fields["sha256Hash"]?.assertStringEquals(
      "abc123def456789abcdef0123456789abcdef0123456789abcdef0123456789ab"
    )
    fields["sha1Hash"]?.assertStringEquals("def4567890123456789abcdef01234567890")
    fields["isPrerelease"]?.assertBoolEquals(false)
    fields["source"]?.assertStringEquals("ipsw.me")

    // Optional fields
    fields["isSigned"]?.assertBoolEquals(true)
    fields["notes"]?.assertStringEquals("Stable release for macOS Sonoma")
    fields["releaseDate"]?.assertIsDate()
    fields["sourceUpdatedAt"]?.assertIsDate()
  }

  @Test("Convert beta record to CloudKit fields")
  func testToCloudKitFieldsBeta() {
    let record = TestFixtures.sequoia15_0_beta
    let fields = record.toCloudKitFields()

    fields["version"]?.assertStringEquals("15.0 Beta 3")
    fields["buildNumber"]?.assertStringEquals("24A5264n")
    fields["isPrerelease"]?.assertBoolEquals(true)
    fields["isSigned"]?.assertBoolEquals(false)
    fields["source"]?.assertStringEquals("mrmacintosh.com")
  }

  @Test("Convert minimal record without optional fields")
  func testToCloudKitFieldsMinimal() {
    let record = TestFixtures.minimalRestoreImage
    let fields = record.toCloudKitFields()

    // Should have required fields
    fields["version"]?.assertStringEquals("14.0")
    fields["buildNumber"]?.assertStringEquals("23A344")
    fields["isPrerelease"]?.assertBoolEquals(false)

    // Should NOT have optional fields
    #expect(fields["isSigned"] == nil)
    #expect(fields["notes"] == nil)
    #expect(fields["sourceUpdatedAt"] == nil)
  }

  @Test("Roundtrip conversion preserves data")
  func testRoundtripConversion() {
    let original = TestFixtures.sonoma14_2_1
    let fields = original.toCloudKitFields()
    let recordInfo = MockRecordInfo.create(
      recordType: "RestoreImage",
      recordName: original.recordName,
      fields: fields
    )

    let reconstructed = RestoreImageRecord.from(recordInfo: recordInfo)

    #expect(reconstructed != nil)
    #expect(reconstructed?.version == original.version)
    #expect(reconstructed?.buildNumber == original.buildNumber)
    #expect(reconstructed?.downloadURL == original.downloadURL)
    #expect(reconstructed?.fileSize == original.fileSize)
    #expect(reconstructed?.sha256Hash == original.sha256Hash)
    #expect(reconstructed?.sha1Hash == original.sha1Hash)
    #expect(reconstructed?.isSigned == original.isSigned)
    #expect(reconstructed?.isPrerelease == original.isPrerelease)
    #expect(reconstructed?.source == original.source)
    #expect(reconstructed?.notes == original.notes)
  }

  @Test("Roundtrip conversion with optional boolean nil")
  func testRoundtripWithNilOptionalBoolean() {
    let original = TestFixtures.minimalRestoreImage
    let fields = original.toCloudKitFields()
    let recordInfo = MockRecordInfo.create(
      recordType: "RestoreImage",
      recordName: original.recordName,
      fields: fields
    )

    let reconstructed = RestoreImageRecord.from(recordInfo: recordInfo)

    #expect(reconstructed != nil)
    #expect(reconstructed?.isSigned == nil)
  }

  @Test("From RecordInfo with missing required fields returns nil")
  func testFromRecordInfoMissingFields() {
    let recordInfo = MockRecordInfo.create(
      recordType: "RestoreImage",
      recordName: "test",
      fields: [
        "version": .string("14.2.1"),
        "buildNumber": .string("23C71"),
        // Missing other required fields
      ]
    )

    let result = RestoreImageRecord.from(recordInfo: recordInfo)
    #expect(result == nil)
  }

  @Test("RecordName generation format")
  func testRecordNameFormat() {
    let record = TestFixtures.sonoma14_2_1
    #expect(record.recordName == "RestoreImage-23C71")

    let betaRecord = TestFixtures.sequoia15_0_beta
    #expect(betaRecord.recordName == "RestoreImage-24A5264n")
  }

  @Test("CloudKit record type is correct")
  func testCloudKitRecordType() {
    #expect(RestoreImageRecord.cloudKitRecordType == "RestoreImage")
  }

  @Test("Boolean field conversion", arguments: [true, false])
  func testBooleanConversion(value: Bool) {
    let record = RestoreImageRecord(
      version: "14.0",
      buildNumber: "23A344",
      releaseDate: Date(),
      downloadURL: "https://example.com/image.ipsw",
      fileSize: 10_000_000_000,
      sha256Hash: "hash256",
      sha1Hash: "hash1",
      isSigned: value,
      isPrerelease: value,
      source: "test"
    )

    let fields = record.toCloudKitFields()
    fields["isSigned"]?.assertBoolEquals(value)
    fields["isPrerelease"]?.assertBoolEquals(value)
  }

  @Test("Format for display produces non-empty string")
  func testFormatForDisplay() {
    let fields = TestFixtures.sonoma14_2_1.toCloudKitFields()
    let recordInfo = MockRecordInfo.create(
      recordType: "RestoreImage",
      recordName: "RestoreImage-23C71",
      fields: fields
    )

    let formatted = RestoreImageRecord.formatForDisplay(recordInfo)
    #expect(!formatted.isEmpty)
    #expect(formatted.contains("23C71"))
  }
}
