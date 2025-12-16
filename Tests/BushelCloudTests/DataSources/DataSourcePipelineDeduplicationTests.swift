//
//  DataSourcePipelineDeduplicationTests.swift
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
import Testing

@testable import BushelCloudKit
@testable import BushelFoundation

// MARK: - Suite 1: RestoreImage Deduplication Tests

@Suite("RestoreImage Deduplication")
struct RestoreImageDeduplicationTests {
  let pipeline = DataSourcePipeline()

  @Test("Empty array returns empty")
  func testDeduplicateEmpty() {
    let result = pipeline.deduplicateRestoreImages([])
    #expect(result.isEmpty)
  }

  @Test("Single record returns unchanged")
  func testDeduplicateSingle() {
    let input = [TestFixtures.sonoma14_2_1]
    let result = pipeline.deduplicateRestoreImages(input)

    #expect(result.count == 1)
    #expect(result[0].buildNumber == "23C71")
  }

  @Test("Different builds all preserved")
  func testDeduplicateDifferentBuilds() {
    let input = [
      TestFixtures.sonoma14_2_1,
      TestFixtures.sequoia15_1,
      TestFixtures.sonoma14_0,
    ]
    let result = pipeline.deduplicateRestoreImages(input)

    #expect(result.count == 3)
    // Should be sorted by releaseDate descending
    #expect(result[0].buildNumber == "24B83")  // sequoia15_1 (Nov 2024)
    #expect(result[1].buildNumber == "23C71")  // sonoma14_2_1 (Dec 2023)
    #expect(result[2].buildNumber == "23A344")  // sonoma14_0 (Sep 2023)
  }

  @Test("Duplicate builds merged")
  func testDeduplicateDuplicateBuilds() {
    let input = [
      TestFixtures.sonoma14_2_1,
      TestFixtures.sonoma14_2_1_mesu,
      TestFixtures.sonoma14_2_1_appledb,
    ]
    let result = pipeline.deduplicateRestoreImages(input)

    // Should have only 1 record after merging
    #expect(result.count == 1)
    #expect(result[0].buildNumber == "23C71")
  }

  @Test("Results sorted by release date descending")
  func testSortingByReleaseDateDescending() {
    let input = [
      TestFixtures.sonoma14_0,  // Oldest: Sep 2023
      TestFixtures.sonoma14_2_1,  // Middle: Dec 2023
      TestFixtures.sequoia15_1,  // Newest: Nov 2024
    ]
    let result = pipeline.deduplicateRestoreImages(input)

    #expect(result.count == 3)
    // Verify descending order
    #expect(result[0].releaseDate > result[1].releaseDate)
    #expect(result[1].releaseDate > result[2].releaseDate)
  }
}

// MARK: - Suite 2: RestoreImage Merge Tests

@Suite("RestoreImage Merge Logic")
struct RestoreImageMergeTests {
  let pipeline = DataSourcePipeline()

  // MARK: Backfill Tests

  @Test("Backfill SHA256 hash from second record")
  func testBackfillSHA256() {
    let incomplete = TestFixtures.sonoma14_2_1_incomplete
    let complete = TestFixtures.sonoma14_2_1

    let merged = pipeline.mergeRestoreImages(incomplete, complete)

    #expect(merged.sha256Hash == complete.sha256Hash)
    #expect(!merged.sha256Hash.isEmpty)
  }

  @Test("Backfill SHA1 hash from second record")
  func testBackfillSHA1() {
    let incomplete = TestFixtures.sonoma14_2_1_incomplete
    let complete = TestFixtures.sonoma14_2_1

    let merged = pipeline.mergeRestoreImages(incomplete, complete)

    #expect(merged.sha1Hash == complete.sha1Hash)
    #expect(!merged.sha1Hash.isEmpty)
  }

  @Test("Backfill file size from second record")
  func testBackfillFileSize() {
    let incomplete = TestFixtures.sonoma14_2_1_incomplete
    let complete = TestFixtures.sonoma14_2_1

    let merged = pipeline.mergeRestoreImages(incomplete, complete)

    #expect(merged.fileSize == complete.fileSize)
    #expect(merged.fileSize > 0)
  }

  // MARK: MESU Authority Tests

  @Test("MESU first takes precedence for isSigned")
  func testMESUFirstAuthoritative() {
    let mesu = TestFixtures.sonoma14_2_1_mesu  // isSigned=false
    let ipsw = TestFixtures.sonoma14_2_1  // isSigned=true

    let merged = pipeline.mergeRestoreImages(mesu, ipsw)

    // MESU authority wins
    #expect(merged.isSigned == false)
  }

