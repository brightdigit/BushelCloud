//
//  SDKVersionRecord+CloudKit.swift
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

internal import BushelFoundation
internal import Foundation
public import MistKit

// MARK: - CloudKitRecord Conformance

extension SDKVersionRecord: CloudKitRecord {
  public static var cloudKitRecordType: String { "SDKVersion" }

  public static func from(recordInfo: RecordInfo) -> Self? {
    guard let platformString = recordInfo.fields["platform"]?.stringValue,
      let platform = Platform(rawValue: platformString),
      let version = recordInfo.fields["version"]?.stringValue,
      let buildNumber = recordInfo.fields["buildNumber"]?.stringValue,
      let releaseDate = recordInfo.fields["releaseDate"]?.dateValue
    else {
      return nil
    }

    return SDKVersionRecord(
      platform: platform,
      version: version,
      buildNumber: buildNumber,
      isPrerelease: recordInfo.fields["isPrerelease"]?.boolValue ?? false,
      prereleaseLabel: recordInfo.fields["prereleaseLabel"]?.stringValue,
      releaseDate: releaseDate,
      xcodeVersion: recordInfo.fields["xcodeVersion"]?.referenceValue?.recordName,
      supersededBy: recordInfo.fields["supersededBy"]?.referenceValue?.recordName,
      supersededAt: recordInfo.fields["supersededAt"]?.dateValue
    )
  }

  public static func formatForDisplay(_ recordInfo: RecordInfo) -> String {
    let platform = recordInfo.fields["platform"]?.stringValue ?? "Unknown"
    let version = recordInfo.fields["version"]?.stringValue ?? "Unknown"
    let build = recordInfo.fields["buildNumber"]?.stringValue ?? "Unknown"
    let label = recordInfo.fields["prereleaseLabel"]?.stringValue
    let releaseDate = recordInfo.fields["releaseDate"]?.dateValue
    let supersededBy = recordInfo.fields["supersededBy"]?.referenceValue?.recordName

    let dateStr = releaseDate.map { Formatters.dateFormat.format($0) } ?? "Unknown"
    let name = [platform, version, label].compactMap(\.self).joined(separator: " ")

    var output = "\n  \(name) (Build \(build))\n"
    output += "    Released: \(dateStr)"
    if let supersededBy {
      output += " | Superseded by: \(supersededBy)"
    }
    return output
  }

  public func toCloudKitFields() -> [String: FieldValue] {
    var fields: [String: FieldValue] = [
      "platform": .string(platform.rawValue),
      "version": .string(version),
      "buildNumber": .string(buildNumber),
      "isPrerelease": FieldValue(booleanValue: isPrerelease),
      "releaseDate": .date(releaseDate),
    ]

    if let prereleaseLabel {
      fields["prereleaseLabel"] = .string(prereleaseLabel)
    }

    if let xcodeVersion {
      fields["xcodeVersion"] = .reference(Reference(recordName: xcodeVersion, action: nil))
    }

    if let supersededBy {
      fields["supersededBy"] = .reference(Reference(recordName: supersededBy, action: nil))
    }

    if let supersededAt {
      fields["supersededAt"] = .date(supersededAt)
    }

    return fields
  }
}
