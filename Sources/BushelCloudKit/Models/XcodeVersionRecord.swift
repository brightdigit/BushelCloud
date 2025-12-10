//
//  XcodeVersionRecord.swift
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

/// Represents an Xcode release with macOS requirements and bundled Swift version
public struct XcodeVersionRecord: Codable, Sendable {
  /// Xcode version (e.g., "15.1", "15.2 Beta 3")
  public var version: String

  /// Build identifier (e.g., "15C65")
  public var buildNumber: String

  /// Release date
  public var releaseDate: Date

  /// Optional developer.apple.com download link
  public var downloadURL: String?

  /// Download size in bytes
  public var fileSize: Int?

  /// Beta/RC indicator
  public var isPrerelease: Bool

  /// Reference to minimum RestoreImage record required (recordName)
  public var minimumMacOS: String?

  /// Reference to bundled Swift compiler (recordName)
  public var includedSwiftVersion: String?

  /// JSON of SDK versions: {"macOS": "14.2", "iOS": "17.2", "watchOS": "10.2"}
  public var sdkVersions: String?

  /// Release notes or additional info
  public var notes: String?

  public init(
    version: String,
    buildNumber: String,
    releaseDate: Date,
    downloadURL: String? = nil,
    fileSize: Int? = nil,
    isPrerelease: Bool,
    minimumMacOS: String? = nil,
    includedSwiftVersion: String? = nil,
    sdkVersions: String? = nil,
    notes: String? = nil
  ) {
    self.version = version
    self.buildNumber = buildNumber
    self.releaseDate = releaseDate
    self.downloadURL = downloadURL
    self.fileSize = fileSize
    self.isPrerelease = isPrerelease
    self.minimumMacOS = minimumMacOS
    self.includedSwiftVersion = includedSwiftVersion
    self.sdkVersions = sdkVersions
    self.notes = notes
  }

  /// CloudKit record name based on build number (e.g., "XcodeVersion-15C65")
  public var recordName: String {
    "XcodeVersion-\(buildNumber)"
  }
}

// MARK: - CloudKitRecord Conformance

extension XcodeVersionRecord: CloudKitRecord {
  public static var cloudKitRecordType: String { "XcodeVersion" }

  public func toCloudKitFields() -> [String: FieldValue] {
    var fields: [String: FieldValue] = [
      "version": .string(version),
      "buildNumber": .string(buildNumber),
      "releaseDate": .date(releaseDate),
      "isPrerelease": FieldValue(booleanValue: isPrerelease),
    ]

    // Optional fields
    if let downloadURL {
      fields["downloadURL"] = .string(downloadURL)
    }

    if let fileSize {
      fields["fileSize"] = .int64(fileSize)
    }

    if let minimumMacOS {
      fields["minimumMacOS"] = .reference(
        FieldValue.Reference(
          recordName: minimumMacOS,
          action: nil
        ))
    }

    if let includedSwiftVersion {
      fields["includedSwiftVersion"] = .reference(
        FieldValue.Reference(
          recordName: includedSwiftVersion,
          action: nil
        ))
    }

    if let sdkVersions {
      fields["sdkVersions"] = .string(sdkVersions)
    }

    if let notes {
      fields["notes"] = .string(notes)
    }

    return fields
  }

  public static func from(recordInfo: RecordInfo) -> Self? {
    guard let version = recordInfo.fields["version"]?.stringValue,
      let buildNumber = recordInfo.fields["buildNumber"]?.stringValue,
      let releaseDate = recordInfo.fields["releaseDate"]?.dateValue
    else {
      return nil
    }

    return XcodeVersionRecord(
      version: version,
      buildNumber: buildNumber,
      releaseDate: releaseDate,
      downloadURL: recordInfo.fields["downloadURL"]?.stringValue,
      fileSize: recordInfo.fields["fileSize"]?.intValue,
      isPrerelease: recordInfo.fields["isPrerelease"]?.boolValue ?? false,
      minimumMacOS: recordInfo.fields["minimumMacOS"]?.referenceValue?.recordName,
      includedSwiftVersion: recordInfo.fields["includedSwiftVersion"]?.referenceValue?.recordName,
      sdkVersions: recordInfo.fields["sdkVersions"]?.stringValue,
      notes: recordInfo.fields["notes"]?.stringValue
    )
  }

  public static func formatForDisplay(_ recordInfo: RecordInfo) -> String {
    let version = recordInfo.fields["version"]?.stringValue ?? "Unknown"
    let build = recordInfo.fields["buildNumber"]?.stringValue ?? "Unknown"
    let releaseDate = recordInfo.fields["releaseDate"]?.dateValue
    let size = recordInfo.fields["fileSize"]?.intValue ?? 0

    let dateStr = releaseDate.map { FormattingHelpers.formatDate($0) } ?? "Unknown"
    let sizeStr = FormattingHelpers.formatFileSize(size)

    var output = "\n  \(version) (Build \(build))\n"
    output += "    Released: \(dateStr) | Size: \(sizeStr)"
    return output
  }
}