  @Test("MESU second takes precedence for isSigned")
  func testMESUSecondAuthoritative() {
    let ipsw = TestFixtures.sonoma14_2_1  // isSigned=true
    let mesu = TestFixtures.sonoma14_2_1_mesu  // isSigned=false

    let merged = pipeline.mergeRestoreImages(ipsw, mesu)

    // MESU authority wins regardless of order
    #expect(merged.isSigned == false)
  }

  @Test("MESU authority overrides newer timestamp")
  func testMESUOverridesNewerTimestamp() {
    let appledb = TestFixtures.sonoma14_2_1_appledb  // newer timestamp, isSigned=true
    let mesu = TestFixtures.sonoma14_2_1_mesu  // MESU, isSigned=false

    let merged = pipeline.mergeRestoreImages(appledb, mesu)

    // MESU authority trumps recency
    #expect(merged.isSigned == false)
  }

  @Test("MESU with nil isSigned does not override")
  func testMESUWithNilDoesNotOverride() {
    // Create MESU record with nil isSigned
    let mesuNil = RestoreImageRecord(
      version: "14.2.1",
      buildNumber: "23C71",
      releaseDate: Date(timeIntervalSince1970: 1_702_339_200),
      downloadURL: "https://mesu.apple.com/assets/macos/23C71/RestoreImage.ipsw",
      fileSize: 0,
      sha256Hash: "",
      sha1Hash: "",
      isSigned: nil,  // nil value
      isPrerelease: false,
      source: "mesu.apple.com"
    )
    let ipsw = TestFixtures.sonoma14_2_1  // isSigned=true

    let merged = pipeline.mergeRestoreImages(mesuNil, ipsw)

    // nil doesn't override
    #expect(merged.isSigned == true)
  }

  // MARK: Timestamp Comparison Tests

  @Test("Newer sourceUpdatedAt wins when both non-MESU")
  func testNewerTimestampWins() {
    let older = TestFixtures.signedOld  // isSigned=true, older timestamp
    let newer = TestFixtures.unsignedNewer  // isSigned=false, newer timestamp

    let merged = pipeline.mergeRestoreImages(older, newer)

    // Newer timestamp wins
    #expect(merged.isSigned == false)
  }

  @Test("Older timestamp loses when both non-MESU")
  func testOlderTimestampLoses() {
    let newer = TestFixtures.unsignedNewer  // isSigned=false, newer timestamp
    let older = TestFixtures.signedOld  // isSigned=true, older timestamp

    let merged = pipeline.mergeRestoreImages(newer, older)

    // Newer wins regardless of order
    #expect(merged.isSigned == false)
  }

  @Test("First with timestamp wins when second has no timestamp")
  func testFirstTimestampWinsWhenSecondNil() {
    let withTimestamp = RestoreImageRecord(
      version: "14.3",
      buildNumber: "23D56",
      releaseDate: Date(timeIntervalSince1970: 1_705_000_000),
      downloadURL: "https://example.com/image.ipsw",
      fileSize: 13_600_000_000,
      sha256Hash: "hash123",
      sha1Hash: "hash456",
      isSigned: true,
      isPrerelease: false,
      source: "ipsw.me",
      notes: nil,
      sourceUpdatedAt: Date(timeIntervalSince1970: 1_705_000_000)
    )
    let withoutTimestamp = RestoreImageRecord(
      version: "14.3",
      buildNumber: "23D56",
      releaseDate: Date(timeIntervalSince1970: 1_705_000_000),
      downloadURL: "https://example.com/image.ipsw",
      fileSize: 13_600_000_000,
      sha256Hash: "hash123",
      sha1Hash: "hash456",
      isSigned: false,
      isPrerelease: false,
      source: "appledb.dev",
      notes: nil,
      sourceUpdatedAt: nil
    )

    let merged = pipeline.mergeRestoreImages(withTimestamp, withoutTimestamp)

    // First with timestamp wins
    #expect(merged.isSigned == true)
  }

