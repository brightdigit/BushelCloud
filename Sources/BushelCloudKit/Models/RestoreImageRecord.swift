//
//  RestoreImageRecord.swift
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

public import Foundation
public import MistKit

/// Represents a macOS IPSW restore image for Apple Virtualization framework
public struct RestoreImageRecord: Codable, Sendable {
  /// macOS version (e.g., "14.2.1", "15.0 Beta 3")
  public var version: String

  /// Build identifier (e.g., "23C71", "24A5264n")
  public var buildNumber: String

  /// Official release date
  public var releaseDate: Date

  /// Direct IPSW download link
  public var downloadURL: String

  /// File size in bytes
  public var fileSize: Int

  /// SHA-256 checksum for integrity verification
  public var sha256Hash: String

  /// SHA-1 hash (from MESU/ipsw.me for compatibility)
  public var sha1Hash: String

  /// Whether Apple still signs this restore image (nil if unknown)
  public var isSigned: Bool?

  /// Beta/RC release indicator
  public var isPrerelease: Bool

  /// Data source: "ipsw.me", "mrmacintosh.com", "mesu.apple.com"
  public var source: String

  /// Additional metadata or release notes
  public var notes: String?

  /// When the source last updated this record (nil if unknown)
  public var sourceUpdatedAt: Date?

  public init(
    version: String,
    buildNumber: String,
    releaseDate: Date,
    downloadURL: String,
    fileSize: Int,
    sha256Hash: String,
    sha1Hash: String,
    isSigned: Bool? = nil,
    isPrerelease: Bool,
    source: String,
    notes: String? = nil,
    sourceUpdatedAt: Date? = nil
  ) {
    self.version = version
    self.buildNumber = buildNumber
    self.releaseDate = releaseDate
    self.downloadURL = downloadURL
    self.fileSize = fileSize
    self.sha256Hash = sha256Hash
    self.sha1Hash = sha1Hash
    self.isSigned = isSigned
    self.isPrerelease = isPrerelease
    self.source = source
    self.notes = notes
    self.sourceUpdatedAt = sourceUpdatedAt
  }

  /// CloudKit record name based on build number (e.g., "RestoreImage-23C71")
  public var recordName: String {
    "RestoreImage-\(buildNumber)"
  }
}

// MARK: - CloudKitRecord Conformance

extension RestoreImageRecord: CloudKitRecord {
  public static var cloudKitRecordType: String { "RestoreImage" }

  public func toCloudKitFields() -> [String: FieldValue] {
    var fields: [String: FieldValue] = [
      "version": .string(version),
      "buildNumber": .string(buildNumber),
      "releaseDate": .date(releaseDate),
      "downloadURL": .string(downloadURL),
      "fileSize": .int64(fileSize),
      "sha256Hash": .string(sha256Hash),
      "sha1Hash": .string(sha1Hash),
      "isPrerelease": FieldValue(booleanValue: isPrerelease),
      "source": .string(source),
    ]

    // Optional fields
    if let isSigned {
      fields["isSigned"] = FieldValue(booleanValue: isSigned)
    }

    if let notes {
      fields["notes"] = .string(notes)
    }

    if let sourceUpdatedAt {
      fields["sourceUpdatedAt"] = .date(sourceUpdatedAt)
    }

    return fields
  }

  public static func from(recordInfo: RecordInfo) -> Self? {
    guard let version = recordInfo.fields["version"]?.stringValue,
      let buildNumber = recordInfo.fields["buildNumber"]?.stringValue,
      let releaseDate = recordInfo.fields["releaseDate"]?.dateValue,
      let downloadURL = recordInfo.fields["downloadURL"]?.stringValue,
      let fileSize = recordInfo.fields["fileSize"]?.intValue,
      let sha256Hash = recordInfo.fields["sha256Hash"]?.stringValue,
      let sha1Hash = recordInfo.fields["sha1Hash"]?.stringValue,
      let source = recordInfo.fields["source"]?.stringValue
    else {
      return nil
    }

    return RestoreImageRecord(
      version: version,
      buildNumber: buildNumber,
      releaseDate: releaseDate,
      downloadURL: downloadURL,
      fileSize: fileSize,
      sha256Hash: sha256Hash,
      sha1Hash: sha1Hash,
      isSigned: recordInfo.fields["isSigned"]?.boolValue,
      isPrerelease: recordInfo.fields["isPrerelease"]?.boolValue ?? false,
      source: source,
      notes: recordInfo.fields["notes"]?.stringValue,
      sourceUpdatedAt: recordInfo.fields["sourceUpdatedAt"]?.dateValue
    )
  }

  public static func formatForDisplay(_ recordInfo: RecordInfo) -> String {
    let build = recordInfo.fields["buildNumber"]?.stringValue ?? "Unknown"
    let signed = recordInfo.fields["isSigned"]?.boolValue ?? false
    let prerelease = recordInfo.fields["isPrerelease"]?.boolValue ?? false
    let source = recordInfo.fields["source"]?.stringValue ?? "Unknown"
    let size = recordInfo.fields["fileSize"]?.intValue ?? 0

    let signedStr = signed ? "✅ Signed" : "❌ Unsigned"
    let prereleaseStr = prerelease ? "[Beta/RC]" : ""
    let sizeStr = FormattingHelpers.formatFileSize(size)

    var output = "    \(build) \(prereleaseStr)\n"
    output += "      \(signedStr) | Size: \(sizeStr) | Source: \(source)"
    return output
  }
}