  @Test("Second with timestamp wins when first has no timestamp")
  func testSecondTimestampWinsWhenFirstNil() {
    let withoutTimestamp = RestoreImageRecord(
      version: "14.3",
      buildNumber: "23D56",
      releaseDate: Date(timeIntervalSince1970: 1_705_000_000),
      downloadURL: "https://example.com/image.ipsw",
      fileSize: 13_600_000_000,
      sha256Hash: "hash123",
      sha1Hash: "hash456",
      isSigned: true,
      isPrerelease: false,
      source: "ipsw.me",
      notes: nil,
      sourceUpdatedAt: nil
    )
    let withTimestamp = RestoreImageRecord(
      version: "14.3",
      buildNumber: "23D56",
      releaseDate: Date(timeIntervalSince1970: 1_705_000_000),
      downloadURL: "https://example.com/image.ipsw",
      fileSize: 13_600_000_000,
      sha256Hash: "hash123",
      sha1Hash: "hash456",
      isSigned: false,
      isPrerelease: false,
      source: "appledb.dev",
      notes: nil,
      sourceUpdatedAt: Date(timeIntervalSince1970: 1_706_000_000)
    )

    let merged = pipeline.mergeRestoreImages(withoutTimestamp, withTimestamp)

    // Second with timestamp wins
    #expect(merged.isSigned == false)
  }

  @Test("Equal timestamps prefer first value when set")
  func testEqualTimestampsPreferFirst() {
    let sameDate = Date(timeIntervalSince1970: 1_705_000_000)
    let first = RestoreImageRecord(
      version: "14.3",
      buildNumber: "23D56",
      releaseDate: Date(timeIntervalSince1970: 1_705_000_000),
      downloadURL: "https://example.com/image.ipsw",
      fileSize: 13_600_000_000,
      sha256Hash: "hash123",
      sha1Hash: "hash456",
      isSigned: true,
      isPrerelease: false,
      source: "ipsw.me",
      notes: nil,
      sourceUpdatedAt: sameDate
    )
    let second = RestoreImageRecord(
      version: "14.3",
      buildNumber: "23D56",
      releaseDate: Date(timeIntervalSince1970: 1_705_000_000),
      downloadURL: "https://example.com/image.ipsw",
      fileSize: 13_600_000_000,
      sha256Hash: "hash123",
      sha1Hash: "hash456",
      isSigned: false,
      isPrerelease: false,
      source: "appledb.dev",
      notes: nil,
      sourceUpdatedAt: sameDate
    )

    let merged = pipeline.mergeRestoreImages(first, second)

    // First wins when timestamps equal
    #expect(merged.isSigned == true)
  }

  // MARK: Nil Handling Tests

  @Test("Both nil timestamps and values disagree prefers false")
  func testBothNilTimestampsPrefersFalse() {
    let signedNilTimestamp = RestoreImageRecord(
      version: "14.3",
      buildNumber: "23D56",
      releaseDate: Date(timeIntervalSince1970: 1_705_000_000),
      downloadURL: "https://example.com/image.ipsw",
      fileSize: 13_600_000_000,
      sha256Hash: "hash123",
      sha1Hash: "hash456",
      isSigned: true,
      isPrerelease: false,
      source: "ipsw.me",
      notes: nil,
      sourceUpdatedAt: nil
    )
    let unsignedNilTimestamp = RestoreImageRecord(
      version: "14.3",
      buildNumber: "23D56",
      releaseDate: Date(timeIntervalSince1970: 1_705_000_000),
      downloadURL: "https://example.com/image.ipsw",
      fileSize: 13_600_000_000,
      sha256Hash: "hash123",
      sha1Hash: "hash456",
      isSigned: false,
      isPrerelease: false,
      source: "appledb.dev",
      notes: nil,
      sourceUpdatedAt: nil
    )

    let merged = pipeline.mergeRestoreImages(signedNilTimestamp, unsignedNilTimestamp)

    // Prefer false when both nil and values disagree
    #expect(merged.isSigned == false)
  }

  @Test("Second isSigned nil preserves first value")
  func testSecondNilPreservesFirst() {
    let signed = TestFixtures.sonoma14_2_1  // isSigned=true
    let incomplete = TestFixtures.sonoma14_2_1_incomplete  // isSigned=nil

    let merged = pipeline.mergeRestoreImages(signed, incomplete)

    #expect(merged.isSigned == true)
  }

  @Test("First isSigned nil uses second value")
  func testFirstNilUsesSecond() {
    let incomplete = TestFixtures.sonoma14_2_1_incomplete  // isSigned=nil
    let signed = TestFixtures.sonoma14_2_1  // isSigned=true

    let merged = pipeline.mergeRestoreImages(incomplete, signed)

    #expect(merged.isSigned == true)
  }

  // MARK: Notes Combination Test

  @Test("Notes combined with semicolon separator")
  func testNotesCombination() {
    let first = RestoreImageRecord(
      version: "14.2.1",
      buildNumber: "23C71",
      releaseDate: Date(timeIntervalSince1970: 1_702_339_200),
      downloadURL: "https://example.com/image.ipsw",
      fileSize: 13_500_000_000,
      sha256Hash: "hash123",
      sha1Hash: "hash456",
      isSigned: true,
      isPrerelease: false,
      source: "ipsw.me",
      notes: "First note"
    )
    let second = RestoreImageRecord(
      version: "14.2.1",
      buildNumber: "23C71",
      releaseDate: Date(timeIntervalSince1970: 1_702_339_200),
      downloadURL: "https://example.com/image.ipsw",
      fileSize: 13_500_000_000,
      sha256Hash: "hash123",
      sha1Hash: "hash456",
      isSigned: true,
      isPrerelease: false,
      source: "appledb.dev",
      notes: "Second note"
    )

    let merged = pipeline.mergeRestoreImages(first, second)

    #expect(merged.notes == "First note; Second note")
  }
}

// MARK: - Suite 3: XcodeVersion Reference Resolution Tests

@Suite("XcodeVersion Reference Resolution")
struct XcodeVersionReferenceResolutionTests {
  let pipeline = DataSourcePipeline()

  @Test("Resolve exact version match 14.2")
  func testResolveExactMatch() {
    let xcode = TestFixtures.xcodeWithRequires_14_2
    let restoreImages = [TestFixtures.restoreImage_14_2]

    let resolved = pipeline.resolveXcodeVersionReferences([xcode], restoreImages: restoreImages)

    #expect(resolved.count == 1)
    #expect(resolved[0].minimumMacOS == "RestoreImage-23C64")
  }

  @Test("Resolve 3-component version 14.2.1")
  func testResolveThreeComponentVersion() {
    let xcode = TestFixtures.xcodeWithRequires_14_2_1
    let restoreImages = [TestFixtures.sonoma14_2_1]

    let resolved = pipeline.resolveXcodeVersionReferences([xcode], restoreImages: restoreImages)

    #expect(resolved.count == 1)
    #expect(resolved[0].minimumMacOS == "RestoreImage-23C71")
  }

  @Test("Resolve 2-component to 3-component match")
  func testResolveTwoToThreeComponent() {
    let xcode = TestFixtures.xcodeWithRequires_14_2
    let restoreImages = [TestFixtures.sonoma14_2_1]  // version="14.2.1"

    let resolved = pipeline.resolveXcodeVersionReferences([xcode], restoreImages: restoreImages)

    // Should match via short version "14.2" to "14.2.1"
    #expect(resolved.count == 1)
    #expect(resolved[0].minimumMacOS == "RestoreImage-23C71")
  }

  @Test("No match leaves minimumMacOS nil")
  func testNoMatchLeavesNil() {
    let xcode = TestFixtures.xcodeWithRequires_14_2
    let restoreImages = [TestFixtures.sequoia15_1]  // Different version

    let resolved = pipeline.resolveXcodeVersionReferences([xcode], restoreImages: restoreImages)

    #expect(resolved.count == 1)
    #expect(resolved[0].minimumMacOS == nil)
  }

  @Test("No REQUIRES field leaves minimumMacOS nil")
  func testNoRequiresLeavesNil() {
    let xcode = TestFixtures.xcodeNoRequires
    let restoreImages = [TestFixtures.sonoma14_2_1]

    let resolved = pipeline.resolveXcodeVersionReferences([xcode], restoreImages: restoreImages)

    #expect(resolved.count == 1)
    #expect(resolved[0].minimumMacOS == nil)
  }

  @Test("Invalid REQUIRES format leaves minimumMacOS nil")
  func testInvalidRequiresLeavesNil() {
    let xcode = TestFixtures.xcodeInvalidRequires
    let restoreImages = [TestFixtures.sonoma14_2_1]

    let resolved = pipeline.resolveXcodeVersionReferences([xcode], restoreImages: restoreImages)

    #expect(resolved.count == 1)
    #expect(resolved[0].minimumMacOS == nil)
  }

  @Test("NOTES_URL preserved after resolution")
  func testNotesURLPreserved() {
    let xcode = TestFixtures.xcodeWithRequires_14_2
    let restoreImages = [TestFixtures.restoreImage_14_2]

    let resolved = pipeline.resolveXcodeVersionReferences([xcode], restoreImages: restoreImages)

    #expect(resolved.count == 1)
    #expect(resolved[0].notes == "https://developer.apple.com/notes")
  }

  @Test("Empty restoreImages array leaves all nil")
  func testEmptyRestoreImagesArray() {
    let xcode = TestFixtures.xcodeWithRequires_14_2
    let restoreImages: [RestoreImageRecord] = []

    let resolved = pipeline.resolveXcodeVersionReferences([xcode], restoreImages: restoreImages)

    #expect(resolved.count == 1)
    #expect(resolved[0].minimumMacOS == nil)
  }

  @Test("Multiple Xcodes resolved correctly")
  func testMultipleXcodeResolution() {
    let xcodes = [
      TestFixtures.xcodeWithRequires_14_2,
      TestFixtures.xcodeWithRequires_14_2_1,
      TestFixtures.xcodeNoRequires,
    ]
    let restoreImages = [
      TestFixtures.restoreImage_14_2,
      TestFixtures.sonoma14_2_1,
    ]

    let resolved = pipeline.resolveXcodeVersionReferences(xcodes, restoreImages: restoreImages)

    #expect(resolved.count == 3)
    // When both "14.2" and "14.2.1" exist, the short version from "14.2.1"
    // overwrites "14.2" in the lookup table (last processed wins)
    // First should resolve to 14.2.1 (due to lookup table collision)
    #expect(resolved[0].minimumMacOS == "RestoreImage-23C71")
    // Second should resolve to 14.2.1 (exact match)
    #expect(resolved[1].minimumMacOS == "RestoreImage-23C71")
    // Third has no REQUIRES, should remain nil
    #expect(resolved[2].minimumMacOS == nil)
  }
}

// MARK: - Suite 4: XcodeVersion Deduplication Tests

@Suite("XcodeVersion Deduplication")
struct XcodeVersionDeduplicationTests {
  let pipeline = DataSourcePipeline()

  @Test("Empty array returns empty")
  func testDeduplicateEmpty() {
    let result = pipeline.deduplicateXcodeVersions([])
    #expect(result.isEmpty)
  }

  @Test("Single record returns unchanged")
  func testDeduplicateSingle() {
    let input = [TestFixtures.xcode15_1]
    let result = pipeline.deduplicateXcodeVersions(input)

    #expect(result.count == 1)
    #expect(result[0].buildNumber == "15C65")
  }

  @Test("Duplicate builds keep first occurrence")
  func testDuplicateBuildsKeepFirst() {
    let input = [
      TestFixtures.xcode15_1,
      TestFixtures.xcode15_1_duplicate,
    ]
    let result = pipeline.deduplicateXcodeVersions(input)

    #expect(result.count == 1)
    // Should keep first occurrence
    #expect(result[0].buildNumber == "15C65")
    #expect(result[0].notes == "Release notes: https://developer.apple.com/xcode/release-notes/")
  }

  @Test("Results sorted by release date descending")
  func testSortingByReleaseDateDescending() {
    let input = [
      TestFixtures.xcode15_1,  // Dec 2023
      TestFixtures.xcode16_0,  // Sep 2024
    ]
    let result = pipeline.deduplicateXcodeVersions(input)

    #expect(result.count == 2)
    // Verify descending order (newer first)
    #expect(result[0].buildNumber == "16A242d")  // xcode16_0
    #expect(result[1].buildNumber == "15C65")  // xcode15_1
  }
}

// MARK: - Suite 5: SwiftVersion Deduplication Tests

@Suite("SwiftVersion Deduplication")
struct SwiftVersionDeduplicationTests {
  let pipeline = DataSourcePipeline()

  @Test("Empty array returns empty")
  func testDeduplicateEmpty() {
    let result = pipeline.deduplicateSwiftVersions([])
    #expect(result.isEmpty)
  }

  @Test("Single record returns unchanged")
  func testDeduplicateSingle() {
    let input = [TestFixtures.swift5_9_2]
    let result = pipeline.deduplicateSwiftVersions(input)

    #expect(result.count == 1)
    #expect(result[0].version == "5.9.2")
  }

  @Test("Duplicate versions keep first occurrence")
  func testDuplicateVersionsKeepFirst() {
    let input = [
      TestFixtures.swift5_9_2,
      TestFixtures.swift5_9_2_duplicate,
    ]
    let result = pipeline.deduplicateSwiftVersions(input)

    #expect(result.count == 1)
    // Should keep first occurrence
    #expect(result[0].version == "5.9.2")
    #expect(result[0].notes == "Stable Swift release bundled with Xcode 15.1")
  }

  @Test("Results sorted by release date descending")
  func testSortingByReleaseDateDescending() {
    let input = [
      TestFixtures.swift5_9_2,  // Dec 2023
      TestFixtures.swift6_1,  // Nov 2024
    ]
    let result = pipeline.deduplicateSwiftVersions(input)

    #expect(result.count == 2)
    // Verify descending order (newer first)
    #expect(result[0].version == "6.1")  // swift6_1
    #expect(result[1].version == "5.9.2")  // swift5_9_2
  }
}
